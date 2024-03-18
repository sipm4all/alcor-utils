#include "framer.h"

const double offset = 30.53 + 28.78 - 6.29509;

void
make_tot(std::vector<sipm4eic::data> &hits, std::vector<std::pair<double,double>> &hits_with_tot)
{

  std::sort(hits.begin(), hits.end());
  int leading0 = -1, leading2 = -1;


  for (int ihit = 0; ihit < hits.size(); ++ihit) {

    if (hits[ihit].tdc == 0) {
      if (leading0 != -1) {        
        hits_with_tot.push_back({ hits[leading0].fine_time_ns(), 0.});
      }
      leading0 = ihit;
    }
    
    if (hits[ihit].tdc == 2) {
      if (leading2 != -1) {
        hits_with_tot.push_back({ hits[leading2].fine_time_ns(), 0.});
      }
      leading2 = ihit;
    }
    
    if (hits[ihit].tdc == 1) {
      if (leading0 != -1) {
        auto tot = hits[ihit].fine_time_ns() - hits[leading0].fine_time_ns();
        hits_with_tot.push_back({ hits[leading0].fine_time_ns(), tot});
      }
      leading0 = -1;
    }
    
    if (hits[ihit].tdc == 3) {
      if (leading2 != -1) {
        auto tot = hits[ihit].fine_time_ns() - hits[leading2].fine_time_ns();
        hits_with_tot.push_back({ hits[leading2].fine_time_ns(), tot});
      }
      leading2 = -1;
    }
    
  }

  
}


