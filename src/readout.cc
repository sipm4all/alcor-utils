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
  std::cout << " --- welcome to ALCOR readout++ " << std::endl;
  
  std::string connection_filename, device_id, output_filename;
  uint8_t fifo_mask;
  
  /** process arguments **/
  namespace po = boost::program_options;
  po::options_description desc("Options");
  try {
    desc.add_options()
      ("help"           , "Print help messages")
      ("connection"     , po::value<std::string>(&connection_filename)->required(), "IPbus XML connection file")
      ("device"         , po::value<std::string>(&device_id)->default_value("kc705"), "Device ID")
      ("fifo"           , po::value<uint8_t>(&fifo_mask)->default_value(0x10), "FIFO mask")
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
  const uhal::Node *occupancy_node[6], *data_node[6], *pulse_node[6];
  for (int i = 0; i < 6; ++i) {
      occupancy_node[i] = &hardware.getNode("alcor_readout_id" + std::to_string(i) + ".fifo_occupancy");
      data_node[i]      = &hardware.getNode("alcor_readout_id" + std::to_string(i) + ".fifo_data");
      pulse_node[i]     = &hardware.getNode("pulser.testpulse_id" + std::to_string(i));
  }
    
  /** open output file **/
  std::ofstream fout;
  if (!output_filename.empty()) {
    std::cout << " --- opening output file: " << output_filename << std::endl;
    fout.open(output_filename, std::ofstream::out | std::ofstream::binary);
  }

  /** register signal handlers **/
  signal(SIGINT, sigint_handler);
  signal(SIGALRM, sigalrm_handler);
  
  /** start infinite loop **/
  std::cout << " --- starting infinite loop " << std::endl;
  auto start = std::chrono::steady_clock::now();
  auto split = start;
  alarm(1);
  int nwords[6] = {0}, nframes[6] = {0}, nhits[6] = {0};
  uint32_t max_occupancy[6] = {0};
  while (running) {

#if 1
    // read fifo occupancy
    uhal::ValWord<uint32_t> occupancy_register[6];
    for (int i = 0; i < 6; ++i) occupancy_register[i] = occupancy_node[i]->read();
    hardware.dispatch();
    
    // read fifo data
    uint32_t occupancy[6];
    uhal::ValVector<uint32_t> data_register[6];
    for (int i = 0; i < 6; ++i) {
      //      if (i != 5) continue;
      if (!occupancy_register[i].valid()) continue;
      occupancy[i] = occupancy_register[i].value() & 0xffff;
      if (occupancy[i] <= 0) continue;
      if (occupancy[i] > max_occupancy[i]) 
	max_occupancy[i] = occupancy[i];
      nwords[i] += occupancy[i];
      data_register[i] = data_node[i]->readBlock(occupancy[i]);
      
      //      if (i == 1) pulse_node[i]->write(0x1); // R+HACK
    }
    hardware.dispatch();
    
    // write to file
    for (int i = 0; i < 6; ++i) {
      //      if (i != 5) continue;
      if (!data_register[i].valid()) continue;
#if 0
      auto mydata = data_register[i].value();
      for (int idata = 0; idata < mydata.size(); ++idata) {
	auto &data = mydata.at(idata);
	if (data == 0x1c1c1c1c) {
	  ++nframes[i];
	  ++idata[i];
	  data = mydata.at(idata);
	  while (data != 0x5c5c5c5c)
	    ++nhits;
	}
      }
#endif
      if (!output_filename.empty())
	fout.write((char *)data_register[i].data(), data_register[i].size() * 4);
    }
  
#else
    sleep(1);
#endif
    
    if (monitor) {
      auto end = std::chrono::steady_clock::now();
      std::chrono::duration<double> elapsed_start = end - start;
      std::chrono::duration<double> elapsed_split = end - split;
      std::cout << " --------------------------------------------------------" << std::endl;
      for (int i = 0; i < 6; ++i) {
	//	if (i != 5) continue;
	std::cout << " -- FIFO # " << i << " ------------------------------------------------" << std::endl;
	std::cout << "elapsed time: " << elapsed_start.count() << " s"
		  << "       count: " << nwords[i] << " words"
		  << "        rate: " << nwords[i] / elapsed_split.count() << " words/s"
		  << "              " << nframes[i] / elapsed_split.count() << " frames/s"
		  << "              " << nhits[i] / elapsed_split.count() << " hits/s" << std::endl;
	std::cout << " max occupancy: " << max_occupancy[i] << std::endl;
	max_occupancy[i] = 0;
	nwords[i] = 0;
	nframes[i] = 0;
	nhits[i] = 0;
      }
      split = std::chrono::steady_clock::now();
      monitor = false;
      alarm(1);
    }

  }

  /** close output file **/
  if (!output_filename.empty()) {
    fout.close();
    std::cout << " --- output file closed, so long " << std::endl;
  }
  return 0;
}
