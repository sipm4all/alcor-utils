TH1 *plotChip(const char *dir, int ichip);

void
plotChip(const char *dir)
{
  auto c = new TCanvas("c", "c", 1600, 800);
  c->Divide(4, 2);
  for (int ichip = 0; ichip < 6; ++ichip) {
    c->cd(ichip + 1)->SetLogy();
    auto h = plotChip(dir, ichip);
    h->GetYaxis()->SetRangeUser(1.e1, 1.e6);
    h->Draw("histoe");
  }
  c->SaveAs(Form("%s/plotChip.png", dir));
}

TH1 *
plotChip(const char *dir, int ichip) {

  auto hout = new TH1F("hout", Form("alcor #%d;channel;rate (Hz)", ichip), 32, 0, 32);
  hout->SetMinimum(0.1);
  hout->SetLineColor(kAzure-3);
  hout->SetLineWidth(2);
  hout->SetMarkerColor(kAzure-3);
  hout->SetMarkerStyle(20);
  hout->SetStats(kFALSE);
  for (int ilane = 0; ilane < 4; ++ilane) {
    auto hlane = new TH1F("hlane", Form("alcor #%d;channel;counts", ichip), 32, 0, 32);
    auto fin = TFile::Open(Form("%s/alcdaq.fifo_%d.root", dir, ilane + 4 * ichip));
    if (!fin || !fin->IsOpen()) continue;
    auto tin = (TTree *)fin->Get("alcor");
    int type, pixel, column, rollover, coarse;
    tin->SetBranchAddress("type", &type);
    tin->SetBranchAddress("pixel", &pixel);
    tin->SetBranchAddress("column", &column);
    tin->SetBranchAddress("rollover", &rollover);
    tin->SetBranchAddress("coarse", &coarse);
    auto nev = tin->GetEntries();
    float seconds = 0.;
    int last_coarse, last_rollover;
    for (int iev = 0; iev < nev; ++iev) {
      tin->GetEntry(iev);
      if (type == 1) { 
	last_coarse = coarse;
	last_rollover = rollover;
	hlane->Fill(pixel + 4 * column);
      }
      if (type == 15) seconds += coarse * 3.1250000e-09 + rollover * 0.00010240000;
    }
    if (seconds <= 0.) {
      //      std::cout << "warning: " << seconds << " seconds" << std::endl;
      seconds = last_coarse * 3.1250000e-09 + last_rollover * 0.00010240000;
    }
    hlane->Scale(1. / seconds);
    hout->Add(hlane);
delete hlane;
  }
  return hout;
 }
