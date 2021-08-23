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

#define CTRLFILE "/tmp/alcorReadoutController.shmkey"
#define PROJID 2333
#define SHMSIZE 1024

bool running = true;
bool monitor = false;

struct program_options_t {
  std::string connection_filename, device_id, output_filename;
  int staging_size, fifo_mask, monitor_period, usleep_period;
};

struct ipbus_struct_t {
  const uhal::Node *occupancy_node[6] = {nullptr}, *data_node[6] = {nullptr}, *pulse_node[6] = {nullptr};
  bool read_fifo[6] = {false};
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


void write_buffer_to_file(std::ofstream &fout, int buffer_id, uint8_t *buffer, int buffer_size)
{
  uint32_t header[2];
  header[0] = 0x000caffe | (buffer_id << 28);
  header[1] = buffer_size;
  fout.write((char *)&header, 8);
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
      ("fifo"             , po::value<int>(&opt.fifo_mask)->default_value(0x3f), "FIFO mask")
      ("usleep"           , po::value<int>(&opt.usleep_period)->default_value(0), "Microsecond sleep between polling cycles")
      ("staging"          , po::value<int>(&opt.staging_size)->default_value(1048576), "Staging buffer size (bytes)")
      ("monitor-period"   , po::value<int>(&opt.monitor_period)->default_value(1), "Monitor period")
      ("output"           , po::value<std::string>(&opt.output_filename), "Output data file")
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
  const uhal::Node *occupancy_node[6] = {nullptr}, *data_node[6] = {nullptr}, *pulse_node[6] = {nullptr};
  bool read_fifo[6] = {false};
  for (int i = 0; i < 6; ++i) {
    if ( !(opt.fifo_mask & (1 << i)) ) continue;
    std::cout << " --- reading data from fifo # " << i << std::endl;
    read_fifo[i] = true;
    occupancy_node[i] = &hardware.getNode("alcor_readout_id" + std::to_string(i) + ".fifo_occupancy");
    data_node[i]      = &hardware.getNode("alcor_readout_id" + std::to_string(i) + ".fifo_data");
    pulse_node[i]     = &hardware.getNode("pulser.testpulse_id" + std::to_string(i));
  }
    
  /** prepare staging buffers and pointers **/
  uint8_t *staging_buffer[6] = {nullptr};
  uint8_t *staging_buffer_pointer[6] = {nullptr};
  uint32_t staging_buffer_bytes[6] = {0};
  bool flush_staging_buffers = false;
  for (int i = 0; i < 6; ++i) {
    if (!read_fifo[i]) continue;
    staging_buffer[i] = new uint8_t[opt.staging_size];
    staging_buffer_pointer[i] = staging_buffer[i];
  }
    
  /** open output file **/
  std::ofstream fout;
  bool write_output = !opt.output_filename.empty();
  if (write_output) {
    std::cout << " --- opening output file: " << opt.output_filename << std::endl;
    fout.open(opt.output_filename, std::ofstream::out | std::ofstream::binary);
  }

  /** register signal handlers **/
  signal(SIGINT, sigint_handler);
  signal(SIGALRM, sigalrm_handler);

  /** connect and initialise control shm **/
  auto control_shmid = shm_connect("/tmp/alcorReadoutController.shmkey", PROJID, SHMSIZE);
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
  bool begin_received = false;
  std::string run_tag;
  
  /** start infinite loop **/
  std::cout << " --- staging buffer size: " << opt.staging_size << " bytes" << std::endl;
  std::cout << " --- usleep period: " << opt.usleep_period << " us" << std::endl;
  std::cout << " --- monitor period: " << opt.monitor_period << " s" << std::endl;
  std::cout << " --- starting infinite loop: ctrl+c to interrupt " << std::endl;
  auto start = std::chrono::steady_clock::now();
  auto split = start;
  alarm(opt.monitor_period);
  int nwords[6] = {0}, nbytes[6] = {0}, nframes[6] = {0}, nhits[6] = {0};
  uint32_t max_occupancy[6] = {0};
  while (running) {

    // read control SHM
    if (control_ptr[0] == 'R') {
      std::cout << " --- reset command received: " << control_ptr << std::endl;
      if (fout.is_open()) {
        std::cout << " --- output file closed" << std::endl;
        fout.close();
      }
      begin_received = false;
    }
    if (control_ptr[0] == 'B' && !begin_received) {
      std::cout << " --- begin command received: " << control_ptr << std::endl;
      run_tag = control_ptr;
      run_tag = run_tag.substr(6);
      if (fout.is_open()) {
        std::cout << " --- output file closed" << std::endl;
        fout.close();
      }
      write_output = !opt.output_filename.empty();
      if (write_output) {
        std::cout << " --- opening output file: " << run_tag + "." + opt.output_filename << std::endl;
        fout.open(run_tag + "." + opt.output_filename, std::ofstream::out | std::ofstream::binary);
      }
      begin_received = true;
    }
    if (control_ptr[0] == 'E' && begin_received) {
      std::cout << " --- end command received: " << control_ptr << std::endl;

      /** flush staging buffers **/
      for (int i = 0; i < 6; ++i) {
        if (!read_fifo[i]) continue;
        /** write staging buffer to file if requested **/
        if (write_output) {
          std::cout << " --- flushing FIFO #" << i << ": " << staging_buffer_bytes[i] << std::endl;
          write_buffer_to_file(fout, i, staging_buffer[i], staging_buffer_bytes[i]);
        }
        staging_buffer_pointer[i] = staging_buffer[i];
        staging_buffer_bytes[i] = 0;
      }
      
      if (fout.is_open()) {
        std::cout << " --- output file closed" << std::endl;
        fout.close();
      }
      begin_received = false;
    }
    if (control_ptr[0] == 'Q') {
      std::cout << " --- quit command received: " << control_ptr << std::endl;
      running = false;
      continue;
    }

    if (!begin_received) continue;
    
    usleep(opt.usleep_period);
    
    // read fifo occupancy
    uhal::ValWord<uint32_t> occupancy_register[6];
    for (int i = 0; i < 6; ++i) {
      if (!read_fifo[i]) continue;
      occupancy_register[i] = occupancy_node[i]->read();
    }
    hardware.dispatch();
    
    // read fifo data
    uint32_t occupancy[6], bytes[6];
    uhal::ValVector<uint32_t> data_register[6];
    for (int i = 0; i < 6; ++i) {
      if (!read_fifo[i]) continue;
      if (!occupancy_register[i].valid()) continue;

      occupancy[i] = occupancy_register[i].value() & 0xffff;
      if (occupancy[i] <= 0) continue;
      data_register[i] = data_node[i]->readBlock(occupancy[i]);

      bytes[i] = occupancy[i] * 4;

      /** check if received bytes will fit into the staging buffer
          if not flag to flush all staging buffers **/
      if (staging_buffer_bytes[i] + bytes[i] > opt.staging_size)
        flush_staging_buffers = true;

      if (occupancy[i] > max_occupancy[i]) max_occupancy[i] = occupancy[i];
      nwords[i] += occupancy[i];
      
      //      if (i == 1) pulse_node[i]->write(0x1); // R+HACK
    }
    hardware.dispatch();
    
    for (int i = 0; i < 6; ++i) {
      if (!read_fifo[i]) continue;

      /** flush staging buffer if requested **/
      if (flush_staging_buffers) {
        /** write staging buffer to file if requested **/
        if (write_output) {
          std::cout << " --- flushing FIFO #" << i << ": " << staging_buffer_bytes[i] << std::endl;
          write_buffer_to_file(fout, i, staging_buffer[i], staging_buffer_bytes[i]);
        }
        staging_buffer_pointer[i] = staging_buffer[i];
        staging_buffer_bytes[i] = 0;
      }
      
      if (!data_register[i].valid()) continue;

      /** copy data into staging buffer **/
      std::memcpy((char *)data_register[i].data(), (char *)staging_buffer_pointer[i], bytes[i]);
      nbytes[i] += bytes[i];
      staging_buffer_pointer[i] += bytes[i];
      staging_buffer_bytes[i] += bytes[i];
    }
    flush_staging_buffers = false;
    

    /** monitor **/
    if (monitor) {
      auto end = std::chrono::steady_clock::now();
      std::chrono::duration<double> elapsed_start = end - start;
      std::chrono::duration<double> elapsed_split = end - split;

      std::cout << std::string(16 * 7, '-') << std::endl;
      //      std::cout << " -- elapsed time: " << elapsed_start.count() << " s" << std::endl;
      std::cout << std::right << std::setw(16) << std::setfill(' ') << "FIFO";
      std::cout << std::right << std::setw(16) << std::setfill(' ') << "max occupancy";
      std::cout << std::right << std::setw(16) << std::setfill(' ') << "words";
      std::cout << std::right << std::setw(16) << std::setfill(' ') << "words/s";
      std::cout << std::right << std::setw(16) << std::setfill(' ') << "bytes/s";
      std::cout << std::right << std::setw(16) << std::setfill(' ') << "frames/s";
      std::cout << std::right << std::setw(16) << std::setfill(' ') << "hits/s";
      std::cout << std::endl;
      std::cout << " SOM " << std::string(16 * 7 - 5, '-') << " " << elapsed_start.count() << std::endl;

      for (int i = 0; i < 6; ++i) {
        if (!read_fifo[i]) continue;
        
        std::cout << std::right << std::setw(16) << std::setfill(' ') << i;
        std::cout << std::right << std::setw(16) << std::setfill(' ') << max_occupancy[i];
        std::cout << std::right << std::setw(16) << std::setfill(' ') << nwords[i];
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
      std::cout << " EOM " << std::string(16 * 7 - 5, '-') << std::endl;
      split = std::chrono::steady_clock::now();
      monitor = false;
      alarm(opt.monitor_period);
    }

  }

  /** flush and release staging buffers **/
  for (int i = 0; i < 6; ++i) {
    if (!read_fifo[i]) continue;
    /** write staging buffer to file if requested **/
    if (write_output) {
      std::cout << " --- flushing FIFO #" << i << ": " << staging_buffer_bytes[i] << std::endl;
      write_buffer_to_file(fout, i, staging_buffer[i], staging_buffer_bytes[i]);
    }
    staging_buffer_pointer[i] = staging_buffer[i];
    staging_buffer_bytes[i] = 0;
    delete [] staging_buffer[i];
  }
    
  /** close output file **/
  if (write_output) {
    fout.close();
    std::cout << " --- output file closed, so long " << std::endl;
  }

  return 0;
}
