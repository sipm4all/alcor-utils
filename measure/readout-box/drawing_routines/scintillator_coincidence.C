#define MAXDATA 8192

#define FINECUT 69
#define FINEMIN 37
#define FINEMAX 101
#define FINEIF 64

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

//int trigger_delay = 210.; // [ns]
int trigger_delay = 210. + 350. + 75. - 65.; // [ns]
double chip_delay[6] = {-11., -11., -11., -11., 0., 0.}; // [ns]
int timing_delay = 0.;

void
scintillator_coincidence(std::string filename = "alcdaq.miniframe.root", double cutmin = -25., double cutmax = 25., bool correct_lane_efficiency = true, bool normalise_to_reference = true, bool trigger_cut = false)
{

  /** load offset calibration **/
  double offset_calib[768];
  auto foffset = TFile::Open("/home/eic/alcor/alcor-utils/measure/readout-box/drawing_routines/offset_calibration_x.root");
  auto pOffset = (TProfile *)foffset->Get("pOffset");
  for (int i = 0; i < 640; ++i) {
    offset_calib[i] = pOffset->GetBinContent(i + 1);
  }
  foffset->Close();
  //
  foffset = TFile::Open("/home/eic/alcor/alcor-utils/measure/readout-box/drawing_routines/offset_calibration_x.root");
  pOffset = (TProfile *)foffset->Get("pOffset");
  for (int i = 640; i < 768; ++i)
    offset_calib[i] = pOffset->GetBinContent(i + 1);
  foffset->Close();
  
  /** load fine calibration **/
  double fine_calib_cut[768], fine_calib_min[768], fine_calib_if[768];
  auto fcalib = TFile::Open("/home/eic/alcor/alcor-utils/measure/readout-box/drawing_routines/fine_calibration.root");
  auto hFineMin = (TH1 *)fcalib->Get("hFineMin");
  auto hFineMax = (TH1 *)fcalib->Get("hFineMax");
  for (int i = 0; i < 768; ++i) {
    double loval = hFineMin->GetBinContent(i + 1);
    double hival = hFineMax->GetBinContent(i + 1);
    if (loval == 0. || hival == 0.) {
      loval = FINEMIN;
      hival = FINEMAX;
    }
    
    loval = 50;
    loval = 200;

    fine_calib_cut[i] = (loval + hival) * 0.5;
    fine_calib_min[i] = loval;
    fine_calib_if[i] = hival - loval;
  }
  fcalib->Close();
  
  auto fin = TFile::Open(filename.c_str());
  TTree *tin[25] = {nullptr};
  frame_data_t frame[25];
  int nev[25] = {0}, nframes = kMaxInt;
  int n_active_fifos = 0;
  int active_fifo[25];
  int n_active_frames[25] = {0};
  
  // loop and link available fifos
  for (int fifo = 0; fifo < 25; ++fifo) {
    tin[fifo] = (TTree *)fin->Get(Form("miniframe_%d", fifo));
    if (!tin[fifo]) continue;
    nev[fifo] = tin[fifo]->GetEntries();
    std::cout << " --- found fifo " << fifo << ": " << nev[fifo] << " entries " << std::endl;
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

    nframes = std::min(nframes, nev[fifo]);
  }
  std::cout << " --- we will loop over " << nframes << " frames " << std::endl;

  auto hN = new TH2F("hN", "", 33, 0., 33., 33, 0., 33);
  
  auto hDelta_first = new TH1F("hDelta_first", "", 2000, -100., 100.);
  hDelta_first->SetLineWidth(2);
  hDelta_first->SetLineColor(kAzure-3);
  hDelta_first->SetMarkerStyle(20);
  hDelta_first->SetMarkerColor(kAzure-3);

  auto hDelta_trigg = new TH1F("hDelta_trigg", "", 200, -100., 100.);
  hDelta_trigg->SetLineWidth(2);
  hDelta_trigg->SetLineColor(kGreen+2);
  hDelta_trigg->SetMarkerStyle(20);
  hDelta_trigg->SetMarkerColor(kGreen+2);

  auto hDelta_avera = new TH1F("hDelta_avera", "", 100, -5., 5.);
  hDelta_avera->SetLineWidth(2);
  hDelta_avera->SetLineColor(kRed+1);
  hDelta_avera->SetMarkerStyle(25);
  hDelta_avera->SetMarkerColor(kRed+1);

  TH1 *hDelta[6] = {nullptr};
  TH2 *hMap[6] = {nullptr};
  for (int ichip = 0; ichip < 6; ++ichip) {
    hDelta[ichip] = new TH1F(Form("hDelta_%d", ichip), Form("chip %d;hit - reference time (ns)", ichip), 2000, -100., 100.);
    hMap[ichip] = new TH2F(Form("hMap_%d", ichip), Form("chip %d;matrix row;matrix column", ichip), 8, 0., 8., 4, 0., 4.);
  }

  
  /** loop over frames **/
  int n_reference_time = 0;
  for (int iframe = 0; iframe < nframes; ++iframe) {

    bool has_pixel_fired[6][32] = {false}, has_first_pixel[6] = {false};
    double pixel_time[6][32] = {0.};
    int n_pixel_fired[6] = {0}, first_pixel[6] = {0};
    
    /** loop over timing fifos **/
    for (int ififo = 0; ififo < n_active_fifos; ++ififo) {
      auto fifo = active_fifo[ififo];
      if (fifo == 24) continue; // skip trigger fifo 
      auto ichip = fifo / 4;
      if (ichip != 4 && ichip != 5) continue;
      tin[fifo]->GetEvent(iframe);

      /** loop over hits **/
      for (int hit = 0; hit < frame[fifo].n; ++hit) {
        
        int ipixel = frame[fifo].pixel[hit] + 4 * frame[fifo].column[hit];
        
        int itdc = frame[fifo].tdc[hit] +
          4 * frame[fifo].pixel[hit] +
          16 * (frame[fifo].column[hit] % 2) +
          32 * fifo;

        /** calculate hit time **/
        double rollover = (double)frame[fifo].rollover[hit];
        double coarse = (double)frame[fifo].coarse[hit];
        double fine = ((double)frame[fifo].fine[hit] - fine_calib_min[itdc]) / fine_calib_if[itdc];
	if (frame[fifo].fine[hit] > fine_calib_cut[itdc]) fine -= 1.;
	double time = (coarse - fine) + 32768. * rollover;
	time -= offset_calib[itdc];
        
        /** store the first hit for each pixel **/
        if (!has_pixel_fired[ichip][ipixel]) {
          pixel_time[ichip][ipixel] = time;
          n_pixel_fired[ichip]++;
        }
        else if (time < pixel_time[ichip][ipixel])
          pixel_time[ichip][ipixel] = time;
        
        has_pixel_fired[ichip][ipixel] = true;

        /** store pixel first hit of the chip **/
        if (!has_first_pixel[ichip]) first_pixel[ichip] = ipixel;
        else if (time < pixel_time[ichip][first_pixel[ichip]])
          first_pixel[ichip] = ipixel;
        
        has_first_pixel[ichip] = true;
      }

    }

    /** compute time of chip **/
    double chip_first_time[6] = {0.}, chip_average_time[6] = {0.};
    int chip_average_n[6] = {0};
    for (int ichip = 0; ichip < 6; ++ichip) {
      if (has_first_pixel[ichip])
        chip_first_time[ichip] = pixel_time[ichip][first_pixel[ichip]];
      for (int ipixel = 0; ipixel < 32; ++ipixel) {
        if (!has_pixel_fired[ichip][ipixel]) continue;
        auto delta = pixel_time[ichip][ipixel] - pixel_time[ichip][first_pixel[ichip]];
        if (delta > 5.) continue;
        chip_average_time[ichip] += pixel_time[ichip][ipixel];
        chip_average_n[ichip]++;
      }
      if (chip_average_n[ichip] > 0)
        chip_average_time[ichip] /= chip_average_n[ichip];
    }

    hN->Fill(n_pixel_fired[4], n_pixel_fired[5]);
    
    if (n_pixel_fired[4] == 32 && n_pixel_fired[5] == 32) { 
      hDelta_first->Fill( (chip_first_time[4] - chip_first_time[5]) * 3.125 );
      hDelta_avera->Fill( (chip_average_time[4] - chip_average_time[5]) * 3.125 );
    }

    if (n_pixel_fired[4] < 32 || n_pixel_fired[5] < 32) continue;

    /*** ALCOR BOX COINCIDENCES **/

    auto reference_time = 0.5 * (chip_average_time[4] + chip_average_time[5]);
    
    /** trigger tag **/
    bool trigger_tag = false;
    if (tin[24]) {
      tin[24]->GetEvent(iframe);
      for (int hit = 0; hit < frame[24].n; ++hit) {
	double rollover = (double)frame[24].rollover[hit];
	double coarse = (double)frame[24].coarse[hit];
	double time = coarse + 32768. * rollover;
	double delta = (time - reference_time) * 3.125;
	delta -= trigger_delay;
	if (delta > -40. && delta < 10.) trigger_tag = true;
	hDelta_trigg->Fill(delta);
      }
    }
    if (trigger_cut && !trigger_tag) continue;
    
    n_reference_time++;

    /** loop over box fifos **/
    for (int ififo = 0; ififo < n_active_fifos; ++ififo) {
      auto fifo = active_fifo[ififo];
      if (fifo == 24) continue; // skip trigger fifo 
      auto ichip = fifo / 4;
      tin[fifo]->GetEvent(iframe);

      /** check if lane is active in this frame **/
      if (frame[fifo].n > 0) n_active_frames[fifo]++;
      else continue;
      
      /** loop over hits **/
      for (int hit = 0; hit < frame[fifo].n; ++hit) {
        
        int ipixel = frame[fifo].pixel[hit] + 4 * frame[fifo].column[hit];

	int eoch = frame[fifo].pixel[hit] + 4 * frame[fifo].column[hit];
	int doch = eo2do[eoch];
	int dorow = doch / 4;
	int docol = doch % 4;
        
        int itdc = frame[fifo].tdc[hit] +
          4 * frame[fifo].pixel[hit] +
          16 * (frame[fifo].column[hit] % 2) +
          32 * fifo;

        /** calculate hit time **/
        double rollover = (double)frame[fifo].rollover[hit];
        double coarse = (double)frame[fifo].coarse[hit];
	double fine = ((double)frame[fifo].fine[hit] - fine_calib_min[itdc]) / fine_calib_if[itdc];
	if (frame[fifo].fine[hit] > fine_calib_cut[itdc]) fine -= 1.;
        double time = (coarse - fine) + 32768. * rollover;
	time -= offset_calib[itdc];
	
	auto delta = (time - reference_time) * 3.125;
	delta -= chip_delay[ichip];
	hDelta[ichip]->Fill(delta);
	
	if ( (delta > cutmin && delta < cutmax) || (cutmin == 0. && cutmax == 0.) )
	  hMap[ichip]->Fill(dorow, docol);
	
      }
    } 
  }


  /** scale hit map with number of reference time measurements **/
  if (normalise_to_reference) {
    for (int ichip = 0; ichip < 6; ++ichip) {
      hMap[ichip]->Sumw2();
      hMap[ichip]->Scale(1. / n_reference_time);
    }
  }
  std::cout << " --- " << std::endl;
  std::cout << " --- reference scintillator coincidences: " << n_reference_time << std::endl;
  
  /** correct hit map for lane efficiency **/
  if (correct_lane_efficiency) {
    for (int fifo = 0; fifo < 24; ++fifo) {
      double lane_efficiency = (double)n_active_frames[fifo] / (double)n_reference_time;
      std::cout << " --- lane " << fifo << " efficiency: " << lane_efficiency << std::endl;
      /** loop over lane channels **/
      for (int ch = 0; ch < 8; ++ch) {
	int ichip = fifo / 4;
	int eoch = ch + 8 * (fifo % 4);
	int doch = eo2do[eoch];
	int dorow = doch / 4;
	int docol = doch % 4;
	double val = hMap[ichip]->GetBinContent(dorow + 1, docol + 1);
	double vale = hMap[ichip]->GetBinError(dorow + 1, docol + 1);
	val /= lane_efficiency;
	vale /= lane_efficiency;
	hMap[ichip]->SetBinContent(dorow + 1, docol + 1, val);
	hMap[ichip]->SetBinError(dorow + 1, docol + 1, vale);
      }
    }
  }
  
  auto cN = new TCanvas("cN");
  hN->Draw("colz");
  cN->SaveAs("cN.png");
  
  auto cDelta_scint = new TCanvas("cDelta_scint");
  hDelta_avera->Draw("ep");
  cDelta_scint->SaveAs(Form("%s.Delta_scint.png", filename.c_str()));
  //  hDelta_first->Draw("same,ep");

  auto cDelta = new TCanvas("cDelta", "cDelta", 1500, 1000);
  cDelta->Divide(3, 2);
  for (int ichip = 0; ichip < 6; ++ichip) {
    cDelta->cd( (ichip % 2) * 3 + (ichip / 2) + 1);
    hDelta[ichip]->Draw();
  }
  cDelta->SaveAs(Form("%s.Delta.png", filename.c_str()));
  
  auto cMap = new TCanvas("cMap", "cMap", 1500, 500);
  cMap->Divide(3, 2);
  for (int ichip = 0; ichip < 6; ++ichip) {
    cMap->cd( (ichip % 2) * 3 + (ichip / 2) + 1);
    hMap[ichip]->SetMinimum(0.);
    hMap[ichip]->SetStats(kFALSE);
    hMap[ichip]->Draw("colz");
  }
  cMap->SaveAs(Form("%s.Map.png", filename.c_str()));
  
  auto cDelta_trigg = new TCanvas("cDelta_trigg");
  hDelta_trigg->Draw("ep");
  cDelta_trigg->SaveAs(Form("%s.Delta_trigg.png", filename.c_str()));

  /** write histograms on file **/
  auto outfilename = filename + std::string(".scintillator_coincidence.root");
  auto fout = TFile::Open(outfilename.c_str(), "RECREATE");
  hN->Write();
  hDelta_avera->Write();
  hDelta_first->Write();
  hDelta_trigg->Write();
  for (int ichip = 0; ichip < 6; ++ichip) {
    hDelta[ichip]->Write();
    hMap[ichip]->Write();
  } 
  fout->Close();
  
}
