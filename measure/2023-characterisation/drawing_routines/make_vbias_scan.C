#pragma once

/** 
    this is a universal macro to create graphs
    from vbias scans and should work for both 
    LED and DCR scans
**/

#include "style.C"

bool make_dcr_ureadout = true;

const char *draw_what[4] = {
  "rate_on",
  "rate_off",
  "rate_on - rate_off",
  "rate" };
  
const char *draw_filt[4] = {
  "ratee_on",
  "ratee_off",
  "sqrt(ratee_on * ratee_on + ratee_off * ratee_off)",
  "ratee" };

float nsigma = 5.;

std::vector<int>
find_dacs(std::string thresholdfname)
{
  auto f = TFile::Open(thresholdfname.c_str());
  if (!f || !f->IsOpen()) return {};
  auto t = (TTree *)f->Get("tree");
  if (!t) return {};

  TH1F hdac("hdac", "", 4096, 0, 4096);
  t->Project("hdac", "bias_dac");
  std::vector<int> dacs;
  for (int i = 0; i < hdac.GetNbinsX(); ++i) {
    if (hdac.GetBinContent(i + 1) <= 0) continue;
    std::cout << "found dac: " << hdac.GetBinLowEdge(i + 1) << std::endl;
    dacs.push_back(hdac.GetBinLowEdge(i + 1));
  }

  f->Close();
  return dacs;
}

TGraphErrors *
graph_ratio(TGraphErrors *gn, TGraphErrors *gd)
{
  auto g = (TGraphErrors*)gn->Clone();
  g->Set(0);
  g->SetName(gn->GetName());
  for (int i = 0; i < gn->GetN(); ++i) {
    auto x = gn->GetX()[i];
    auto y = gn->GetY()[i];
    auto ex = gn->GetEX()[i];
    auto ey = gn->GetEY()[i];
    if (gn->Eval(x) == 0. || gd->Eval(x) == 0.) continue;
    y /= gd->Eval(x);
    ey /= gd->Eval(x);
    auto n = g->GetN();
    g->SetPoint(n, x, y);
    g->SetPointError(n, ex, ey);
    n++;
  }
  return g;
}

TGraphErrors *ureadout_dcr_get(const std::string filename, const std::string whatx, const std::string whaty = "dead_rate");

void make_csv(TGraphErrors *gin, std::string fout);

TGraphErrors *make_vbias_scan(std::string filename, int pulse_frequency, int pulse_voltage, int delta_threshold, int idraw, float breakdown_voltage);

TGraphErrors *make_threshold_scan(std::string filename, int pulse_frequency, int pulse_voltage, int bias_dac, int idraw, float *vbias);

TGraphErrors *
make_dcr_vbias_scan(std::string filename, int delta_threshold = 5, float breakdown_voltage = 0.)
{
  TGraphErrors *g = nullptr;
  if (make_dcr_ureadout)
    g = ureadout_dcr_get(filename, "bias_voltage", "dead_rate");
  else
    g = make_vbias_scan(filename, 0, 0, delta_threshold, 3, breakdown_voltage);
  make_csv(g, filename + ".delta_threshold=" + std::to_string(delta_threshold) + ".csv");
  return g;
}

TGraphErrors *
make_dcr_threshold_scan(std::string filename, int bias_dac, float *vbias = nullptr)
{
  TGraphErrors *g = nullptr;
  if (make_dcr_ureadout)
    g = ureadout_dcr_get(filename, "delta_threshold", "dead_rate");
  else
    g = make_threshold_scan(filename, 0, 0, bias_dac, 3, vbias);
  make_csv(g, filename + ".csv");
  return g;
}

void
make_csv(TGraphErrors *gin, std::string fout)
{
  if (!gin) return;
  std::ofstream ofs(fout.c_str(), std::ofstream::out);
  ofs << "# x y ex ey" << std::endl;
  for (int i = 0; i < gin->GetN(); ++i) {
    ofs << gin->GetX()[i] << ' '
        << gin->GetY()[i] << ' '
        << gin->GetEX()[i] << ' '
        << gin->GetEY()[i]
        << std::endl;
  }
  ofs.close();
}

