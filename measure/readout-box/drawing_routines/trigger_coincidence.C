#define MAXDATA 8192

struct frame_data_t {
  int spill_id;
  int frame_id;
  int fifo;
  int n;
  int column[MAXDATA];
  int pixel[MAXDATA];
  int tdc[MAXDATA];
  int rollover[MAXDATA];
  int coarse[MAXDATA];
  int fine[MAXDATA];
};

int eo2do[32] = {22, 20, 18, 16, 24, 26, 28, 30, 25, 27, 29, 31, 23, 21, 19, 17, 9, 11, 13, 15, 7, 5, 3, 1, 6, 4, 2, 0, 8, 10, 12, 14};
int do2eo[32] = {27, 23, 26, 22, 25, 21, 24, 20, 28, 16, 29, 17, 30, 18, 31, 19, 3, 15, 2, 14, 1, 13, 0, 12, 4, 8, 5, 9, 6, 10, 7, 11};

int trigger_delay = 56+9;

void
trigger_coincidence(std::string filename, double cutmin = -3., double cutmax = +3.)
{
  gStyle->SetOptStat(10);
  
  auto fin = TFile::Open(filename.c_str());
  TTree *tin[25] = {nullptr};
  frame_data_t frame[25];
  int nev[25] = {0}, nframes = kMaxInt;
  int n_active_fifos = 0;
  int active_fifo[25];

  // loop and link available fifos
  for (int fifo = 0; fifo < 25; ++fifo) {
    tin[fifo] = (TTree *)fin->Get(Form("miniframe_%d", fifo));
    if (!tin[fifo]) continue;
    nev[fifo] = tin[fifo]->GetEntries();
    std::cout << " --- found fifo " << fifo << ": " << nev[fifo] << " entries " << std::endl;
    if (nframes == kMaxInt) nframes = nev[fifo];
    if (nev[fifo] != nframes) {
      std::cout << " --- fifo entries mismatch " << std::endl;
      continue;
    }
    
    active_fifo[n_active_fifos] = fifo;
    n_active_fifos++;
    
    tin[fifo]->SetBranchAddress("spill_id", &frame[fifo].spill_id);
    tin[fifo]->SetBranchAddress("frame_id", &frame[fifo].frame_id);
    tin[fifo]->SetBranchAddress("fifo", &frame[fifo].fifo);
    tin[fifo]->SetBranchAddress("n", &frame[fifo].n);
    tin[fifo]->SetBranchAddress("column", &frame[fifo].column);
    tin[fifo]->SetBranchAddress("pixel", &frame[fifo].pixel);
    tin[fifo]->SetBranchAddress("tdc", &frame[fifo].tdc);
    tin[fifo]->SetBranchAddress("rollover", &frame[fifo].rollover);
    tin[fifo]->SetBranchAddress("coarse", &frame[fifo].coarse);
    tin[fifo]->SetBranchAddress("fine", &frame[fifo].fine);

    //    nframes = std::min(nframes, nev[fifo]);
  }
  std::cout << " --- we will loop over " << nframes << " frames " << std::endl;
  
  TH1 *hDelta[6] = {nullptr};
  TH2 *hMap[6] = {nullptr};
  for (int ichip = 0; ichip < 6; ++ichip) {
    hDelta[ichip] = new TH1F(Form("hDelta_%d", ichip), Form("chip %d;hit - trigger time (3.125 ns)", ichip), 32768 * 16, -8. * 32768, 8. * 32768);
    hMap[ichip] = new TH2F(Form("hMap_%d", ichip), Form("chip %d;matrix row;matrix column", ichip), 8, 0., 8., 4, 0., 4.);
  }
  
  /** loop over frames **/
  for (int iframe = 0; iframe < nframes; ++iframe) {

    /** loop over hits in the trigger fifo **/
    tin[24]->GetEvent(iframe);
    for (int ref = 0; ref < frame[24].n; ++ref) {
      double reference_rollover = (double)frame[24].rollover[ref];
      double reference_coarse = (double)frame[24].coarse[ref];
      double reference_time = reference_coarse + 32768. * reference_rollover - trigger_delay;
      
      /** loop over active fifos **/
      for (int ififo = 0; ififo < n_active_fifos; ++ififo) {
        auto fifo = active_fifo[ififo];
        auto chip = fifo / 4;
        if (fifo == 24) continue;
        tin[fifo]->GetEvent(iframe);
        for (int hit = 0; hit < frame[fifo].n; ++hit) {
          int eoch = frame[fifo].pixel[hit] + 4 * frame[fifo].column[hit];
          int doch = eo2do[eoch];
          int dorow = doch / 4;
          int docol = doch % 4;
          double rollover = (double)frame[fifo].rollover[hit];
          double coarse = (double)frame[fifo].coarse[hit];
          double time = coarse + 32768. * rollover;
          auto delta = time - reference_time;
          hDelta[chip]->Fill(delta);
          if ( (delta > cutmin && delta < cutmax) || (cutmin == 0. && cutmax == 0.) )
            hMap[chip]->Fill(dorow, docol);
        }
      }
    }
  }

  auto cDelta = new TCanvas("cDelta", "cDelta", 1500, 1000);
  cDelta->Divide(3, 2);
  for (int ichip = 0; ichip < 6; ++ichip) {
    cDelta->cd( (ichip % 2) * 3 + (ichip / 2) + 1);
    hDelta[ichip]->Draw();
  }
  
  auto cMap = new TCanvas("cMap", "cMap", 1500, 500);
  cMap->Divide(3, 2);
  for (int ichip = 0; ichip < 6; ++ichip) {
    cMap->cd( (ichip % 2) * 3 + (ichip / 2) + 1);
    hMap[ichip]->SetMinimum(0.);
    hMap[ichip]->SetStats(kFALSE);
    hMap[ichip]->Draw("colz");
  }

  /** write histograms on file **/
  auto outfilename = filename + std::string(".trigger_coincidence.root");
  auto fout = TFile::Open(outfilename.c_str(), "RECREATE");
  for (int ichip = 0; ichip < 6; ++ichip) {
    hDelta[ichip]->Write();
    hMap[ichip]->Write();
  }
  fout->Close();
  
}
