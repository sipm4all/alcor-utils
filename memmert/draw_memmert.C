#include "style.C"

void
draw_memmert(const char *fname, int seconds = kMaxInt, float tmin = -50., float tmax = 20.)
{
  style();

  TTree t;
  t.ReadFile(fname);

  auto nev = t.GetEntries();
  t.GetEntry(0);
  int tsi = t.GetLeaf("timestamp")->GetValue();
  t.GetEntry(nev - 1);
  int tsf = t.GetLeaf("timestamp")->GetValue();

  auto c = new TCanvas("c", "c", 1600, 800);
  c->Divide(2, 1);
  c->cd(1)->SetGridy();
  auto h1 = c->cd(1)->DrawFrame(std::max(tsi, tsf - seconds), tmin, tsf, tmax, ";time;T (#circC)");
  h1->GetXaxis()->SetTimeDisplay(1);
  c->cd(2)->SetGridy();
  auto h2 = c->cd(2)->DrawFrame(std::max(tsi, tsf - seconds), -5., tsf, 5, ";time;#DeltaT (#circC)");
  h2->GetXaxis()->SetTimeDisplay(1);

  TGraph *g = nullptr;

  c->cd(1);
  
  t.Draw("tset:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("OLD");
  g->SetLineWidth(3);
  g->SetLineColor(kRed+1);

  t.Draw("temp:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("OLD");
  g->SetLineWidth(3);
  g->SetLineColor(kAzure-3);

  auto gsave = g;
  
  t.Draw("rh:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("OLD");
  g->SetLineWidth(3);
  g->SetLineColor(kGreen+2);

  c->cd(2);
  
  t.Draw("(temp-tset):timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("OLD");
  g->SetLineWidth(3);
  g->SetLineColor(kAzure-3);

  std::string foutname = fname;
  size_t last_slash_idx = foutname.find_last_of('/');
  if (std::string::npos != last_slash_idx)
    foutname = foutname.substr(0, last_slash_idx) + "/draw_memmert.png";
  else foutname = "draw_memmert.png";
  c->SaveAs(foutname.c_str());

  foutname = fname;
  last_slash_idx = foutname.find_last_of('/');
  if (std::string::npos != last_slash_idx)
    foutname = foutname.substr(0, last_slash_idx) + "/draw_memmert.root";
  else foutname = "draw_memmert.root";
  TFile fout(foutname.c_str(), "RECREATE");
  gsave->Write("graph");
  fout.Close();

  // check if memmert is stable

  
}