TGraphErrors *
make_vbias_scan(std::string filename, int pulse_frequency, int pulse_voltage, int delta_threshold, int idraw, float breakdown_voltage = 0.)
{
  
  std::string cuts;
  if (idraw == 3)
    cuts = std::string("(threshold - base_threshold) == ") + std::to_string(delta_threshold);
  else
    cuts = std::string("(threshold_on - base_threshold) == ") + std::to_string(delta_threshold) +
      std::string("&& pulse_voltage == ") + std::to_string(pulse_voltage) +
      std::string(" && pulse_frequency == ") + std::to_string(pulse_frequency);
      
  auto g = new TGraphErrors;
  g->SetName(filename.c_str());
  auto grms = new TGraphErrors;
  auto f = TFile::Open(filename.c_str());
  if (!f || !f->IsOpen()) return nullptr;
  auto t = (TTree *)f->Get("tree");
  TH1F hdac("hdac", "hdac", 4096, 0., 4096);
  TH1F hvoltage("hvoltage", "", 10000, 0., 100.);
  TH1F hrate("hrate", "", 20000000, -10000000., 10000000.);
  TH1F hratee("hratee", "", 1000000, 0., 1000000.);
  t->Project("hdac", "bias_dac", cuts.c_str());
  for (int i = 0; i < hdac.GetNbinsX(); ++i) {
    if (hdac.GetBinContent(i + 1) == 0) continue;
    int dac = hdac.GetBinLowEdge(i + 1);
    std::string ccuts = cuts +
      std::string(" && bias_dac == ") +
      std::to_string(dac);
    // build filter for outliers
    t->Project("hratee", draw_filt[idraw], ccuts.c_str());
    t->Project("hrate", draw_what[idraw], ccuts.c_str());
    auto rate = hrate.GetMean();
    auto ratee = hratee.GetMean();
    std::string fcuts = ccuts +
      std::string(" && fabs(") +
      std::string(draw_what[idraw]) +
      std::string(" - ") +
      std::to_string(rate) +
      std::string(") < ") +
      std::to_string(nsigma) +
      std::string(" * ") +
      std::to_string(ratee);
    t->Project("hvoltage", "bias_voltage", fcuts.c_str());
    t->Project("hrate", draw_what[idraw], fcuts.c_str());

    if (hvoltage.GetEntries() <= 0.) continue;
    
    auto voltage = hvoltage.GetMean();
    auto mean = hrate.GetMean();
    auto meane = hrate.GetMeanError();
    auto rms = hrate.GetRMS();
    auto n = g->GetN();
    /*
    g->SetPoint(n, voltage, mean / (1.e3 * pulse_frequency));
    g->SetPointError(n, 0., meane / (1.e3 * pulse_frequency));
    grms->SetPoint(n, voltage, mean / (1.e3 * pulse_frequency));
    grms->SetPointError(n, 0., rms / (1.e3 * pulse_frequency));
    */
    g->SetPoint(n, voltage - breakdown_voltage, mean);
    g->SetPointError(n, 0., meane);
    grms->SetPoint(n, voltage - breakdown_voltage, mean);
    grms->SetPointError(n, 0., rms);
  }

  f->Close();
  return g;
}

