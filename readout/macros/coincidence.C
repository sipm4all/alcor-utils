#define MAXDATA 1024

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


void
coincidence()
{

  auto fin = TFile::Open("alcdaq.miniframe.root");
  TTree *tin[24] = {nullptr};
  frame_data_t frame[24];
  int nev[24] = {0}, nframes = kMaxInt;
  int n_active_fifos = 0;
  int active_fifo[24];

  std::ofstream fout("coincidence.txt");
  fout << "chip/I:frame/I:rollover/F:coarse/F" << std::endl;

  
  // loop and link available fifos
  for (int fifo = 0; fifo < 24; ++fifo) {
    tin[fifo] = (TTree *)fin->Get(Form("miniframe_%d", fifo));
    if (!tin[fifo]) continue;
    nev[fifo] = tin[fifo]->GetEntries();
    std::cout << " --- found fifo " << fifo << ": " << nev[fifo] << " entries " << std::endl;
    active_fifo[n_active_fifos] = fifo;
    n_active_fifos++;
    
    //    frame[fifo] = new frame_data_t;
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

    nframes = std::min(nframes, nev[fifo]);
  }
  std::cout << " --- we will loop over " << nframes << " frames " << std::endl;

  TH1 *hDelta = new TH1F("hDelta", "", 100000, -5000., 5000.);
  TH1 *hDelta_fastest = new TH1F("hDelta_fastest", "", 1000000, -5000., 5000.);
  TH2 *hDelta_fastest_fine_4 = new TH2F("hDelta_fastest_fine_4", "", 200, 0, 200, 1000, -5., 5.);

  float MIN = 38.;
  float MAX = 100.;
  float CUT = (MAX + MIN) * 0.5;
  float IF = MAX - MIN;
  
  int nhits[6] = {0}, fastest_fine[6];
  float rollover[6] = {0.}, coarse[6] = {0.}, fastest[6] = {99999999.};
  for (int iframe = 0; iframe < nframes; ++iframe) {
    
    for (int i = 0; i < 6; ++i) {
      nhits[i] = 0;
      rollover[i] = 0.;
      coarse[i] = 0.;
      fastest[i] = 999999999.;
    }
    for (int ififo = 0; ififo < n_active_fifos; ++ififo) {
      auto fifo = active_fifo[ififo];
      auto chip = fifo / 4;
      tin[fifo]->GetEvent(iframe);
      nhits[chip] += frame[fifo].n;
      for (int hit = 0; hit < frame[fifo].n; ++hit) {
        rollover[chip] += frame[fifo].rollover[hit];
        auto eochannel = frame[fifo].pixel[hit] + 4 * frame[fifo].column[hit];
        auto dochannel = eo2do[eochannel];
        rollover[chip] += frame[fifo].rollover[hit];
        if (frame[fifo].fine[hit] < MIN)
          frame[fifo].fine[hit] = MIN;
        if (frame[fifo].fine[hit] > MAX)
          frame[fifo].fine[hit] = MAX;
        float fine_time = (frame[fifo].fine[hit] - MIN) / IF;
        if (frame[fifo].fine[hit] > CUT)
          fine_time = (frame[fifo].fine[hit] - MIN) / IF - 1.;
        //        std::cout << fine_time << std::endl;
        auto time = frame[fifo].coarse[hit];// - fine_time;
        coarse[chip] += time;
        if (time < fastest[chip]) {
          fastest[chip] = time;
          fastest_fine[chip] = frame[fifo].fine[hit];
        }
      }
    }

    if (nhits[4] < 9 || nhits[5] < 9) continue;

    coarse[4] /= nhits[4];
    coarse[5] /= nhits[5];
    
    auto delta = coarse[4] - coarse[5];
    auto delta_fastest = fastest[4] - fastest[5];
    hDelta->Fill(delta);
    hDelta_fastest->Fill(delta_fastest);
    hDelta_fastest_fine_4->Fill(fastest_fine[4], delta_fastest);
    
    //    hDelta->Draw();
    //    gPad->Update();
    
  }

  hDelta_fastest->Draw();
  hDelta->Draw("same");

  new TCanvas("c4");
  hDelta_fastest_fine_4->Draw("colz");
  
  fout.close();
  
}
