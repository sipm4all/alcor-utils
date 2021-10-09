// HV in = 70 V
// adapter #2

// mV
float dac[] = {
  300,
  500,
  1000,
  1500,
  2000,
  2500
};

// V
float hv[] = {
  5.77,
  9.59,
  19.19,
  28.79,
  38.38,
  47.98
};

void
hvcalib(double target = 10.)
{
  auto n = sizeof(dac) / 4;
  auto g = new TGraph(n, hv, dac);
  auto f = (TF1 *)gROOT->GetFunction("pol1");
  g->Fit(f);
  g->Draw("ap*");
  f->Draw("same");

  std::cout << " --- target voltage: " << target << std::endl;
  std::cout << " --- DAC setting:    " << std::round(f->Eval(target)) << std::endl;
}

