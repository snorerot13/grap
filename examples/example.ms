.EQ
delim $$
.EN
.G1
copy "400mtimes.d"
.G2
.G1
copy "400mpairs.d"
.G2
.G1
draw solid
copy "400mpairs.d"
.G2
.G1
frame invis ht 2 wid 3 left solid bot solid
label left "Time (in seconds)" left .75
label bot "Olympic 400 Meter Run: Winning Times"
draw solid
copy "400mpairs.d"
.G2
.G1
.ft H
frame invis ht 2 wid 3 left solid bot solid
label left "Time (in seconds)" left .75
label bot "Olympic 400 Meter Run: Winning Times"
coord x 1894, 1994 y 42, 56
draw solid
copy "400mpairs.d"
.G2
.G1
frame invis ht 2 wid 3 left solid bot solid
label left "Time (in seconds)" left .75
label bot "Olympic 400 Meter Run: Winning Times"
coord x 1894, 1994 y 42, 56
ticks left out at 44 "44", 46, 48 "48", 50, 52 "52", 54
ticks bot in from 1900 to 1980 by 20
draw solid
copy "400mpairs.d"
.G2
.G1
copy "internet.d"
.G2
.G1
coord x 80,100 y 1e-4, 30 log y
ticks bot at 80 "1980", 100 "2000"
ticks bot from 85 to 95 by 5 "' %g"
ticks left 
label left "Millions of Hosts" left .75 
label bot "Year"
draw solid
copy "internet.d" thru { next at $1, $2/1e6; }
.G2
.G1
frame ht 2 wid 2
coord x 0,100 y 0,100
grid bot dotted from 20 to 80 by 20
grid left dotted from 20 to 80 by 20

"Text above" above at 50,50
"Text rjust   " rjust at 50,50
bullet at 80,90
vtick at 80,80
box at 80,70
times at 80,60

circle at 50,50
circle at 50,80 radius .25
line dashed from 10,90 to 30,90
arrow from 10,70 to 30,90

draw A solid
draw B dashed delta
next A at 10,10
next B at 10,20
next A at 50,20
next A at 90,10
next B at 50,30
next B at 90,30
.G2
.G1
frame ht 1.5 wid 1.5
define square {($1) * ($1)}
define root {($1)^.5 }
define P {
	"x" at i, square(i); i = i +1;
	circle at j, root(j); j= j+5;
}
i = 1; j = 5
P; P; P; P; P
.G2
.G1
frame invis ht 2 wid 3 left solid bot solid
label left "Time (in seconds)"
label bot "Olympic 400 Meter Run: Winning Times"
coord x 1894, 1994 y 42, 56
ticks left out at 44 , 46 "", 48, 50 "", 52, 54 ""
ticks bot in from 1900 to 1980 by 20
draw solid
copy until "END" thru {next at $1, $2;}
1896 54.2
1900 49.4
1904 49.2
1908 50
1912 48.2
1920 49.6
1924 47.6
1928 47.8
1932 46.2
1936 46.5
1948 46.2
1952 45.9
1956 46.7
1960 44.9
1964 45.1
1968 43.8
1972 44.66
1976 44.26
1980 44.60
1984 44.27
1988 43.87
1992 43.50
END
new dotted
copy until "END" thru {next at $1, $2;}
1964 52
1968 52
1972 51.08
1976 49.29
1980 48.88
1984 48.83
1988 48.95
1992 48.83
END
"Women"  size -3 at 1958,52
"Men" size -3 at 1910,47
.G2
.G1
label left "Representatives to Congress"
label bot "Poplation (Millions)"
coord x .3, 35 y .8, 60 log log
define PlotState { circle at $3/1e6, $2; }
copy "states.d" thru PlotState
.G2
.G1
define square {"\s-2\(sq\s0"}
frame ht 3 wid 3.5
label left "Population in Millions (Plotted as \(bu)"
label bot "Rank in Population"
label right "Representatives (Plotted as \(sq)"
coord pop x 0,51 y .2,35 log y
coord rep x 0,51 y .3,100 log y
ticks left out at pop .3,1,3,10,30
ticks bot out at pop 1,50
ticks right out at rep 1,3,10,30,100
thisrank = 50
copy "states.d" thru {
	bullet at pop thisrank,$3/1e6
	square at rep thisrank,$2
	thisrank = thisrank -1
}
.G2
.G1
frame ht 1 wid 3
draw solid
pi = atan2(0,-1)
for i from 0 to 2* pi by .1 do { next at i, sin(i); }
.G2
.G1
label left "Winning Time" left .8
label bot "Olympics Men's 400 m"
bestsofar = 1000
lastyear = 1896
copy "400mpairs.d" thru {
	bullet at $1,$2
	bestsofar = min(bestsofar,$2)
	line from $1,bestsofar to $1+4,bestsofar
}
.G2
.G1
graph Linear
coord x 1785, 1955 y 0, 160
label left "Population in Millions"
label right "Linear Scale" unaligned "Linear Fit" right .8
ticks bot off
copy "usapop.d"
define fit { 35 + 1.4 * ($1-1870) }
line from 1850, fit(1850) to 1950,fit(1950)
graph Exponential with .Frame.n at Linear.Frame.s - (0, .05)
coord x 1785, 1955 y 3, 160 log y
label left "Population in Millions"
label right "Logarithmic Scale" unaligned "Exponential Fit" right .8
copy "usapop.d"
define fit { exp(.75 + .012 * ($1-1800)) }
line from 1790, fit(1790) to 1920,fit(1920)
.G2
.G1
label left "Population in Millions"
label right "$x$ re-expressed as" unaligned "" "$space 0 left ( { date -1600 } over 100 right ) sup 7$" right 1.2
define newx { exp(7*(log(($1-1600)/100))) }
ticks bot out at newx(1800) "1800", newx(1850) "1850", \
	newx(1900) "1900"