void
signal(std::string dirname, std::string xychannel, int reference = 0, bool totmode = false, std::string prevfilename = "")
{

  int target = reference == 0 ? 1 : 0;
  std::cout << "reference / target chip = " << reference << " / " << target << std::endl;
  
  double another_offset = 0.;
  if (!prevfilename.empty()) {
    auto fprev = TFile::Open(prevfilename.c_str());
    auto hprev = (TH1 *)fprev->Get("hDelta");
    another_offset = hprev->GetBinCenter(hprev->GetMaximumBin());
    fprev->Close();
  }
  
  std::vector<std::string> rows = {"A", "B", "C", "D", "E", "F", "G", "H"};
  std::vector<std::string> cols = {"1", "2", "3", "4"}; 
  std::map<std::string, int> channel_map;
  int channel = 0;
  for (auto row : rows) {
    for (auto col : cols) {
      std::string ch = row + col;
      channel_map[ch] = channel++;
    }
  }
  channel = channel_map[xychannel];
  std::cout << " --- processing for channel " << xychannel << ": do-index " << channel << std::endl;
  
  std::vector<std::string> filenames;
  for (int ififo = 0; ififo < 8; ++ififo) {
    std::string filename = dirname + "/alcdaq.fifo_" + std::to_string(ififo) + ".root";
    filenames.push_back(filename);
  }
  int frame_size = 256;
  sipm4eic::framer framer(filenames, frame_size);

  //  std::string finecalib_filename = "fine_calib.root";
  //  sipm4eic::data::load_fine_calibration(finecalib_filename);

  auto hPeriod = new TH1F("hPeriod", "", 40, 300. * 3.125, 340. * 3.125);
  auto hHits_spill = new TH1F("hHits_spill", "", 100, 0., 100);
  auto hTriggers_spill = new TH1F("hTriggers_spill", "", 100, 0., 100);

  auto hDelta = new TH1F("hDelta", "", 100, -50. * 3.125, 50. * 3.125);
  auto hAllDelta = new TH1F("hAllDelta", "", 100, -50. * 3.125, 50. * 3.125);
  auto hDelta_spill = new TH2F("hDelta_spill", "", 100, 0., 100, 100, -50. * 3.125, 50. * 3.125);
  auto hAllDelta_spill = new TH2F("hAllDelta_spill", "", 100, 0., 100, 100, -50. * 3.125, 50. * 3.125);
  auto hDelta_plus = new TH1F("hDelta_plus", "", 100, -50. * 3.125, 50. * 3.125);
  auto hAllDelta_plus = new TH1F("hAllDelta_plus", "", 100, -50. * 3.125, 50. * 3.125);
  auto hDelta_minus = new TH1F("hDelta_minus", "", 100, -50. * 3.125, 50. * 3.125);
  auto hAllDelta_minus = new TH1F("hAllDelta_minus", "", 100, -50. * 3.125, 50. * 3.125);
    
  /** loop over spills **/
  int ntriggers = 0;
  std::vector<std::pair<double,double>> hits_with_tot;
  for (int spill = 0; framer.next_spill(); ++spill) {
    auto &frames = framer.frames();

    /** check all fifos are present **/
    std::cout << framer.fifos().size() << std::endl;
    if (framer.fifos().size() != 5) continue;

    /** after-pulse detection **/
    double prevtime = -1;
    for (auto &[iframe, frame] : frames) {
      std::sort(frame.chips[target][channel].begin(), frame.chips[target][channel].end());
      for (auto &hit : frame.chips[target][channel]) {
	if (prevtime == -1) {
	  hit.afterpulse = false;
	  prevtime = hit.fine_time_ns();
	  continue;
	}
	auto delta = hit.fine_time_ns() - prevtime;
	if (delta < 100.) hit.afterpulse = true;
	else {
	  hit.afterpulse = false;
	  prevtime = hit.fine_time_ns();
	}
      }
    }
    
    int ntriggers_spill = 0;
    int nhits_spill = 0;
    
    /** loop over frames **/
    bool has_first_in_spill = false;
    double ptime = 0.;
    for (auto &[iframe, frame] : frames) {

      nhits_spill += frame.chips[target][channel].size();
      
      /** request one hit on test pulse ALCOR chip **/
      if (frame.chips[reference].size() != 1) continue;

      /** fill period plot **/
      for (auto &rrhit : frame.chips[reference][22]) {
        auto rrtime = rrhit.fine_time_ns();
        if (has_first_in_spill) {
          hPeriod->Fill(rrtime - ptime);
        }
        ptime = rrtime;
        has_first_in_spill = true;
      }
      
      /** request one hit on test pulse ALCOR chip **/
      if (frame.chips[reference].size() != 1) continue;
      auto rhit = frame.chips[reference][22][0];
      auto rtime = rhit.fine_time_ns();
      ntriggers++;
      ntriggers_spill++;

      for (int iiframe = iframe; iiframe <= iframe + 1; iiframe++) {
	if (iiframe < 0 && iframe >= frames.size()) continue;
	auto tframe = frames[iiframe];
	for (auto &hit : tframe.chips[target][channel]) {
	  auto time = hit.fine_time_ns();
	  auto delta = time - rtime - offset;
	  if (!hit.afterpulse) {
	    hDelta->Fill(delta);
	    hDelta_spill->Fill(spill, delta);
	  }
	  hAllDelta->Fill(delta);
	  hAllDelta_spill->Fill(spill, delta);
	}
      }

      for (int iiframe = iframe + 128; iiframe <= (iframe + 128 + 1); iiframe++) {
	if (iiframe < 0 && iframe >= frames.size()) continue;
	auto tframe = frames[iiframe];
	for (auto &hit : tframe.chips[target][channel]) {
	  auto time = hit.fine_time_ns();
	  auto delta = time - rtime - offset - 102400.0;
	  if (!hit.afterpulse) {
	    hDelta->Fill(delta);
	    hDelta_spill->Fill(spill, delta);
	    hDelta_plus->Fill(delta);
	  }
	  hAllDelta->Fill(delta);
	  hAllDelta_spill->Fill(spill, delta);
	  hAllDelta_plus->Fill(delta);
	}
      }

      for (int iiframe = iframe - 128; iiframe <= (iframe - 128 + 1); iiframe++) {
	if (iiframe < 0 && iframe >= frames.size()) continue;
	auto tframe = frames[iiframe];
	for (auto &hit : tframe.chips[target][channel]) {
	  //	  if (hit.afterpulse) continue;
	  auto time = hit.fine_time_ns();
	  auto delta = time - rtime - offset + 102400.0;
	  if (!hit.afterpulse) {
	    hDelta->Fill(delta);
	    hDelta_spill->Fill(spill, delta);
	    hDelta_minus->Fill(delta);
	  }
	  hAllDelta->Fill(delta);
	  hAllDelta_spill->Fill(spill, delta);
	  hAllDelta_minus->Fill(delta);
	}
      }

    } /** end of loop over frames **/

    hTriggers_spill->SetBinContent(spill + 1, ntriggers_spill);
    hHits_spill->SetBinContent(spill + 1, nhits_spill);
    
  } /** end of loop over spills **/

  std::cout << " --- found " << ntriggers << " triggers " << std::endl;
  
  auto fout = TFile::Open(Form("%s/signal.root", dirname.c_str()), "RECREATE");
  hPeriod->Write();
  hTriggers_spill->Write();
  hHits_spill->Write();

  hDelta->Sumw2();
  hDelta->Scale(1. / ntriggers);
  hDelta->Write();

  hAllDelta->Sumw2();
  hAllDelta->Scale(1. / ntriggers);
  hAllDelta->Write();

  hDelta_spill->Write();
  hAllDelta_spill->Write();

  hDelta_plus->Sumw2();
  hDelta_plus->Scale(1. / ntriggers);
  hDelta_plus->Write();

  hAllDelta_plus->Sumw2();
  hAllDelta_plus->Scale(1. / ntriggers);
  hAllDelta_plus->Write();

  hDelta_minus->Sumw2();
  hDelta_minus->Scale(1. / ntriggers);
  hDelta_minus->Write();

  hAllDelta_minus->Sumw2();
  hAllDelta_minus->Scale(1. / ntriggers);
  hAllDelta_minus->Write();

  fout->Close();
  
}
