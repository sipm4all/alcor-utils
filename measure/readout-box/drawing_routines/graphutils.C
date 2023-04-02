#pragma once

namespace graphutils {

std::pair<double, double>
eval(TGraphErrors *g, double x) {
  TGraph gval, gerr;
  for (int i = 0; i < g->GetN(); ++i) {
    gval.SetPoint(i, g->GetX()[i], g->GetY()[i]);
    gerr.SetPoint(i, g->GetX()[i], g->GetEY()[i]);
  }
  return { gval.Eval(x) , gerr.Eval(x) };
}

TGraphErrors *
swapxy(TGraphErrors *gin)
{
  auto g = (TGraphErrors*)gin->Clone();
  g->Set(0);
  g->SetName(gin->GetName());
  for (int i = 0; i < gin->GetN(); ++i) {
    auto x = gin->GetX()[i];
    auto ex = gin->GetEX()[i];
    auto y = gin->GetY()[i];
    auto ey = gin->GetEY()[i];
    g->SetPoint(i, y, x);
    g->SetPointError(i, ey, ex);
  }
  return g;
}
  
TGraphErrors *
derivate(TGraphErrors *gin, double sign = 1.)
{
  auto g = (TGraphErrors*)gin->Clone();
  g->Set(0);
  g->SetName(gin->GetName());
  for (int i = 0; i < gin->GetN(); ++i) {
    if (gin->GetEY()[i] <= 0.) continue;
    auto x0 = gin->GetX()[i];
    auto y0 = gin->GetY()[i];
    auto ey0 = gin->GetEY()[i];
    for (int j = i + 1; j < gin->GetN(); ++j) {
      if (gin->GetEY()[j] <= 0.) continue;
      auto x1 = gin->GetX()[j];
      auto y1 = gin->GetY()[j];
      auto ey1 = gin->GetEY()[j];
      
      auto val = sign * (y1 - y0);
      auto vale = TMath::Sqrt(ey1 * ey1 + ey0 * ey0);
      
      auto n = g->GetN();
      g->SetPoint(n, x0, val);
      g->SetPointError(n, 0, vale);
      break;
    }
  }
  
  return g;
}

TGraph *
derivate(TGraph *gin, double sign = 1.)
{
  auto g = (TGraph*)gin->Clone();
  g->Set(0);
  g->SetName(gin->GetName());
  for (int i = 0; i < gin->GetN(); ++i) {
    auto x0 = gin->GetX()[i];
    auto y0 = gin->GetY()[i];
    for (int j = i + 1; j < gin->GetN(); ++j) {
      auto x1 = gin->GetX()[j];
      auto y1 = gin->GetY()[j];      
      auto val = sign * (y1 - y0);
      auto n = g->GetN();
      g->SetPoint(n, x0, val);
      break;
    }
  }
  
  return g;
}

  /*
TGraphErrors *
derivate(TGraphErrors *gin)
{
  auto g = (TGraphErrors*)gin->Clone();
  g->Set(0);
  g->SetName(gin->GetName());
  for (int i = 0; i < gin->GetN(); ++i) {
    if (gin->GetEY()[i] <= 0.) continue;
    auto x0 = gin->GetX()[i];
    auto y0 = gin->GetY()[i];
    auto ey0 = gin->GetEY()[i];
    for (int j = i + 1; j < gin->GetN(); ++j) {
      if (gin->GetEY()[j] <= 0.) continue;
      auto x1 = gin->GetX()[j];
      auto y1 = gin->GetY()[j];
      auto ey1 = gin->GetEY()[j];
      
      auto cen = 0.5 * (x1 + x0);
      auto val = -(y1 - y0) / (x1 - x0);
      auto vale = TMath::Sqrt(ey1 * ey1 + ey0 * ey0) / (x1 - x0);
      
      auto n = g->GetN();
      g->SetPoint(n, cen, val);
      g->SetPointError(n, 0, vale);
      break;
    }
  }
  
  return g;
}
  */
  
TGraphErrors *
ratio(TGraphErrors *gn, TGraphErrors *gd, bool propagate_error = true)
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
    auto ret = eval(gd, x);
    auto d = ret.first;
    auto ed = ret.second;
    auto rey = ey / y;
    auto red = ed / d;
    y = y / d;
    if (propagate_error) ey = sqrt(rey * rey + red * red) * y;
    else ey = ey / d;
    auto n = g->GetN();
    g->SetPoint(n, x, y);
    g->SetPointError(n, ex, ey);
    n++;
  }
  return g;
}
  
