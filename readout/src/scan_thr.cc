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

#include "alcor/alcor.hh"

struct program_options_t {
  std::string connection_filename, device_id, output;
  int chip, channel, vth, range, offset1, min_counts, max_timer, min_timer, usleep, udelay;
  bool skip_user_settings;
};

void process_program_options(int argc, char *argv[], program_options_t &opt);

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
      ("chip"             , po::value<int>(&opt.chip)->required(), "ALCOR chip number")
      ("channel"          , po::value<int>(&opt.channel)->required(), "ALCOR channel number")
      ("vth"              , po::value<int>(&opt.vth)->default_value(0), "ALCOR threshold offset")
      ("range"            , po::value<int>(&opt.range)->default_value(0), "ALCOR threshold range")
      ("offset1"          , po::value<int>(&opt.offset1)->default_value(-1), "ALCOR baseline offset")
      ("min_counts"       , po::value<int>(&opt.min_counts)->default_value(100), "Minimum number of counts")
      ("min_timer"        , po::value<int>(&opt.min_timer)->default_value(32000), "Minimum number of timer")
      ("max_timer"        , po::value<int>(&opt.max_timer)->default_value(32000000), "Maximum number of timer")
      ("output"           , po::value<std::string>(&opt.output)->default_value("scan_thr.txt"), "Output filename")
      ("usleep"           , po::value<int>(&opt.usleep)->default_value(1000000), "Microsecond sleep")
      ("udelay"           , po::value<int>(&opt.udelay)->default_value(0), "Microsecond delay between measurements")
      ("skip_user_settings"          , po::bool_switch(&opt.skip_user_settings), "Skip user settings")
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
  program_options_t opt;
  process_program_options(argc, argv, opt);

  uhal::ConnectionManager connection_manager("file://" + opt.connection_filename);
  uhal::HwInterface hardware = connection_manager.getDevice(opt.device_id);

  alcor::alcor_t alcor;
  alcor.init(hardware, opt.chip);

  alcor::bcr0246_union_t bcr0246;
  alcor::bcr1357_union_t bcr1357;
  alcor::pcr2_union_t pcr2[4], pcr2_save[4];
  alcor::pcr3_union_t pcr3_temp, pcr3[4], pcr3_save[4];

  // save the coordinates
  int channel[4], pix[4], col[4], add2[4], add3[4]; 
  for (int lane = 0; lane < 4; ++lane) {
    channel[lane] = opt.channel + 8 * lane;
    pix[lane] = channel[lane] % 4;
    col[lane] = channel[lane] / 4;
    add2[lane] = PCR(2, pix[lane], col[lane]);
    add3[lane] = PCR(3, pix[lane], col[lane]);
  }

  // save pcr2 / pcr3 at start 
  for (int lane = 0; lane < 4; ++lane) {
    pcr2_save[lane].val = alcor.spi.read(add2[lane]);
    pcr3_save[lane].val = alcor.spi.read(add3[lane]);
  }  

  // switch off all channels
  for (int ich = 0; ich < 32; ++ich) {
    int ipix = ich % 4;
    int icol = ich / 4;
    pcr3_temp.val = alcor.spi.read(PCR(3, ipix, icol));
    pcr3_temp.reg.OpMode = 0x0;
    alcor.spi.write(PCR(3, ipix, icol), pcr3_temp.val);
  }

  // apply user settings on top of initial values, if not requested to skip them
  if (!opt.skip_user_settings) {
    for (int lane = 0; lane < 4; ++lane) {
      pcr2[lane].val = pcr2_save[lane].val;
      pcr3[lane].val = pcr3_save[lane].val;
      pcr2[lane].reg.LEDACVth = opt.vth;
      pcr2[lane].reg.LEDACrange = opt.range;
      pcr3[lane].reg.Offset1 = opt.offset1;
    }
  }

  uhal::ValWord<uint32_t> fifo_occupancy[4], fifo_timer[4];
  uhal::ValVector<uint32_t> fifo_data[4];

  std::ofstream fout(opt.output);
  fout << "channel/I:threshold/I:range/I:vth/I:offset/I:rate/F:ratee/F" << std::endl;  

  hardware.getNode("regfile.mode").write(3);
  hardware.dispatch();

  int sum_occupancy[4] = {0};
  int sum_timer[4] = {0};
  bool lane_continue[4] = {false};
  bool lane_done[4] = {false};
  bool lane_broken[4] = {false};
  int nbroken = 0;

  // loop over threshold
  for (int threshold = 0x3f; threshold >- 0; --threshold) {

    std::cout << "--- new threshold setup ---" << std::endl;
    
    // switch off
    for (int lane = 0; lane < 4; ++lane) {
      pcr3[lane].reg.OpMode = 0;
      alcor.spi.write(add3[lane], pcr3[lane].val);
    }

    // set threshold
    for (int lane = 0; lane < 4; ++lane) {
      pcr2[lane].reg.LE1DAC = threshold;
      alcor.spi.write(add2[lane], pcr2[lane].val);
      std::cout << " --- setting PCR2 on lane " << lane << std::endl;
      pcr2[lane].reg.print();
    }

    // switch on
    for (int lane = 0; lane < 4; ++lane) {
      pcr3[lane].reg.OpMode = 1;
      alcor.spi.write(add3[lane], pcr3[lane].val);
      std::cout << " --- setting PCR3 on lane " << lane << std::endl;
      pcr3[lane].reg.print();
    }

    // reset counters
    for (int lane = 0; lane < 4; ++lane) {
      sum_occupancy[lane] = 0;
      sum_timer[lane] = 0;
      lane_continue[lane] = false;
    }

    usleep(opt.udelay);
    
    // reset/read loop until minimum counts/timer achieved
    while (true) {

      // reset fifo lanes
      for (int lane = 0; lane < 4; ++lane) {
	if (lane_broken[lane]) continue;
	alcor.fifo[lane].reset->write(0x1);
      }
      hardware.dispatch();

      // sleep at least a few useconds
      usleep(opt.usleep);

      // read fifo lane occupancy
      for (int lane = 0; lane < 4; ++lane) {
	if (lane_broken[lane]) continue;
	fifo_occupancy[lane] = alcor.fifo[lane].occupancy->read();
	fifo_timer[lane] = alcor.fifo[lane].timer->read();
      }
      hardware.dispatch();

      // read data from the lane
      for (int lane = 0; lane < 4; ++lane) {
	if (lane_broken[lane]) continue;
	if (fifo_occupancy[lane].value() & 0xffff > 0)
	  fifo_data[lane] = alcor.fifo[lane].data->readBlock(fifo_occupancy[lane]);
      }
      hardware.dispatch();
      
      // check if lane is broken
      for (int lane = 0; lane < 4; ++lane) {
	if (lane_broken[lane]) continue;
	if (!fifo_data[lane].valid()) continue;
	auto last = fifo_data[lane].value()[fifo_data[lane].size() - 1];
	if ((last & 0x000000ff) == 0) {
	  printf(" --- lane %d is broken: 0x%08x \n", lane, last);
	  lane_broken[lane] = true;
	  nbroken++;
	  break;
	}
      }

      // increment counters
      for (int lane = 0; lane < 4; ++lane) {
	if (lane_broken[lane]) continue;
	sum_occupancy[lane] += (fifo_occupancy[lane].value() & 0xffff);
	sum_timer[lane] += fifo_timer[lane].value();
	
	if (sum_timer[lane] < opt.min_timer) {
	  //	  std::cout << lane << " below min_timer " << std::endl;
	  lane_continue[lane] = true;
	}
	if (sum_timer[lane] >= opt.max_timer) {
	  //	  std::cout << lane << " above max_timer " << std::endl;
	  lane_continue[lane] = false;
	}
	if (sum_occupancy[lane] >= opt.min_counts) {
	  //	  std::cout << lane << " above min_counts " << std::endl;
	  lane_continue[lane] = false;
	}

	std::cout << channel[lane] << " " << sum_timer[lane] << " " << sum_occupancy[lane] << std::endl;
      }
      
      // check number of broken lanes
      if (nbroken >= 4) {
	std::cout << " --- all lanes are broken, quit " << std::endl;
	break;
      }
      
      // check if all lanes are done
      bool all_lane_done = true;
      for (int lane = 0; lane < 4; ++lane) {
	if (lane_broken[lane]) continue;
	if (lane_continue[lane]) {
	  all_lane_done = false;
	  break;
	}
      }      
      if (all_lane_done) break;
      
    }

    // check number of broken lanes
    if (nbroken >= 4) {
      std::cout << " --- all lanes are broken, quit " << std::endl;
      break;
    }
    
    // write output to file
    for (int lane = 0; lane < 4; ++lane) {
      if (lane_broken[lane]) continue;
      double counts = sum_occupancy[lane];
      double period = sum_timer[lane] / 32.e6;

      std::cout << " --- " << channel[lane] << " " << sum_timer[lane] << " " << sum_occupancy[lane] << std::endl;
      
      std::cout << channel[lane] << " " << pcr2[lane].reg.LE1DAC << " " << counts / period << " " << 0. << " " << std::sqrt(counts) / period << std::endl;

      fout << channel[lane] << " "
	   << pcr2[lane].reg.LE1DAC << " "
	   << pcr2[lane].reg.LEDACrange << " "
	   << pcr2[lane].reg.LEDACVth << " " 
	   << pcr3[lane].reg.Offset1 << " " 
	   << counts / period << " " 
	   << std::sqrt(counts) / period << std::endl;
      
    }
    
  }
  
  hardware.getNode("regfile.mode").write(0);
  hardware.dispatch();
  
  fout.close();
  
  return 0;
}
  
