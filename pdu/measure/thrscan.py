#! /usr/bin/env python

import sys
import matplotlib.pyplot as plt

title=''
if len(sys.argv) > 0:
    title = sys.argv[1]

# Open the data file for reading
with open('/tmp/thrscan.dat', 'r') as file:
    # Read and store x and y values
    x_values, y_values = zip(*[map(float, line.split()) for line in file])

# Create a simple line plot
plt.semilogy(x_values, y_values, marker='o', linestyle='-')

# Add labels and a title
plt.xlabel('threshold (au)')
plt.ylabel('count rate (Hz)')
plt.title(title)

# Display the plot (or save it to a file using plt.savefig('output.png'))
plt.savefig('/tmp/thrscan.png')
