#include <iostream>
#include <fstream>
#include <boost/program_options.hpp>
#include <boost/interprocess/shared_memory_object.hpp>
#include <boost/interprocess/mapped_region.hpp>
#include <signal.h>
#include "uhal/uhal.hpp"

#define VERSION 20220925

const int alarm_period = 3;

struct shared_t {
  bool in_run; // in run flag
  bool in_spill; // in spill flag
  uint32_t mode; // current run mode
  uint32_t status; // current status
  uint32_t fwrev; // firmware version
  uint32_t run_number; // run number
  uint32_t timestamp; // timestamp
  uint32_t run_mode; // run mode
  uint32_t filter_mode; // filter mode
  uint32_t reset[6][4]; // chip-lane reset request
} *shared_data = nullptr;

struct alcor_hit_t {
  uint32_t fine   : 9;
  uint32_t coarse : 15;
  uint32_t tdc    : 2;
  uint32_t pixel  : 3;
  uint32_t column : 3;
  void print() {
    printf(" hit: %d %d %d %d %d \n", column, pixel, tdc, coarse, fine);
  }
};

struct program_options_t {
  std::string connection_filename, device_id, output_filename;
  int chip, lane, usleep_period, staging_size, min_occupancy, clock;
  bool trigger;
} opt;

//int *shared_memory;

bool running = true;
bool in_spill = false;
bool monitor = false;
bool staging_overflow = false;
bool fifo_overflow = false;
bool write_output = false;

char *staging_buffer = nullptr;
char *staging_buffer_end = nullptr;

void
sigint_handler(int signum) {
  std::cout << " --- infinite loop terminate requested" << std::endl;
  running = false;
}

void
sigalrm_handler(int signum) {
  std::cout << " --- waiting for spill " << std::endl;
  alarm(alarm_period);
}

float rollover_period;
float rollover_frequency;

void
decode_data(int chip, int lane, char *buffer, int size, bool verbose = false)
{
  std::cout << " --- start decoding spill " << std::endl;

  auto word = (uint32_t *)buffer;
  auto nwords = size / 4;
  auto last = word + nwords;

  /** first word must be spill header **/
  if ( *word & 0xf0000000 != 0x70000000) {
    printf (" 0x%08x -- spill header mismatch \n", *word);
    while (word < last) {
      printf (" 0x%08x -- \n", *word);
      ++word;
    }
    return;
  }
  
  /** last word must be spill trailer **/
  if ( *(word + nwords - 2) & 0xf0000000 != 0xf0000000 ) {
    printf (" 0x%08x -- spill trailer mismatch \n", *word);
    return;
  }

  /** buffer is safe, decode it **/
  word += 2;
  int rollover_counter = 0, hit_counter = 0;
  int channel_hit_counter[8] = {0};
  while (word < last) {

    /** spill trailer **/
    if ( (*word & 0xf0000000) == 0xf0000000 ) {
      if (verbose) printf (" 0x%08x -- spill trailer \n", *word);
      break;
    }
    
    /** rollover **/
    if (*word == 0x5c5c5c5c) {
      if (verbose) printf(" 0x%08x -- rollover (counter=%d) \n", *word, rollover_counter);
      ++rollover_counter;
      ++word;
      continue;
    }

    /** hit **/
    auto hit = (alcor_hit_t *)word;
    auto pixel = hit->pixel;
    auto column = hit->column;
    auto channel = pixel + 4 * column - 8 * lane;
    hit_counter++;
    if (channel >= 0 && channel < 8) channel_hit_counter[channel]++;
    ++word;
    
  }
  
  std::cout << " --- spill decode succesfull: "
	    << rollover_counter << " rollovers"
	    << " | "
	    << hit_counter << " hits"
	    << " | "
	    << (float)hit_counter / (float)rollover_counter * rollover_frequency << " hits/s"
	    << std::endl;

  //  return;

#if 0
  for (int ich = 0; ich < 8; ++ich)
    std::cout << " ---- channel " << ich << ": " << (float)channel_hit_counter[ich] / (float)rollover_counter * 9765.625 << " hits/s"
	      << std::endl;
#endif
  
  /** post ALCOR rates **/
  std::string alcor_post_system = std::getenv("ALCOR_DIR");
  alcor_post_system += "/measure/readout-box/post_rates.sh " + std::to_string(chip) + " " + std::to_string(lane);
  for (int ich = 0; ich < 8; ++ich) alcor_post_system += std::string(" ") + std::to_string((float)channel_hit_counter[ich] / (float)rollover_counter * rollover_frequency);
  alcor_post_system += std::string(" > /dev/null &");
  //  std::cout << " --- calling system: " << alcor_post_system << std::endl;
  system(alcor_post_system.c_str());
  //  std::cout << " --- called: " << alcor_post_system << std::endl;
  
}

