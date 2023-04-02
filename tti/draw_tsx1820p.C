#include "style.C"

float vmin = -1.;
float vmax = 1.;;//15.;
float imin = -1.;
float imax = 15.;
float pmin = -1.;
float pmax = 1.;;//150.;

void
draw_tsx1820p(const char *fname, int seconds = kMaxInt)
{
  style();

  TTree t;
  t.ReadFile(fname);

  auto nev = t.GetEntries();
  t.GetEntry(0);
  int tsi = t.GetLeaf("timestamp")->GetValue();
  t.GetEntry(nev - 1);
  int tsf = t.GetLeaf("timestamp")->GetValue();

  auto c = new TCanvas("c", "c", 1800, 600);
  c->Divide(3, 1);
  c->cd(1)->SetGridy();
  auto h1 = c->cd(1)->DrawFrame(std::max(tsi, tsf - seconds), vmin, tsf, vmax, ";time;voltage (V)");
  h1->GetXaxis()->SetTimeDisplay(1);
  c->cd(2)->SetGridy();
  auto h2 = c->cd(2)->DrawFrame(std::max(tsi, tsf - seconds), imin, tsf, imax, ";time;current (A)");
  h2->GetXaxis()->SetTimeDisplay(1);
  c->cd(3)->SetGridy();
  auto h3 = c->cd(3)->DrawFrame(std::max(tsi, tsf - seconds), pmin, tsf, pmax, ";time;power (W)");
  h3->GetXaxis()->SetTimeDisplay(1);

  TGraph *g = nullptr;

  c->cd(1);
  
  t.Draw("vset:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("VSET");
  g->SetLineWidth(3);
  g->SetLineColor(kRed+1);

  t.Draw("vout:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("VOUT");
  g->SetLineWidth(3);
  g->SetLineColor(kAzure-3);

  auto gsave = g;
  
  c->cd(2);
  
  t.Draw("iset:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("ISET");
  g->SetLineWidth(3);
  g->SetLineColor(kRed+1);

  t.Draw("iout:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("IOUT");
  g->SetLineWidth(3);
  g->SetLineColor(kAzure-3);

  c->cd(3);
  
  t.Draw("vout*iout:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("POWER");
  g->SetLineWidth(3);
  g->SetLineColor(kGreen+2);

  
  std::string foutname = fname;
  size_t last_slash_idx = foutname.find_last_of('/');
  if (std::string::npos != last_slash_idx)
    foutname = foutname.substr(0, last_slash_idx) + "/draw_tsx1820p.png";
  else foutname = "draw_tsx1820p.png";
  c->SaveAs(foutname.c_str());

  foutname = fname;
  last_slash_idx = foutname.find_last_of('/');
  if (std::string::npos != last_slash_idx)
    foutname = foutname.substr(0, last_slash_idx) + "/draw_tsx1820p.root";
  else foutname = "draw_tsx1820p.root";
  TFile fout(foutname.c_str(), "RECREATE");
  gsave->Write("graph");
  fout.Close();

  // check if tsx1820p is stable

  
}
