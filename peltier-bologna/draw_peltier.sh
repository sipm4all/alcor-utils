#! /usr/bin/env bash

### prepare the data for the tree
echo "timestamp/D:vset/F:vout/F:iset/F:iout/F:temp0/F:temp1/F:temp2/F:temp3/F:tempin/F:rhin/F" > /home/eic/DATA/peltier/peltier_tree.dat
cat /home/eic/DATA/peltier/2022*.peltier_monitor.log >> /home/eic/DATA/peltier/peltier_tree.dat

### prepare directory for plots
mkdir -p /home/eic/DATA/peltier/PNG
mkdir -p /home/eic/DATA/peltier/ROOT

### 10 minutes plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/peltier-bologna/draw_peltier.C(\"/home/eic/DATA/peltier/peltier_tree.dat\", 600)"
mv /home/eic/DATA/peltier/draw_peltier.png /home/eic/DATA/peltier/PNG/draw_peltier_10m.png
mv /home/eic/DATA/peltier/draw_peltier.root /home/eic/DATA/peltier/ROOT/draw_peltier_10m.root

### 2 hours plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/peltier-bologna/draw_peltier.C(\"/home/eic/DATA/peltier/peltier_tree.dat\", 7200)"
mv /home/eic/DATA/peltier/draw_peltier.png /home/eic/DATA/peltier/PNG/draw_peltier_2h.png
mv /home/eic/DATA/peltier/draw_peltier.root /home/eic/DATA/peltier/ROOT/draw_peltier_2h.root

### 8 hours plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/peltier-bologna/draw_peltier.C(\"/home/eic/DATA/peltier/peltier_tree.dat\", 28800)"
mv /home/eic/DATA/peltier/draw_peltier.png /home/eic/DATA/peltier/PNG/draw_peltier_8h.png
mv /home/eic/DATA/peltier/draw_peltier.root /home/eic/DATA/peltier/ROOT/draw_peltier_8h.root

### 24 hours plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/peltier-bologna/draw_peltier.C(\"/home/eic/DATA/peltier/peltier_tree.dat\", 86400)"
mv /home/eic/DATA/peltier/draw_peltier.png /home/eic/DATA/peltier/PNG/draw_peltier_24h.png
mv /home/eic/DATA/peltier/draw_peltier.root /home/eic/DATA/peltier/ROOT/draw_peltier_24h.root

### 1 week plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/peltier-bologna/draw_peltier.C(\"/home/eic/DATA/peltier/peltier_tree.dat\", 604800)"
mv /home/eic/DATA/peltier/draw_peltier.png /home/eic/DATA/peltier/PNG/draw_peltier_1w.png
mv /home/eic/DATA/peltier/draw_peltier.root /home/eic/DATA/peltier/ROOT/draw_peltier_1w.root

### remove tree data
##rm -rf /home/eic/DATA/peltier/peltier_tree.dat