void
decode_trigger(char *buffer, int size, bool verbose = false)
{
  std::cout << " --- start decoding spill " << std::endl;

  auto word = (uint32_t *)buffer;
  auto nwords = size / 4;
  auto last = word + nwords;

  /** last word must be spill trailer **/
  if ( *(word + nwords - 2) & 0xf0000000 != 0xf0000000) {
    printf (" 0x%08x -- spill trailer mismatch \n", *word);
    return;
  }

  /** buffer is safe, decode it **/
  int trigger_counter = 0;
  bool spill_open = false;
  
  while (word < last) {

    /** spill header **/
    if ( (*word & 0xf0000000) == 0x70000000) {
      if (verbose) printf (" 0x%08x -- spill header \n", *word);
      spill_open = true;
      word += 2;
    }
  
    /** spill trailer **/
    else if ( (*word & 0xf0000000) == 0xf0000000 ) {
      if (verbose) printf(" 0x%08x -- spill trailer \n", *word);
      break;
    }
    
    /** trigger **/
    else if ( (*word & 0xf0000000) == 0x90000000 ) {
      if (spill_open) trigger_counter++;
      if (verbose) printf(" 0x%08x -- trigger header\n", *word);
      word += 2;
    }

    /** else **/
    else {
      if (verbose) printf(" 0x%08x -- unexpected word \n", *word);
      ++word;
    }
    
  }
  
  std::cout << " --- spill decode succesfull: "
	    << trigger_counter << " triggers"
	    << std::endl;
 
}

void
process_program_options(int argc, char *argv[], program_options_t &opt)
{
  /** process arguments **/
  namespace po = boost::program_options;
  po::options_description desc("Options");
  try {
    desc.add_options()
      ("help"             , "Print help messages")
      ("connection"       , po::value<std::string>(&opt.connection_filename)->required(), "IPbus XML connection file")
      ("device"           , po::value<std::string>(&opt.device_id)->default_value("kc705"), "Device ID")
      ("chip"             , po::value<int>(&opt.chip)->required(), "ALCOR chip ID")
      ("lane"             , po::value<int>(&opt.lane)->required(), "ALCOR lane")
      ("trigger"          , po::bool_switch(&opt.trigger), "Trigger fifo")
      ("usleep"           , po::value<int>(&opt.usleep_period)->default_value(100), "Microsecond sleep between polling cycles")
      ("staging"          , po::value<int>(&opt.staging_size)->default_value(10 * 1024 * 1024), "Staging buffer size (bytes)")
      ("occupancy"        , po::value<int>(&opt.min_occupancy)->default_value(4096), "FIFO minimum occupancy")
      ("clock"            , po::value<int>(&opt.clock)->default_value(320), "Master clock frequency (MHz)")
      ("output"           , po::value<std::string>(&opt.output_filename), "Output data filename prefix")
      ;

    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);

    if (vm.count("help")) {
      std::cout << desc << std::endl;
      exit(1);
    }
  } catch (std::exception& e) {
    std::cerr << "Error: " << e.what() << std::endl;
    std::cout << desc << std::endl;
    exit(1);
  }

  /** update variables **/
  write_output = !opt.output_filename.empty();
  rollover_period = 32768. / (opt.clock * 1.e6);
  rollover_frequency = 1. / rollover_period;
  std::cout << " --- rollover period / frequency: " << rollover_period * 1.e6 << " us / " << rollover_frequency * 1.e-3 << " kHz " << std::endl;
}

