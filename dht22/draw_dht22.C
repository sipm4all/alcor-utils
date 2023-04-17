#include "style.C"

void
draw_dht22(const char *fname, int seconds = kMaxInt, float tmin = 0., float tmax = 50.)
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
  auto h1 = c->cd(1)->DrawFrame(std::max(tsi, tsf - seconds), tmin, tsf, tmax, ";time;T (#circC) RH (%)");
  h1->GetXaxis()->SetTimeDisplay(1);
  c->cd(2)->SetGridy();
  auto h2 = c->cd(2)->DrawFrame(std::max(tsi, tsf - seconds), tmin, tsf, tmax, ";time;T_{dew} (#circC)");
  h2->GetXaxis()->SetTimeDisplay(1);

  TGraph *g = nullptr;

  c->cd(1);
  
  t.Draw("temp:timestamp", Form("abs(temp) < 100 && timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("TEMP");
  g->SetTitle("TEMP");
  g->SetLineWidth(3);
  g->SetLineColor(kAzure-3);
  g->SetMarkerColor(kAzure-3);
  g->SetFillStyle(0);
  g->SetFillColor(0);
  
  auto gsave = g;

  t.Draw("rh:timestamp", Form("abs(rh) < 100 && timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("RH");
  g->SetTitle("RH");
  g->SetLineWidth(3);
  g->SetLineColor(kGreen+2);
  g->SetMarkerColor(kGreen+2);
  g->SetFillStyle(0);
  g->SetFillColor(0);

  auto l = c->cd(1)->BuildLegend(0.9, 0.9, 1.0, 1.0);
  l->DeleteEntry();
  
  c->cd(2);

  /*
    float b = 18.678;
    float c = 257.14;
    auto ga = std::log(rh / 100.) + b * temp / (c + temp);
    auto dp = c * ga / (b - ga);
  */

  t.Draw("257.14 * ( log(rh / 100.) + 18.678 * temp / (257.14 + temp) ) / (18.678 - ( log(rh / 100.) + 18.678 * temp / (257.14 + temp) )) : timestamp", Form("abs(temp) < 100 && abs(rh) < 100 && timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("DEW");
  g->SetLineWidth(3);
  g->SetLineColor(kRed+1);
  
  std::string foutname = fname;
  size_t last_slash_idx = foutname.find_last_of('/');
  if (std::string::npos != last_slash_idx)
    foutname = foutname.substr(0, last_slash_idx) + "/draw_dht22.png";
  else foutname = "draw_dht22.png";
  c->SaveAs(foutname.c_str());

  foutname = fname;
  last_slash_idx = foutname.find_last_of('/');
  if (std::string::npos != last_slash_idx)
    foutname = foutname.substr(0, last_slash_idx) + "/draw_dht22.root";
  else foutname = "draw_dht22.root";
  TFile fout(foutname.c_str(), "RECREATE");
  gsave->Write("graph");
  fout.Close();

  // check if dht22 is stable

  
}
