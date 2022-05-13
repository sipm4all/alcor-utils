#! /usr/bin/env bash

### prepare the data for the tree
echo "timestamp/D:tset/F:temp/F:rh/F" > /home/eic/DATA/memmert/memmert_tree.dat
grep -vh OK /home/eic/DATA/memmert/2022*.memmert_monitor.log | grep -vih err /home/eic/DATA/memmert/2022*.memmert_monitor.log >> /home/eic/DATA/memmert/memmert_tree.dat

### prepare directory for plots
mkdir -p /home/eic/DATA/memmert/PNG
mkdir -p /home/eic/DATA/memmert/ROOT

### 2 hours plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/memmert/draw_memmert.C(\"/home/eic/DATA/memmert/memmert_tree.dat\", 7200, -50., 100.)"
mv /home/eic/DATA/memmert/draw_memmert.png /home/eic/DATA/memmert/PNG/draw_memmert_2h.png
mv /home/eic/DATA/memmert/draw_memmert.root /home/eic/DATA/memmert/ROOT/draw_memmert_2h.root

### 8 hours plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/memmert/draw_memmert.C(\"/home/eic/DATA/memmert/memmert_tree.dat\", 28800, -50., 100.)"
mv /home/eic/DATA/memmert/draw_memmert.png /home/eic/DATA/memmert/PNG/draw_memmert_8h.png
mv /home/eic/DATA/memmert/draw_memmert.root /home/eic/DATA/memmert/ROOT/draw_memmert_8h.root

### 24 hours plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/memmert/draw_memmert.C(\"/home/eic/DATA/memmert/memmert_tree.dat\", 86400, -50., 100.)"
mv /home/eic/DATA/memmert/draw_memmert.png /home/eic/DATA/memmert/PNG/draw_memmert_24h.png
mv /home/eic/DATA/memmert/draw_memmert.root /home/eic/DATA/memmert/ROOT/draw_memmert_24h.root

### 1 week plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/memmert/draw_memmert.C(\"/home/eic/DATA/memmert/memmert_tree.dat\", 604800, -50., 100.)"
mv /home/eic/DATA/memmert/draw_memmert.png /home/eic/DATA/memmert/PNG/draw_memmert_1w.png
mv /home/eic/DATA/memmert/draw_memmert.root /home/eic/DATA/memmert/ROOT/draw_memmert_1w.root

### remove tree data
rm -rf /home/eic/DATA/memmert/memmert_tree.dat
