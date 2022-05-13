#include "style.C"

void
draw_masterlogic(const char *fname, const char *tname, int seconds = kMaxInt, float tmin = -50., float tmax = 20.)
{
  style();

  TTree t;
  t.ReadFile(fname);

  auto nev = t.GetEntries();
  t.GetEntry(0);
  int tsi = t.GetLeaf("timestamp")->GetValue();
  t.GetEntry(nev - 1);
  int tsf = t.GetLeaf("timestamp")->GetValue();

  auto c = new TCanvas("c", "c", 800, 800);
  c->SetGridy();
  auto h = c->DrawFrame(std::max(tsi, tsf - seconds), tmin, tsf, tmax, ";time;T (#circC)");
  h->GetXaxis()->SetTimeDisplay(1);

  TGraph *g = nullptr;

  t.Draw("temp:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("OLD");
  g->SetLineWidth(3);
  g->SetLineColor(kAzure-3);

  std::string foutname = fname;
  size_t last_slash_idx = foutname.find_last_of('/');
  if (std::string::npos != last_slash_idx)
    foutname = foutname.substr(0, last_slash_idx) + std::string("/draw_masterlogic") + tname + std::string(".png");
  else foutname = std::string("draw_masterlogic") + tname + std::string(".png");
  c->SaveAs(foutname.c_str());

  foutname = fname;
  last_slash_idx = foutname.find_last_of('/');
  if (std::string::npos != last_slash_idx)
    foutname = foutname.substr(0, last_slash_idx) + std::string("/draw_masterlogic") + tname + std::string(".root");
  else foutname = std::string("draw_masterlogic") + tname + std::string(".root");
  TFile fout(foutname.c_str(), "RECREATE");
  g->Write("graph");
  fout.Close();
}