TGraphErrors *
multi(TGraphErrors *gn, TGraphErrors *gd, bool propagate_error = true)
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
    auto ret = eval(gd, x);
    auto d = ret.first;
    auto ed = ret.second;
    auto rey = ey / y;
    auto red = ed / d;
    y = y * d;
    if (propagate_error) ey = sqrt(rey * rey + red * red) * y;
    else ey = ey * d;
    auto n = g->GetN();
    g->SetPoint(n, x, y);
    g->SetPointError(n, ex, ey);
    n++;
  }
  return g;
}
  
TGraphErrors *
diff(TGraphErrors *gn, TGraphErrors *gd, bool propagate_error = true)
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
    auto ret = eval(gd, x);
    auto d = ret.first;
    auto ed = ret.second;
    y = y - d;
    if (propagate_error) ey = sqrt(ey * ey + ed * ed);
    else ey = ey;
    auto n = g->GetN();
    g->SetPoint(n, x, y);
    g->SetPointError(n, ex, ey);
    n++;
  }
  return g;
}
  
void
x_shift(TGraphErrors *g, float val)
{
  for (int i = 0; i < g->GetN(); ++i)
    g->GetX()[i] -= val;
}
  
  TGraph *
  diff(TGraph *gin, TGraph *gref)
  {
    auto gout = new TGraph;
    for (int i = 0; i < gin->GetN(); ++i) {
      auto x = gin->GetX()[i];
      auto y = gin->GetY()[i];
      if (x < gref->GetX()[0]) continue;
      if (x > gref->GetX()[gref->GetN() - 1]) continue;
      auto ref = gref->Eval(x);
      auto val = (y - ref) / ref;
      gout->SetPoint(gout->GetN(), x, val);
    }
    return gout;
  }

  TGraph *
  fromZero(TGraph *gin)
  {
    auto gout = new TGraph;
    for (int i = 0; i < gin->GetN(); ++i) {
      auto x = gin->GetX()[i] - gin->GetX()[0];
      auto y = gin->GetY()[i];
      gout->SetPoint(i, x, y);
    }
    return gout;
  }

  TGraph *
  invertY(TGraph *gin)
  {
    auto gout = new TGraph;
    for (int i = 0; i < gin->GetN(); ++i) {
      auto x = gin->GetX()[i];
      auto y = -gin->GetY()[i];
      gout->SetPoint(i, x, y);
    }
    return gout;
  }

  TGraph *
  invertX(TGraph *gin)
  {
    auto gout = new TGraph;
    for (int i = 0; i < gin->GetN(); ++i) {
      auto x = -gin->GetX()[i];
      auto y = gin->GetY()[i];
      gout->SetPoint(i, x, y);
    }
    return gout;
  }

  TGraph *
  average(TGraph *gin, int n = 2)
  {
    auto gout = new TGraph;
    for (int i = 0; i < gin->GetN() - n; i += n) {
      double x = 0.;
      double y = 0.;
      for (int j = i; j < i + n; ++j) {
	x += gin->GetX()[j];
	y += gin->GetY()[j];
      }
      x /= (double)n;
      y /= (double)n;
      gout->SetPoint(gout->GetN(), x, y);
    }
    return gout;
  }
  
  TGraph *
  rms(TGraph *gin, int n = 2)
  {
    auto gout = new TGraph;
    for (int i = 0; i < gin->GetN() - n; i += n) {
      double x = 0.;
      double y = 0.;
      for (int j = i; j < i + n; ++j) {
	x += gin->GetX()[j];
	y += gin->GetY()[j];
      }
      x /= (double)n;
      y /= (double)n;
      auto mean = y;
      y = 0.;
      for (int j = i; j < i + n; ++j) {
	y += (gin->GetY()[j] - mean) * (gin->GetY()[j] - mean);
      }
      y /= (double)n;
      gout->SetPoint(gout->GetN(), x, std::sqrt(y));
    }
    return gout;
  }
  
  TGraph *
  moving_average(TGraph *gin, int n = 2)
  {
    auto gout = new TGraph;
    for (int i = 0; i < gin->GetN() - n; ++i) {
      double x = 0.;
      double y = 0.;
      for (int j = i; j < i + n; ++j) {
	x += gin->GetX()[j];
	y += gin->GetY()[j];
      }
      x /= (double)n;
      y /= (double)n;
      gout->SetPoint(i, x, y);
    }
    return gout;
  }
  
}
