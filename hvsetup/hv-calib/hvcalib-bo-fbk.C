// HV in = 70 V
// adapter #2

// mV
float dac[] = {
  300,
  500,
  1500
};

// V
float hv[] = {
  5.8,
  9.63,
  28.9
};

void
hvcalib(double target = 10., bool reverse = false)
{
  auto n = sizeof(dac) / 4;
  auto g = reverse ? new TGraph(n, dac, hv) : new TGraph(n, hv, dac);
  auto f = (TF1 *)gROOT->GetFunction("pol1");
  g->Fit(f);
  g->Draw("ap*");
  f->Draw("same");

  if (reverse) {
    std::cout << " --- DAC setting: " << target << std::endl;
    std::cout << " --- supplied voltage:    " << f->Eval(target) << std::endl;
  } else {
    std::cout << " --- target voltage: " << target << std::endl;
    std::cout << " --- DAC setting:    " << std::round(f->Eval(target)) << std::endl;
  }
  }