TGraphErrors *
make_threshold_scan(std::string filename, int pulse_frequency, int pulse_voltage, int bias_dac, int idraw, float *vbias)
{

  auto dacs = find_dacs(filename);
  if (dacs.size() == 0) return nullptr;
  
  std::string cuts;
  if (idraw == 3)
    cuts = std::string("bias_dac == ") + std::to_string(dacs[bias_dac]);
  else
    cuts = std::string("bias_dac == ") + std::to_string(dacs[bias_dac]);
      std::string("&& pulse_voltage == ") + std::to_string(pulse_voltage) +
      std::string(" && pulse_frequency == ") + std::to_string(pulse_frequency);
      
  auto g = new TGraphErrors;
  g->SetName(filename.c_str());
  auto grms = new TGraphErrors;
  auto f = TFile::Open(filename.c_str());
  if (!f || !f->IsOpen()) return nullptr;
  auto t = (TTree *)f->Get("tree");
  TH1F hbasethr("hbasethr", "hbasethr", 94, 0., 94);
  TH1F hvoltage("hvoltage", "", 10000, 0., 100.);
  TH1F hthr("hthr", "hthr", 94, 0., 94);
  TH1F hrate("hrate", "", 20000000, -10000000., 10000000.);
  TH1F hratee("hratee", "", 1000000, 0., 1000000.);
  t->Project("hthr", "threshold", cuts.c_str());
  for (int i = 0; i < hthr.GetNbinsX(); ++i) {
    if (hthr.GetBinContent(i + 1) == 0) continue;
    int thr = hthr.GetBinLowEdge(i + 1);
    std::string ccuts = cuts +
      std::string(" && threshold == ") +
      std::to_string(thr);
    // build filter for outliers
    t->Project("hratee", draw_filt[idraw], ccuts.c_str());
    t->Project("hrate", draw_what[idraw], ccuts.c_str());
    auto rate = hrate.GetMean();
    auto ratee = hratee.GetMean();
    std::string fcuts = ccuts +
      std::string(" && fabs(") +
      std::string(draw_what[idraw]) +
      std::string(" - ") +
      std::to_string(rate) +
      std::string(") < ") +
      std::to_string(nsigma) +
      std::string(" * ") +
      std::to_string(ratee);
    t->Project("hvoltage", "bias_voltage", fcuts.c_str());
    t->Project("hbasethr", "base_threshold", fcuts.c_str());
    t->Project("hrate", draw_what[idraw], fcuts.c_str());

    if (hbasethr.GetEntries() <= 0.) continue;
    
    auto basethr = hbasethr.GetMean();
    auto mean = hrate.GetMean();
    auto meane = hrate.GetMeanError();
    auto rms = hrate.GetRMS();
    auto n = g->GetN();
    /*
    g->SetPoint(n, voltage, mean / (1.e3 * pulse_frequency));
    g->SetPointError(n, 0., meane / (1.e3 * pulse_frequency));
    grms->SetPoint(n, voltage, mean / (1.e3 * pulse_frequency));
    grms->SetPointError(n, 0., rms / (1.e3 * pulse_frequency));
    */
    //    g->SetPoint(n, thr - basethr, mean);
    g->SetPoint(n, thr, mean);
    g->SetPointError(n, 0., meane);
    //    grms->SetPoint(n, thr - basethr, mean);
    grms->SetPoint(n, thr, mean);
    grms->SetPointError(n, 0., rms);

    auto voltage = hvoltage.GetMean();
    //    std::cout << "voltage: " << voltage << std::endl;
    if (vbias) *vbias = voltage;

  }

  f->Close();
  return g;
}


TGraphErrors *
ureadout_dcr_get(const std::string filename, const std::string whatx, const std::string whaty)
{
  auto fin = TFile::Open(filename.c_str());
  if (!fin || !fin->IsOpen()) return nullptr;
  auto tin = (TTree *)fin->Get("ureadout_dcr_scan");
  std::cout << tin->GetEntries() << std::endl;

  
  
  int base_threshold, threshold, bias_dac;
  float bias_voltage, raw_rate, raw_ratee, dead_rate, dead_ratee, fit_rate, fit_ratee;
  tin->SetBranchAddress("bias_dac", &bias_dac);
  tin->SetBranchAddress("bias_voltage", &bias_voltage);
  tin->SetBranchAddress("base_threshold", &base_threshold);
  tin->SetBranchAddress("threshold", &threshold);
  tin->SetBranchAddress("raw_rate", &raw_rate);
  tin->SetBranchAddress("raw_ratee", &raw_ratee);
  tin->SetBranchAddress("dead_rate", &dead_rate);
  tin->SetBranchAddress("dead_ratee", &dead_ratee);
  tin->SetBranchAddress("fit_rate", &fit_rate);
  tin->SetBranchAddress("fit_ratee", &fit_ratee);

  auto g = new TGraphErrors;

  std::map<std::string, float> x, y, ey;
  
  for (int iev = 0; iev < tin->GetEntries(); ++iev) {
    tin->GetEntry(iev);

    x["bias_voltage"] = bias_voltage;
    x["threshold"] = threshold;
    x["delta_threshold"] = threshold - base_threshold;
    
    y["raw_rate"] = raw_rate;
    y["dead_rate"] = dead_rate;
    y["fit_rate"] = fit_rate;
    
    ey["raw_rate"] = raw_ratee;
    ey["dead_rate"] = dead_ratee;
    ey["fit_rate"] = fit_ratee;
    
    if (!x.count(whatx)) {
      std::cout << "unknown whatx: " << whatx << std::endl;
      continue;
    }

    if (!y.count(whaty) || !ey.count(whaty)) {
      std::cout << "unknown whaty: " << whaty << std::endl;
      continue;
    }
    g->SetPoint(iev, x[whatx], y[whaty]);
    g->SetPointError(iev, 0., ey[whaty]);
  }

  g->Sort();
  return g;
}


