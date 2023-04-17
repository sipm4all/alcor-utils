void
count_coincidences(std::string filename,
                   bool secondpeak = true,
		   float_t sigmin = -50., float_t sigmax = 50.,
		   float_t bkgmin = -100., float_t bkgmax = -50.
                   )
{

  auto fin = TFile::Open(filename.c_str());
  if (!fin || !fin->IsOpen()) return;
  auto hdelta = (TH1 *)fin->Get("hDelta");
  auto hntrg = (TH1 *)fin->Get("hNTriggers");
  if (!hdelta || !hntrg) return;
  auto ntrg = hntrg->GetBinContent(1);
  
  auto isigmin = hdelta->GetXaxis()->FindBin(sigmin + 0.001);
  auto isigmax = hdelta->GetXaxis()->FindBin(sigmax - 0.001);
  auto nsig = hdelta->Integral(isigmin, isigmax);
  if (secondpeak) {
    isigmin = hdelta->GetXaxis()->FindBin(sigmin + 32768 + 0.001);
    isigmax = hdelta->GetXaxis()->FindBin(sigmax + 32768 - 0.001);
    nsig += hdelta->Integral(isigmin, isigmax);
  }
  
  auto ibkgmin = hdelta->GetXaxis()->FindBin(bkgmin + 0.001);
  auto ibkgmax = hdelta->GetXaxis()->FindBin(bkgmax - 0.001);
  auto nbkg = hdelta->Integral(ibkgmin, ibkgmax);
  if (secondpeak) {
    ibkgmin = hdelta->GetXaxis()->FindBin(bkgmin + 32768 + 0.001);
    ibkgmax = hdelta->GetXaxis()->FindBin(bkgmax + 32768 - 0.001);
    nbkg += hdelta->Integral(ibkgmin, ibkgmax);
  }

  auto nsige = std::sqrt(nsig);
  auto nbkge = std::sqrt(nbkg);

  // write numbers on output histogram
  auto hout = new TH1F("hCounts", "", 10, 0., 10);
  hout->SetBinContent(1, ntrg);
  hout->SetBinContent(2, sigmin);
  hout->SetBinContent(3, sigmax);
  hout->SetBinContent(4, nsig);
  hout->SetBinContent(5, bkgmin);
  hout->SetBinContent(6, bkgmax);
  hout->SetBinContent(7, nbkg);
  size_t lastindex = filename.find_last_of("."); 
  std::string foutname = filename.substr(0, lastindex);
  auto fout = TFile::Open((foutname + ".count.root").c_str(), "RECREATE");
  hout->Write();
  fout->Close();  
  fin->Close();

  std::cout << nsig / ntrg << std::endl;
  return;
}
