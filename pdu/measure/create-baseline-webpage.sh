#! /usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo " usage: $0 [run] "
    exit 1
fi
run=$1

basedir="$HOME/DATA/2023-testbeam/actual/baseline-scan"
index="$basedir/index.html"
echo $index

cat <<EOF > $index
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Baseline Gallery</title>
    <style>
        /* Add CSS styles for your gallery here */
        /* For example, you can control image size, spacing, etc. */
        .gallery {
            display: grid;
            grid-template-columns: repeat(2, 1fr); /* Adjust the number of columns as needed */
            gap: 10px; /* Adjust the spacing between images as needed */
        }

        .gallery img {
            max-width: 100%;
            height: auto;
            cursor: pointer;
        }

	@media print {
            .page-break {
                page-break-after: always;
            }

        }


    </style>
</head>
<body>
EOF

devices=$(awk '$1 !~ /^#/' /etc/drich/drich_readout.conf | awk {'print $4'} | sort | uniq | tr '\n' ' ')

for device in $devices; do

    chips=$(awk -v device="$device" '$1 !~ /^#/ && $4 == device' /etc/drich/drich_readout.conf | awk {'print $5, $6'} | tr '\n' ' ')

    echo "<div>" >> $index
    echo "<h1>$device (run $run)</h1>" >> $index
    echo "<div class=\"gallery\">" >> $index

    for chip in {0..5}; do
	image="$device/$run/scanthr.chip_$chip.eo.png"
	[ ! -f $basedir/$image ] && continue
	echo "<div>" >> $index
	echo "<h3 style=\"display: inline\">chip-$chip</h3> ($(date -r $basedir/$image))" >> $index
       	echo "<img src=\"$image\" alt=\"$device chip-$chip\">" >> $index
	echo "</div>" >> $index
    done
    
    echo "</div>" >> $index
    echo "</div>" >> $index
    echo "<div class="page-break"></div>" >> $index
    
done

echo "</body>" >> $index
echo "</html>" >> $index
