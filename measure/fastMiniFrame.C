/**
   write some thinking here
 **/

#define FRAME_SIZE 8
#define MAXFRAMES 256
#define MAXDATA 1024

void
fastMiniFrame(const char *fnamein, const char *fnameout, bool verbose = true)
{
  auto fin = TFile::Open(fnamein);
  auto tin = (TTree *)fin->Get("alcor");

  struct data_t {
    int fifo;
    int type;
    int counter;
    int column;
    int pixel;
    int tdc;
    int rollover;
    int coarse;
    int fine;
  } data;
  tin->SetBranchAddress("fifo", &data.fifo);
  tin->SetBranchAddress("type", &data.type);
  tin->SetBranchAddress("counter", &data.counter);
  tin->SetBranchAddress("column", &data.column);
  tin->SetBranchAddress("pixel", &data.pixel);
  tin->SetBranchAddress("tdc", &data.tdc);
  tin->SetBranchAddress("rollover", &data.rollover);
  tin->SetBranchAddress("coarse", &data.coarse);
  tin->SetBranchAddress("fine", &data.fine);
  auto nev = tin->GetEntries();
  tin->GetEntry(0);
  
  auto fout = TFile::Open(fnameout, "RECREATE");
  auto tout = new TTree(Form("miniframe_%d", data.fifo), "miniframe");
  struct frame_data_t {
    int spill_id;
    int frame_id;
    int fifo;
    int n;
    int column[MAXDATA];
    int pixel[MAXDATA];
    int tdc[MAXDATA];
    int rollover[MAXDATA];
    int coarse[MAXDATA];
    int fine[MAXDATA];
  } frame;

  tout->Branch("spill_id", &frame.spill_id, "spill_id/I");
  tout->Branch("frame_id", &frame.frame_id, "frame_id/I");
  tout->Branch("fifo", &frame.fifo, "fifo/I");
  tout->Branch("n", &frame.n, "n/I");
  tout->Branch("column", &frame.column, "column[n]/I");
  tout->Branch("pixel", &frame.pixel, "pixel[n]/I");
  tout->Branch("tdc", &frame.tdc, "tdc[n]/I");
  tout->Branch("rollover", &frame.rollover, "rollover[n]/I");
  tout->Branch("coarse", &frame.coarse, "coarse[n]/I");
  tout->Branch("fine", &frame.fine, "fine[n]/I");

  bool in_spill = false;
  int current_frame = 0, current_fifo = 0;
  int spill_counter = 0;
  for (int iev = 0; iev < nev; ++iev) {
    tin->GetEntry(iev);

    // spill header
    if (data.type == 7) {
      std::cout << " spill header: " << spill_counter << std::endl;
      in_spill = true;
      current_fifo = data.fifo;
      // set current frame
      frame.spill_id = spill_counter;
      frame.frame_id = 0;
      frame.fifo = current_fifo;
      frame.n = 0;
      current_frame = 0;
      continue;
    }

    // must be in spill to do the following
    if (!in_spill) continue;
    
    // alcor hit / trigger
    if (data.type == 1 || data.type == 9) {
      int frame_id = data.rollover / FRAME_SIZE;

      // invalid frame id
      if (frame_id < current_frame) {
	std::cout << " [ERROR] invalid frame id" << std::endl;
	return;
      }

      // new frame id 
      else if (frame_id != current_frame) {
	// fill tree with current frame
	if (verbose) std::cout << " --- filling tree with frame #" << current_frame << ": " << frame.n << " entries" << std::endl;
	tout->Fill();
	// fill empty frames in between
	for (int iframe = current_frame + 1; iframe < frame_id; ++iframe) {
	  frame.spill_id = spill_counter;
	  frame.frame_id = iframe;
	  frame.fifo = current_fifo;
	  frame.n = 0;
	  if (verbose) std::cout << " --- filling tree with frame #" << iframe << ": " << frame.n << " entries" << std::endl;
	  tout->Fill();
	}
	// set current frame
	frame.spill_id = spill_counter;
	frame.frame_id = frame_id;
	frame.fifo = current_fifo;
	frame.n = 0;
	current_frame = frame_id;
      }
      
      if (frame_id >= MAXFRAMES) continue;
      auto n = frame.n;
      if (n == MAXDATA) {
        std::cout << " [WARNING] buffer overflow " << std::endl;
        continue;
      }
      frame.column[n] = data.column;
      frame.pixel[n] = data.pixel;
      frame.tdc[n] = data.tdc;
      frame.rollover[n] = data.rollover;
      frame.coarse[n] = data.coarse;
      frame.fine[n] = data.fine;
      frame.n++;
      continue;
    }

    if (data.type == 15 || data.type == 666) { // spill trailer
      std::cout << " spill trailer: " << data.coarse * 3.125e-09 + data.rollover * 102.4e-6 << " s " << std::endl;
      in_spill = false;
      // fill tree with current frame
      if (verbose) std::cout << " --- filling tree with frame #" << current_frame << ": " << frame.n << " entries" << std::endl;
      tout->Fill();
      // fill empty frames till end of spill
      for (int iframe = current_frame + 1; iframe < MAXFRAMES; ++iframe) {
	frame.spill_id = spill_counter;
	frame.frame_id = iframe;
	frame.fifo = current_fifo;
	frame.n = 0;
	if (verbose) std::cout << " --- filling tree with frame #" << iframe << ": " << frame.n << " entries" << std::endl;
	tout->Fill();
      }
      spill_counter++;      
    }
  }
  
  tout->Write();

}
