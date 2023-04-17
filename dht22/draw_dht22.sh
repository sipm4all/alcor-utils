#! /usr/bin/env bash

### prepare the data for the tree
echo "timestamp/D:temp/F:rh/F" > /home/eic/DATA/dht22/dht22_tree.dat
grep -vh OK /home/eic/DATA/dht22/2023*.dht22_monitor.log | grep -vih err /home/eic/DATA/dht22/2023*.dht22_monitor.log >> /home/eic/DATA/dht22/dht22_tree.dat

### prepare directory for plots
mkdir -p /home/eic/DATA/dht22/PNG
mkdir -p /home/eic/DATAdht22/ROOT

### 2 hours plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/dht22/draw_dht22.C(\"/home/eic/DATA/dht22/dht22_tree.dat\", 7200, 0., 50.)"
mv /home/eic/DATA/dht22/draw_dht22.png /home/eic/DATA/dht22/PNG/draw_dht22_2h.png
mv /home/eic/DATA/dht22/draw_dht22.root /home/eic/DATA/dht22/ROOT/draw_dht22_2h.root

### 8 hours plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/dht22/draw_dht22.C(\"/home/eic/DATA/dht22/dht22_tree.dat\", 28800, 0., 50.)"
mv /home/eic/DATA/dht22/draw_dht22.png /home/eic/DATA/dht22/PNG/draw_dht22_8h.png
mv /home/eic/DATA/dht22/draw_dht22.root /home/eic/DATA/dht22/ROOT/draw_dht22_8h.root

### 24 hours plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/dht22/draw_dht22.C(\"/home/eic/DATA/dht22/dht22_tree.dat\", 86400, 0., 50.)"
mv /home/eic/DATA/dht22/draw_dht22.png /home/eic/DATA/dht22/PNG/draw_dht22_24h.png
mv /home/eic/DATA/dht22/draw_dht22.root /home/eic/DATA/dht22/ROOT/draw_dht22_24h.root

### 1 week plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/dht22/draw_dht22.C(\"/home/eic/DATA/dht22/dht22_tree.dat\", 604800, 0., 50.)"
mv /home/eic/DATA/dht22/draw_dht22.png /home/eic/DATA/dht22/PNG/draw_dht22_1w.png
mv /home/eic/DATA/dht22/draw_dht22.root /home/eic/DATA/dht22/ROOT/draw_dht22_1w.root

### remove tree data
rm -rf /home/eic/DATA/dht22/dht22_tree.dat
