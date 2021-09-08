#include <iostream>
#include <iomanip>
#include <fstream>
#include <string>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
#include <chrono>
#include <boost/program_options.hpp>
#include "uhal/uhal.hpp"

#include "sys/ipc.h"
#include "sys/shm.h"

/** readout control protocol works over SHM
    the following commands are accepted 
    R (Reset) 
    B (Begin) [runParams]
    E (End)
    Q (Quit)
**/

#define PARANOID

#define MAX_FIFOS 26

#define CTRL_SHMFILE "/tmp/alcorReadoutController.shmkey"
#define CTRL_PROJID 2333
#define CTRL_SHMSIZE 1024

bool running = true;
bool monitor = false;

struct program_options_t {
  std::string connection_filename, device_id, output_filename;
  int staging_size, fifo_mask, fifo_occupancy, monitor_period, usleep_period, run_mode, timeout;
  bool standalone, merged_lanes, send_pulse, reset_fifo, send_reset, quit_on_monitor;
};

struct ipbus_struct_t {
  const uhal::Node *occupancy_node[MAX_FIFOS] = {nullptr}, *data_node[MAX_FIFOS] = {nullptr}, *pulse_node[MAX_FIFOS] = {nullptr};
};

void process_program_options(int argc, char *argv[], program_options_t &opt);


void
sigint_handler(int signum) {
  std::cout << " --- infinite loop terminate requested" << std::endl;
  running = false;
}

void
sigalrm_handler(int signum) {
  monitor = true;
}


void write_buffer_to_file(std::ofstream &fout, int buffer_source, int buffer_counter, uint8_t *buffer, int buffer_size)
{
  uint32_t header[4];
  header[0] = 0x123caffe;
  header[1] = buffer_source;
  header[2] = buffer_counter;
  header[3] = buffer_size;
  fout.write((char *)&header, 16);
  fout.write((char *)buffer, buffer_size);
}

int
shm_connect(const char* keyFile, int proj, size_t size)
{
  auto key = ftok(keyFile, proj);
  if (key < 0) {
    std::cerr << " [shm_connect] ftok error: " << strerror(errno) << std::endl;
    exit(1);
  }
  auto shmid = shmget(key, size, IPC_CREAT | IPC_EXCL | 0664);
  if (shmid == -1) {
    if (errno == EEXIST) {
      shmid = shmget(key, 0, 0);
      std::cout << " [shm_connect] shared memory already exists: shmid = " << shmid << std::endl;
    } else {
      std::cerr << " [shm_connect] shmget error: " << strerror(errno) << std::endl;
      exit(1);
    }
  } else {
    std::cout << " [shm_connect] shared memory succesfully created: shmid = " << shmid << std::endl;
  }
  return shmid;
}

void
shm_cleanup(int id, void *p, char *d)
{
  if (shmdt(p) < 0) {
    std::cerr << " [shm_cleanup] shmdt error: " << strerror(errno) << std::endl;
    exit(1);
  }
  if (shmctl(id, IPC_RMID, nullptr) == -1) {
    std::cerr << " [shm_cleanup] shmctl error: " << strerror(errno) << std::endl;
    exit(1);
  }
  std::cout << " [shm_cleanup] shared memory succesfully removed: shmid = " << id << std::endl;
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
      ("fifo"             , po::value<int>(&opt.fifo_mask)->default_value(0xffff), "FIFO mask")
      ("occupancy"        , po::value<int>(&opt.fifo_occupancy)->default_value(4096), "FIFO minimum occupancy")
      ("usleep"           , po::value<int>(&opt.usleep_period)->default_value(0), "Microsecond sleep between polling cycles")
      ("staging"          , po::value<int>(&opt.staging_size)->default_value(1048576), "Staging buffer size (bytes)")
      ("monitor-period"   , po::value<int>(&opt.monitor_period)->default_value(1), "Monitor period")
      ("mode"             , po::value<int>(&opt.run_mode)->default_value(0x3), "Run mode")
      ("timeout"          , po::value<int>(&opt.timeout)->default_value(0), "Readout timeout")
      ("output"           , po::value<std::string>(&opt.output_filename), "Output data file")
      ("standalone"       , po::bool_switch(&opt.standalone), "Standalone operation mode")
      ("merged_lanes"     , po::bool_switch(&opt.merged_lanes), "Use old FIFOs with merged lanes")
      ("send_pulse"       , po::bool_switch(&opt.send_pulse), "Send a pulse at the beginning")
      ("send_reset"       , po::bool_switch(&opt.send_reset), "Send a reset at the beginning")
      ("reset_fifo"       , po::bool_switch(&opt.reset_fifo), "Reset FIFOs at the beginning")
      ("quit_on_monitor"  , po::bool_switch(&opt.quit_on_monitor), "Quit after first monitor")
      ;
    
    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);
    
    if (vm.count("help")) {
      std::cout << desc << std::endl;
      exit(1);
    }
  }
  catch(std::exception& e) {
    std::cerr << "Error: " << e.what() << std::endl;
    std::cout << desc << std::endl;
    exit(1);
  }
}

