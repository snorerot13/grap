BEGIN {bzs = 0; bw=1e6 }
{ thisbin = int(($3-bzs)/bw); print $1, thisbin, count[thisbin]++ }
