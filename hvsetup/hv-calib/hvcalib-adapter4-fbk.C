// HV in = 70 V
// adapter #4

// mV
float dac[] = {
  500,
  1039,
  1239,
  1299,
};

// V
float hv[] = {
  9.66,
  20.03,
  23.87,
  25.03
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

