#pragma once

#include "data.h"

namespace sipm4eic {

/*******************************************************************************/
  
class framer {

public:
  
  framer(std::vector<std::string> filenames, int frame_size = 1024) :
    _filenames(filenames), _frame_size(frame_size), _verbose(false) {
    for (const auto &filename : filenames)
      _next_spill[filename] = 0;
  };
  
  bool next_spill();
  void verbose(bool flag = true) { _verbose = flag; };
  
  typedef std::vector<data> channel_t;
  typedef std::map<int, channel_t> chip_t;
  typedef struct {
    std::map<int, chip_t> chips;
    std::vector<data> triggers;
  } frame_t;
  
  std::map<int, frame_t> &frames() { return _frames; };
  std::vector<int> &fifos() { return _fifos; };
  
private:
  
  int _frame_size;
  std::vector<std::string> _filenames;
  bool _verbose;
  std::map<std::string, int> _next_spill;
  std::map<int, frame_t> _frames;
  std::vector<int> _fifos;
  
};
  
/*******************************************************************************/
  
bool framer::next_spill()
{
  bool has_data = false;
  _frames.clear();
  _fifos.clear();
  
  /** loop over input file list **/
  for (const auto filename : _filenames) {
    
    /** open file **/
    if (_verbose) std::cout << " --- opening decoded file: " << filename << std::endl; 
    auto fin = TFile::Open(filename.c_str());
    if (!fin || !fin->IsOpen()) continue;
    
    /** retrieve tree and link it **/
    auto tin = (TTree *)fin->Get("alcor");
    auto nev = tin->GetEntries();
    if (_verbose) std::cout << " --- found " << nev << " entries in tree " << std::endl;
    sipm4eic::data data;
    data.link_to_tree(tin);
    
    /** loop over events in tree **/
    for (int iev = _next_spill[filename]; iev < nev; ++iev) {
      tin->GetEntry(iev);
      
      /** start of spill **/
      if (data.is_start_spill()) {
        if (_verbose) std::cout << " --- start of spill found: event " << iev << std::endl;
        has_data = true;
	if (!data.is_deadbeef())
	  _fifos.push_back(data.fifo);
      }
      
      /** ALCOR hit **/
      if (data.is_alcor_hit()) {
        auto chip = data.chip();
        auto channel = data.do_channel();
        auto frame = data.coarse_time_clock() / _frame_size;
        _frames[frame].chips[chip][channel].push_back(data);
      }

      /** trigger tag **/
      if (data.is_trigger_tag()) {
        auto frame = data.coarse_time_clock() / _frame_size;
        _frames[frame].triggers.push_back(data);
      }
      
      /** end of spill **/
      if (data.is_end_spill()) {
        if (_verbose) std::cout << " --- end of spill found: event " << iev << std::endl;
        _next_spill[filename] = iev + 1;
        break;
      }
      
    } /** end of loop over events in tree **/
    
    fin->Close();
    
  } /** end of loop over input file list **/
  
  return has_data;
  
}
  
} /** namespace sipm4eic **/

