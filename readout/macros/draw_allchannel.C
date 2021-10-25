#include "style.C"

bool kUSE_DO = false;

int eo2do[32] = {22, 20, 18, 16, 24, 26, 28, 30, 25, 27, 29, 31, 23, 21, 19, 17, 9, 11, 13, 15, 7, 5, 3, 1, 6, 4, 2, 0, 8, 10, 12, 14};

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
draw_allchannel(const char *dirname, int chip, std::vector<std::string> tags)
{
  style();

  gStyle->SetOptTitle(false);

  TCanvas* c = nullptr;
  if ( kUSE_DO ) {
    c = new TCanvas("c", "c", 400, 800);
    c->Divide(4, 8, 0., 0.);
  } else {
    c = new TCanvas("c", "c", 1600, 800);
    c->Divide(8, 4, 0., 0.);
  }

  // loop over channels
  for (int channel = 0; channel < 32; ++channel) {
      int icanvas = channel + 1;
      if ( kUSE_DO ) icanvas = eo2do[channel]+1;
      c->cd(icanvas);
      auto hframe = c->cd(icanvas)->DrawFrame(0., 2.e-1, 63., 5.e6, ";threshold;rate (Hz)");
      hframe->GetXaxis()->SetNdivisions(507);
      c->cd(icanvas)->SetLogy();
      c->cd(icanvas)->SetGridx();
      c->cd(icanvas)->SetGridy();

      // loop over tags
      for (int tag = 0; tag < tags.size(); ++tag) {
        
        if (tags[tag].empty()) continue;
        
        // loop over vth values
        for (int vth = 0; vth < 4; ++vth) {
          draw(dirname, tags[tag].c_str(), chip, channel, -1, -1, -1, col[tag], 3, kSolid, Form("vth=%d", vth));
        }
        
      }
  }

  c->SaveAs(Form("%s/scanthr.chip_%d.png", dirname, chip));

}
