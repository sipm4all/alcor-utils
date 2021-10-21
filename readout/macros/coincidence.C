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

  TH1 *hDelta = new TH1F("hDelta", "", 100000, -50000., 50000.);
  
  for (int iframe = 0; iframe < nframes; ++iframe) {
    int nhits[6] = {0};
    float rollover[6] = {0.}, coarse[6] = {0.};

    for (int ififo = 0; ififo < n_active_fifos; ++ififo) {
      auto fifo = active_fifo[ififo];
      auto chip = fifo / 4;
      tin[fifo]->GetEvent(iframe);
      nhits[chip] += frame[fifo].n;
      for (int hit = 0; hit < frame[fifo].n; ++hit) {
        rollover[chip] += frame[fifo].rollover[hit];
        coarse[chip] += (frame[fifo].coarse[hit] - frame[fifo].fine[hit] / 64.);
        auto eochannel = frame[fifo].pixel[hit] + 4 * frame[fifo].column[hit];
        auto dochannel = eo2do[eochannel];
      }
    }

    if (nhits[4] < 1 || nhits[5] < 1) continue;

    coarse[4] /= nhits[4];
    coarse[5] /= nhits[5];
    
    auto delta = coarse[4] - coarse[5];
    hDelta->Fill(delta);
    
    //    hDelta->Draw();
    //    gPad->Update();
    
  }

  hDelta->Draw();
  fout.close();
  
}
