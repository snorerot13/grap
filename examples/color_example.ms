.EQ
delim $$
.EN
.PP
.KS
.PP
A gratuitous color graph.  Don't ever produce anything this ugly.  The
data is the 400m times used earlier.  There's a demonstration of 
.CW sprintf
in there, too.
.EQ
delim off
.EN
.DS
.ft CW
\&.G1
\&frame invis ht 2 wid 3 left solid color "blue" bot solid color "orange"
\&label left "Time (in seconds)" left .75
\&label bot "Olympic 400 Meter Run: Winning Times"
\&coord x 1894, 1994 y 42, 56
\&ticks left out at 44 , 46 "", 48, 50 "", 52, 54 ""
\&ticks bot in from 1900 to 1980 by 20
\&grid bot ticks off  color "yellow" from 1900 to 1980 by 20
\&grid left ticks off  color "yellow" at 44, 46, 48, 50, 52, 54 
\&draw solid color "green"
\&copy "400mpairs.d"
\&new dotted color "red"
\&copy "400wpairs.d"
\&"Women" size -3 at 1958,52
\&"Men" size -3 at 1910,47
\&sprintf("I say %g %5.3f%% %f %e",1,2,3,4.5) at 1940,50
\&.G2
.ft
.DE
.EQ
delim $$
.EN
.G1
frame invis ht 2 wid 3 left solid color "blue" bot solid color "orange"
label left "Time (in seconds)" left .75
label bot "Olympic 400 Meter Run: Winning Times"
coord x 1894, 1994 y 42, 56
ticks left out at 44 , 46 "", 48, 50 "", 52, 54 ""
ticks bot in from 1900 to 1980 by 20
grid bot ticks off  color "yellow" from 1900 to 1980 by 20
grid left ticks off  color "yellow" at 44, 46, 48, 50, 52, 54 
draw solid color "green" delta color "blue"
copy "400mpairs.d"
new dotted color "red"
copy "400wpairs.d"
"Women" size -3 at 1958,52
"Men" size -3 at 1910,47
sprintf("I say %g %5.3f%% %f %e",1,2,3,4.5) at 1940,50
.G2
.KE
