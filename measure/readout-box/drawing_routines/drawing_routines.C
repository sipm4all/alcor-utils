#pragma once
#include "style.C"
#include "graphutils.C"
#include "definitions.h"
#include "make_iv_scan.C"
#include "make_vbias_scan.C"

namespace defs = definitions;

namespace drawing_routines {

std::string rows[8] = { "A", "B", "C", "D", "E", "F", "G", "H" };
std::string cols[4] = { "1", "2", "3", "4" };

float dcr_min = 2.e-1;
float dcr_max = 5.e7;

float iv_min = 2.e-13;
float iv_max = 5.e-3;

float ratio_min = 2.e-2;
float ratio_max = 5.e3;

float invratio_min = 2.e-1;
float invratio_max = 5.e3;

float led_min = 1.e-3;
float led_max = 1.e-1;
  
float gain_min = 2.e4;
float gain_max = 5.e8;

bool subtract_open_current = false;
bool threshold_derivate = false;
  
bool draw_average_rms = true;
  
void
draw_label_bottom_right(std::string label)
{
  TLatex latex;
  latex.SetNDC();
  latex.SetTextAlign(31);
  latex.SetTextSize(0.045);
  latex.DrawLatex(0.9, 0.2, label.c_str());
}
  
void
draw_label_top_right(std::string label)
{
  TLatex latex;
  latex.SetNDC();
  latex.SetTextAlign(31);
  latex.SetTextSize(0.045);
  latex.DrawLatex(0.9, 0.875, label.c_str());
}
  
void
draw_label_top_left(std::string label)
{
  TLatex latex;
  latex.SetNDC();
  latex.SetTextAlign(11);
  latex.SetTextSize(0.045);
  latex.DrawLatex(0.2, 0.875, label.c_str());
}
  
void
draw_label(std::string label)
{
  draw_label_bottom_right(label);
}
  
void
set_style(TGraphErrors *g, int marker, int color, int fill = 0)
{
  if (!g) return;
  g->SetMarkerStyle(marker);
  g->SetMarkerColor(color);
  g->SetLineColor(color);
  g->SetFillColor(color);
  g->SetFillStyle(fill);
}
  
void
set_style(TH1 *h, int marker, int color, int fill = 0)
{
  if (!h) return;
  h->SetMarkerStyle(marker);
  h->SetMarkerColor(color);
  h->SetLineColor(color);
  h->SetFillColor(color);
  h->SetFillStyle(fill);
}
  
int
get_pad_map_8x4(int irow, int icol)
{
  auto ipad = (3 - icol) * 8 + irow;
  return ipad;
}
  
TCanvas *
prepare_map_8x4(float xmin, float ymin, float xmax, float ymax, const char* title, bool logy)
{
  auto c = new TCanvas("c", "c", 1600, 800);
  c->Divide(8, 4, 0., 0.);
  for (int irow = 0; irow < 8; ++irow) {
    for (int icol = 0; icol < 4; ++icol) {
      auto ipad = get_pad_map_8x4(irow, icol);
      c->cd(1 + ipad)->DrawFrame(xmin, ymin, xmax, ymax, title);
      if (logy) c->cd(1 + ipad)->SetLogy();
      c->cd(1 + ipad)->SetGridx();
    }
  }
  return c;
}

/******************************************************************************/
  
TGraphErrors *
get_iv_scan_2021(std::string dirname, std::string tagname, std::string chname, int marker = 20, int color = kAzure-3)
{
  std::string filename = dirname + "/" + tagname + "_243K_" + chname + "/" + tagname + "_243K_" + chname + ".ivscan.csv";
  std::string filenameZERO = dirname + "/" + tagname + "_243K_" + chname + "/" + tagname + "_243K_" + chname + ".zero.csv";
  return make_iv_scan(filename, "", filenameZERO);
}

TGraphErrors *
get_iv_scan_FERRARA(std::string dirname, std::string tagname, std::string chname, int marker = 20, int color = kAzure-3)
{
  std::string finaltag;
  if (dirname.find("MC0") != std::string::npos) {
    finaltag = "_-30C.csv";
  } else if (dirname.find("MC1") != std::string::npos) {
    finaltag = "_-30C_MC1.csv";
  } else if (dirname.find("MC7") != std::string::npos) {
    finaltag = "_-30C_MC7.csv";
  }


  std::string filename = dirname + "/" + chname + "/" + tagname + "_" + chname + finaltag;
  auto g = new TGraphErrors(filename.c_str());
  return g;
}

TGraphErrors *
get_iv_scan(std::string dirname, std::string tagname, std::string chname, int marker = 20, int color = kAzure-3, float vbreak = 0.)
{
  TGraphErrors *g = nullptr;
  if (dirname.find("sipm4eic/characterisation/data/FERRARA") != std::string::npos) {
    g = get_iv_scan_FERRARA(dirname, tagname, chname, marker, color);
  } else if (dirname.find("sipm4eic/characterisation/data") != std::string::npos) {
    g = get_iv_scan_2021(dirname, tagname, chname, marker, color);
  } else {
    std::string filename = dirname + "/" + tagname + "_243K_" + chname + ".ivscan.csv";
    std::string filenameOPEN = dirname + "/" + tagname + "_243K_OPEN-" + chname + ".ivscan.csv";
    g = make_iv_scan(filename, filenameOPEN);
  }
  set_style(g, marker, color);

  // subtract open current
  if (subtract_open_current) {
    auto fSURF = iv_fit(g, vbreak);
    fSURF->SetParameter(3, 100.);
    fSURF->SetRange(0., 100.);
    for (int i = 0; i < g->GetN(); ++i) {
      double surfcurr = fSURF->Eval(g->GetX()[i]);
      g->GetY()[i] -= surfcurr;
    }
  }
  
  return g;
}

TGraphErrors *
get_dcr_vbias_scan(std::string dirname, std::string chip, std::string chname, int delta_threshold = 5, int marker = 20, int color = kAzure-3)
{
  std::string filename = dirname + "/rate/vbias_scan/chip" + chip + "-" + chname + ".vbias_scan.dat.tree.root";
  auto g = make_dcr_vbias_scan(filename, delta_threshold);
  set_style(g, marker, color);
  return g;
}
  
TGraphErrors *
get_dcr_threshold_scan(std::string dirname, std::string chip, std::string chname, int bias_dac = 1, int marker = 20, int color = kAzure-3, float *vbias = nullptr)
{
  std::string filename = dirname + "/rate/threshold_scan/chip" + chip + "-" + chname + ".threshold_scan.dat.tree.root";
  auto g = make_dcr_threshold_scan(filename, bias_dac, vbias);
  set_style(g, marker, color);
  if (threshold_derivate) g = graphutils::derivate(g);
  return g;
}
  
/******************************************************************************/

float
get_led_vbias(int dac, std::string board)
{
  std::map<std::string, float> res = {
    { "HAMA1" , 54.9 } ,
    { "HAMA2" , 73.2 }
  };
  
  /*
    dac = 1000. * vbias / ( (1000. / res ) + 1. )
    (dac / 1000.) * ((1000. / res) + 1) = vbias 
  */

  float vbias = (float)dac / 1000. * ( 1000. / res[board] + 1.);
  vbias = std::round(vbias * 10.) / 10.;

  return vbias;
}
  
std::vector<std::string>
get_led_dirs(std::string board, std::string status, std::string chname, int pulse_frequency = 1000, int pulse_voltage = 1000, int delta_threshold = 5)
{
  auto dirname = defs::dirname_led[board][status];
  TSystemDirectory dir(dirname.c_str(), dirname.c_str());
  auto li = dir.GetListOfFiles();
  TString fname;
  std::vector<std::string> outlist;
  for (int i = 0; i < li->GetEntries(); ++i) {
    auto file = (TSystemFile *)li->At(i);
    fname = file->GetName();
    if (!file->IsDirectory()) continue;
    if (!fname.BeginsWith("chip")) continue;
    if (!fname.Contains(chname)) continue;
    outlist.push_back(dirname + "/" + fname.Data() +
                      "/ureadout/vbias_scan" +
                      "/pulse_frequency_" + std::to_string(pulse_frequency) +
                      "/pulse_voltage_" + std::to_string(pulse_voltage) +
                      "/delta_threshold_" + std::to_string(delta_threshold) );
  }
  return outlist;
}

std::vector<std::pair<float, float>>
count_led_coincidences(std::string filename)
{

  auto fin = TFile::Open(filename.c_str());
  if (!fin || !fin->IsOpen()) return { {0., 0.} , {0. , 0.} };
  auto h = (TH1 *)fin->Get("hCounts");
  if (!h) return { {0., 0.} , {0. , 0.} };
  auto ntrg = h->GetBinContent(1);
  auto sigmin = h->GetBinContent(2);
  auto sigmax = h->GetBinContent(3);
  auto nsig = h->GetBinContent(4);
  auto nsige = std::sqrt(nsig);
  auto bkgmin = h->GetBinContent(5);
  auto bkgmax = h->GetBinContent(6);
  auto nbkg = h->GetBinContent(7);
  auto nbkge = std::sqrt(nbkg);

  // scale background by signal window
  auto scale = (sigmax - sigmin) / (bkgmax - bkgmin);
  nbkg *= scale;
  nbkge *= scale;
  
  // calculate trigger-normalised coincidences
  auto ncoin = nsig - nbkg;
  auto ncoine = std::sqrt(nsige * nsige + nbkge * nbkge);
  ncoin /= ntrg;
  ncoine /= ntrg;

  // calculate DCR
  auto bkgwin = (bkgmax - bkgmin) * 3.125e-09 * ntrg;
  nbkg  /= bkgwin;
  nbkge /= bkgwin;
  
  fin->Close();
  return { {ncoin, ncoine} , {nbkg, nbkge} };
}
  
TGraphErrors *
make_led_graph(std::string dir, std::string board)
{
  auto g = new TGraphErrors;
  g->SetName(dir.c_str());
  for (auto dac : defs::dacs_led[board]) {
    auto filename = dir + "/bias_dac_" + std::to_string(dac) + "/coincidence.count.root";
    auto data = count_led_coincidences(filename.c_str());
    if (data[0] == std::pair<float,float>({0., 0.})) continue;
    auto n = g->GetN();
    g->SetPoint(n, get_led_vbias(dac, board), data[0].first);
    g->SetPointError(n, 0., data[0].second);
  }
  return g;
}
  
TGraphErrors *
make_led_background_graph(std::string dir, std::string board)
{
  auto g = new TGraphErrors;
  g->SetName(dir.c_str());
  for (auto dac : defs::dacs_led[board]) {
    auto filename = dir + "/bias_dac_" + std::to_string(dac) + "/coincidence.count.root";
    auto data = count_led_coincidences(filename.c_str());
    if (data[1] == std::pair<float,float>({0., 0.})) continue;
    auto n = g->GetN();
    g->SetPoint(n, get_led_vbias(dac, board), data[1].first);
    g->SetPointError(n, 0., data[1].second);
  }
  return g;
}
  
std::vector<TGraphErrors *>
get_led_graphs(std::string board, std::string status, std::string chname, int pulse_frequency = 1000, int pulse_voltage = 1000, int delta_threshold = 5, int marker = 20, int color = kAzure-3)
{
  auto dirlist = get_led_dirs(board, status, chname, pulse_frequency, pulse_voltage, delta_threshold);
  std::vector<TGraphErrors *> outlist;
  for (auto dir : dirlist) {
    auto g = make_led_graph(dir, board);
    if (!g) continue;
    set_style(g, marker, color);
    outlist.push_back(g);
  }
  return outlist;
}
  
std::vector<TGraphErrors *>
get_led_background_graphs(std::string board, std::string status, std::string chname, int pulse_frequency = 1000, int pulse_voltage = 1000, int delta_threshold = 5, int marker = 20, int color = kAzure-3)
{
  auto dirlist = get_led_dirs(board, status, chname, pulse_frequency, pulse_voltage, delta_threshold);
  std::vector<TGraphErrors *> outlist;
  for (auto dir : dirlist) {
    auto g = make_led_background_graph(dir, board);
    if (!g) continue;
    set_style(g, marker, color);
    outlist.push_back(g);
  }
  return outlist;
}
  
/******************************************************************************/

std::map<std::string, TGraphErrors *>
make_average_rms(std::vector<TGraphErrors *> graphs, int marker = 20, int color = kAzure-3)
{
  TProfile p("p", "", 20000, -100., 100.);
  TProfile pS("pS", "", 20000, -100., 100., "S");
  double themin[20000], themax[20000];
  for (int i = 0; i < 20000; ++i) themin[i] = themax[i] = -999.;
  for (auto g : graphs) {
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

  TGraphErrors *gave = new TGraphErrors;
  gave->SetName("gave");
  set_style(gave, marker, color, 0);
  TGraphErrors *grms = new TGraphErrors;
  grms->SetName("grms");
  //  set_style(grms, marker, color, 3002);
  set_style(grms, marker, color, 0);
  TGraphErrors *gwidth = new TGraphErrors;
  gwidth->SetName("gwidth");
  set_style(gwidth, marker, color, 0);
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

  return { {"average", gave} , {"rms" , grms} , {"width", gwidth} };
}
  
TCanvas *
dcr_vbias_scan_map_8x4(std::string dirname, std::string chip, int delta_threshold, int marker = 20, int color = kAzure-3, float vmin = 0., float vmax = 100., float vbreak = 0., TCanvas *c = nullptr)
{
  style();
  int dmarker[2] = {20, 20};
  int dcolor[2] = {kRed+1, kAzure-3};
  TLatex latex;
  if (!c) c = prepare_map_8x4(vmin - vbreak, dcr_min, vmax - vbreak, dcr_max, (vbreak == 0. ? ";bias voltage (V);DCR (Hz)" : ";over voltage (V);DCR (Hz)"), true);
  for (int irow = 0; irow < 8; ++irow) {
    for (int icol = 0; icol < 4; ++icol) {
      auto ipad = get_pad_map_8x4(irow, icol);
      c->cd(1 + ipad)->cd();
      std::string chname = rows[irow] + cols[icol];
      auto g = get_dcr_vbias_scan(dirname, chip, chname, delta_threshold, marker == 0 ? dmarker[irow % 2] : marker, color == 0 ? dcolor[irow % 2] : color);
      if (!g) continue;
      graphutils::x_shift(g, vbreak);
      g->Draw("samelp");
      latex.DrawLatex( vmin + 0.1 * (vmax - vmin), 5.e6, Form("#Delta_{thr} = %d", delta_threshold));
    }
  }
  return c;
}

TCanvas *
iv_scan_map_8x4(std::string dirname, std::string tagname, int marker = 20, int color = kAzure-3, float vmin = 0., float vmax = 100., TCanvas *c = nullptr)
{
  style();
  if (!c) c = prepare_map_8x4(vmin, iv_min, vmax, iv_max, ";bias voltage (V);current (A)", true);  
  for (int irow = 0; irow < 8; ++irow) {
    for (int icol = 0; icol < 4; ++icol) {
      auto ipad = get_pad_map_8x4(irow, icol);
      c->cd(1 + ipad)->cd();
      std::string chname = rows[irow] + cols[icol];
      auto g = get_iv_scan(dirname, tagname, chname, marker, color);
      if (!g) continue;
      g->Draw("samelp");
    }
  }
  return c;
}

TCanvas *
dcr_vbias_scan_selected(std::string dirname, std::string chip, std::vector<std::string> rows, std::vector<std::string> cols, std::vector<std::string> skip, int delta_threshold = 5, int marker = 20, int color = kAzure-3, float vmin = 0., float vmax = 100., float vbreak = 0., bool draw_average = false, TCanvas *c = nullptr)
{
  // to allow merging of FBKa and FBKb
  TString dirname_s = dirname;
  TString chip_s = chip;
  auto dirname_oa = dirname_s.Tokenize("+ ");
  auto chip_oa = chip_s.Tokenize("+ ");
  std::vector<std::string> _dirname, _chip;
  std::vector<std::vector<std::string>> _skip;
  auto ndirs = dirname_oa->GetEntries();
  for (int idir = 0; idir < ndirs; ++idir) {
    _dirname.push_back(dirname_oa->At(idir)->GetName());
    _chip.push_back(chip_oa->At(idir)->GetName());
    _skip.push_back({});
  }
  for (auto chname : skip) {
    auto last = chname.size();
    if (chname[last - 1] == '+') {
      chname.pop_back();
      _skip[1].push_back(chname);
    } else {
      _skip[0].push_back(chname);
    }
  }
  
  style();
  std::map<std::string, TObject *> output;
  if (!c) {
    c = new TCanvas("c", "c", 800, 800);
    c->DrawFrame(vmin - vbreak, dcr_min, vmax - vbreak, dcr_max, (vbreak == 0. ? ";bias voltage (V);DCR (Hz)" : ";over voltage (V);DCR (Hz)"));
    c->SetLogy();
  }
  std::vector<TGraphErrors *> graphs;
  for (int idir = 0; idir < ndirs; ++idir) {
  for (auto row : rows) {
    for (auto col : cols) {
      std::string chname = row + col;
      if (std::find(_skip[idir].begin(), _skip[idir].end(), chname) != _skip[idir].end()) continue;
      c->cd();
      auto g = get_dcr_vbias_scan(_dirname[idir], _chip[idir], chname, delta_threshold, marker, color);
      if (!g) continue;
      graphutils::x_shift(g, vbreak);
      if (!draw_average) g->Draw("samelp");
      graphs.push_back(g);
    }
  }}
  if (draw_average) {
    auto rets = make_average_rms(graphs, marker, color);
    rets["average"]->Draw("samep");
    //    rets["width"]->Draw("samee3");
    if (draw_average_rms) rets["rms"]->Draw("samee3");
  }
  return c;
}

/********************************************************************/

TCanvas *
led_vbias_scan_selected(std::string board, std::string status, std::vector<std::string> rows, std::vector<std::string> cols, std::vector<std::string> skip, int pulse_frequency = 1000, int pulse_voltage = 1000, int delta_threshold = 5, int marker = 20, int color = kAzure-3, float vmin = 0., float vmax = 100., float vbreak = 0., bool use_overvoltage = false, bool draw_average = false, TCanvas *c = nullptr)
{
  style();
  if (!c) {
    c = new TCanvas("c", "c", 800, 800);
    if (use_overvoltage) c->DrawFrame(vmin - vbreak, led_min, vmax - vbreak, led_max, ";over voltage (V);coincidences / triggers");
    else c->DrawFrame(vmin, led_min, vmax, led_max, ";bias voltage (V);coincidences / triggers");
    c->SetLogy();
  }
  std::vector<TGraphErrors *> graphs;
  for (auto row : rows) {
    for (auto col : cols) {
      std::string chname = row + col;
      if (std::find(skip.begin(), skip.end(), chname) != skip.end()) continue;
      c->cd();
      auto gl = get_led_graphs(board, status, chname, pulse_frequency, pulse_voltage, delta_threshold, marker, color);
      for (auto g : gl) {
        if (use_overvoltage) graphutils::x_shift(g, vbreak);
        if (!draw_average) g->Draw("samelp");
        graphs.push_back(g);
      }
    }
  }
  if (draw_average) {
    auto rets = make_average_rms(graphs, marker, color);
    rets["average"]->Draw("samep");
    //    rets["width"]->Draw("samee3");
    if (draw_average_rms) rets["rms"]->Draw("samee3");
  }
  return c;
}

TCanvas *
led_background_vbias_scan_selected(std::string board, std::string status, std::vector<std::string> rows, std::vector<std::string> cols, std::vector<std::string> skip, int pulse_frequency = 1000, int pulse_voltage = 1000, int delta_threshold = 5, int marker = 20, int color = kAzure-3, float vmin = 0., float vmax = 100., float vbreak = 0., bool use_overvoltage = false, bool draw_average = false, TCanvas *c = nullptr)
{
  style();
  if (!c) {
    c = new TCanvas("c", "c", 800, 800);
    if (use_overvoltage) c->DrawFrame(vmin - vbreak, dcr_min, vmax - vbreak, dcr_max, ";over voltage (V);background rate (Hz)");
    else c->DrawFrame(vmin, dcr_min, vmax, dcr_max, ";bias voltage (V);background rate (Hz)");
    c->SetLogy();
  }
  std::vector<TGraphErrors *> graphs;
  for (auto row : rows) {
    for (auto col : cols) {
      std::string chname = row + col;
      if (std::find(skip.begin(), skip.end(), chname) != skip.end()) continue;
      c->cd();
      auto gl = get_led_background_graphs(board, status, chname, pulse_frequency, pulse_voltage, delta_threshold, marker, color);
      for (auto g : gl) {
        if (use_overvoltage) graphutils::x_shift(g, vbreak);
        if (!draw_average) g->Draw("samelp");
        graphs.push_back(g);
      }
    }
  }
  if (draw_average) {
    auto rets = make_average_rms(graphs, marker, color);
    rets["average"]->Draw("samep");
    //    rets["width"]->Draw("samee3");
    if (draw_average_rms) rets["rms"]->Draw("samee3");
  }
  return c;
}

TCanvas *
led_vbias_scan_ratio_selected(std::string board, std::string status, TGraphErrors *gden, std::vector<std::string> rows, std::vector<std::string> cols, std::vector<std::string> skip, int pulse_frequency = 1000, int pulse_voltage = 1000, int delta_threshold = 5, int marker = 20, int color = kAzure-3, float vmin = 0., float vmax = 100., float vbreak = 0., bool use_overvoltage = false, bool draw_average = false, TCanvas *c = nullptr)
{
  style();
  if (!c) {
    c = new TCanvas("c", "c", 800, 800);
    if (use_overvoltage) c->DrawFrame(vmin - vbreak, ratio_min, vmax - vbreak, ratio_max, ";over voltage (V);coincidences / triggers ratio");
    else c->DrawFrame(vmin, ratio_min, vmax, ratio_max, ";bias voltage (V);coincidences / triggers ratio");
    c->SetLogy();
  }
  std::vector<TGraphErrors *> graphs;
  for (auto row : rows) {
    for (auto col : cols) {
      std::string chname = row + col;
      if (std::find(skip.begin(), skip.end(), chname) != skip.end()) continue;
      c->cd();
      auto gl = get_led_graphs(board, status, chname, pulse_frequency, pulse_voltage, delta_threshold, marker, color);
      for (auto gnum : gl) {
        if (!gnum || !gden) continue;
        //      auto g = graphutils::ratio(gnum, gden);
        auto g = graph_ratio(gnum, gden);
        if (use_overvoltage) graphutils::x_shift(g, vbreak);
        if (!draw_average) g->Draw("samelp");
        graphs.push_back(g);
      }
    }
  }
  if (draw_average) {
    auto rets = make_average_rms(graphs, marker, color);
    rets["average"]->Draw("samep");
    //    rets["width"]->Draw("samee3");
    if (draw_average_rms) rets["rms"]->Draw("samee3");
  }
  return c;
}

TCanvas *
led_vbias_scan_selected(std::string board, std::string status, std::string model, std::string columns = "ALL", int pulse_frequency = 1000, int pulse_voltage = 1000, bool skip_outliers = false, bool use_overvoltage = false, bool draw_averages = false, int marker = 20, int color = kAzure-3, TCanvas *c = nullptr)
{
  bool draw_the_label = (c == nullptr);
  // must ensure to exclude the reference sensor
  auto rows = defs::rows[model];
  rows.erase(std::remove(rows.begin(), rows.end(), "A"), rows.end());
  rows.erase(std::remove(rows.begin(), rows.end(), "B"), rows.end());
  
  int delta_threshold = 5;
  c = led_vbias_scan_selected(board, status, defs::rows[model], defs::cols[columns], skip_outliers ? defs::outliers_led[board][status] : std::vector<std::string>(), pulse_frequency, pulse_voltage, delta_threshold, marker, color, defs::vrange_led[board].first, defs::vrange_led[board].second, defs::vbreak[board][model], use_overvoltage, draw_averages, c);
  if (draw_the_label) draw_label(defs::producer_label[board] + " " + defs::model_label[model]);
  return c;
}

TCanvas *
led_background_vbias_scan_selected(std::string board, std::string status, std::string model, std::string columns = "ALL", int pulse_frequency = 1000, int pulse_voltage = 1000, bool skip_outliers = false, bool use_overvoltage = false, bool draw_averages = false, int marker = 20, int color = kAzure-3, TCanvas *c = nullptr)
{
  bool draw_the_label = (c == nullptr);
  // must ensure to exclude the reference sensor
  auto rows = defs::rows[model];
  rows.erase(std::remove(rows.begin(), rows.end(), "A"), rows.end());
  rows.erase(std::remove(rows.begin(), rows.end(), "B"), rows.end());
  
  int delta_threshold = 5;
  c = led_background_vbias_scan_selected(board, status, defs::rows[model], defs::cols[columns], skip_outliers ? defs::outliers_led[board][status] : std::vector<std::string>(), pulse_frequency, pulse_voltage, delta_threshold, marker, color, defs::vrange_led[board].first, defs::vrange_led[board].second, defs::vbreak[board][model], use_overvoltage, draw_averages, c);
  if (draw_the_label) draw_label(defs::producer_label[board] + " " + defs::model_label[model]);
  return c;
}

TCanvas *
led_vbias_scan_reference(std::string board, std::string status, int pulse_frequency = 1000, int pulse_voltage = 1000, bool use_overvoltage = false, bool draw_averages = false, int marker = 20, int color = kAzure-3, TCanvas *c = nullptr)
{
  bool draw_the_label = (c == nullptr);
  int delta_threshold = 5;
  c = led_vbias_scan_selected(board, status, {"A"}, {"1"}, {}, pulse_frequency, pulse_voltage, delta_threshold, marker, color, defs::vbreak["HAMA1"]["13360_3050"] - 5., defs::vbreak["HAMA1"]["13360_3050"] + 15., defs::vbreak["HAMA1"]["13360_3050"], use_overvoltage, draw_averages, c);
  //  draw_label(defs::producer_label[board] + " " + defs::model_label[model]);
  if (draw_the_label) draw_label("reference sensor");
  return c;
}

TCanvas *
led_vbias_scan_ratio_selected(std::string board, std::string status_num, TGraphErrors *gden, std::string model, std::string columns = "ALL", int pulse_frequency = 1000, int pulse_voltage = 1000, bool skip_outliers = false, bool use_overvoltage = false, bool draw_averages = false, int marker = 20, int color = kAzure-3, TCanvas *c = nullptr)
{
  bool draw_the_label = (c == nullptr);
  // must ensure to exclude the reference sensor
  auto rows = defs::rows[model];
  rows.erase(std::remove(rows.begin(), rows.end(), "A"), rows.end());
  rows.erase(std::remove(rows.begin(), rows.end(), "B"), rows.end());
  
  int delta_threshold = 5;
  c = led_vbias_scan_ratio_selected(board, status_num, gden, defs::rows[model], defs::cols[columns], skip_outliers ? defs::outliers_led[board][status_num] : std::vector<std::string>(), pulse_frequency, pulse_voltage, delta_threshold, marker, color, defs::vbreak[board][model] - 5., defs::vbreak[board][model] + 15., defs::vbreak[board][model], use_overvoltage, draw_averages, c);
  if (draw_the_label) draw_label(defs::producer_label[board] + " " + defs::model_label[model]);
  return c;
}

TCanvas *
led_vbias_scan_ratio_reference(std::string board, std::string status_num, TGraphErrors *gden, int pulse_frequency = 1000, int pulse_voltage = 1000, bool use_overvoltage = false, bool draw_averages = false, int marker = 20, int color = kAzure-3, TCanvas *c = nullptr)
{
  bool draw_the_label = (c == nullptr);
  int delta_threshold = 5;
  c = led_vbias_scan_ratio_selected(board, status_num, gden, {"A"}, {"1"}, {}, pulse_frequency, pulse_voltage, delta_threshold, marker, color, defs::vbreak["HAMA1"]["13360_3050"] - 5., defs::vbreak["HAMA1"]["13360_3050"] + 15., defs::vbreak["HAMA1"]["13360_3050"], use_overvoltage, draw_averages, c);
  //  draw_label(defs::producer_label[board] + " " + defs::model_label[model]);
  if (draw_the_label) draw_label("reference sensor");
  return c;
}

/*********************************************************************/

TCanvas *
dcr_vbias_scan_ratio_selected(std::string dirname_num, std::string dirname_den, std::string chip, std::vector<std::string> rows, std::vector<std::string> cols, std::vector<std::string> skip, int delta_threshold = 5, int marker = 20, int color = kAzure-3, float vmin = 0., float vmax = 100., float vbreak = 0., bool draw_average = false, TCanvas *c = nullptr, bool do_diff = false)
{
  // to allow merging of FBKa and FBKb
  TString dirname_num_s = dirname_num;
  TString dirname_den_s = dirname_den;
  TString chip_s = chip;
  auto dirname_num_oa = dirname_num_s.Tokenize("+ ");
  auto dirname_den_oa = dirname_den_s.Tokenize("+ ");
  auto chip_oa = chip_s.Tokenize("+ ");
  std::vector<std::string> _dirname_num, _dirname_den, _chip;
  std::vector<std::vector<std::string>> _skip;
  auto ndirs = dirname_num_oa->GetEntries();
  for (int idir = 0; idir < ndirs; ++idir) {
    _dirname_num.push_back(dirname_num_oa->At(idir)->GetName());
    _dirname_den.push_back(dirname_den_oa->At(idir)->GetName());
    _chip.push_back(chip_oa->At(idir)->GetName());
    _skip.push_back({});
  }
  for (auto chname : skip) {
    auto last = chname.size();
    if (chname[last - 1] == '+') {
      chname.pop_back();
      _skip[1].push_back(chname);
    } else {
      _skip[0].push_back(chname);
    }
  }


  style();
  std::map<std::string, TObject *> output;
  if (!c) {
    c = new TCanvas("c", "c", 800, 800);
    if (do_diff)
      c->DrawFrame(vmin - vbreak, dcr_min, vmax - vbreak, dcr_max, (vbreak == 0. ? ";bias voltage (V);DCR increase (Hz)" : ";over voltage (V);DCR increase (Hz)"));
    else
      c->DrawFrame(vmin - vbreak, ratio_min, vmax - vbreak, ratio_max, (vbreak == 0. ? ";bias voltage (V);DCR ratio" : ";over voltage (V);DCR ratio"));
    c->SetLogy();
  }
  std::vector<TGraphErrors *> graphs;
  for (int idir = 0; idir < ndirs; ++idir) {
  for (auto row : rows) {
    for (auto col : cols) {
      std::string chname = row + col;
      if (std::find(_skip[idir].begin(), _skip[idir].end(), chname) != _skip[idir].end()) continue;
      c->cd();
      auto gnum = get_dcr_vbias_scan(_dirname_num[idir], _chip[idir], chname, delta_threshold, marker, color);
      auto gden = get_dcr_vbias_scan(_dirname_den[idir], _chip[idir], chname, delta_threshold, marker, color);
      if (!gnum || !gden) continue;
      //      auto g = graphutils::ratio(gnum, gden);
      auto g = do_diff ? graphutils::diff(gnum, gden) : graph_ratio(gnum, gden);
      graphutils::x_shift(g, vbreak);
      if (!draw_average) g->Draw("samelp");
      graphs.push_back(g);
    }
  }}
  if (draw_average) {
    auto rets = make_average_rms(graphs, marker, color);
    rets["average"]->Draw("samep");
    //    rets["width"]->Draw("samee3");
    if (draw_average_rms) rets["rms"]->Draw("samee3");
  }
  return c;
}

TCanvas *
dcr_vbias_scan_ratio_selected(std::string dirname_num, TGraphErrors *gden, std::string chip, std::vector<std::string> rows, std::vector<std::string> cols, std::vector<std::string> skip, int delta_threshold = 5, int marker = 20, int color = kAzure-3, float vmin = 0., float vmax = 100., float vbreak = 0., bool draw_average = false, TCanvas *c = nullptr, bool do_diff = false)
{
  // to allow merging of FBKa and FBKb
  TString dirname_num_s = dirname_num;
  TString chip_s = chip;
  auto dirname_num_oa = dirname_num_s.Tokenize("+ ");
  auto chip_oa = chip_s.Tokenize("+ ");
  std::vector<std::string> _dirname_num, _chip;
  std::vector<std::vector<std::string>> _skip;
  auto ndirs = dirname_num_oa->GetEntries();
  for (int idir = 0; idir < ndirs; ++idir) {
    _dirname_num.push_back(dirname_num_oa->At(idir)->GetName());
    _chip.push_back(chip_oa->At(idir)->GetName());
    _skip.push_back({});
  }
  for (auto chname : skip) {
    auto last = chname.size();
    if (chname[last - 1] == '+') {
      chname.pop_back();
      _skip[1].push_back(chname);
    } else {
      _skip[0].push_back(chname);
    }
  }

  style();
  std::map<std::string, TObject *> output;
  if (!c) {
    c = new TCanvas("c", "c", 800, 800);
    if (do_diff)
      c->DrawFrame(vmin - vbreak, dcr_min, vmax - vbreak, dcr_max, (vbreak == 0. ? ";bias voltage (V);DCR increase (Hz)" : ";over voltage (V);DCR increase (Hz)"));
    else
      c->DrawFrame(vmin - vbreak, ratio_min, vmax - vbreak, ratio_max, (vbreak == 0. ? ";bias voltage (V);DCR ratio" : ";over voltage (V);DCR ratio"));
    c->SetLogy();
  }
  std::vector<TGraphErrors *> graphs;
  for (int idir = 0; idir < ndirs; ++idir) {
  for (auto row : rows) {
    for (auto col : cols) {
      std::string chname = row + col;
      if (std::find(_skip[idir].begin(), _skip[idir].end(), chname) != _skip[idir].end()) continue;
      c->cd();
      auto gnum = get_dcr_vbias_scan(_dirname_num[idir], _chip[idir], chname, delta_threshold, marker, color);
      if (!gnum || !gden) continue;
      //      auto g = graphutils::ratio(gnum, gden);
      auto g = do_diff ? graphutils::diff(gnum, gden) : graph_ratio(gnum, gden);
      graphutils::x_shift(g, vbreak);
      if (!draw_average) g->Draw("samelp");
      graphs.push_back(g);
    }
  }}
  if (draw_average) {
    auto rets = make_average_rms(graphs, marker, color);
    rets["average"]->Draw("samep");
    //    rets["width"]->Draw("samee3");
    if (draw_average_rms) rets["rms"]->Draw("samee3");
  }
  return c;
}

TCanvas *
dcr_vbias_scan_selected(std::string board, std::string status, std::string model, std::string columns = "ALL", bool skip_outliers = false, bool use_overvoltage = false, bool draw_averages = false, int marker = 20, int color = kAzure-3, TCanvas *c = nullptr)
{
  bool draw_the_label = (c == nullptr);
//  c = dcr_vbias_scan_selected(defs::dirname_dcr[board][status], defs::chip_dcr[board], defs::rows[model], defs::cols[columns], skip_outliers ? defs::outliers_dcr[board][status] : std::vector<std::string>(), 5, marker, color, defs::vrange_dcr[board].first, defs::vrange_dcr[board].second, use_overvoltage ? defs::vbreak[board][model] : 0., draw_averages, c);
  c = dcr_vbias_scan_selected(defs::dirname_dcr[board][status], defs::chip_dcr[board], defs::rows[model], defs::cols[columns], skip_outliers ? defs::outliers_dcr[board][status] : std::vector<std::string>(), 5, marker, color, defs::vbreak[board][model] - 5., defs::vbreak[board][model] + 15., use_overvoltage ? defs::vbreak[board][model] : 0., draw_averages, c);
  if (draw_the_label) draw_label(defs::producer_label[board] + " " + defs::model_label[model]);
  return c;
}

TCanvas *
dcr_vbias_scan_ratio_selected(std::string board, std::string status_num, std::string status_den, std::string model, std::string columns = "ALL", bool skip_outliers = false, bool use_overvoltage = false, bool draw_averages = false, int marker = 20, int color = kAzure-3, TCanvas *c = nullptr, bool do_diff = false)
{
  bool draw_the_label = (c == nullptr);
  //  c = dcr_vbias_scan_ratio_selected(defs::dirname_dcr[board][status_num], defs::dirname_dcr[board][status_den], defs::chip_dcr[board], defs::rows[model], defs::cols[columns], skip_outliers ? defs::outliers_dcr[board][status_num] : std::vector<std::string>(), 5, marker, color, defs::vrange_dcr[board].first, defs::vrange_dcr[board].second, use_overvoltage ? defs::vbreak[board][model] : 0., draw_averages, c);
  c = dcr_vbias_scan_ratio_selected(defs::dirname_dcr[board][status_num], defs::dirname_dcr[board][status_den], defs::chip_dcr[board], defs::rows[model], defs::cols[columns], skip_outliers ? defs::outliers_dcr[board][status_num] : std::vector<std::string>(), 5, marker, color, defs::vbreak[board][model] - 5., defs::vbreak[board][model] + 15., use_overvoltage ? defs::vbreak[board][model] : 0., draw_averages, c, do_diff);
  if (draw_the_label) draw_label(defs::producer_label[board] + " " + defs::model_label[model]);
  return c;
}

TCanvas *
dcr_vbias_scan_ratio_selected(std::string board, std::string status_num, TGraphErrors *gden, std::string model, std::string columns = "ALL", bool skip_outliers = false, bool use_overvoltage = false, bool draw_averages = false, int marker = 20, int color = kAzure-3, TCanvas *c = nullptr, bool do_diff = false)
{
  bool draw_the_label = (c == nullptr);
  //  c = dcr_vbias_scan_ratio_selected(defs::dirname_dcr[board][status_num], gden, defs::chip_dcr[board], defs::rows[model], defs::cols[columns], skip_outliers ? defs::outliers_dcr[board][status_num] : std::vector<std::string>(), 5, marker, color, defs::vrange_dcr[board].first, defs::vrange_dcr[board].second, use_overvoltage ? defs::vbreak[board][model] : 0., draw_averages, c);
  c = dcr_vbias_scan_ratio_selected(defs::dirname_dcr[board][status_num], gden, defs::chip_dcr[board], defs::rows[model], defs::cols[columns], skip_outliers ? defs::outliers_dcr[board][status_num] : std::vector<std::string>(), 5, marker, color, defs::vbreak[board][model] - 5., defs::vbreak[board][model] + 15., use_overvoltage ? defs::vbreak[board][model] : 0., draw_averages, c, do_diff);
  if (draw_the_label) draw_label(defs::producer_label[board] + " " + defs::model_label[model]);
  return c;
}

/******************************************************************/

TCanvas *
iv_scan_selected(std::string dirname, std::string tagname, std::vector<std::string> rows, std::vector<std::string> cols, std::vector<std::string> skip, int marker = 20, int color = kAzure-3, float vmin = 0., float vmax = 100., float vcut = 100., float vbreak = 0., bool use_overvoltage = false, bool draw_average = false, TCanvas *c = nullptr)
{
  // to allow merging of FBKa and FBKb
  TString dirname_s = dirname;
  TString tagname_s = tagname;
  auto dirname_oa = dirname_s.Tokenize("+ ");
  auto tagname_oa = tagname_s.Tokenize("+ ");
  dirname_oa->ls();
  tagname_oa->ls();
  std::vector<std::string> _dirname, _tagname;
  std::vector<std::vector<std::string>> _skip;
  auto ndirs = dirname_oa->GetEntries();
  for (int idir = 0; idir < ndirs; ++idir) {
    _dirname.push_back(dirname_oa->At(idir)->GetName());
    _tagname.push_back(tagname_oa->At(idir)->GetName());
    _skip.push_back({});
  }
  for (auto chname : skip) {
    auto last = chname.size();
    if (chname[last - 1] == '+') {
      chname.pop_back();
      _skip[1].push_back(chname);
    } else {
      _skip[0].push_back(chname);
    }
  }

  style();
  std::map<std::string, TObject *> output;
  if (!c) {
    c = new TCanvas("c", "c", 800, 800);
    if (use_overvoltage) c->DrawFrame(vmin - vbreak, iv_min, vmax - vbreak, iv_max, ";over voltage (V);current (A)");
    else c->DrawFrame(vmin, iv_min, vmax, iv_max, ";bias voltage (V);current (A)");
    c->SetLogy();
  }
  std::vector<TGraphErrors *> graphs;
  for (int idir = 0; idir < ndirs; ++idir) {
  for (auto row : rows) {
    for (auto col : cols) {
      std::string chname = row + col;
      if (std::find(_skip[idir].begin(), _skip[idir].end(), chname) != _skip[idir].end()) continue;
      c->cd();
      auto g = get_iv_scan(_dirname[idir], _tagname[idir], chname, marker, color, vbreak);
      if (!g) continue;
      for (int i = g->GetN() - 1; i >= 0; --i) {
        if (g->GetX()[i] < vcut) break;
        g->RemovePoint(i);
      }
      if (use_overvoltage) graphutils::x_shift(g, vbreak);
      if (!draw_average) g->Draw("samelp");
      graphs.push_back(g);
    }
  } }
  if (draw_average) {
    auto rets = make_average_rms(graphs, marker, color);
    rets["average"]->Draw("samep");
    //    rets["width"]->Draw("samee3");
    if (draw_average_rms) rets["rms"]->Draw("samee3");
  }
  return c;
}

TCanvas *
iv_scan_ratio_selected(std::string dirname_num, std::string tagname_num, std::string dirname_den, std::string tagname_den, std::vector<std::string> rows, std::vector<std::string> cols, std::vector<std::string> skip, int marker = 20, int color = kAzure-3, float vmin = 0., float vmax = 100., float vcut = 100., float vbreak = 0., bool use_overvoltage = false, bool draw_average = false, TCanvas *c = nullptr, bool do_diff = false)
{
  if (dirname_num.empty() || tagname_num.empty() || 
      dirname_den.empty() || tagname_den.empty()) return c;
      
  // to allow merging of FBKa and FBKb
  TString dirname_num_s = dirname_num;
  TString dirname_den_s = dirname_den;
  TString tagname_num_s = tagname_num;
  TString tagname_den_s = tagname_den;
  auto dirname_num_oa = dirname_num_s.Tokenize("+ ");
  auto dirname_den_oa = dirname_den_s.Tokenize("+ ");
  auto tagname_num_oa = tagname_num_s.Tokenize("+ ");
  auto tagname_den_oa = tagname_den_s.Tokenize("+ ");
  std::vector<std::string> _dirname_num, _dirname_den, _tagname_num, _tagname_den;
  std::vector<std::vector<std::string>> _skip;
  auto ndirs = dirname_num_oa->GetEntries();
  for (int idir = 0; idir < ndirs; ++idir) {
    _dirname_num.push_back(dirname_num_oa->At(idir)->GetName());
    _tagname_num.push_back(tagname_num_oa->At(idir)->GetName());
    _dirname_den.push_back(dirname_den_oa->At(idir)->GetName());
    _tagname_den.push_back(tagname_den_oa->At(idir)->GetName());
    _skip.push_back({});
  }
  for (auto chname : skip) {
    auto last = chname.size();
    if (chname[last - 1] == '+') {
      chname.pop_back();
      _skip[1].push_back(chname);
    } else {
      _skip[0].push_back(chname);
    }
  }

  style();
  std::map<std::string, TObject *> output;
  if (!c) {
    c = new TCanvas("c", "c", 800, 800);
    if (use_overvoltage)
      if (do_diff)
        c->DrawFrame(vmin - vbreak, iv_min, vmax - vbreak, iv_max, ";over voltage (V);current increase (A)");
      else
        c->DrawFrame(vmin - vbreak, ratio_min, vmax - vbreak, ratio_max, ";over voltage (V);current ratio");
    else
      if (do_diff)
        c->DrawFrame(vmin, iv_min, vmax, iv_max, ";bias voltage (V);current increase (A)");
      else
        c->DrawFrame(vmin, ratio_min, vmax, ratio_max, ";bias voltage (V);current ratio");
    c->SetLogy();
  }
  std::vector<TGraphErrors *> graphs;
  for (int idir = 0; idir < ndirs; ++idir) {
  for (auto row : rows) {
    for (auto col : cols) {
      std::string chname = row + col;
      if (std::find(_skip[idir].begin(), _skip[idir].end(), chname) != _skip[idir].end()) continue;
      c->cd();
      auto gnum = get_iv_scan(_dirname_num[idir], _tagname_num[idir], chname, marker, color, vbreak);
      auto gden = get_iv_scan(_dirname_den[idir], _tagname_den[idir], chname, marker, color, vbreak);
      if (!gnum || !gden) continue;
      //      auto g = graphutils::ratio(gnum, gden);
      auto g = do_diff ? graphutils::diff(gnum, gden) : graph_ratio(gnum, gden);
      for (int i = g->GetN() - 1; i >= 0; --i) {
        if (g->GetX()[i] < vcut) break;
        g->RemovePoint(i);
      }
      if (use_overvoltage) graphutils::x_shift(g, vbreak);
      if (!draw_average) g->Draw("samelp");
      graphs.push_back(g);
    }
  }}
  if (draw_average) {
    auto rets = make_average_rms(graphs, marker, color);
    rets["average"]->Draw("samep");
    //    rets["width"]->Draw("samee3");
    if (draw_average_rms) rets["rms"]->Draw("samee3");
  }
  return c;
}

TCanvas *
iv_scan_ratio_selected(std::string dirname_num, std::string tagname_num, TGraphErrors *gden, std::vector<std::string> rows, std::vector<std::string> cols, std::vector<std::string> skip, int marker = 20, int color = kAzure-3, float vmin = 0., float vmax = 100., float vcut = 100., float vbreak = 0., bool use_overvoltage = false, bool draw_average = false, TCanvas *c = nullptr, bool do_diff = false)
{
  // to allow merging of FBKa and FBKb
  TString dirname_num_s = dirname_num;
  TString tagname_num_s = tagname_num;
  auto dirname_num_oa = dirname_num_s.Tokenize("+ ");
  auto tagname_num_oa = tagname_num_s.Tokenize("+ ");
  std::vector<std::string> _dirname_num, _tagname_num;
  std::vector<std::vector<std::string>> _skip;
  auto ndirs = dirname_num_oa->GetEntries();
  for (int idir = 0; idir < ndirs; ++idir) {
    _dirname_num.push_back(dirname_num_oa->At(idir)->GetName());
    _tagname_num.push_back(tagname_num_oa->At(idir)->GetName());
    _skip.push_back({});
  }
  for (auto chname : skip) {
    auto last = chname.size();
    if (chname[last - 1] == '+') {
      chname.pop_back();
      _skip[1].push_back(chname);
    } else {
      _skip[0].push_back(chname);
    }
  }

  style();
  std::map<std::string, TObject *> output;
  if (!c) {
    c = new TCanvas("c", "c", 800, 800);
    if (use_overvoltage)
      if (do_diff)
        c->DrawFrame(vmin - vbreak, iv_min, vmax - vbreak, iv_max, ";over voltage (V);current increase (A)");
      else
        c->DrawFrame(vmin - vbreak, ratio_min, vmax - vbreak, ratio_max, ";over voltage (V);current ratio");
    else
      if (do_diff)
        c->DrawFrame(vmin, iv_min, vmax, iv_max, ";bias voltage (V);current increase (A)");
      else
        c->DrawFrame(vmin, ratio_min, vmax, ratio_max, ";bias voltage (V);current ratio");
    c->SetLogy();
  }
  std::vector<TGraphErrors *> graphs;
  for (int idir = 0; idir < ndirs; ++idir) {
  for (auto row : rows) {
    for (auto col : cols) {
      std::string chname = row + col;
      if (std::find(_skip[idir].begin(), _skip[idir].end(), chname) != _skip[idir].end()) continue;
      c->cd();
      auto gnum = get_iv_scan(_dirname_num[idir], _tagname_num[idir], chname, marker, color, vbreak);
      if (!gnum || !gden) continue;
      //      auto g = graphutils::ratio(gnum, gden);
      auto g = do_diff ? graphutils::diff(gnum, gden) : graph_ratio(gnum, gden);
      for (int i = g->GetN() - 1; i >= 0; --i) {
        if (g->GetX()[i] < vcut) break;
        g->RemovePoint(i);
      }
      if (use_overvoltage) graphutils::x_shift(g, vbreak);
      if (!draw_average) g->Draw("samelp");
      graphs.push_back(g);
    }
  }}
  if (draw_average) {
    auto rets = make_average_rms(graphs, marker, color);
    rets["average"]->Draw("samep");
    //    rets["width"]->Draw("samee3");
    if (draw_average_rms) rets["rms"]->Draw("samee3");
  }
  return c;
}

TCanvas *
iv_scan_selected(std::string board, std::string status, std::string model, std::string columns = "ALL", bool skip_outliers = false, bool use_overvoltage = false, bool draw_averages = false, int marker = 20, int color = kAzure-3, TCanvas *c = nullptr)
{
  bool draw_the_label = (c == nullptr);
  //  c = iv_scan_selected(defs::dirname_iv[board][status], defs::tagname_iv[board][status], defs::rows[model], defs::cols[columns], skip_outliers ? defs::outliers_iv[board][status] : std::vector<std::string>(), marker, color, defs::vrange_iv[board].first - , defs::vrange_iv[board].second, defs::vcut_iv[board][model], defs::vbreak[board][model], use_overvoltage, draw_averages, c);
  c = iv_scan_selected(defs::dirname_iv[board][status], defs::tagname_iv[board][status], defs::rows[model], defs::cols[columns], skip_outliers ? defs::outliers_iv[board][status] : std::vector<std::string>(), marker, color, defs::vbreak[board][model] - 5., defs::vbreak[board][model] + 15., defs::vcut_iv[board][model], defs::vbreak[board][model], use_overvoltage, draw_averages, c);
  if (draw_the_label) draw_label(defs::producer_label[board] + " " + defs::model_label[model]);
  return c;
}

TCanvas *
iv_scan_ratio_selected(std::string board, std::string status_num, std::string status_den, std::string model, std::string columns = "ALL", bool skip_outliers = false, bool use_overvoltage = false, bool draw_averages = false, int marker = 20, int color = kAzure-3, TCanvas *c = nullptr, bool do_diff = false)
{
  bool draw_the_label = (c == nullptr);
  //  c = iv_scan_ratio_selected(defs::dirname_iv[board][status_num], defs::tagname_iv[board][status_num], defs::dirname_iv[board][status_den], defs::tagname_iv[board][status_den], defs::rows[model], defs::cols[columns], skip_outliers ? defs::outliers_iv[board][status_num] : std::vector<std::string>(), marker, color, defs::vrange_iv[board].first, defs::vrange_iv[board].second, defs::vcut_iv[board][model], defs::vbreak[board][model], use_overvoltage, draw_averages, c);
  c = iv_scan_ratio_selected(defs::dirname_iv[board][status_num], defs::tagname_iv[board][status_num], defs::dirname_iv[board][status_den], defs::tagname_iv[board][status_den], defs::rows[model], defs::cols[columns], skip_outliers ? defs::outliers_iv[board][status_num] : std::vector<std::string>(), marker, color, defs::vbreak[board][model] - 5., defs::vbreak[board][model] + 15., defs::vcut_iv[board][model], defs::vbreak[board][model], use_overvoltage, draw_averages, c, do_diff);
  if (draw_the_label) draw_label(defs::producer_label[board] + " " + defs::model_label[model]);
  return c;
}

TCanvas *
iv_scan_ratio_selected(std::string board, std::string status_num, TGraphErrors *gden, std::string model, std::string columns = "ALL", bool skip_outliers = false, bool use_overvoltage = false, bool draw_averages = false, int marker = 20, int color = kAzure-3, TCanvas *c = nullptr, bool do_diff = false)
{
  bool draw_the_label = (c == nullptr);
  c = iv_scan_ratio_selected(defs::dirname_iv[board][status_num], defs::tagname_iv[board][status_num], gden, defs::rows[model], defs::cols[columns], skip_outliers ? defs::outliers_iv[board][status_num] : std::vector<std::string>(), marker, color, defs::vbreak[board][model] - 5., defs::vbreak[board][model] + 15., defs::vcut_iv[board][model], defs::vbreak[board][model], use_overvoltage, draw_averages, c, do_diff);
  if (draw_the_label) draw_label(defs::producer_label[board] + " " + defs::model_label[model]);
  return c;
}


/**********************************************************************/

TCanvas *
gain_scan_selected(std::string dirname_iv, std::string tagname_iv, std::string dirname_dcr, std::string chip_dcr, std::vector<std::string> rows, std::vector<std::string> cols, std::vector<std::string> skip, int marker = 20, int color = kAzure-3, float vmin = 0., float vmax = 100., float vcut = 100., float vbreak = 0., bool use_overvoltage = false, bool draw_average = false, TCanvas *c = nullptr)
{
  int delta_threshold = 5;

  // to allow merging of FBKa and FBKb
  TString dirname_iv_s = dirname_iv;
  TString tagname_iv_s = tagname_iv;
  TString dirname_dcr_s = dirname_dcr;
  TString chip_dcr_s = chip_dcr;
  auto dirname_iv_oa = dirname_iv_s.Tokenize("+ ");
  auto tagname_iv_oa = tagname_iv_s.Tokenize("+ ");
  auto dirname_dcr_oa = dirname_dcr_s.Tokenize("+ ");
  auto chip_dcr_oa = chip_dcr_s.Tokenize("+ ");
  dirname_iv_oa->ls();
  tagname_iv_oa->ls();
  dirname_dcr_oa->ls();
  chip_dcr_oa->ls();
  std::vector<std::string> _dirname_iv, _tagname_iv, _dirname_dcr, _chip_dcr;
  std::vector<std::vector<std::string>> _skip;
  auto ndirs = dirname_iv_oa->GetEntries();
  for (int idir = 0; idir < ndirs; ++idir) {
    _dirname_iv.push_back(dirname_iv_oa->At(idir)->GetName());
    _tagname_iv.push_back(tagname_iv_oa->At(idir)->GetName());
    _dirname_dcr.push_back(dirname_dcr_oa->At(idir)->GetName());
    _chip_dcr.push_back(chip_dcr_oa->At(idir)->GetName());
    _skip.push_back({});
  }
  for (auto chname : skip) {
    auto last = chname.size();
    if (chname[last - 1] == '+') {
      chname.pop_back();
      _skip[1].push_back(chname);
    } else {
      _skip[0].push_back(chname);
    }
  }

  style();
  std::map<std::string, TObject *> output;
  if (!c) {
    c = new TCanvas("c", "c", 800, 800);
    if (use_overvoltage) c->DrawFrame(vmin - vbreak, gain_min, vmax - vbreak, gain_max, ";over voltage (V);gain");
    else c->DrawFrame(vmin, gain_min, vmax, gain_max, ";bias voltage (V);gain");
    c->SetLogy();
  }
  std::vector<TGraphErrors *> graphs;
  for (int idir = 0; idir < ndirs; ++idir) {
  for (auto row : rows) {
    for (auto col : cols) {
      std::string chname = row + col;
      if (std::find(_skip[idir].begin(), _skip[idir].end(), chname) != _skip[idir].end()) continue;
      c->cd();
      auto giv = get_iv_scan(_dirname_iv[idir], _tagname_iv[idir], chname, marker, color, vbreak);
      if (!giv) continue;
      for (int i = giv->GetN() - 1; i >= 0; --i) {
        if (giv->GetX()[i] < vcut) break;
        giv->RemovePoint(i);
      }
      auto gdcr = get_dcr_vbias_scan(_dirname_dcr[idir], _chip_dcr[idir], chname, delta_threshold, marker, color);
      if (!gdcr) continue;
      auto g = graphutils::ratio(giv, gdcr);
      for (int i = 0; i < g->GetN(); ++i) {
        g->GetY()[i] /= 1.6021766e-19;
        g->GetEY()[i] /= 1.6021766e-19;
      }
      if (use_overvoltage) graphutils::x_shift(g, vbreak);
      if (!draw_average) g->Draw("samelp");
      graphs.push_back(g);
    }
  } }
  if (draw_average) {
    auto rets = make_average_rms(graphs, marker, color);
    rets["average"]->Draw("samep");
    //    rets["width"]->Draw("samee3");
    if (draw_average_rms) rets["rms"]->Draw("samee3");
  }
  return c;
}

TCanvas *
gain_scan_selected(std::string board, std::string status, std::string model, std::string columns = "ALL", bool skip_outliers = false, bool use_overvoltage = false, bool draw_averages = false, int marker = 20, int color = kAzure-3, TCanvas *c = nullptr)
{
  bool draw_the_label = (c == nullptr);

  std::vector<std::string> skip;
  for (auto ch : defs::outliers_iv[board][status]) skip.push_back(ch);
  for (auto ch : defs::outliers_dcr[board][status]) skip.push_back(ch);

  c = gain_scan_selected(defs::dirname_iv[board][status], defs::tagname_iv[board][status], defs::dirname_dcr[board][status], defs::chip_dcr[board], defs::rows[model], defs::cols[columns], skip_outliers ? skip : std::vector<std::string>(), marker, color, defs::vrange_iv[board].first, defs::vrange_iv[board].second, defs::vcut_iv[board][model], defs::vbreak[board][model], use_overvoltage, draw_averages, c);
  if (draw_the_label) draw_label(defs::producer_label[board] + " " + defs::model_label[model]);
  return c;
}



/*********************************************************************/

TCanvas *
dcr_threshold_scan_selected(std::string dirname, std::string chip, std::vector<std::string> rows, std::vector<std::string> cols, std::vector<std::string> skip, int bias_dac = 1, int marker = 20, int color = kAzure-3, bool draw_average = false, TCanvas *c = nullptr)
{
  style();
  TLine line;
  line.SetLineStyle(kDashed);
  std::map<std::string, TObject *> output;
  if (!c) {
    c = new TCanvas("c", "c", 800, 800);
    c->DrawFrame(-5., dcr_min, 65., dcr_max, ";threshold (au);DCR (Hz)");
    c->SetLogy();
  }
  std::vector<TGraphErrors *> graphs;
  for (auto row : rows) {
    for (auto col : cols) {
      std::string chname = row + col;
      if (std::find(skip.begin(), skip.end(), chname) != skip.end()) continue;
      c->cd();
      auto g = get_dcr_threshold_scan(dirname, chip, chname, bias_dac, marker, color);
      if (!g) continue;
      graphs.push_back(g);
      if (!draw_average) g->Draw("samelp");
      line.DrawLine(5., dcr_min, 5., dcr_max);
    }
  }
  if (draw_average) {
    auto rets = make_average_rms(graphs, marker, color);
    rets["average"]->Draw("samep");
    //    rets["width"]->Draw("samee3");
    if (draw_average_rms) rets["rms"]->Draw("samee3");
  }
  return c;
}

TCanvas *
dcr_threshold_scan_map_8x4(std::string dirname, std::string chip, int bias_dac = 1, int marker = 20, int color = kAzure-3, TCanvas *c = nullptr)
{
  style();
  int dmarker[2] = {20, 20};
  int dcolor[2] = {kRed+1, kAzure-3};
  float vbias;
  TLine line;
  line.SetLineStyle(kDashed);
  TLatex latex;
  if (!c) c = prepare_map_8x4(-32., dcr_min, 64., dcr_max, ";delta threshold (au);DCR (Hz)", true);
  for (int irow = 0; irow < 8; ++irow) {
    for (int icol = 0; icol < 4; ++icol) {
      auto ipad = get_pad_map_8x4(irow, icol);
      c->cd(1 + ipad)->cd();
      std::string chname = rows[irow] + cols[icol];
      auto g = get_dcr_threshold_scan(dirname, chip, chname, bias_dac, marker == 0 ? dmarker[irow % 2] : marker, color == 0 ? dcolor[irow % 2] : color, &vbias);
      if (!g) continue;
      g->Draw("samecp");
      line.DrawLine(5., dcr_min, 5., dcr_max);
      latex.DrawLatex(10, 5.e6, Form("V_{bias} = %.1f V", vbias));
    }
  }  
  return c;
}

TCanvas *
dcr_vbias_scan_map_8x4(std::string board, std::string status)
{
  auto c = dcr_vbias_scan_map_8x4(defs::dirname_dcr[board][status], defs::chip_dcr[board], 5, 20, kAzure-3, defs::vrange_dcr[board].first, defs::vrange_dcr[board].second, 0.);
  c = dcr_vbias_scan_map_8x4(defs::dirname_dcr[board][status], defs::chip_dcr[board], 3, 25, kAzure-3, defs::vrange_dcr[board].first, defs::vrange_dcr[board].second, 0., c);
  return c;
}

TCanvas *
dcr_threshold_scan_selected(std::string board, std::string status, std::string model, std::string columns = "ALL", bool skip_outliers = false, bool draw_averages = false, TCanvas *c = nullptr)
{
  c = dcr_threshold_scan_selected(defs::dirname_dcr[board][status], defs::chip_dcr[board], defs::rows[model], defs::cols[columns], skip_outliers ? defs::outliers_dcr[board][status] : std::vector<std::string>(), 0, 20, kAzure-3, draw_averages, c);
  return c;
}

TCanvas *
dcr_vbias_scan_niel(std::string board, std::string status, std::string model, bool skip_outliers = false, bool use_overvoltage = false, bool draw_averages = false, TCanvas *c = nullptr)
{
  c = dcr_vbias_scan_selected(defs::dirname_dcr[board][status], defs::chip_dcr[board], defs::rows[model], defs::cols["NIEL09"], skip_outliers ? defs::outliers_dcr[board][status] : std::vector<std::string>(), 5, 20, kAzure-3, defs::vrange_dcr[board].first, defs::vrange_dcr[board].second, use_overvoltage ? defs::vbreak[board][model] : 0., draw_averages, c);
  c = dcr_vbias_scan_selected(defs::dirname_dcr[board][status], defs::chip_dcr[board], defs::rows[model], defs::cols["NIEL10"], skip_outliers ? defs::outliers_dcr[board][status] : std::vector<std::string>(), 5, 20, kGreen+2, defs::vrange_dcr[board].first, defs::vrange_dcr[board].second, use_overvoltage ? defs::vbreak[board][model] : 0., draw_averages, c);
  c = dcr_vbias_scan_selected(defs::dirname_dcr[board][status], defs::chip_dcr[board], defs::rows[model], defs::cols["NIEL11"], skip_outliers ? defs::outliers_dcr[board][status] : std::vector<std::string>(), 5, 20, kRed+1, defs::vrange_dcr[board].first, defs::vrange_dcr[board].second, use_overvoltage ? defs::vbreak[board][model] : 0., draw_averages, c);
  return c;
}

TCanvas *
dcr_threshold_scan_map_8x4(std::string board, std::string status)
{
  auto c = dcr_threshold_scan_map_8x4(defs::dirname_dcr[board][status], defs::chip_dcr[board], 1, 20, kAzure-3);
  c = dcr_threshold_scan_map_8x4(defs::dirname_dcr[board][status], defs::chip_dcr[board], 0, 25, kAzure-3, c);
  return c;
}

  
} // namespace draw
