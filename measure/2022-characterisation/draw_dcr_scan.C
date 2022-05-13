void draw_map(float vmin = 22., float vmax = 34.);

void
draw_dcr_scan()
{
  draw_map();
}


const char *chipname = "chip3-";

TProfile *
draw_channel(int chip, const char *channel, int ithr = 0)
{
  std::string hname = std::string("chip") + std::to_string(chip) + std::string("-") + channel;
  std::string fname = hname + std::string(".vbias_scan.dat.tree.root");
  auto f = TFile::Open(fname.c_str());
  if (!f || !f->IsOpen()) return nullptr;
  auto t = (TTree *)f->Get("tree");
  if (!t) return nullptr;
  
  std::cout << "processing: " << fname << std::endl;

  // find threshold values
  TH1F hthr("hthr", "", 64, 0, 64);
  t->Project("hthr", "threshold");
  std::vector<int> thresholds;
  for (int i = 0; i < hthr.GetNbinsX(); ++i) {
    if (hthr.GetBinContent(i + 1) <= 0) continue;
    thresholds.push_back(hthr.GetBinLowEdge(i + 1));
  }
  if (thresholds.size() < ithr + 1) {
    std::cout << " --- not enough thresholds found: " << thresholds.size() << std::endl;
    return nullptr;
  }
      
  auto h = new TProfile(hname.c_str(), "", 1000, 0., 100.);      
  t->Project(hname.c_str(), "rate : bias_voltage", Form("threshold == %d", thresholds[ithr]));
  h->SetMarkerStyle(20);
  h->SetMarkerColor(kRed+1);
  h->SetLineColor(kRed+1);
  h->Draw("same");

  return h;
}

void
draw_map(float vmin, float vmax)
{

  auto cmap = new TCanvas("cmap", "cmap", 1600, 800);
  cmap->Divide(8, 4, 0., 0.);
  
  auto call = new TCanvas("call", "call", 800, 800);
  call->DrawFrame(vmin, 1.e-1, vmax, 1.e8);
  call->SetLogy();
  
  const char *row[8] = {"A", "B", "C", "D", "E", "F", "G", "H"};
  const char *col[4] = {"1", "2", "3", "4"};

  auto pA = new TProfile("pA", "", 1000, 0., 100.);
  pA->SetFillStyle(0);
  pA->SetMarkerStyle(20);
  pA->SetMarkerColor(kRed+1);
  pA->SetLineColor(kRed+1);
  pA->SetFillColor(kRed+1);
  pA->Draw("same");

  auto pB = new TProfile("pB", "", 1000, 0., 100.);
  pB->SetFillStyle(0);
  pB->SetMarkerStyle(25);
  pB->SetMarkerColor(kAzure-3);
  pB->SetLineColor(kAzure-3);
  pB->SetFillColor(kAzure-3);
  pB->Draw("same");
  
  auto pArms = new TProfile("pArms", "", 1000, 0., 100., "S");
  pArms->SetFillStyle(0);
  pArms->SetMarkerStyle(20);
  pArms->SetMarkerColor(kRed+1);
  pArms->SetLineColor(kRed+1);
  pArms->SetFillColor(kRed+1);
  pArms->Draw("same");

  auto pBrms = new TProfile("pBrms", "", 1000, 0., 100., "S");
  pBrms->SetFillStyle(0);
  pBrms->SetMarkerStyle(25);
  pBrms->SetMarkerColor(kAzure-3);
  pBrms->SetLineColor(kAzure-3);
  pBrms->SetFillColor(kAzure-3);
  pBrms->Draw("same");
  
  for (int irow = 0; irow < 8; ++irow) {
    for (int icol = 0; icol < 4; ++icol) {
      std::string fname = std::string(chipname) + row[irow] + col[icol] + std::string(".vbias_scan.dat.tree.root");
      auto f = TFile::Open(fname.c_str());
      if (!f || !f->IsOpen()) continue;
      auto t = (TTree *)f->Get("tree");
      if (!t) continue;

      std::cout << "processing: " << fname << std::endl;
      
      // find threshold values
      
      TH1F hthr("hthr", "", 64, 0, 64);
      t->Project("hthr", "threshold");
      std::vector<int> thresholds;
      for (int i = 0; i < hthr.GetNbinsX(); ++i) {
        if (hthr.GetBinContent(i + 1) <= 0) continue;
        thresholds.push_back(hthr.GetBinLowEdge(i + 1));
      }

      if (thresholds.size() == 0) {
	std::cout << " --- no thresholds found " << std::endl;
	continue;
      }
      
      // draw

      int iicol = irow;
      int iirow = 3 - icol;
      
      cmap->cd(1 + iicol + 8 * iirow)->DrawFrame(vmin, 1.e-1, vmax, 1.e8);
      cmap->cd(1 + iicol + 8 * iirow)->SetLogy();

      
      int color = irow % 2 == 0 ? kRed+1 : kAzure-3;
      int marker = irow % 2 == 0 ? 20 : 25;
      
      auto h0 = new TProfile(Form("h%s%s_0", row[irow], col[icol]), "", 1000, 0., 100.);      
      t->Project(Form("h%s%s_0", row[irow], col[icol]), "rate : bias_voltage", Form("threshold == %d", thresholds[0]));
      h0->SetMarkerStyle(marker);
      h0->SetMarkerColor(color);
      h0->SetLineColor(color);
      h0->Draw("same");

      call->cd();
      h0->Draw("same");

      // exclude

      if ( (irow == 0 && icol == 0) ||
	   (irow == 0 && icol == 1) ||
	   (irow == 5 && icol == 0) ||
	   (irow == 5 && icol == 1) 
	   ) continue;
      
      if (irow % 2 == 0) {
	pA->Add(h0);
	pArms->Add(h0);
      }
      else {
	pB->Add(h0);
	pBrms->Add(h0);
      }
      
#if 0
      
      auto h1 = new TProfile(Form("h%s%s_1", row[irow], col[icol]), "", 1000, 0., 100.);      
      t->Project(Form("h%s%s_1", row[irow], col[icol]), "rate : bias_voltage", Form("threshold == %d", thresholds[1]));
      h1->SetMarkerStyle(25);
      h1->SetMarkerColor(kRed+1);
      h1->SetLineColor(kRed+1);
      h1->Draw("same");

#endif
      
    }
  }
  
  auto cpro = new TCanvas("cpro", "cpro", 800, 800);
  cpro->DrawFrame(vmin, 1.e-1, vmax, 1.e8);
  cpro->SetLogy();
  pA->Draw("same");
  pArms->Draw("same,E5");
  pB->Draw("same");
  pBrms->Draw("same,E5");

  cmap->SaveAs("cmap.png");
  call->SaveAs("call.png");
  cpro->SaveAs("cpro.png");
    
}

