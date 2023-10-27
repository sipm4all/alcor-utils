void
basicQA(std::string fname)
{
  auto fin = TFile::Open(fname.c_str());
  auto hCounters = (TH1 *)fin->Get("hCounters");
  std::cout << "nspills = " << hCounters->GetBinContent(1) << " rollovers = " << hCounters->GetBinContent(2) << std::endl;
}
