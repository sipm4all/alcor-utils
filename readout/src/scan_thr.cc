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
  int chip, channel, vth, range, offset1, min_counts, max_timer, min_timer, usleep, interesting, nretry, udelay;
  bool forward, skip_user_settings;
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
      ("interesting"      , po::value<int>(&opt.interesting)->default_value(1000), "Interesting rate (Hz)")
      ("nretry"           , po::value<int>(&opt.nretry)->default_value(10), "Number of trials for intersting rate")
      ("forward"          , po::bool_switch(&opt.forward), "Forward scan mode")
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

  typedef union bcr0246_union_t {
    uint16_t val;
    struct alcor::bcr0246_t reg;
  } bcr0246_union_t;

  typedef union bcr1357_union_t {
    uint16_t val;
    struct alcor::bcr1357_t reg;
  } bcr1357_union_t;

  typedef union pcr2_union_t {
    uint16_t val;
    struct alcor::pcr2_t reg;
  } pcr2_union_t;

  typedef union pcr3_union_t {
    uint16_t val;
    struct alcor::pcr3_t reg;
  } pcr3_union_t;

  bcr0246_union_t bcr0246;
  bcr1357_union_t bcr1357;
  pcr2_union_t pcr2;
  pcr3_union_t pcr3, pcr3_save;

  // save pcr3 of current channel
  int pix = opt.channel % 4;
  int col = opt.channel / 4;
  pcr3_save.val = alcor.spi.read(PCR(3, pix, col));
  
  // switch off all channels
  for (int ich = 0; ich < 32; ++ich) {
    pix = ich % 4;
    col = ich / 4;
    int add = PCR(3, pix, col);
    pcr3.val = alcor.spi.read(PCR(3, pix, col));
    pcr3.reg.OpMode = 0x0;
    alcor.spi.write(add, pcr3.val);
    std::cout << " channel " << ich << std::endl;
    pcr3.reg.print();
  }

  // switch on desider channel
  pcr3.val = pcr3_save.val;
  pix = opt.channel % 4;
  col = opt.channel / 4;
  int lane = opt.channel / 8;
  int add3 = PCR(3, pix, col);
  pcr3.val = alcor.spi.read(PCR(3, pix, col));
  pcr3.reg.OpMode = 1;
  alcor.spi.write(add3, pcr3.val);
  std::cout << " channel " << opt.channel << std::endl;  
  pcr3.reg.print();

  // baseline PCR2 register
  pcr2.reg.LE2DAC = 0x3f;
  pcr2.reg.LEDACVth = opt.vth;
  pcr2.reg.LEDACrange = opt.range;
  pcr2.reg.LE1DAC = 0x3f;
  int add2 = PCR(2, pix, col);

  // read PCR register
  pcr2.val = alcor.spi.read(PCR(2, pix, col));
  pcr3.val = alcor.spi.read(PCR(3, pix, col));

  // apply user settings
  if (!opt.skip_user_settings) {
    pcr2.reg.LEDACVth = opt.vth;
    pcr2.reg.LEDACrange = opt.range;
    pcr3.reg.Offset1 = opt.offset1;
  }

  // read BCR register
  int add_bcr0246 = BCR(lane * 2);
  int add_bcr1357 = BCR(lane * 2 + 1);
  bcr0246.val = alcor.spi.read(add_bcr0246);
  bcr1357.val = alcor.spi.read(add_bcr1357);

  uhal::ValWord<uint32_t> fifo_occupancy, fifo_timer;
  uhal::ValVector<uint32_t> fifo_data;

  std::ofstream fout(opt.output);
  fout << "channel/I:threshold/I:range/I:vth/I:offset/I:rate/F:ratee/F" << std::endl;  

  hardware.getNode("regfile.mode").write(3);
  hardware.dispatch();

  bool broken = false;

  // fill threshold vector
  std::vector<int> thresholds;
  if (opt.forward) 
    for (int threshold = 0; threshold <= 0x3f; ++threshold) thresholds.push_back(threshold);
  else
    for (int threshold = 0x3f; threshold >- 0; --threshold) thresholds.push_back(threshold);

  // loop over threshold
  for (auto threshold : thresholds) {

    // switch off
    pcr3.reg.OpMode = 0;
    alcor.spi.write(add3, pcr3.val);

    // set threshold
    pcr2.reg.LE1DAC = threshold;
    alcor.spi.write(add2, pcr2.val);
    std::cout << "--- new threshold setup ---" << std::endl;

    // switch on
    pcr3.reg.OpMode = 1;
    alcor.spi.write(add3, pcr3.val);

    // print
    bcr0246.reg.print();
    bcr1357.reg.print();
    pcr2.reg.print();
    pcr3.reg.print();

    usleep(opt.udelay);
    
    for (int iretry = 0; iretry < opt.nretry; ++iretry) {

    // reset/read loop until minimum counts/timer achieved
    int sum_occupancy = 0;
    int sum_timer = 0;
    while (true) {
      alcor.fifo[lane].reset->write(0x1);
      hardware.dispatch();
      usleep(opt.usleep);
      fifo_occupancy = alcor.fifo[lane].occupancy->read();
      fifo_timer = alcor.fifo[lane].timer->read();
      hardware.dispatch();

      if (fifo_occupancy.value() & 0xffff > 0) {
	fifo_data = alcor.fifo[lane].data->readBlock(fifo_occupancy);
	hardware.dispatch();
	auto last = fifo_data.value()[fifo_data.size() - 1];
	if ((last & 0x000000ff) == 0) {
	  printf(" 0x%08x -- broken \n", last);
	  broken = true;
	  break;
	}
      }

      sum_occupancy += (fifo_occupancy.value() & 0xffff);
      sum_timer += fifo_timer.value();

      if (sum_timer < opt.min_timer) continue;
      if (sum_timer >= opt.max_timer) break;
      if (sum_occupancy >= opt.min_counts) break;
    }

    if (broken) {
      std::cout << " --- chip is broken, quit " << std::endl;
      break;
    }

    double counts = sum_occupancy;
    double period = sum_timer / 32.e6;
    std::cout << pcr2.reg.LE1DAC << " " << counts / period << " " << 0. << " " << std::sqrt(counts) / period << std::endl;

    fout << opt.channel << " "
	 << pcr2.reg.LE1DAC << " "
	 << pcr2.reg.LEDACrange << " "
	 << pcr2.reg.LEDACVth << " " 
	 << pcr3.reg.Offset1 << " " 
	 << counts / period << " " 
	 << std::sqrt(counts) / period << std::endl;

    if (counts / period > opt.interesting) {
      std::cout << "--- rate is interesting, let's try again " << std::endl;
      continue;
    }
    break;

    }

    if (broken) {
      std::cout << " --- chip is broken, quit " << std::endl;
      break;
    }
    
  }

  hardware.getNode("regfile.mode").write(0);
  hardware.dispatch();

  fout.close();

  return 0;
}
