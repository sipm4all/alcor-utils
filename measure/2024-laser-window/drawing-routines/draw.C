#include "data.h"

void
draw()
{

  auto g = new TGraphErrors;
  
  for (auto &[fname, pos] : datain) {
    auto fin = TFile::Open(fname.c_str());
    if (!fin) continue;
    auto hin = (TH1 *)fin->Get("hDelta");
    if (!hin) continue;
    
#if 1
    auto sbmin = hin->GetXaxis()->FindBin(-50 + 0.001);
    auto sbmax = hin->GetXaxis()->FindBin(+50 - 0.001);
    auto lbmin = hin->GetXaxis()->FindBin(-100 + 0.001);
    auto lbmax = hin->GetXaxis()->FindBin(-50 - 0.001);
    auto hbmin = hin->GetXaxis()->FindBin(+50 + 0.001);
    auto hbmax = hin->GetXaxis()->FindBin(+100 - 0.001);
#else
    auto sbmin = hin->GetXaxis()->FindBin(-25 + 0.001);
    auto sbmax = hin->GetXaxis()->FindBin(+25 - 0.001);
    auto lbmin = hin->GetXaxis()->FindBin(-100 + 0.001);
    auto lbmax = hin->GetXaxis()->FindBin(-75 - 0.001);
    auto hbmin = hin->GetXaxis()->FindBin(-75 + 0.001);
    auto hbmax = hin->GetXaxis()->FindBin(-50 - 0.001);
#endif
    
    double sinte;
    double sint = hin->IntegralAndError(sbmin, sbmax, sinte);
    double linte;
    double lint = hin->IntegralAndError(lbmin, lbmax, linte);
    double hinte;
    double hint = hin->IntegralAndError(hbmin, hbmax, hinte);

    double bint = 0.5 * (lint + hint);
    double binte = 0.5 * hypot(linte, hinte);
    sint -= bint;
    sinte = hypot(sinte, binte);
    
    auto n = g->GetN();
    g->SetPoint(n, pos, sint);
    g->SetPointError(n, 0., sinte);
  }

  auto c = new TCanvas("c", "c");
  g->SetTitle(";bias voltage (V); pseudo-efficiency");
  g->Draw("ap*");
  c->SaveAs("c.png");
}
