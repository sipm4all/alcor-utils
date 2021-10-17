#include "style.C"

int col[4] = {kRed+1, kGreen+2, kAzure-3, kYellow+2};
int sty[4] = {kSolid, kSolid, kDashed, kDashed};

void draw(const char *dirname, const char *tagname, int chip, int channel, int vth, int range, int offset, int color, int width, int style, const char *title, const char *opt = "l,same") {  
  TTree t;
  t.ReadFile(Form("%s/%s.scanthr.lanechannel_%d.vth_%d.range_%d.offset_%d.txt", dirname, tagname, channel % 8, vth, range, offset));
  t.Draw("rate : threshold", Form("chip == %d && channel == %d", chip, channel), opt);
  
  auto g = (TGraph*)gPad->GetListOfPrimitives()->Last();
  g->SetTitle(title);
  g->SetLineWidth(width);
  g->SetLineColor(color);
  g->SetLineStyle(style);
  g->SetMarkerColor(color);
  g->SetMarkerStyle(20);
  g->SetMarkerSize(0.6);
  g->SetFillStyle(0);
  g->SetFillColor(0);
  
}

void
draw_lanechannel(const char *dirname, int chip, int channel, std::vector<std::string> tags, bool finalise = false)
{
  style();

  int lanechannel = channel % 8;
  
  gStyle->SetOptTitle(false);

  if (!finalise) {
  
  auto c = new TCanvas("c", "c", 1600, 800);
  c->Divide(8, 4, 0., 0.);
  
  // loop over offset/range values
  for (int offset = 0; offset < 8; ++offset) {
    for (int range = 0; range < 4; ++range) {      
      int icanvas = range * 8 + offset + 1;
      c->cd(icanvas);
      auto hframe = c->cd(icanvas)->DrawFrame(0., 2.e-1, 63., 5.e6, ";threshold;rate (Hz)");
      hframe->GetXaxis()->SetNdivisions(507);
      hframe->SetTitle(Form("offset=%d", offset));
      c->cd(icanvas)->SetLogy();
      c->cd(icanvas)->SetGridx();
      c->cd(icanvas)->SetGridy();

      // loop over tags
      for (int tag = 0; tag < tags.size(); ++tag) {

        if (tags[tag].empty()) continue;
        
        // loop over vth values
        for (int vth = 0; vth < 4; ++vth) {
          draw(dirname, tags[tag].c_str(), chip, channel, vth, range, offset, col[vth], 3, sty[tag], Form("vth=%d", vth));
        }
        // draw legend
        if (tag == 0 && icanvas == 8) {
          auto legend = c->cd(icanvas)->BuildLegend(0.1, 0.1, 0.9, 0.9);
          legend->DeleteEntry();
        }
        

      }

    }}
  
  c->SaveAs(Form("%s/scanthr.chip_%d.channel_%d.png", dirname, chip, channel));

  } else {
  
  auto c1 = new TCanvas("c1", "c1", 800, 800);
  auto hframe = c1->cd()->DrawFrame(0., 2.e-1, 63., 5.e6, ";threshold;rate (Hz)");
  hframe->GetXaxis()->SetNdivisions(507);
  c1->cd()->SetLogy();
  c1->cd()->SetGridx();
  c1->cd()->SetGridy();
  
  // loop over tags
  for (int tag = 0; tag < tags.size(); ++tag) {
    if (tags[tag].empty()) continue;
    draw(dirname, tags[tag].c_str(), chip, channel, -1, -1, -1, col[tag], 3, kSolid, "");
  }
  
  c1->SaveAs(Form("%s/scanthr.finalise.chip_%d.channel_%d.png", dirname, chip, channel));

  }
}
