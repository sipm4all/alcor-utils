#! /usr/bin/env python3
from matplotlib import pyplot as plt
import numpy as np
import sys

cdata = np.load('centers.npy')
fig, axes = plt.subplots(3, 4)

for i in range(3):
    for j in range(4):
        ch = i * 4 + j
        data = np.load('image.' + str(ch) + '.npy')
        if 'sdata' not in locals():
            sdata = data
        else:
            sdata += data
        axes[i, j].imshow(data)
        if np.isnan(cdata[1, ch]) or np.isnan(cdata[0, ch]):
            continue
        x = int(cdata[1, ch])
        y = int(cdata[0, ch])
        axes[i, j].plot(y, x, marker='s', color = 'red', markerfacecolor = 'none', markersize=10)

fig.tight_layout()

plt.figure()
plt.imshow(sdata)
plt.show()
