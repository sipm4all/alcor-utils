void
draw(const char *treefilename, const char *pngfilename,
     const char* varexp, const char* selection, Option_t* option = "profile")
{
  gStyle->SetOptStat(false);
  TFile f(treefilename);
  auto t = (TTree *)f.Get("tree");
  t->Draw(varexp, selection, option);
  gPad->SetLogy();
  gPad->SaveAs(pngfilename);
}