TCanvas *
draw_dcr_vbias_scan_map_4x2(std::string dirname, int chip, int delta_threshold = 5, int marker = 20, int color = kAzure-3, float vmin = 0., float vmax = 100., float breakdown_voltage = 0.)
{
  auto c = new TCanvas("c", "c", 1600, 800);
  c->Divide(4, 2);
  for (int irow = 0; irow < 2; ++irow) {
    for (int icol = 0; icol < 4; ++icol) {
      if (breakdown_voltage == 0.) c->cd(1 + icol + 4 * irow)->DrawFrame(vmin, 1.e-1, vmax, 1.e7, ";bias voltage (V);DCR (Hz)");
      else                         c->cd(1 + icol + 4 * irow)->DrawFrame(vmin, 1.e-1, vmax, 1.e7, ";over voltage (V);DCR (Hz)");
      c->cd(1 + icol + 4 * irow)->SetLogy();
    }
  }
  
  std::string rows[8] = { "A", "B", "C", "D", "E", "F", "G", "H" };
  std::string cols[4] = { "1", "2", "3", "4" };

  for (int irow = 0; irow < 8; ++irow) {
    for (int icol = 0; icol < 4; ++icol) {
      c->cd(1 + icol + 4 * (irow % 2))->cd();
      std::string filename = dirname + "/chip" + std::to_string(chip) + "-" + rows[irow] + cols[icol] + ".vbias_scan.dat.tree.root";
      if (make_dcr_ureadout)
        filename = dirname + "/chip" + std::to_string(chip) + "-" + rows[irow] + cols[icol] + ".ureadout_dcr_scan.tree.root";
      auto g = make_dcr_vbias_scan(filename, delta_threshold, breakdown_voltage);
      if (!g) continue;
      g->SetMarkerStyle(marker);
      g->SetMarkerColor(color);
      g->SetLineColor(color);
      g->Draw("samelp");
    }
  }
  
  return c;
}

TCanvas *
draw_dcr_vbias_scan(std::string dirname,
                    int chip,
                    std::vector<std::string> rows,
                    std::vector<std::string> cols,
                    std::vector<std::string> outliers,
                    int delta_threshold = 5,
                    TCanvas *c = nullptr,
                    int marker = 20,
                    int color = kAzure-3,
                    float vmin = 0.,
                    float vmax = 100,
                    float breakdown_voltage = 0.)
{

  if (!c) {
    c = new TCanvas("c", "c", 800, 800);
    c->DrawFrame(vmin, 1.e-1, vmax, 1.e7, ";bias voltage (V);DCR (Hz)");
    c->SetLogy();
  }
  
  for (auto row : rows) {
    for (auto col : cols) {
      std::string chname = row + col;
      if (std::find(outliers.begin(), outliers.end(), chname) != outliers.end()) continue;
      std::string filename = dirname + "/chip" + std::to_string(chip) + "-" + chname + ".vbias_scan.dat.tree.root";
      if (make_dcr_ureadout)
        filename = dirname + "/chip" + std::to_string(chip) + "-" + chname + ".ureadout_dcr_scan.tree.root";
      auto g = make_dcr_vbias_scan(filename, delta_threshold, breakdown_voltage);
      if (!g) continue;
      g->SetMarkerStyle(marker);
      g->SetMarkerColor(color);
      g->SetLineColor(color);
      g->Draw("samelp");
    }
  }
  
  return c;
}

