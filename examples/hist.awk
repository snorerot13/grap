BEGIN { bzs; bw = 1e6 }
{ count [int(($3-bzs)/bw)]++ }
END { for (i in count) print i, count[i] }