int main(int argc, char *argv[])
{
  std::cout << " --- welcome to ALCOR nano-readout " << std::endl;
  process_program_options(argc, argv, opt);

  //  try {
    using namespace boost::interprocess;
    /** open already created shared memory object **/
    shared_memory_object shm (open_only, "MySharedMemory", read_write);
    /** map the whole shared memory in this process **/
    mapped_region region(shm, read_write);
    shared_data = (shared_t *)region.get_address();
    //    void *shared_address = region.get_address();
    //    shared_data = new (shared_address) shared_t;
    //  } catch (std::exception& e) {
    //    std::cout << " --- could not map shared memory, make sure ctrl-readout is running " << std::endl;
    //    exit(1);
    //  }
  
  /** initialise and retrieve hardware nodes **/
  uhal::disableLogging();
  uhal::ConnectionManager connection_manager("file://" + opt.connection_filename);
  uhal::HwInterface hardware = connection_manager.getDevice(opt.device_id);

  /** make sure run mode is off before starting **/
  if (shared_data->mode != 0x0) {
    std::cout << " --- mode is not zero at startup: 0x"
	      << std::hex << shared_data->mode << std::dec
	      << std::endl;
    exit(1);
  }

  /** data stuff **/
  std::string base_node_name;
  if (opt.trigger) base_node_name =  "trigger_info";
  else base_node_name = "alcor_readout_id" + std::to_string(opt.chip) + "_lane" + std::to_string(opt.lane);
  auto occupancy_node = &hardware.getNode(base_node_name + ".fifo_occupancy");
  auto data_node = &hardware.getNode(base_node_name + ".fifo_data");
  
  /** open output file **/
  std::ofstream fout;
  std::string filename;
  if (write_output) {
    if (opt.trigger) filename = opt.output_filename + ".fifo_24.dat";
    else filename = opt.output_filename + ".fifo_" + std::to_string(4 * opt.chip + opt.lane) + ".dat";
    std::cout << " --- opening output file: " << filename << std::endl;
    fout.open(filename, std::ofstream::out | std::ofstream::binary);
    if (!fout.is_open()) {
      std::cout << " --- cannot open output file: " << filename << std::endl;
      exit(1);
    }
  }
  
  /** write firmware info and other stuff in file header **/
  if (write_output) {
    auto timestamp = std::time(nullptr);
    uint32_t header[32] = {0x0};
    header[0] = 0x000caffe;
    header[1] = VERSION; // readout version
    header[2] = shared_data->fwrev; // firmware version
    header[3] = shared_data->run_number; // run number
    header[4] = shared_data->timestamp; // timestamp
    header[5] = opt.staging_size; // staging size 
    header[6] = shared_data->run_mode; // run mode
    header[7] = shared_data->filter_mode; // filter mode
    fout.write((char *)&header, 64);
  }
  
  /** prepare staging buffer and pointer **/
  staging_buffer = new char[opt.staging_size];
  staging_buffer_end = staging_buffer + opt.staging_size;
  auto staging_buffer_pointer = staging_buffer;
  int buffer_counter = 0;
  
  /** register signal handlers **/
  signal(SIGINT, sigint_handler);
  signal(SIGALRM, sigalrm_handler);

  /** endless loop till start of run (or interrupted) **/
  std::cout << " --- waiting for start of run " << std::endl;
  while (running) {

    /** usleep a bit **/
    usleep(opt.usleep_period);

    /** check run status **/
    if (shared_data->in_run) {
      std::cout << " --- start of run " << std::endl;
      alarm(alarm_period);
      break;
    }

  } /** end of endless loop till start of run (or interrupted) **/

  /** endless loop till end of run (or interrupted) **/
  int n_polls = 0, max_occupancy = 0, integrated_words = 0;
  std::cout << " --- serving till end of run " << std::endl;
  while (running) {

    /** usleep a bit **/
    usleep(opt.usleep_period);

    /** check run status **/
    if (!shared_data->in_run) {
      std::cout << " --- end of run " << std::endl;
      running = false;
    }
    
    /** detect start/end of spill **/
    if (in_spill != shared_data->in_spill) { // spill status has changed
      in_spill = shared_data->in_spill;
      if (in_spill) {
	std::cout << " --- start of spill " << std::endl;
	alarm(0); // cancel alarm when spill goes up
      }
      else {
	std::cout << " --- end of spill " << std::endl;
	monitor = true; // monitor when spill goes down
      }
    }
    
    if (!monitor && (fifo_overflow || staging_overflow || !in_spill)) continue;
    n_polls++;

    /** read fifo occupancy **/
    auto occupancy_register = occupancy_node->read();
    hardware.dispatch();
    auto occupancy_value = (occupancy_register.value() & 0xffff);
    if (occupancy_value <= opt.min_occupancy && !monitor) continue;
    if (occupancy_value > max_occupancy) max_occupancy = occupancy_value;

    /** check if fifo overflow **/
    if (!fifo_overflow && occupancy_value >= 8191) {
      std::cout << " --- fifo overflow " << std::endl;
      if (!opt.trigger) shared_data->reset[opt.chip][opt.lane] = 1;
      fifo_overflow = true;
      continue;
    }

    /** check space left on buffer **/
    auto bytes = occupancy_value * 4;
    if ( (int)(staging_buffer_end - staging_buffer_pointer) < bytes) {
      std::cout << " --- staging buffer overflow " << std::endl;
      if (!opt.trigger) shared_data->reset[opt.chip][opt.lane] = 2;
      staging_overflow = true;
      continue;
    }
    
    /** read fifo data **/
    auto data_register = data_node->readBlock(occupancy_value);
    hardware.dispatch();
    integrated_words += occupancy_value;

    /** stage data on buffer **/
    std::memcpy(staging_buffer_pointer, data_register.data(), bytes);
    staging_buffer_pointer += bytes;
    
    /******* must download all FIFO data before monitor
	     this is why I had put monitor at the end
	     find a good solution ******/
    
    /** monitor **/
    if (monitor) {

      if (fifo_overflow || staging_overflow) {
	staging_buffer_pointer = staging_buffer; // write empty event	
      }
      
      /** write staging buffer **/
      int buffer_size = (int)(staging_buffer_pointer - staging_buffer);
      if (write_output) {
	uint32_t header[4];
	header[0] = 0x123caffe;
	header[1] = opt.trigger ? 24 : 4 * opt.chip + opt.lane;
	header[2] = buffer_counter++;
	header[3] = buffer_size;
	fout.write((char *)&header, 16);
	fout.write(staging_buffer, buffer_size);
      }

      /** post statistics **/
      if (!opt.trigger) {
 	/** post ALCOR lane broken **/
	if (fifo_overflow) {
	  std::string alcor_post_system = std::getenv("ALCOR_DIR");
	  alcor_post_system += "/measure/readout-box/post_broken.sh " + std::to_string(opt.chip) + " " + std::to_string(opt.lane);
	  alcor_post_system += std::string(" > /dev/null &");
	  system(alcor_post_system.c_str());
	}
	std::string post_spill_system = std::getenv("ALCOR_DIR");
	post_spill_system += "/measure/readout-box/post_spill.sh " + std::to_string(opt.chip) + " " + std::to_string(opt.lane) + " " + std::to_string(n_polls) + " " + std::to_string(max_occupancy) + " " + std::to_string(4 * integrated_words);
	post_spill_system += std::string(" > /dev/null &");
	system(post_spill_system.c_str());
      }
      
      /** printout monitor **/
      std::cout << " n_polls: " << n_polls
		<< " max_occupancy: " << max_occupancy
		<< " integrated_bytes: " << 4 * integrated_words
		<< std::endl;
      n_polls = max_occupancy = integrated_words = 0;
      monitor = fifo_overflow = staging_overflow = false;

      /** decode **/
      if (opt.trigger) decode_trigger(staging_buffer, buffer_size);
      else decode_data(opt.chip, opt.lane, staging_buffer, buffer_size);
      
      staging_buffer_pointer = staging_buffer;
      alarm(alarm_period);
    }

  }

  /** close output file **/
  if (write_output) {
    fout.close();
    std::cout << " --- output file closed: " << filename << std::endl;
  } 
  
  return 0;
}

