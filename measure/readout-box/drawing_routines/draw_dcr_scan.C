#include "/home/eic/alcor/alcor-utils/measure/readout-box/drawing_routines/drawing_routines.C"

void draw_map(std::string dirname, int chip, float vmin = 22., float vmax = 34.);

void
draw_dcr_scan(std::string dirname, int chip, float vmin, float vmax)
{
  
  draw_map(std::string(dirname) + "/rate/vbias_scan", chip, vmin, vmax);

  auto cthr0 = drawing_routines::dcr_threshold_scan_map_8x4(dirname, std::to_string(chip), 0, 0, 0);
  cthr0->SaveAs("cthr0.png");
  auto cthr1 = drawing_routines::dcr_threshold_scan_map_8x4(dirname, std::to_string(chip), 1, 0, 0);
  cthr1->SaveAs("cthr1.png");

  auto cbias3 = drawing_routines::dcr_vbias_scan_map_8x4(dirname, std::to_string(chip), 3, 0, 0, vmin, vmax);
  cbias3->SaveAs("cbias3.png");
  auto cbias5 = drawing_routines::dcr_vbias_scan_map_8x4(dirname, std::to_string(chip), 5, 0, 0, vmin, vmax);
  cbias5->SaveAs("cbias5.png");
}

void
draw_map(std::string dirname, int chip, float vmin, float vmax)
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
      std::string fname = std::string(dirname) + std::string("/") + std::string("chip") + std::to_string(chip) + std::string("-") + row[irow] + col[icol] + std::string(".vbias_scan.dat.tree.root");
      auto f = TFile::Open(fname.c_str());
      if (!f || !f->IsOpen()) continue;
      auto t = (TTree *)f->Get("tree");
      if (!t) continue;

      std::cout << "processing: " << fname << std::endl;
      
      // draw

      int iicol = irow;
      int iirow = 3 - icol;
      
      cmap->cd(1 + iicol + 8 * iirow)->DrawFrame(vmin, 1.e-1, vmax, 1.e8);
      cmap->cd(1 + iicol + 8 * iirow)->SetLogy();

      
      int color = irow % 2 == 0 ? kRed+1 : kAzure-3;
      int marker = irow % 2 == 0 ? 20 : 25;
      
      auto h0 = new TProfile(Form("h%s%s_0", row[irow], col[icol]), "", 1000, 0., 100.);      
      t->Project(Form("h%s%s_0", row[irow], col[icol]), "rate : bias_voltage", "threshold - base_threshold == 5");
      h0->SetMarkerStyle(marker);
      h0->SetMarkerColor(color);
      h0->SetLineColor(color);
      h0->Draw("same");

      call->cd();
      h0->Draw("same");

      if (irow % 2 == 0) {
	pA->Add(h0);
	pArms->Add(h0);
      }
      else {
	pB->Add(h0);
	pBrms->Add(h0);
      }
      
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