TCanvas *
draw_dcr_vbias_scan_threshold_ratio(std::string dirname,
                                    int chip,
                                    std::vector<std::string> rows,
                                    std::vector<std::string> cols,
                                    std::vector<std::string> outliers,
                                    TCanvas *c = nullptr,
                                    int marker = 20,
                                    int color = kAzure-3,
                                    float vmin = 0.,
                                    float vmax = 100,
                                    float breakdown_voltage = 0.)
{

  if (!c) {
    c = new TCanvas("c", "c", 800, 800);
    c->DrawFrame(vmin, 0., vmax, 1.5, ";bias voltage (V);DCR threshold ratio");
  }
  
  for (auto row : rows) {
    for (auto col : cols) {
      std::string chname = row + col;
      if (std::find(outliers.begin(), outliers.end(), chname) != outliers.end()) continue;
      std::string filename = dirname + "/chip" + std::to_string(chip) + "-" + chname + ".vbias_scan.dat.tree.root";
      if (make_dcr_ureadout)
        filename = dirname + "/chip" + std::to_string(chip) + "-" + chname + ".ureadout_dcr_scan.tree.root";
      auto g3 = make_dcr_vbias_scan(filename, 3, breakdown_voltage);
      if (!g3) continue;
      auto g5 = make_dcr_vbias_scan(filename, 5, breakdown_voltage);
      if (!g5) continue;
      auto g = graph_ratio(g5, g3);
      g->SetMarkerStyle(marker);
      g->SetMarkerColor(color);
      g->SetLineColor(color);
      g->Draw("samelp");
    }
  }
  
  return c;
}

TCanvas *
make_average_rms(TCanvas *c)
{
  TProfile p("p", "", 20000, -100., 100.);
  TProfile pS("pS", "", 20000, -100., 100., "S");
  double themin[20000], themax[20000];
  for (int i = 0; i < 20000; ++i) themin[i] = themax[i] = -999.;
  auto l = c->GetListOfPrimitives();
  for (int i = 0; i < l->GetEntries(); ++i) {
    if (l->At(i)->IsA() != TGraphErrors::Class()) continue;
    auto g = (TGraphErrors *)l->At(i);
    for (int j = 0; j < g->GetN(); ++j) {
      auto x = g->GetX()[j];
      auto y = g->GetY()[j];
      int ibin = p.Fill(x, y);
      pS.Fill(x, y);

      if (themin[ibin - 1] == -999.) themin[ibin - 1] = y;
      if (themax[ibin - 1] == -999.) themax[ibin - 1] = y;
      if (y < themin[ibin - 1]) themin[ibin - 1] = y;
      if (y > themax[ibin - 1]) themax[ibin - 1] = y;
    }
  }

  // clone canvas and remove graphs
  auto cc = (TCanvas *)c->DrawClone();
  cc->SetName("cc");
  l = cc->GetListOfPrimitives();
  std::vector<TObject *> toberemoved;
  for (int i = 0; i < l->GetEntries(); ++i) {
    if (l->At(i)->IsA() != TGraphErrors::Class()) continue;
    auto obj = l->At(i);
    toberemoved.push_back(obj);
  }
  for (auto obj : toberemoved)
    l->Remove(obj);
  cc->Modified();
  
  TGraphErrors *gave = new TGraphErrors;
  gave->SetName("gave");
  gave->SetMarkerStyle(20);
  gave->SetMarkerColor(kRed+1);
  gave->SetLineColor(kRed+1);
  gave->SetFillColor(kRed+1);
  gave->SetFillStyle(0);
  TGraphErrors *grms = new TGraphErrors;
  grms->SetName("grms");
  grms->SetMarkerStyle(20);
  grms->SetMarkerColor(kRed+1);
  grms->SetLineColor(kRed+1);
  grms->SetFillColor(kRed+1);
  grms->SetFillStyle(3002);
  TGraphErrors *gwidth = new TGraphErrors;
  gwidth->SetName("gwidth");
  gwidth->SetMarkerStyle(20);
  gwidth->SetMarkerColor(kRed+1);
  gwidth->SetLineColor(kRed+1);
  gwidth->SetFillColor(kRed+1);
  gwidth->SetFillStyle(0);
  for (int i = 0; i < p.GetNbinsX(); ++i) {
    if (p.GetBinError(i + 1) <= 0) continue;
    auto n = gave->GetN();
    gave->SetPoint(n, p.GetBinLowEdge(i + 1), p.GetBinContent(i + 1));
    gave->SetPointError(n, 0., p.GetBinError(i + 1));
    grms->SetPoint(n, p.GetBinLowEdge(i + 1), p.GetBinContent(i + 1));
    grms->SetPointError(n, 0., pS.GetBinError(i + 1));
    gwidth->SetPoint(n, p.GetBinLowEdge(i + 1), 0.5 * (themax[i] + themin[i]));
    gwidth->SetPointError(n, 0., 0.5 * (themax[i] - themin[i]));
  }
  gave->Draw("samep");
  gwidth->Draw("samee3");
  grms->Draw("samee3");

  return cc;
}

