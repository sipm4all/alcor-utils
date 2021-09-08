#include <iostream>
#include <fstream>
#include <string>
#include <boost/program_options.hpp>

bool verbose = false;
int rollover = -1; // we start from -1 becaue the very first word is a rollover
int hit_counter[4][8] = {0};

struct buffer_header_t {
  uint32_t caffe;
  uint32_t id;
  uint32_t counter;
  uint32_t size;
};

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

void decode(char *buffer, int size, bool raw_mode, std::ofstream &fout)
{
  size /= 4;
  auto word = (uint32_t *)buffer;
  alcor_hit_t *hit;
  uint32_t pos = 0;

  while (pos < size) {
    
    // find next rollover
    while (pos < size) {
      if (*word != 0x5c5c5c5c) {
        ++word; ++pos;
        continue;
      }
      if (verbose) printf(" 0x%08x -- rollover \n", *word);
      break;
    }
    ++rollover;
    ++word; ++pos;
      
    // find frame header
    while (pos < size) {
      if (*word == 0x1c1c1c1c) break;
      if (verbose) printf(" 0x%08x -- \n", *word);
      ++word; ++pos;
    }
    if (verbose) printf(" 0x%08x -- frame header \n", *word);
    ++word; ++pos;
    if (verbose) printf(" 0x%08x -- frame counter \n", *word);
    auto frame = *word;
    ++word; ++pos;
    
    // find next rollover
    while (pos < size) {
      if (*word == 0x5c5c5c5c) break;
      if (verbose) printf(" 0x%08x -- hit \n", *word);
      hit = (alcor_hit_t *)word;
      fout << hit->column << " " << hit->pixel << " " << hit->tdc << " " << frame << " " << rollover << " " << hit->coarse << " " << hit->fine << std::endl;
      hit_counter[hit->column][hit->pixel]++;
      ++word; ++pos;
    }
    
  }
  
  return;

#if 0
  
  word++; pos++;


  
  // skip till the frame header
  for (; pos < size; pos++) {
    if (word == 0x1c1c1c1c) break;
    word++;
  }

  // this is the frame counter
  word++; pos++

  // till the end these are hits
  for (; pos < size; pos++) {
    if (word == 0x1c1c1c1c) break;
    word++;
  }

  for (int i = 0; i < size; ++i) {

    
    word++;
  }

#endif

}

int main(int argc, char *argv[])
{
  std::cout << " --- welcome to ALCOR decoder " << std::endl;

  std::string input_filename, output_filename;
  bool raw_mode = false;
  
  /** process arguments **/
  namespace po = boost::program_options;
  po::options_description desc("Options");
  try {
    desc.add_options()
      ("help"   , "Print help messages")
      ("input"  , po::value<std::string>(&input_filename), "Input data file")
      ("output" , po::value<std::string>(&output_filename), "Output data file")
      ("raw"    , po::bool_switch(&raw_mode)->default_value(true), "Raw mode flag")
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

  /** open input file **/
  std::cout << " --- opening input file: " << input_filename << std::endl;
  std::ifstream fin;
  fin.open(input_filename, std::ofstream::in | std::ofstream::binary);
  
  /** open output file **/
  std::cout << " --- opening output file: " << output_filename << std::endl;
  std::ofstream fout;
  fout.open(output_filename, std::ofstream::out);
  fout << "column/I:pixel/I:tdc/I:frame/I:rollover/I:coarse/I:fine/I" << std::endl;
  
  /** loop over data **/
  buffer_header_t head;
  uint32_t word;
  char *buffer = new char[500000000];
  while (true) {
    fin.read((char *)(&head), sizeof(head));
    if (fin.eof()) break;
    if (head.caffe != 0x123caffe) {
      printf(" [ERROR] invalid caffe header: %08x \n", head.caffe);
      break;
    }
    printf(" 0x%08x -- caffe header \n", head.caffe);
    printf(" 0x%08x -- buffer id \n", head.id);
    printf(" 0x%08x -- buffer counter \n", head.counter);
    printf(" 0x%08x -- buffer size \n", head.size);
    fin.read(buffer, head.size);
    decode(buffer, head.size, raw_mode, fout);
  }
  
  /** close input file **/
  fin.close();
  fout.close();
  std::cout << " --- all done, so long " << std::endl;

  double integrated = (double)rollover * 0.0001024;
  std::cout << " >>>integrated " << integrated << std::endl;
  for (int i = 0; i < 8; ++i) {
    for (int j = 0; j < 4; ++j) {
      std::cout << ">>>channel " << i << " " << j << " " << (double)hit_counter[i][j] / integrated << " " << std::sqrt(hit_counter[i][j]) / integrated << std::endl;
    }
  }
  
  return 0;
}
