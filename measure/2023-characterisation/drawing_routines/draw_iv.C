#include "/home/eic/alcor/sipm4eic/characterisation/macros/makeiv.C"

std::map< std::string, std::pair<float, float> > vrange = { {"HAMA1_sn2_243K", {44., 64.}}, {"HAMA1_sn0_243K", {44., 64.}}, {"HAMA2_sn2_243K", {32., 52.}}, {"BCOM_sn1_243K", {20., 40.}}, {"SENSL_sn1_243K", {20., 40.}}, {"FBK_sn1_243K", {26., 46.}}, {"FBK_sn2_243K", {26., 46.}}, {"HAMA2_sn0_243K", {32., 52.}}, {"HAMA3_sn0_243K", {32., 64.}} };

void
draw_iv(std::string dirname, std::string tagname, float vmin = -1., float vmax = -1.)
{

  vmin = vmin < 0. ? vrange[tagname].first : vmin;
  vmax = vmax < 0. ? vrange[tagname].second : vmax;
  
  auto cmap = new TCanvas("cmap", "cmap", 1600, 800);
  cmap->Divide(8, 4, 0., 0.);

  auto call = new TCanvas("call", "call", 800, 800);
  call->DrawFrame(vmin, 1.e-11, vmax, 1.e-3);
  call->SetLogy();
  call->SetGridx();
  call->SetGridy();
  
  std::vector<std::string> rows = {"A", "B", "C", "D", "E", "F", "G", "H"};
  std::vector<std::string> cols = {"1", "2", "3", "4"};


  // OPEN
  auto name = dirname + "/" + tagname + "_OPEN.ivscan.csv";
  auto gopen = makeiv(name.c_str(), "");
  gopen->SetName(name.c_str());
  gopen->SetMarkerStyle(21);
  gopen->SetMarkerColor(kBlack);
  gopen->SetLineColor(kBlack);
  gopen->SetMarkerSize(0.5);
  call->cd();
  gopen->Draw("samelp");

  // channels
  for (int irow = 0; irow < 8; ++irow) { 
    for (int icol = 0; icol < 4; ++icol) {

      int iicol = irow;
      int iirow = 3 - icol;
      
      int color = irow % 2 == 0 ? kRed+1 : kAzure-3;
      int marker = irow % 2 == 0 ? 20 : 25;
      
      auto name = dirname + "/" + tagname + "_" + rows[irow] + cols[icol] + ".ivscan.csv";
      auto g = makeiv(name.c_str(), "");
      g->SetName(name.c_str());
      g->SetMarkerStyle(marker);
      g->SetMarkerColor(color);
      g->SetLineColor(color);
      g->SetMarkerSize(0.5);

      // OPEN
      name = dirname + "/" + tagname + "_OPEN-" + rows[irow] + cols[icol] + ".ivscan.csv";
      auto gopen = makeiv(name.c_str(), "");
      gopen->SetName(name.c_str());
      gopen->SetMarkerStyle(21);
      gopen->SetMarkerColor(kBlack);
      gopen->SetLineColor(kBlack);
      gopen->SetMarkerSize(0.5);
      
      cmap->cd(1 + iicol + 8 * iirow)->DrawFrame(vmin, 1.e-11, vmax, 1.e-3);
      cmap->cd(1 + iicol + 8 * iirow)->SetLogy();
      g->Draw("samelp");
      gopen->Draw("samelp");
      
      call->cd();
      g->Draw("samelp");
      
    }
  }

  cmap->SaveAs("ivmap.png");
  call->SaveAs("ivall.png");

}
