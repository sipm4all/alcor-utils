// HV in = 70 V
// adapter #5
// mV
float dac[] = {
  500,
  1000,
  1717,
  2060
};

// V
float hv[] = {
  7.28,
  14.56,
  25.00,
  30.00
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