#if 0

std::vector<std::string> ref_files = {
  "test-run-2/chip1-A1-20220509-103554/rate/vbias_scan/chip1-A1.vbias_scan.dat.tree.root", 
  "test-run-2/chip1-A1-20220510-003507/rate/vbias_scan/chip1-A1.vbias_scan.dat.tree.root", 
  "test-run-2/chip1-A1-20220510-165736/rate/vbias_scan/chip1-A1.vbias_scan.dat.tree.root", 
  "test-run-2/chip1-A1-20220511-092544/rate/vbias_scan/chip1-A1.vbias_scan.dat.tree.root", 
  "test-run-2/chip1-A1-20220512-020406/rate/vbias_scan/chip1-A1.vbias_scan.dat.tree.root"
};

std::vector<std::string> C_files = {
  "test-run-2/chip0-C1-20220509-112649/rate/vbias_scan/chip0-C1.vbias_scan.dat.tree.root",
  "test-run-2/chip0-C2-20220509-144248/rate/vbias_scan/chip0-C2.vbias_scan.dat.tree.root",
  "test-run-2/chip0-C3-20220509-180028/rate/vbias_scan/chip0-C3.vbias_scan.dat.tree.root",
  "test-run-2/chip0-C4-20220509-211741/rate/vbias_scan/chip0-C4.vbias_scan.dat.tree.root",
  "test-run-2/chip0-E1-20220510-035211/rate/vbias_scan/chip0-E1.vbias_scan.dat.tree.root",
  "test-run-2/chip0-E2-20220510-070816/rate/vbias_scan/chip0-E2.vbias_scan.dat.tree.root",
  "test-run-2/chip0-E3-20220510-102400/rate/vbias_scan/chip0-E3.vbias_scan.dat.tree.root",
  "test-run-2/chip0-E4-20220510-134111/rate/vbias_scan/chip0-E4.vbias_scan.dat.tree.root",
  "test-run-2/chip0-G1-20220510-201511/rate/vbias_scan/chip0-G1.vbias_scan.dat.tree.root",
  "test-run-2/chip0-G2-20220510-233301/rate/vbias_scan/chip0-G2.vbias_scan.dat.tree.root",
  "test-run-2/chip0-G3-20220511-025018/rate/vbias_scan/chip0-G3.vbias_scan.dat.tree.root",
  "test-run-2/chip0-G4-20220511-060736/rate/vbias_scan/chip0-G4.vbias_scan.dat.tree.root"
};

