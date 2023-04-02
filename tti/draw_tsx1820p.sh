#! /usr/bin/env bash

### prepare the data for the tree
echo "timestamp/D:vset/F:vout/F:iset/F:iout/F" > /home/eic/DATA/tsx1820p/tsx1820p_tree.dat
grep -vh OK /home/eic/DATA/tsx1820p/2022*.tsx1820p_monitor.log | grep -vih err /home/eic/DATA/tsx1820p/2022*.tsx1820p_monitor.log >> /home/eic/DATA/tsx1820p/tsx1820p_tree.dat

### prepare directory for plots
mkdir -p /home/eic/DATA/tsx1820p/PNG
mkdir -p /home/eic/DATA/tsx1820p/ROOT

### 2 hours plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/tti/draw_tsx1820p.C(\"/home/eic/DATA/tsx1820p/tsx1820p_tree.dat\", 7200)"
mv /home/eic/DATA/tsx1820p/draw_tsx1820p.png /home/eic/DATA/tsx1820p/PNG/draw_tsx1820p_2h.png
mv /home/eic/DATA/tsx1820p/draw_tsx1820p.root /home/eic/DATA/tsx1820p/ROOT/draw_tsx1820p_2h.root

### 8 hours plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/tti/draw_tsx1820p.C(\"/home/eic/DATA/tsx1820p/tsx1820p_tree.dat\", 28800)"
mv /home/eic/DATA/tsx1820p/draw_tsx1820p.png /home/eic/DATA/tsx1820p/PNG/draw_tsx1820p_8h.png
mv /home/eic/DATA/tsx1820p/draw_tsx1820p.root /home/eic/DATA/tsx1820p/ROOT/draw_tsx1820p_8h.root

### 24 hours plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/tti/draw_tsx1820p.C(\"/home/eic/DATA/tsx1820p/tsx1820p_tree.dat\", 86400)"
mv /home/eic/DATA/tsx1820p/draw_tsx1820p.png /home/eic/DATA/tsx1820p/PNG/draw_tsx1820p_24h.png
mv /home/eic/DATA/tsx1820p/draw_tsx1820p.root /home/eic/DATA/tsx1820p/ROOT/draw_tsx1820p_24h.root

### 1 week plot
/snap/bin/root -b -q -l "/home/eic/alcor/alcor-utils/tti/draw_tsx1820p.C(\"/home/eic/DATA/tsx1820p/tsx1820p_tree.dat\", 604800)"
mv /home/eic/DATA/tsx1820p/draw_tsx1820p.png /home/eic/DATA/tsx1820p/PNG/draw_tsx1820p_1w.png
mv /home/eic/DATA/tsx1820p/draw_tsx1820p.root /home/eic/DATA/tsx1820p/ROOT/draw_tsx1820p_1w.root

### remove tree data
rm -rf /home/eic/DATA/tsx1820p/tsx1820p_tree.dat
