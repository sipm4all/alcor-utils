#include <iostream>
#include <fstream>
#include <string>
#include <unistd.h>
#include <signal.h>
#include <chrono>
#include <boost/program_options.hpp>
#include "uhal/uhal.hpp"

bool running = true;
bool monitor = false;

void
sigint_handler(int signum) {
  std::cout << " --- infinite loop terminate requested" << std::endl;
  running = false;
}

void
sigalrm_handler(int signum) {
  monitor = true;
}

int main(int argc, char *argv[])
{
  std::cout << " --- welcome to ALCOR readout " << std::endl;
  
  std::string connection_filename, device_id, output_filename;
  int staging_size, fifo_mask, monitor_period, usleep_period;
  
  /** process arguments **/
  namespace po = boost::program_options;
  po::options_description desc("Options");
  try {
    desc.add_options()
      ("help"           , "Print help messages")
      ("connection"     , po::value<std::string>(&connection_filename)->required(), "IPbus XML connection file")
      ("device"         , po::value<std::string>(&device_id)->default_value("kc705"), "Device ID")
      ("fifo"           , po::value<int>(&fifo_mask)->default_value(0x3f), "FIFO mask")
      ("usleep"         , po::value<int>(&usleep_period)->default_value(0), "Microsecond sleep between polling cycles")
      ("staging"        , po::value<int>(&staging_size)->default_value(1048576), "Staging buffer size (bytes)")
      ("monitor"        , po::value<int>(&monitor_period)->default_value(1), "Monitor period")
      ("output"         , po::value<std::string>(&output_filename), "Output data file")
      ;
    
    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);
    
    if (vm.count("help")) {
      std::cout << desc << std::endl;
      return 1;
    }
  }
  catch(std::exception& e) {
    std::cerr << "Error: " << e.what() << std::endl;
    std::cout << desc << std::endl;
    return 1;
  }

  /** initialise and retrieve hardware nodes **/
  uhal::ConnectionManager connection_manager("file://" + connection_filename);
  uhal::HwInterface hardware = connection_manager.getDevice(device_id);
  const uhal::Node *occupancy_node[6] = {nullptr}, *data_node[6] = {nullptr}, *pulse_node[6] = {nullptr};
  bool read_fifo[6] = {false};
  for (int i = 0; i < 6; ++i) {
    if ( !(fifo_mask & (1 << i)) ) continue;
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
    staging_buffer[i] = new uint8_t[staging_size];
    staging_buffer_pointer[i] = staging_buffer[i];
  }
    
  /** open output file **/
  std::ofstream fout;
  bool write_output = !output_filename.empty();
  if (write_output) {
    std::cout << " --- opening output file: " << output_filename << std::endl;
    fout.open(output_filename, std::ofstream::out | std::ofstream::binary);
  }

  /** register signal handlers **/
  signal(SIGINT, sigint_handler);
  signal(SIGALRM, sigalrm_handler);
  
  /** start infinite loop **/
  std::cout << " --- staging buffer size: " << staging_size << " bytes" << std::endl;
  std::cout << " --- usleep period: " << usleep_period << " s" << std::endl;
  std::cout << " --- monitor period: " << monitor_period << " s" << std::endl;
  std::cout << " --- starting infinite loop: ctrl+c to interrupt " << std::endl;
  auto start = std::chrono::steady_clock::now();
  auto split = start;
  alarm(monitor_period);
  int nwords[6] = {0}, nbytes[6] = {0}, nframes[6] = {0}, nhits[6] = {0};
  uint32_t max_occupancy[6] = {0};
  while (running) {

    // micro sleep
    usleep(usleep_period);
    
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
      if (staging_buffer_bytes[i] + bytes[i] > staging_size)
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
          uint32_t header[2];
          header[0] = 0x000caffe | (i << 28);
          header[1] = staging_buffer_bytes[i];
          fout.write((char *)&header, 8);
          fout.write((char *)staging_buffer[i], staging_buffer_bytes[i]);
          std::cout << " --- flushing FIFO #" << i << ": " << staging_buffer_bytes[i] << std::endl;
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
      std::cout << std::string(80, '-') << std::endl;
      std::cout << " -- elapsed time: " << elapsed_start.count() << " s" << std::endl;
      for (int i = 0; i < 6; ++i) {
        if (!read_fifo[i]) continue;
        std::cout << " --- FIFO # " << i << " | max occupancy: " << max_occupancy[i] << std::endl;
        std::cout << "     count: " << nwords[i] << " words"
		  << "      rate: " << nwords[i]  / elapsed_split.count() << " words/s"
		  << "            " << nbytes[i]  / elapsed_split.count() << " bytes/s"
		  << "            " << nframes[i] / elapsed_split.count() << " frames/s"
		  << "            " << nhits[i]   / elapsed_split.count() << " hits/s" << std::endl;
	max_occupancy[i] = 0;
	nwords[i] = 0;
	nbytes[i] = 0;
	nframes[i] = 0;
	nhits[i] = 0;
      }
      split = std::chrono::steady_clock::now();
      monitor = false;
      alarm(monitor_period);
    }

  }

  /** release staging buffers **/
  for (int i = 0; i < 6; ++i) {
    if (!read_fifo[i]) continue;
    delete [] staging_buffer[i];
  }
    
  /** close output file **/
  if (write_output) {
    fout.close();
    std::cout << " --- output file closed, so long " << std::endl;
  }

  return 0;
}
