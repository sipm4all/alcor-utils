TH1 *
draw_what(const char *filename,
          const char *what,
          const char *vs_what,
          const char *cuts = "pulse_voltage == 1000 && pulse_frequency == 100",
          const char *opts = "profile")
{
  auto f = TFile::Open(filename);
  auto t = (TTree*)f->Get("tree");
  printf("drawing %s : %s | %s | %s \n", what, vs_what, cuts , opts);
  t->Draw(Form("%s : %s", what, vs_what), cuts, opts);
  auto h = (TH1*)gPad->FindObject("htemp");
  h->SetName("hold");
  h->SetMarkerStyle(20);
  h->SetYTitle(what);
  h->SetXTitle(vs_what);
  h->SetTitle(cuts);
  return h;
}

void
draw_universal_scan(const char *filename,
		    const char *vs_what,
		    const char *cuts = "pulse_voltage == 1000 && pulse_frequency == 100",
		    const char *opts = "profile",
		    bool logy = true)
{
  gStyle->SetOptStat(false);
  auto c = new TCanvas("c", "c", 1200, 400);
  c->Divide(3, 1);
  c->cd(1)->SetLogy(logy);
  auto h1 = draw_what(filename, "rate_off", vs_what, cuts, opts);
  c->cd(2)->SetLogy(logy);
  auto h2 = draw_what(filename, "rate_on", vs_what, cuts, opts);
  c->cd(3)->SetLogy(logy);
  auto h3 = draw_what(filename, "rate_on - rate_off", vs_what, cuts, opts);

  auto c2 = new TCanvas("c2", "c2", 800, 800);
  c2->SetLogy();
  h2->Draw();
  h1->Draw("same");
  h1->SetMarkerColor(kRed+1);
  h3->Draw("same");
  h3->SetMarkerColor(kAzure-3);

  c->SaveAs(Form("%s.png", filename));
}
