void
tree(const char *fname)
{
  TTree t;
  t.ReadFile(fname);
  TFile fout(Form("%s.root", fname), "RECREATE");
  t.Write("tree");
  fout.Close();
}
