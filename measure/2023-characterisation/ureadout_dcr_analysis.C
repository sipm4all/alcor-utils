#include "analysis_utils.h"

const int spill_max = 30;
const int coarse_max = 32768;
float min_deltat = 160.; // [clock cycles] 

/** 
    the way dead time is introduced implements a non-paralyzable detector,
    namely the events occurring during the dead time of a previous one
    do not extend the dead time of the previous event

    the true rate N is related to the meaured rate M and the dead time tau as

    N = M / ( 1 - M tau )

**/

void
HistoUtils_BinLogX(TH1 *h)
{
  TAxis *axis = h->GetXaxis();
  Int_t bins = axis->GetNbins();
  Axis_t from = axis->GetXmin();
  Axis_t to = axis->GetXmax();
  Axis_t width = (to - from) / bins;
  Axis_t *new_bins = new Axis_t[bins + 1];
  for (int i = 0; i <= bins; i++) new_bins[i] = TMath::Power(10, from + i * width);
  axis->Set(bins, new_bins);
  delete [] new_bins;
}

void
ureadout_dcr_analysis(std::string finname, std::string foutname = "dcr.root")
{

  /** histograms **/
  auto hDeltat = new TH1F("hDeltat", ";#Deltat (clock cycle);", 100, 0., 100.);
  auto hDeltat_log = new TH1F("hDeltat_log", ";#Deltat (clock cycle);", 200, 0., 10.);
  HistoUtils_BinLogX(hDeltat_log);
  auto hDead = new TH1F("hDead", "", 2, 0, 1);
  
  /** open file **/
  std::cout << " --- opening decoded file: " << finname << std::endl; 
  auto fin = TFile::Open(finname.c_str());
  if (!fin || !fin->IsOpen()) {
    std::cout << " --- input file does not exist: " << finname << std::endl;
    return;
  }
  auto hCounters = (TH1F *)fin->Get("hCounters");
  
  /** retrieve tree and link it **/
  analysis_utils::data_t data;
  auto tin = (TTree *)fin->Get("alcor");
  auto nev = tin->GetEntries();
  std::cout << " --- found " << nev << " entries in tree " << std::endl;
  tin->SetBranchAddress("fifo", &data.fifo);
  tin->SetBranchAddress("type", &data.type);
  tin->SetBranchAddress("counter", &data.counter);
  tin->SetBranchAddress("column", &data.column);
  tin->SetBranchAddress("pixel", &data.pixel);
  tin->SetBranchAddress("tdc", &data.tdc);
  tin->SetBranchAddress("rollover", &data.rollover);
  tin->SetBranchAddress("coarse", &data.coarse);
  tin->SetBranchAddress("fine", &data.fine);
  
  /** loop over events in tree **/
  std::vector<int> *hits[5000];
  for (int iframe = 0; iframe < 5000; ++iframe) {
    hits[iframe] = new std::vector<int>;
  }
  
  int ispill = 0;
  int number_of_hits = 0;
  int number_of_visible_hits = 0;
  for (int iev = 0; iev < nev; ++iev) {
    tin->GetEntry(iev);
    
    /** ALCOR hits **/
    if (data.type == analysis_utils::kAlcorHit) {
      hits[data.rollover]->push_back(data.coarse + data.rollover * analysis_utils::rollover_to_coarse);
    }
    
    /** increment spill id and reset **/
    if (data.type == analysis_utils::kEndSpill) {
      int ptime = -1;
      int qtime = -1;
      for (int iframe = 0; iframe < 5000; ++iframe) {
	std::sort(hits[iframe]->begin(), hits[iframe]->end());
	for (int i = 0; i < hits[iframe]->size(); ++i) {
          number_of_hits++;
	  auto itime = hits[iframe]->at(i);

          /** count number of visible hits **/
          if (qtime != -1) {
            int dtime = itime - qtime;
            if (dtime > min_deltat) {
              number_of_visible_hits++;
              qtime = itime;
            }
          } else {
            number_of_visible_hits++;
            qtime = itime;    
          }
          
          /** make histograms with deltat **/
          if (ptime != -1) {
            int dtime = itime - ptime;
            hDeltat->Fill(dtime);
            hDeltat_log->Fill(dtime);
            if (dtime < min_deltat) ptime = -1;
            else ptime = itime;
          } else ptime = itime;

#if 0
          if (ptime < 0) { // the very first hit in the spill
	    ptime = itime;
            number_of_visible_hits++;
	    continue;
	  }
	  int dtime = itime - ptime;
	  hDeltat->Fill(dtime);
	  hDeltat_log->Fill(dtime);
          if (dtime < min_deltat) { /** dead time
                                        potential afterpulse
                                        this hit is not seen **/
            ptime = -1; // reset, likely not ok 
            continue;
          }
          number_of_visible_hits++;
	  ptime = itime;
#endif
          
	}
	hits[iframe]->clear();
      }
      ispill++;
    }
    
  }
  
  hDead->SetBinContent(1, min_deltat);
  hDead->SetBinContent(2, number_of_visible_hits);

  auto fout = TFile::Open(foutname.c_str(), "RECREATE");
  fout->cd();
  hCounters->Write();
  hDead->Write();
  hDeltat->Write();
  hDeltat_log->Write();

  fout->Close();
  fin->Close();


}
