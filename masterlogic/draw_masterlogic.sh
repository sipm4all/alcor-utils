#! /usr/bin/env bash

if [ -x $1 ]; then
    echo "usage: draw_masterlogic.sh [masterlogic]"
    exit 1
fi

### prepare the data for the tree
echo "timestamp/D:temp/F" > /home/eic/DATA/masterlogic/masterlogic_tree_ml$1.dat
cat /home/eic/DATA/masterlogic/2022*.masterlogic_monitor_ml$1.log >> /home/eic/DATA/masterlogic/masterlogic_tree_ml$1.dat

### prepare directory for plots
mkdir -p /home/eic/DATA/masterlogic/PNG
mkdir -p /home/eic/DATA/masterlogic/ROOT

### 2 hours plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/masterlogic/draw_masterlogic.C(\"/home/eic/DATA/masterlogic/masterlogic_tree_ml$1.dat\", \"_ml$1\", 7200, -50., 100.)"
mv /home/eic/DATA/masterlogic/draw_masterlogic_ml$1.png /home/eic/DATA/masterlogic/PNG/draw_masterlogic_ml$1_2h.png
mv /home/eic/DATA/masterlogic/draw_masterlogic_ml$1.root /home/eic/DATA/masterlogic/ROOT/draw_masterlogic_ml$1_2h.root

### 8 hours plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/masterlogic/draw_masterlogic.C(\"/home/eic/DATA/masterlogic/masterlogic_tree_ml$1.dat\", \"_ml$1\", 28800, -50., 100.)"
mv /home/eic/DATA/masterlogic/draw_masterlogic_ml$1.png /home/eic/DATA/masterlogic/PNG/draw_masterlogic_ml$1_8h.png
mv /home/eic/DATA/masterlogic/draw_masterlogic_ml$1.root /home/eic/DATA/masterlogic/ROOT/draw_masterlogic_ml$1_8h.root

### 24 hours plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/masterlogic/draw_masterlogic.C(\"/home/eic/DATA/masterlogic/masterlogic_tree_ml$1.dat\", \"_ml$1\", 86400, -50., 100.)"
mv /home/eic/DATA/masterlogic/draw_masterlogic_ml$1.png /home/eic/DATA/masterlogic/PNG/draw_masterlogic_ml$1_24h.png
mv /home/eic/DATA/masterlogic/draw_masterlogic_ml$1.root /home/eic/DATA/masterlogic/ROOT/draw_masterlogic_ml$1_24h.root

### remove tree data
#rm -rf /home/eic/DATA/masterlogic/masterlogic_tree_ml$1.dat
