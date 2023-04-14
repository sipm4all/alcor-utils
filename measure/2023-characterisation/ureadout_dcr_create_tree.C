void
ureadout_dcr_create_tree(std::string dirname, std::string foutname)
{
  TSystemDirectory destdir(dirname.c_str(), dirname.c_str());
  auto dirlist = destdir.GetListOfFiles();

  auto fout = TFile::Open(foutname.c_str(), "RECREATE");
  auto tout = new TTree("ureadout_dcr_scan", "ureadout_dcr_scan");
  int base_threshold, threshold, bias_dac;
  float bias_voltage, raw_rate, raw_ratee, dead_rate, dead_ratee, fit_rate, fit_ratee;
  tout->Branch("bias_dac", &bias_dac, "bias_dac/I");
  tout->Branch("bias_voltage", &bias_voltage, "bias_voltage/F");
  tout->Branch("base_threshold", &base_threshold, "base_threshold/I");
  tout->Branch("threshold", &threshold, "threshold/I");
  tout->Branch("raw_rate", &raw_rate, "raw_rate/F");
  tout->Branch("raw_ratee", &raw_ratee, "raw_ratee/F");
  tout->Branch("dead_rate", &dead_rate, "dead_rate/F");
  tout->Branch("dead_ratee", &dead_ratee, "dead_ratee/F");
  tout->Branch("fit_rate", &fit_rate, "fit_rate/F");
  tout->Branch("fit_ratee", &fit_ratee, "fit_ratee/F");
  
  for (int i = 0; i < dirlist->GetEntries(); ++i) {
    TString filename = dirlist->At(i)->GetName();
    if (!filename.BeginsWith("dcr_ureadout")) continue;
    if (!filename.EndsWith(".root")) continue;
    TString metadata_str = filename;
    metadata_str.Remove(0, sizeof("dcr_readout_"));
    metadata_str.Remove(metadata_str.Length() - sizeof(".root") + 1, sizeof(".root") );
    auto metadata_oa = metadata_str.Tokenize("_");
    for (int i = 0; i < metadata_oa->GetEntries(); ++i) {
      TString str = metadata_oa->At(i)->GetName();
      auto oa = str.Tokenize("=");
      if (oa->GetEntries() != 2) continue;
      TString key = oa->At(0)->GetName();
      TString value = oa->At(1)->GetName();
      if (key.EqualTo("biasdac") || key.EqualTo("bias_dac") || key.EqualTo("dac"))
        bias_dac = value.Atoi();
      else if (key.EqualTo("biasvoltage") || key.EqualTo("bias_voltage") || key.EqualTo("voltage"))
        bias_voltage = value.Atof();
      else if (key.EqualTo("basethreshold") || key.EqualTo("base_threshold"))
        base_threshold = value.Atoi();
      else if (key.EqualTo("threshold"))
        threshold = value.Atoi();        
    }

    
    TString pathname = TString(dirname.c_str()) + TString("/") + filename;
    std::cout << "processing: " << filename << std::endl;
    auto fin = TFile::Open(pathname);

    /** rate based on raw number of hits **/
    
    auto hCounters = (TH1F *)fin->Get("hCounters");
    float itime = hCounters->GetBinContent(2) * 0.0001024;
    float nhits = hCounters->GetBinContent(3);

    raw_rate = nhits / itime;
    raw_ratee = sqrt(nhits) / itime;

    /** rate based on dead-timed number of hits **/

    auto hDead = (TH1F *)fin->Get("hDead");
    float tdead = hDead->GetBinContent(1) * 3.1250000e-09;
    float ndead = hDead->GetBinContent(2);
    float mdead = ndead / itime;
    float mdeade = sqrt(ndead) / itime;

    dead_rate = mdead / (1. - mdead * tdead);
    dead_ratee = mdeade / (1. - mdead * tdead); // R+FIXME
    
    /** rate based on fit to deltat distribution **/
    
    auto hDeltat = (TH1 *)fin->Get("hDeltat_log");
    hDeltat->Scale(1., "width");
    
    auto f = (TF1 *)gROOT->GetFunction("expo");
    int fitres = hDeltat->Fit(f, "0q", "", 160., 1.e10);

    if (fitres == 0) {
      fit_rate = f->GetParameter(1) * -320.e6;
      fit_ratee = f->GetParError(1) * 320.e6;
    } else {
      fit_rate = 0.;
      fit_ratee = 0.;
    }

    tout->Fill();
    
    fin->Close();
    
  }

  fout->cd();
  tout->Write();
  fout->Close();
  
}