void
draw_row(TCanvas *cvbias, TProfile *p, const char *row, int threshold, int marker, int color)
{
  for (auto col : {"1", "2", "3", "4"}) {
    std::string fname = std::string(chipname)
      + row + col +
      std::string(".vbias_scan.dat.tree.root");
    auto f = TFile::Open(fname.c_str());
    if (!f || !f->IsOpen()) continue;
    auto t = (TTree *)f->Get("tree");
    TCanvas c("c", "c", 800, 800);
    t->Draw("1 : threshold >> htemp(63, 0, 63)", "", "profile");
    auto h = (TH1*)gPad->FindObject("htemp");
    h->SetName("hthr");
    std::vector<int> thresholds;
    for (int i = 0; i < h->GetNbinsX(); ++i) {
      if (h->GetBinError(i + 1) <= 0) continue;
      thresholds.push_back(h->GetBinLowEdge(i + 1));
    }
    cvbias->cd();
    t->Draw("rate : bias_voltage >> htemp(1000, 0, 100)", Form("threshold == %d", thresholds[threshold]), "profile,same");
    h = (TH1*)gPad->FindObject("htemp");
    h->SetName(Form("htemp%s%s", row, col));
    h->SetMarkerStyle(marker);
    h->SetMarkerColor(color);
    h->SetLineColor(color);

    for (int i = 0; i < h->GetNbinsX(); ++i) {
      if (h->GetBinError(i + 1) <= 0.) continue;
      p->Fill(h->GetBinCenter(i + 1), h->GetBinContent(i + 1));
    }
    p->SetMarkerStyle(marker);
    p->SetMarkerColor(color);
    p->SetLineColor(color);
  }
  
}

void
draw()
{

  auto cvbias = new TCanvas("cvbias", "cvbias", 800, 800);
  cvbias->DrawFrame(0., 1.e-1, 70., 1.e8);

  auto pCHK_0 = new TProfile("pCHK_0", "", 1000, 0, 100, "S");
  auto pCHK_1 = new TProfile("pCHK_1", "", 1000, 0, 100, "S");
  auto pRH_0 = new TProfile("pRH_0", "", 1000, 0, 100, "S");
  auto pRH_1 = new TProfile("pRH_1", "", 1000, 0, 100, "S");

  for (auto row : {"A", "C", "E"})
    draw_row(cvbias, pCHK_0, row, 0, 25, kRed+1);
  for (auto row : {"B", "D", "F"}) {
    draw_row(cvbias, pRH_0, row, 0, 25, kAzure-3);
  }

  for (auto row : {"A", "C", "E"})
    draw_row(cvbias, pCHK_1, row, 1, 20, kRed+1);
  for (auto row : {"B", "D", "F"}) {
    draw_row(cvbias, pRH_1, row, 1, 20, kAzure-3);
  }

  auto cvbias_p = new TCanvas("cvbias_p", "cvbias_p", 800, 800);
  cvbias_p->DrawFrame(0., 1.e-1, 100., 1.e8);
  pCHK_0->Draw("same");
  pCHK_1->Draw("same");
  pRH_0->Draw("same");
  pRH_1->Draw("same");
  
}