copy "usapop.d" thru {
	if $1 <= 1900 then { bullet at newx($1),$2 }
}
.G2
.G1
copy "boyhts.d"
.G2
.G1
label left "Heights in Feet"
label bot "Heights of Boys in the US Ages 2-18"
cmpft = 12
minx = 1e12; maxx = -1e12
n = 0; sigx = 0; sigx2 = 0; sigy = 0; sigxy = 0;
copy "boyhts.d" thru {
	line from $1, $2/cmpft to $1, $4/cmpft
	ty = $3 / cmpft
	bullet at $1, ty
	n = n+1
	sigx = sigx + $1; sigx2 = sigx2 + $1 * $1
	sigy = sigy + ty; sigxy = sigxy + $1*ty
	minx = min(minx,$1); maxx = max(maxx,$1);
}
slope = ( n*sigxy - sigx* sigy) / (n*sigx2 - sigx * sigx)
inter = ( sigy - slope * sigx) / n
line from minx, slope * minx+inter to maxx, slope * maxx + inter
.G2
.G1
coord x 38, 95 y .8, 10000 log y
label bot "U.S. Military Personnel"
label left "Thousands"
draw of solid
draw ef dashed
draw om dotted
draw em solid
copy "army.d" thru {
	next of at $1, $3
	next ef at $1, $5
	next om at $1, $2
	next em at $1, $4
}
copy until "XXX" thru { "$1 $2" size -3 at 60, $3; }
Enlisted Men 1200
Male Officers 140
Enlisted Women 12
Female Officers 2.5
XXX
.G2
.G1
graph A 
frame ht 1.6667 wid 1.6667
label bot "Male_Officers"
label left "Enlisted_Men"
coord log log
ticks off
copy "army.d" thru { "\s-3$1\s+3" at $2,$4; }
graph A with .Frame.w at A.Frame.e +(.1,0)
frame ht 1.6667 wid 1.6667
label bot "Female_Officers"
coord log log
ticks off
copy "army.d" thru { "\s-3$1\s+3" at $3,$4; }
graph A with .Frame.w at A.Frame.e +(.1,0)
frame ht 1.6667 wid 1.6667
label bot "Enlisted_Womed"
coord log log
ticks off
copy "army.d" thru { "\s-3$1\s+3" at $5,$4; }
.G2
.G1
frame ht 2.5 wid 2.5
coord x 0,1 y 0,1
label bot "Direction Field is $y sup prime = x sup 2 / y$"
label left "$y = sqrt { ( 2 x sup 3 + 1 ) / 3 }$"
ticks left in 0 at 0,1
ticks bot in 0 at 0,1
len = .04
for tx from .01 to .91 by .1 do {
	for ty from .01 to .91 by .1 do {
		deriv = tx*tx/ty
		scale = len / sqrt(1 + deriv*deriv)
		line from tx,ty to tx+scale, ty+scale*deriv
	}
}
draw solid
for tx from 0 to 1 by .05 do {
	next at tx, sqrt((2*tx*tx*tx+1)/3)
}
.G2
.G1
frame wid 5 ht 4
label left "Rank in Population"
label bot "Population (in Millions)"
label top "$log sub 2$ Population"
coord x .3, 35 y 0, 51 log x
define L { (2.0^$1)/1e6 "$1" }
ticks bot out at .5, 1, 2, 5, 10, 20
ticks left out from 10 to 50 by 10
ticks top out at L(19), L(20), L(21), L(22), L(23), L(24), L(25)
thisy = 50
copy "states.d" thru {
	"$1" size -4 at $3/1e6, thisy
	thisy = thisy-1
}
line dotted from 15.3,1 to .515, 50
.G2
.G1
frame invis ht .3 wid 5 bottom solid
label bot "Populations (in Millions) of the 50 States"
coord x .3, 35 y 0, 1 log x
ticks bot out at .5, 1, 2, 5, 10, 20
ticks left off
copy "states.d" thru { vtick at $3/1e6, .5; }
.G2
.G1
frame invis ht 1 wid 5 bottom solid
label bot "Populations (in Millions) of the 50 States"
coord x .3, 35 y 0, 1000 log x
ticks bot out at .5, 1, 2, 5, 10, 20
ticks left off
copy "states.d" thru { "$1" size -4 at $3/1e6, 100+900*rand(); }
.G2
.G1
frame invis bot solid
label bot "Populations (in Millions) of the 50 States"
label left "Number of States"
ticks bot out from 0 to 30 by 5
coord x 0, 35 y 0, 13
copy "states2.d" thru {
	line from $1,0 to $1,$2
	line from $1, $2 to $1+1, $2
	line from $1+1,$2 to $1+1,0
}
.G2
.G1
frame invis bot solid
label bot "Populations (in Millions) of the 50 States"
label left "Number of States"
ticks bot out from 0 to 35 by 5
coord x 0, 35 y 0, 13
copy "states2.d" thru {
	line dotted from $1+.5,0 to $1+.5,$2
	"\(bu" size +3 at $1+.5, $2
}
.G2
.G1
frame invis wid 4 ht 2.5 bot solid
label bot "Populations (in Millions) of the 50 States"
ticks bot out from 0 to 35 by 5
ticks left off
coord x 0, 35 y 0, 13
copy "states3.d" thru {"$1" size -4 at $2+.5, $3+.5; }
.G2
.G1
ticks left off
cury = 0
barht = .7
copy "prof2.d" thru {
	line from 0,cury to $1, cury
	line from $1, cury to $1, cury-barht
	line from 0, cury-barht to $1, cury-barht
	"  $2" ljust at 0, cury-barht/2
	cury = cury-1
}
line from 0,0 to 0,cury+1-barht
bars = -cury
frame invis ht bars/3 wid 3
.G2
.G1
frame invis ht 4 wid 3 bot solid
ticks off
coord x .5, 3.5 y 0,25
define Ht { "- $1,000 -" size -3 at 2, $1 }
Ht(5); Ht(10); Ht(15); Ht(20);
"Highest Point" "in 50 States" at 1,23
"Heights of" "219 Volcanoes" at 3,23
"Feet" at 2,21.5; arrow from 2,22.5 to 2,24
define box {
	xc = $1; xl = xc - boxwidth/2; xh = xc+boxwidth/2
	y1 = $2; y2 = $3; y3 = $4; y4= $5; y5 = $6
	bullet at xc,y1
	"  $7" size -3 ljust at xc, y1
	line from (xc,y1) to (xc,y2)
	line from (xl,y2) to (xh,y2)
	line from (xl,y3) to (xh,y3)
	line from (xl,y4) to (xh,y4)
	line from (xl,y2) to (xl,y4)
	line from (xh,y2) to (xh,y4)
	line from (xc,y4) to (xc,y5)
	bullet at xc,y5
	"  $8" ljust size -3  at (xc,y5)
}
boxwidth = .3
box(1, .3, 2.0, 4.6, 11.2,20.3, Florida, Alaska)
box(3,.2, 3.7, 6.5, 9.5, 19.9, Ilhanova, Guallatiri)
.G2
.ps 14
.vs 18
.G1 4
frame ht 2 wid 2
label left "Response Variable" left .65
label bot "Factor Variable" down .5
line from 0,0 to 1,1
line dotted from .5,0 to .5,1
define blob X "\v'.1m'\(bu\v'-.1m'" X
blob at 0,.5; blob at .5, .5; blob at 1,.5
.G2
.ps 10
.vs 12
.G1
frame invis ht 2 wid 3 left solid color "blue" bot solid color "orange"
label left "Time (in seconds)" left .75
label bot "Olympic 400 Meter Run: Winning Times"
coord x 1894, 1994 y 42, 56
ticks left out at 44 , 46 "", 48, 50 "", 52, 54 ""
ticks bot in from 1900 to 1980 by 20
grid bot ticks off  color "yellow" from 1900 to 1980 by 20
grid left ticks off  color "yellow" at 44, 46, 48, 50, 52, 54 
draw solid color "green"
copy "400mpairs.d"
new dotted color "red"
copy "400wpairs.d"
"Women" size -3 at 1958,52
"Men" size -3 at 1910,47
.G2