int main(int argc, char *argv[])
{
  std::cout << " --- welcome to ALCOR readout " << std::endl;

  program_options_t opt;
  process_program_options(argc, argv, opt);
  
  /** initialise and retrieve hardware nodes **/
  uhal::ConnectionManager connection_manager("file://" + opt.connection_filename);
  uhal::HwInterface hardware = connection_manager.getDevice(opt.device_id);
  const uhal::Node *occupancy_node[MAX_FIFOS] = {nullptr}, *reset_node[MAX_FIFOS], *data_node[MAX_FIFOS] = {nullptr};//, *pulse_node[6] = {nullptr};
  uhal::ValWord<uint32_t> occupancy_register[MAX_FIFOS];
  uhal::ValVector<uint32_t> data_register[MAX_FIFOS];
  int n_active_fifos = 0;
  int fifo_id[MAX_FIFOS] = {0};
  for (int i = 0; i < MAX_FIFOS; ++i) {
    if ( !(opt.fifo_mask & 1 << i ) ) continue;
    int chip = i / 4;
    int lane = i % 4;
    if (opt.merged_lanes) {
      if (lane == 0) {
	std::cout << " --- reading data from FIFO # " << i << " (chip = " << chip << ")" << std::endl;
	occupancy_node[n_active_fifos] = &hardware.getNode("alcor_readout_id" + std::to_string(chip) + ".fifo_occupancy");
	reset_node[n_active_fifos]     = &hardware.getNode("alcor_readout_id" + std::to_string(chip) + ".fifo_reset");
	data_node[n_active_fifos]      = &hardware.getNode("alcor_readout_id" + std::to_string(chip) + ".fifo_data");
	fifo_id[n_active_fifos] = i;
	n_active_fifos++;
      }
    } else {
      std::cout << " --- reading data from FIFO # " << i << " (chip = " << chip << ", lane = " << lane << ")" << std::endl;
      occupancy_node[n_active_fifos] = &hardware.getNode("alcor_readout_id" + std::to_string(chip) + "_lane" + std::to_string(lane) + ".fifo_occupancy");
      reset_node[n_active_fifos]     = &hardware.getNode("alcor_readout_id" + std::to_string(chip) + "_lane" + std::to_string(lane) + ".fifo_reset");
      data_node[n_active_fifos]      = &hardware.getNode("alcor_readout_id" + std::to_string(chip) + "_lane" + std::to_string(lane) + ".fifo_data");
      fifo_id[n_active_fifos] = i;
      n_active_fifos++;
    }
  }

  /** prepare staging buffers and pointers **/
  uint8_t *staging_buffer[MAX_FIFOS] = {nullptr};
  uint8_t *staging_buffer_pointer[MAX_FIFOS] = {nullptr};
  uint32_t staging_buffer_bytes[MAX_FIFOS] = {0};
  uint32_t buffer_counter = 0;
  bool flush_staging_buffers = false;
  for (int i = 0; i < n_active_fifos; ++i) {
    staging_buffer[i] = new uint8_t[opt.staging_size];
    staging_buffer_pointer[i] = staging_buffer[i];
  }
    
  /** open output file **/
  std::ofstream fout[MAX_FIFOS];
  bool write_output = !opt.output_filename.empty();
  if (write_output) {
    for (int i = 0; i < n_active_fifos; ++i) {
      std::string filename = "fifo_" + std::to_string(fifo_id[i]) + "." + opt.output_filename;
      std::cout << " --- opening output file: " << filename << std::endl;
      fout[i].open(filename , std::ofstream::out | std::ofstream::binary);
    }
  }

  /** register signal handlers **/
  signal(SIGINT, sigint_handler);
  signal(SIGALRM, sigalrm_handler);

  /** connect and initialise control shm **/
  auto control_shmid = shm_connect(CTRL_SHMFILE, CTRL_PROJID, CTRL_SHMSIZE);
  auto control_ptr = (char *)shmat(control_shmid, 0, 0);
  if (control_ptr == (void *)-1) {
    if (shmctl(control_shmid, IPC_RMID, nullptr) == -1) {
      std::cerr << " --- shmget error: " << strerror(errno) << std::endl;
      exit(1);
    } else {
      printf("Attach shared memory failed\n");
      printf("remove shared memory identifier successful\n");
    }
    std::cerr << " --- shmat error: " << strerror(errno) << std::endl;
    exit(1);
  }
  control_ptr[0] = '\0';
  //  char last_received = '\0';
  bool begin_received = false;
  std::string run_tag;
  
  /** ready to rock **/
  auto fwrev_node = &hardware.getNode("regfile.fwrev");
  auto fwrev_register = fwrev_node->read();
  auto mode_node = &hardware.getNode("regfile.mode");
  mode_node->write(opt.run_mode);
  hardware.dispatch();
  auto fwrev = fwrev_register.value();

  /** start infinite loop **/
  std::cout << " --- firmware revision: " << std::hex << fwrev << std::dec << std::endl;
  std::cout << " --- FIFO minimum occupancy: " << opt.fifo_occupancy << std::endl;
  std::cout << " --- staging buffer size: " << opt.staging_size << " bytes" << std::endl;
  std::cout << " --- usleep period: " << opt.usleep_period << " us" << std::endl;
  std::cout << " --- monitor period: " << opt.monitor_period << " s" << std::endl;
  std::cout << " --- starting infinite loop: ctrl+c to interrupt " << std::endl;
  auto start = std::chrono::steady_clock::now();
  auto split = start;
  alarm(opt.monitor_period);
  int nwords[MAX_FIFOS] = {0}, nbytes[MAX_FIFOS] = {0}, nframes[MAX_FIFOS] = {0}, nhits[MAX_FIFOS] = {0};
  uint32_t max_occupancy[MAX_FIFOS] = {0}, n_polls = 0;
  uint32_t occupancy[MAX_FIFOS], bytes[MAX_FIFOS];
  bool fifo_download = false;

  // reset fifos
  if (opt.reset_fifo) {
    for (int i = 0; i < n_active_fifos; ++i) {
      reset_node[i]->write(0x1);
    }
    hardware.dispatch();
    std::cout << " --- FIFO reset sent " << std::endl;
  }

  // send reset
  if (opt.send_reset) {
    for (int i = 0; i < 6; ++i) {
      hardware.getNode("pulser.reset_id" + std::to_string(i)).write(0x1);
    }
    hardware.dispatch();
    std::cout << " --- reset sent " << std::endl;
  }

  // send pulse
  if (opt.send_pulse) {
    for (int i = 0; i < 6; ++i) {
      hardware.getNode("pulser.testpulse_id" + std::to_string(i)).write(0x1);
    }
    hardware.dispatch();
    std::cout << " --- pulse sent " << std::endl;
  }

  while (running) {

    if (!opt.standalone) {
    
      // read control SHM
      if (control_ptr[0] == 'R') {
        std::cout << " --- reset command received: " << control_ptr << std::endl;
	for (int i = 0; i < n_active_fifos; ++i) {
	  if (fout[i].is_open()) {
	    std::cout << " --- output file closed: " << std::endl;
	    fout[i].close();
	  }
	}
        begin_received = false;
	control_ptr[0] = 'A';
      }
      if (control_ptr[0] == 'B' && !begin_received) {
        std::cout << " --- begin command received: " << control_ptr << std::endl;
        run_tag = control_ptr;
        run_tag = run_tag.substr(6);
	for (int i = 0; i < n_active_fifos; ++i) {
	  if (fout[i].is_open()) {
	    std::cout << " --- output file closed: " << std::endl;
	    fout[i].close();
	  }
	}
        write_output = !opt.output_filename.empty();
        if (write_output) {
	  for (int i = 0; i < n_active_fifos; ++i) {
	    std::string filename = run_tag + "." + "fifo_" + std::to_string(fifo_id[i]) + "." + opt.output_filename;
	    std::cout << " --- opening output file: " << filename << std::endl;
	    fout[i].open(filename , std::ofstream::out | std::ofstream::binary);
	  }
        }
        begin_received = true;
	buffer_counter = 0;
	control_ptr[0] = 'A';
      }
      if (control_ptr[0] == 'E' && begin_received) {
        std::cout << " --- end command received: " << control_ptr << std::endl;
        
        /** flush staging buffers **/
        for (int i = 0; i < n_active_fifos; ++i) {
          /** write staging buffer to file if requested **/
          if (write_output) {
            std::cout << " --- flushing FIFO #" << fifo_id[i] << ": " << staging_buffer_bytes[i] << std::endl;
            write_buffer_to_file(fout[i], fifo_id[i], buffer_counter, staging_buffer[i], staging_buffer_bytes[i]);
          }
          staging_buffer_pointer[i] = staging_buffer[i];
          staging_buffer_bytes[i] = 0;
        }
	buffer_counter++;
        
        for (int i = 0; i < n_active_fifos; ++i) {
	  if (fout[i].is_open()) {
	    std::cout << " --- output file closed: " << std::endl;
	    fout[i].close();
	  }
	}
        begin_received = false;
	control_ptr[0] = 'A';
      }
      if (control_ptr[0] == 'Q') {
        std::cout << " --- quit command received: " << control_ptr << std::endl;
        running = false;
	control_ptr[0] = 'A';
        continue;
      }
      
      if (!begin_received) continue;
    }

    // increment poll counter and usleep
    n_polls++;
    usleep(opt.usleep_period);

    // dispatch read fifo occupancy
    for (int i = 0; i < n_active_fifos; ++i)
      occupancy_register[i] = occupancy_node[i]->read();
    hardware.dispatch();
    
    // retrieve fifo occupancy
    // set download flag if at least one fifo is above threshold
    // set flush staging is at least one will overflow
    fifo_download = false;
    flush_staging_buffers = false;
    for (int i = 0; i < n_active_fifos; ++i) {
#ifdef PARANOID
      if (!occupancy_register[i].valid()) continue;
#endif
      occupancy[i] = occupancy_register[i].value() & 0xffff;
      bytes[i] = occupancy[i] * 4;
      if (occupancy[i] > max_occupancy[i]) max_occupancy[i] = occupancy[i];
      if (occupancy[i] >= opt.fifo_occupancy) fifo_download = true;
      if (staging_buffer_bytes[i] + bytes[i] > opt.staging_size) flush_staging_buffers = true;
    }

    // download fifo data
    if (fifo_download || flush_staging_buffers) {

    // flush staging buffers if requested
    // write staging buffers to file if requested
    // dispatch block read of fifo data
    for (int i = 0; i < n_active_fifos; ++i) {
      if (flush_staging_buffers) {
        if (write_output) {
          std::cout << " --- flushing FIFO #" << fifo_id[i] << ": " << staging_buffer_bytes[i] << std::endl;
          write_buffer_to_file(fout[i], fifo_id[i], buffer_counter, staging_buffer[i], staging_buffer_bytes[i]);
        }
        staging_buffer_pointer[i] = staging_buffer[i];
        staging_buffer_bytes[i] = 0;
      }
      if (occupancy[i] <= 0) continue;
      data_register[i] = data_node[i]->readBlock(occupancy[i]);
    }
    hardware.dispatch();

    if (flush_staging_buffers) {
      buffer_counter++;
      flush_staging_buffers = false;
    }    

    for (int i = 0; i < n_active_fifos; ++i) {
#ifdef PARANOID      
      if (!data_register[i].valid()) continue;
#endif
      /** copy data into staging buffer **/
      std::memcpy((char *)staging_buffer_pointer[i], (char *)data_register[i].data(), bytes[i]);
      nwords[i] += occupancy[i];
      nbytes[i] += bytes[i];
      staging_buffer_pointer[i] += bytes[i];
      staging_buffer_bytes[i] += bytes[i];
    }

    }

    /** monitor **/
    if (monitor) {
      auto end = std::chrono::steady_clock::now();
      std::chrono::duration<double> elapsed_start = end - start;
      std::chrono::duration<double> elapsed_split = end - split;

      std::cout << std::string(16 * 8, '-') << std::endl;
      //      std::cout << " -- elapsed time: " << elapsed_start.count() << " s" << std::endl;
      std::cout << std::right << std::setw(16) << std::setfill(' ') << "FIFO";
      std::cout << std::right << std::setw(16) << std::setfill(' ') << "max occupancy";
      std::cout << std::right << std::setw(16) << std::setfill(' ') << "words";
      std::cout << std::right << std::setw(16) << std::setfill(' ') << "words/poll";
      std::cout << std::right << std::setw(16) << std::setfill(' ') << "words/s";
      std::cout << std::right << std::setw(16) << std::setfill(' ') << "bytes/s";
      std::cout << std::right << std::setw(16) << std::setfill(' ') << "frames/s";
      std::cout << std::right << std::setw(16) << std::setfill(' ') << "hits/s";
      std::cout << std::endl;
      std::cout << " SOM " << std::string(16 * 8 - 5, '-') << " " << elapsed_start.count() << " " << n_polls / elapsed_split.count() << std::endl;

      for (int i = 0; i < n_active_fifos; ++i) {
        
        std::cout << std::right << std::setw(16) << std::setfill(' ') << i;
        std::cout << std::right << std::setw(16) << std::setfill(' ') << max_occupancy[i];
        std::cout << std::right << std::setw(16) << std::setfill(' ') << nwords[i];
        std::cout << std::right << std::setw(16) << std::setfill(' ') << nwords[i] / n_polls;
        std::cout << std::right << std::setw(16) << std::setfill(' ') << nwords[i] / elapsed_split.count();
        std::cout << std::right << std::setw(16) << std::setfill(' ') << nbytes[i] / elapsed_split.count();
        std::cout << std::right << std::setw(16) << std::setfill(' ') << nframes[i] / elapsed_split.count();
        std::cout << std::right << std::setw(16) << std::setfill(' ') << nhits[i] / elapsed_split.count();
        std::cout << std::endl;
        
	max_occupancy[i] = 0;
	nwords[i] = 0;
	nbytes[i] = 0;
	nframes[i] = 0;
	nhits[i] = 0;
      }
      std::cout << " EOM " << std::string(16 * 8 - 5, '-') << std::endl;
      split = std::chrono::steady_clock::now();
      monitor = false;
      n_polls = 0;
      alarm(opt.monitor_period);

      if (opt.quit_on_monitor) running = false;
      //      if (elapsed_start.count() > opt.timeout) running = false;
    }

  }

  /** flush and release staging buffers **/
  for (int i = 0; i < n_active_fifos; ++i) {
    /** write staging buffer to file if requested **/
    if (write_output) {
      std::cout << " --- flushing FIFO #" << i << ": " << staging_buffer_bytes[i] << std::endl;
      write_buffer_to_file(fout[i], fifo_id[i], buffer_counter, staging_buffer[i], staging_buffer_bytes[i]);
      fout[i].close();
      std::cout << " --- output file closed: " << std::endl;
    }
    staging_buffer_pointer[i] = staging_buffer[i];
    staging_buffer_bytes[i] = 0;
    delete [] staging_buffer[i];
  }
  buffer_counter++;
    
  std::cout << " --- exiting, so long " << std::endl;

  return 0;
}
