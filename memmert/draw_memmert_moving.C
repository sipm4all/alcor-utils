#include "style.C"

void
draw_memmert_moving(const char *fname, int t1 = -600, int t2 = 0)
{
  style();

  TTree t;
  t.ReadFile(fname);

  auto nev = t.GetEntries();
  t.GetEntry(nev - 1);
  int tsf = t.GetLeaf("timestamp")->GetValue();
  float tset = t.GetLeaf("tset")->GetValue();

  TH1F h("h", "", 2000, -100, 100);
  
  t.Project("h", Form("temp - %f", tset), Form("timestamp > %d && timestamp < %d", tsf + t1, tsf + t2));
  auto temp = h.GetMean();

  std::cout << " --- current set temperatue: " << tset << std::endl;
  std::cout << " --- average temerature: " << temp << std::endl;

}
