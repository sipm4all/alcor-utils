
void
peltier_control(int begint, int endt)
{
  TTree t;
  t.ReadFile("peltier_control.dat");

  auto c = new TCanvas("c", "c", 800, 800);
  c->Divide(1, 3, 0.005, 0.005);

  TH1 *h = c->cd(1)->DrawFrame(begint, -30., endt, 0.);
  c->cd(1)->SetGridy();
  h->GetXaxis()->SetTimeDisplay(1);
  t.Draw("Tsmall : timestamp" , "", "l,same");
  auto g = (TGraph *)gPad->GetListOfPrimitives()->Last();
  g->SetLineColor(kRed+1);
  g->SetLineWidth(2);
  g->SetFillStyle(0);
  g->SetFillColor(0);
  g->SetTitle("SMALL");
  auto l = c->cd(1)->BuildLegend();
  l->SetBorderSize(0);
  l->DeleteEntry();
  
  h = c->cd(2)->DrawFrame(begint, -30., endt, 0.);
  c->cd(2)->SetGridy();
  h->GetXaxis()->SetTimeDisplay(1);
  t.Draw("Tbig0 : timestamp" , "", "l,same");
  g = (TGraph *)gPad->GetListOfPrimitives()->Last();
  g->SetLineColor(kAzure-3);
  g->SetLineWidth(2);
  g->SetFillStyle(0);
  g->SetFillColor(0);
  g->SetTitle("BIG-0");
  l = c->cd(2)->BuildLegend();
  l->SetBorderSize(0);
  l->DeleteEntry();
  
  h = c->cd(3)->DrawFrame(begint, -30., endt, 0.);
  c->cd(3)->SetGridy();
  h->GetXaxis()->SetTimeDisplay(1);
  t.Draw("Tbig1 : timestamp" , "", "l,same");
  g = (TGraph *)gPad->GetListOfPrimitives()->Last();
  g->SetLineColor(kGreen+2);
  g->SetLineWidth(2);
  g->SetFillStyle(0);
  g->SetFillColor(0);
  g->SetTitle("BIG-1");
  l = c->cd(3)->BuildLegend();
  l->SetBorderSize(0);
  l->DeleteEntry();
  
  c->SaveAs("peltier_control.png");
}
