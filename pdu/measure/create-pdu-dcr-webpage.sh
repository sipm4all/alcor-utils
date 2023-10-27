#! /usr/bin/env bash

basedir="$HOME/DATA/2023-testbeam/actual/dcr-scan"
index="$basedir/index-pdu.html"
echo $index

cat <<EOF > $index
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DCR Gallery</title>
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


pdus=$(awk '$1 !~ /^#/' /etc/drich/drich_readout.conf | awk {'print $1'} | sort | uniq | tr '\n' ' ')

for pdu in $pdus; do
    matrices=$(awk -v pdu="$pdu" '$1 !~ /^#/ && $1 == pdu' /etc/drich/drich_readout.conf | awk {'print $3'} | tr '\n' ' ')
    
    echo "<div>" >> $index
    echo "<h1>PDU $pdu</h1>" >> $index
    echo "<div class=\"gallery\">" >> $index

    for matrix in $matrices; do
	device=$(awk -v pdu="$pdu" -v matrix="$matrix" '$1 !~ /^#/ && $1 == pdu && $3 == matrix' /etc/drich/drich_readout.conf | awk {'print $4'})
	masterlogic=$(awk -v pdu="$pdu" -v matrix="$matrix" '$1 !~ /^#/ && $1 == pdu && $3 == matrix' /etc/drich/drich_readout.conf | awk {'print $7'})
	chips=$(awk -v pdu="$pdu" -v matrix="$matrix" '$1 !~ /^#/ && $1 == pdu && $3 == matrix' /etc/drich/drich_readout.conf | awk {'print $5, $6'})
	for chip in $chips; do
	    image=$(readlink -f "$basedir/$device/latest/s13-chip$chip/cthr.png")
	    [ -z $image ] && continue
	    relpath=${image#"$basedir/"}
	    [ ! -f $image ] && continue
	    echo "<div>" >> $index
	    echo "<h2 style=\"display: inline\">U$matrix</h2> $device chip-$chip masterlogic-$masterlogic</h3> ($(date -r $image))" >> $index
       	    echo "<img src=\"$relpath\" alt=\"$device chip-$chip\">" >> $index
	    echo "</div>" >> $index
	done
    done
    
    echo "</div>" >> $index
    echo "</div>" >> $index
    echo "<div class="page-break"></div>" >> $index
    
done

echo "</body>" >> $index
echo "</html>" >> $index
