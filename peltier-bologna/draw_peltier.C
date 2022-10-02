
#include "style.C"

float tmin = -50;
float tmax = 50;
float ivmin = 0.;
float ivmax = 15.;
float pmin = 0.;
float pmax = 100.;

float ttemp = -30.;

void
draw_peltier(const char *fname, int seconds = kMaxInt)
{
  style();

  TTree t;
  t.ReadFile(fname);

  auto nev = t.GetEntries();
  t.GetEntry(0);
  int tsi = t.GetLeaf("timestamp")->GetValue();
  t.GetEntry(nev - 1);
  int tsf = t.GetLeaf("timestamp")->GetValue();

  auto c = new TCanvas("c", "c", 2400, 1600);
  c->Divide(3, 2);
  c->cd(1)->SetGridy();
  auto h1 = c->cd(1)->DrawFrame(std::max(tsi, tsf - seconds), tmin, tsf, tmax, ";time;temperature (#circC)");
  h1->GetXaxis()->SetTimeDisplay(1);
  c->cd(2)->SetGridy();
  auto h2 = c->cd(2)->DrawFrame(std::max(tsi, tsf - seconds), -5, tsf, 5, ";time;#Delta temperature wrt. average (#circC)");
  h2->GetXaxis()->SetTimeDisplay(1);
  c->cd(3)->SetGridy();
  auto h3 = c->cd(3)->DrawFrame(std::max(tsi, tsf - seconds), -5, tsf, 5, ";time;#Delta temperature wrt. target (#circC)");
  h3->GetXaxis()->SetTimeDisplay(1);
  c->cd(4)->SetGridy();
  auto h4 = c->cd(4)->DrawFrame(std::max(tsi, tsf - seconds), ivmin, tsf, ivmax, ";time;voltage (V) current (A)");
  h4->GetXaxis()->SetTimeDisplay(1);
  c->cd(5)->SetGridy();
  auto h5 = c->cd(5)->DrawFrame(std::max(tsi, tsf - seconds), pmin, tsf, pmax, ";time;power (W)");
  h5->GetXaxis()->SetTimeDisplay(1);
  auto h6 = c->cd(6)->DrawFrame(std::max(tsi, tsf - seconds), 0., tsf, 5., ";time;resistance (#Omega)");
  h6->GetXaxis()->SetTimeDisplay(1);

  TGraph *g = nullptr;

  c->cd(1);

  t.Draw("temp0:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("ML0");
  g->SetTitle("ML0");
  g->SetLineWidth(3);
  g->SetLineColor(kRed+1);

  auto gsave = g;

  t.Draw("temp1:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("ML1");
  g->SetTitle("ML1");
  g->SetLineWidth(3);
  g->SetLineColor(kGreen+2);

  t.Draw("temp2:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("ML2");
  g->SetTitle("ML2");
  g->SetLineWidth(3);
  g->SetLineColor(kYellow+2);

  t.Draw("temp3:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("ML3");
  g->SetTitle("ML3");
  g->SetLineWidth(3);
  g->SetLineColor(kAzure-3);

  t.Draw("tempin:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("TEMPIN");
  g->SetTitle("TEMPIN");
  g->SetLineWidth(3);
  g->SetLineColor(kBlack);

  t.Draw("rhin:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("RHIN");
  g->SetTitle("RHIN");
  g->SetLineWidth(3);
  g->SetLineStyle(kDashed);
  g->SetLineColor(kBlack);
  
  c->cd(2);
  
  t.Draw("temp0-0.25*(temp0+temp1+temp2+temp3):timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("ML0");
  g->SetTitle("ML0");
  g->SetLineWidth(3);
  g->SetLineColor(kRed+1);

  t.Draw("temp1-0.25*(temp0+temp1+temp2+temp3):timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("ML1");
  g->SetTitle("ML1");
  g->SetLineWidth(3);
  g->SetLineColor(kGreen+2);

  t.Draw("temp2-0.25*(temp0+temp1+temp2+temp3):timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("ML2");
  g->SetTitle("ML2");
  g->SetLineWidth(3);
  g->SetLineColor(kYellow+2);

  t.Draw("temp3-0.25*(temp0+temp1+temp2+temp3):timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("ML3");
  g->SetTitle("ML3");
  g->SetLineWidth(3);
  g->SetLineColor(kAzure-3);

  c->cd(3);
  
  t.Draw(Form("temp0-%f:timestamp", ttemp), Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("ML0");
  g->SetTitle("ML0");
  g->SetLineWidth(3);
  g->SetLineColor(kRed+1);

  t.Draw(Form("temp1-%f:timestamp", ttemp), Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("ML1");
  g->SetTitle("ML1");
  g->SetLineWidth(3);
  g->SetLineColor(kGreen+2);

  t.Draw(Form("temp2-%f:timestamp", ttemp), Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("ML2");
  g->SetTitle("ML2");
  g->SetLineWidth(3);
  g->SetLineColor(kYellow+2);

  t.Draw(Form("temp3-%f:timestamp", ttemp), Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("ML3");
  g->SetTitle("ML3");
  g->SetLineWidth(3);
  g->SetLineColor(kAzure-3);

  t.Draw(Form("0.25*(temp0+temp1+temp2+temp3)-%f:timestamp", ttemp), Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("AVE");
  g->SetTitle("AVE");
  g->SetLineWidth(3);
  g->SetLineStyle(kDashed);
  g->SetLineColor(kBlack);

#if 0
  auto gder = new TGraph;
  for (int i = 0; i < g->GetN() - 1; ++i) {
    double xi = g->GetX()[i];
    double xf = g->GetX()[i+1];
    double yi = g->GetY()[i];
    double yf = g->GetY()[i+1];
    //    std::cout << yf << " " << yi << " " << xf << " " << xi << std::endl; 
    gder->SetPoint(gder->GetN(), xi, (yf-yi)/(xf-xi)); 
    
  }

  auto gint = new TGraph;
  for (int i = 0; i < gder->GetN() - 10; i += 10) {
    double x = gder->GetX()[i];
    double y = 0.;
    for (int j = 0; j < 10; ++j) {
      y += gder->GetY()[i + j];
    }
    gint->SetPoint(gint->GetN(), x, 10. * y);
  }
  
  gint->SetLineColor(kOrange-3);
  gint->SetLineWidth(3);
  gint->Draw("samel");
#endif

  c->cd(4);
  
  t.Draw("vout:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("VOUT");
  g->SetTitle("VOUT");
  g->SetLineWidth(3);
  g->SetLineColor(kRed+1);

  t.Draw("iout:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("IOUT");
  g->SetTitle("IOUT");
  g->SetLineWidth(3);
  g->SetLineColor(kAzure-3);

  c->cd(5);
  
  t.Draw("vout*iout:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("POWER");
  g->SetLineWidth(3);
  g->SetLineColor(kGreen+2);
  
  c->cd(6);
  
  t.Draw("vout/iout:timestamp", Form("timestamp > %d", tsf - seconds), "same,l");
  g = (TGraph*)gPad->GetPrimitive("Graph");
  g->SetName("OHM");
  g->SetLineWidth(3);
  g->SetLineColor(kYellow+2);

  
  std::string foutname = fname;
  size_t last_slash_idx = foutname.find_last_of('/');
  if (std::string::npos != last_slash_idx)
    foutname = foutname.substr(0, last_slash_idx) + "/draw_peltier.png";
  else foutname = "draw_peltier.png";
  c->SaveAs(foutname.c_str());

  foutname = fname;
  last_slash_idx = foutname.find_last_of('/');
  if (std::string::npos != last_slash_idx)
    foutname = foutname.substr(0, last_slash_idx) + "/draw_peltier.root";
  else foutname = "draw_peltier.root";
  TFile fout(foutname.c_str(), "RECREATE");
  gsave->Write("graph");
  fout.Close();

  // check if peltier is stable

  
}