std::vector<std::string> D_files = {
  "test-run-2/chip0-D1-20220511-124438/rate/vbias_scan/chip0-D1.vbias_scan.dat.tree.root", 
  "test-run-2/chip0-D2-20220511-160426/rate/vbias_scan/chip0-D2.vbias_scan.dat.tree.root", 
  "test-run-2/chip0-D3-20220511-192350/rate/vbias_scan/chip0-D3.vbias_scan.dat.tree.root", 
  "test-run-2/chip0-D4-20220511-224337/rate/vbias_scan/chip0-D4.vbias_scan.dat.tree.root", 
  "test-run-2/chip0-F1-20220512-052334/rate/vbias_scan/chip0-F1.vbias_scan.dat.tree.root", 
  "test-run-2/chip0-F2-20220512-084222/rate/vbias_scan/chip0-F2.vbias_scan.dat.tree.root", 
  "test-run-2/chip0-F3-20220512-204046/rate/vbias_scan/chip0-F3.vbias_scan.dat.tree.root", 
  "test-run-2/chip0-F4-20220513-000126/rate/vbias_scan/chip0-F4.vbias_scan.dat.tree.root"
};


TGraphErrors *
draw(std::vector<std::string> files,
     int pulse_frequency = 100,
     int pulse_voltage = 1000,
     int delta_threshold = 5,
     bool return_rms = false)
  
{
  auto c = new TCanvas("c", "c", 1600, 800);
  c->Divide(2, 1);
  c->cd(1)->SetLogy();
  c->cd(1)->DrawFrame(48., 1., 58., 1.e4);
  std::vector<TGraphErrors *> gs;  
  TProfile p("p", "", 10000, 0., 100.);
  TProfile pS("pS", "", 10000, 0., 100., "S");
  
  for (auto file : files) {
    auto g = make_vbias_scan(file, pulse_frequency, pulse_voltage, delta_threshold, 0);
    g->SetMarkerStyle(20);
    g->Draw("samep");
    gs.push_back(g);

    for (int i = 0; i < g->GetN(); ++i) {
      auto x = g->GetX()[i];
      auto y = g->GetY()[i];
      p.Fill(x, y);
      pS.Fill(x, y);
    }
  }
  
  // make average graph
  TGraphErrors *gave = new TGraphErrors;
  TGraphErrors *grms = new TGraphErrors;
  for (int i = 0; i < p.GetNbinsX(); ++i) {
    if (p.GetBinError(i + 1) <= 0) continue;
    auto n = gave->GetN();
    gave->SetPoint(n, p.GetBinLowEdge(i + 1), p.GetBinContent(i + 1));
    gave->SetPointError(n, 0., p.GetBinError(i + 1));
    grms->SetPoint(n, p.GetBinLowEdge(i + 1), p.GetBinContent(i + 1));
    grms->SetPointError(n, 0., pS.GetBinError(i + 1));
  }
  gave->SetFillStyle(0);
  gave->SetFillColor(kRed+1);
  gave->SetMarkerStyle(25);
  gave->SetMarkerColor(kRed+1);
  gave->SetLineColor(kRed+1);
  gave->Draw("samep,e1");
  grms->SetFillStyle(0);
  grms->SetFillColor(kRed+1);
  grms->SetMarkerStyle(25);
  grms->SetMarkerColor(kRed+1);
  grms->SetLineColor(kRed+1);
  grms->Draw("same,e3");

  // ratio to average

  c->cd(2)->DrawFrame(48., 0.5, 58., 1.5);
  for (auto g : gs) {
    auto gr = new TGraphErrors;
    gr->SetMarkerStyle(20);
    for (int i = 0; i < g->GetN(); ++i) {
      gr->SetPoint(i, g->GetX()[i], g->GetY()[i] / gave->GetY()[i]);
      gr->SetPointError(i, 0., g->GetEY()[i] / gave->GetY()[i]);
    }
    gr->Draw("samep");
  }
  auto gr = new TGraphErrors;
  for (int i = 0; i < grms->GetN(); ++i) {
    gr->SetPoint(i, grms->GetX()[i], grms->GetY()[i] / gave->GetY()[i]);
    gr->SetPointError(i, 0., grms->GetEY()[i] / gave->GetY()[i]);
  }
  gr->SetFillStyle(0);
  gr->SetFillColor(kRed+1);
  gr->SetMarkerStyle(25);
  gr->SetMarkerColor(kRed+1);
  gr->SetLineColor(kRed+1);
  gr->Draw("same,e3");

  return return_rms ? grms : gave;
}


#endif
