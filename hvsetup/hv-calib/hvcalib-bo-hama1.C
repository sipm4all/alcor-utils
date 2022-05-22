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
  5.7,
  9.57,
  19.15,
  28.73,
  38.3,
  47.87
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

