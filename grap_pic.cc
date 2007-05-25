#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#include <stdio.h>
#include <iostream>
#include <math.h>
#include <stdexcept>
#include "grap.h"
#include "grap_data.h"
#include "grap_draw.h"
#include "grap_pic.h"

// This file is (c) 1998-2001 Ted Faber (faber@lunabase.org) see COPYRIGHT
// for the full copyright and limitations of liabilities.

// Convert the abstract types to Pictypes and draw them.  These are
// called from for_each.  These are declared outside the pic classes
// to keep g++ 2.7.3 happy.
template <class FROM, class TO>
class draw_f :
    public unary_function<FROM *, int> {
    frame *f;
public:
    draw_f(frame *fr) : f(fr) { }
    int operator()(FROM *ds) {
	TO p(*ds);
	p.draw(f);
	return 0;
    }
};

// Simpler declarations
typedef draw_f<DisplayString, PicDisplayString> draw_string_f;
typedef draw_f<tick, Pictick> draw_tick_f;
typedef draw_f<grid, Picgrid> draw_grid_f;

// A little helper function - tells if a DisplayString * points to a string
// with the clipped attribute.  In an anonymous namespace so no one else has to
// see it.
namespace {
    bool clipped(DisplayString *d) { return d->clip; }
}

extern bool compat_mode;

void Picgraph::init(string *n /* =0 */, string* p /* =0 */ ) {
    // Start a new graph, but maybe not a new block.
    
    if ( frame_queued ) base = 0;
    graph::init(n, p);	// clear the base classes parameters

    if ( !base ) 
	base = pframe = new Picframe;
    if ( p ) pos = new string(*p);
    frame_queued = false;
}
	
void Picgraph::draw(frame *) {
    // Do the work of drawing the current graph.
    displayer_f displayer(pframe); 	// Call draw on the object.  This is
                                        // an embedded class of graph.
    if ( visible ) {
	if ( !graphs++ ) {
	    cout << ".PS";
	    if (ps_param ) {
		cout << *ps_param;
		delete ps_param;
		ps_param = 0;
	    }
	    cout << endl;
	}

	// if we have a name, use it
	if ( name ) 
	    cout << *name << ": ";

	// The graph itself
	cout << "[" << endl;

	for_each(coords.begin(), coords.end(), addmargin);
	// put out the xy_gg mpic macros
	for (coordinateDictionary::iterator ci = coords.begin();
	     ci != coords.end();
	     ci++) {
	    Piccoord pc(*(*ci).second);
	    displayer(&pc);
	}
	for_each(objs.begin(), objs.end(), displayer);
	cout << "]";

	    // Positioning info relative to another graph in this block
	if ( pos ) {
	    cout << " " << *pos << endl;
	    delete pos;
	    pos = 0;
	}
	else cout << endl;

    }

}


void PicDisplayString::draw(frame *) {
// Draw a display string.  Basically just a straight translation into
// pic/troff idioms.

    cout << '"';
    if ( size ) {
	if ( relsz ) {
	    char relchar = ( size > 0 ) ? '+' : '-';
	    size = fabs(size);
	    if ( compat_mode ) {
		cout << "\\s" << relchar;
		cout << ((size > 9) ? "(" : "") << size;
	    }
	    else {
		cout << "\\s[" << relchar << size << "]";
	    }
	}
	else {
	    // double digit size changes need the ( using classic troff.  Groff
	    // allows a general [] syntax, that we use if available ).
	    if ( compat_mode ) 
		cout << "\\s" << ((size > 9) ? "(" : "") << size;
	    else
		cout << "\\s[" << size << "]";
	}
    }
    if ( color && !compat_mode ) {
	unquote(color);
	cout << "\\m[" << *color << "]";
    }
    
    unquote(this);
    cout << *(string*)this;

    if ( color && !compat_mode ) cout << "\\m[]";
    if ( size ) cout << "\\s" << 0 ;
    cout << "\" ";

    if ( j & (int) ljust ) cout << "ljust ";
    if ( j & (int) rjust ) cout << "rjust ";
    if ( j & (int) above ) cout << "above ";
    if ( j & (int) below ) cout << "below ";
    if ( j & (int) aligned ) cout << "aligned ";
}


void Picframe::frame_line(double x2, double y2, sides s) {
// straightforward line drawing of one frame line

    switch (s) {
	case left_side:
	    cout << "Left: ";
	    break;
	case right_side:
	    cout << "Right: ";
	    break;
	case top_side:
	    cout << "Top: ";
	    break;
	case bottom_side:
	    cout << "Bottom: ";
	    break;
    }
    cout << "line ";
    switch (desc[s].ld) {
	case invis:
	    cout << "invis ";
	    break;
	case solid:
	default:
	    break;
	case dotted:
	    cout << "dotted ";
	    if ( desc[s].param )
		cout << desc[s].param << " ";
	    break;
	case dashed:
	    cout << "dashed ";
	    if ( desc[s].param )
		cout << desc[s].param << " ";
	    break;
    }
    if ( !compat_mode ) { 
	if ( desc[s].color ) cout << " color " << *desc[s].color << " " ;
	if ( desc[s].thick ) cout << " thickness " << desc[s].thick << " " ;
    }
    cout << "right " << x2 << " up " << y2 << endl;
}

void Picframe::label_line(sides s) {
// Label a graph side.  We rely heavily on pic tricks here.  The C++
// is straightforward.

    // Functor to convert a DisplayString to a PicdisplayString and print it
    draw_string_f draw_string(this);
    double dx, dy; // Used to place the alignment line relative to the axis
    shiftlist::const_iterator csi;

    switch (s) {
	case left_side:
	    dx = -0.4; dy = 0;
	    break;
	case right_side:
	    dx = 0.4; dy = 0;
	    break;
	case top_side:
	    dx = 0; dy = 0.4;
	    break;
	case bottom_side:
	    dx = 0; dy = -0.4;
	    break;
	default: // to keep the compiler quiet
	    dx = dy = 0;
	    break;
    }

    for (csi = lshift[s]->begin(); csi != lshift[s]->end(); csi++) {
	switch ((*csi)->dir) {
	    case left_side:
		dx -= (*csi)->param;
		break;
	    case right_side:
		dx += (*csi)->param;
		break;
	    case top_side:
		dy += (*csi)->param;
		break;
	    case bottom_side:
		dy -= (*csi)->param;
		break;
	}
    }

    // DWB grap did not put the whitespace around for unlabelled sizes of the
    // graph, so omit that space if in compatibility mode.
    if ( compat_mode && label[s]->empty() ) return;
    cout << "line invis ";

    // draw all the labels
    for_each(label[s]->begin(), label[s]->end(), draw_string);

    switch (s) {
	case left_side:
	    cout << "from Frame.Left.start + (" << dx << ", " << dy << ") " ;
	    cout << "to Frame.Left.end + (" << dx << ", " << dy << ") " ;
	    break;
	case right_side:
	    cout << "from Frame.Right.start + (" << dx << ", " << dy << ") " ;
	    cout << "to Frame.Right.end + (" << dx <<  ", " << dy << ") " ;
	    break;
	case bottom_side:
	    cout << "from Frame.Bottom.end + (" << dx <<  ", " << dy << ") " ;
	    cout << "to Frame.Bottom.start + (" << dx <<  ", " << dy << ") " ;
	    break;
	case top_side:
	    cout << "from Frame.Top.start + (" << dx <<  ", " << dy << ") " ;
	    cout << "to Frame.Top.end + (" << dx << ", " << dy << ") " ;
	    break;
	default:
	    break;
    }
    cout << endl;
}

void Picframe::autoguess(sides sd, double &idx, double& dir, double& lim,
			 double &ts, int& ls, coord *c) {
// Calculate a reasonable placement of tickmarks if the user has not
// specified one.  We aim for 5.  The algorithm is heuristic.
    
    double lo, hi;	// Low and high tickmarks
    double range;	// the range of the coordinate system

    // determine the range of the axes
    
    if ( sd == bottom_side || sd == top_side ) {
	lo = c->xmin;
	hi = c->xmax;
	ls = (c->logscale & x_axis);
    } else {
	lo = c->ymin;
	hi = c->ymax;
	ls = (c->logscale & y_axis);
    }

    // Make our ticksize guess
    if ( !ls ) {
	range = fabs(hi - lo);
	
	ts = pow(10,floor(log10(range)));
	while ( range/ts > 4 ) ts *= 2;
	while ( range/ts < 3 ) ts /=2;
	idx = ts * ceil(lo/ts);
    } else {
	idx = pow(10,floor(log10(lo)));
    }

    // On machines with signed 0 representations, this ensures that
    // tickmarks have a 0 label (not a -0).  See math(3).

    if ( idx == -0.0 ) idx = 0.0;
    
    // Are ticks increasing or decreasing?
    if ( hi - lo < 0 ) dir = -1;
    else dir = 1;

    lim = hi;
}


void Picframe::addautoticks(sides sd) {
// Place ticks in accordance with the parameters returned by autoguess
    double ts;		// The tick size (for linear axes)
    double dir, idx;	// The direction of ticks and an index value
    double hi;		// the tick limit
    int ls;		// is this a logscale axis?
    tick *t;		// Temporary tick value

    if ( tickdef[sd].size == 0 ) return;

    autoguess(sd, idx, dir, hi, ts, ls, tickdef[sd].c);

    // This changed to match the code in grap_parse (all the computations on
    // one side of the comparison)
    while ( (idx - hi)* dir < epsilon ) {
	t = new tick(idx,tickdef[sd].size,sd,0, &tickdef[sd].shift,
		     tickdef[sd].c);
	if ( tickdef[sd].prt)
	    t->prt = new DisplayString(idx,tickdef[sd].prt);
	    //t->prt = dblString(idx,tickdef[sd].prt);
	tks.push_back(t);
	if ( ls ) idx *= 10;
	else idx += ts;
    }
}
    
void Picframe::addautogrids(sides sd) {
// Place grids in accordance with the parameters returned by autoguess
    double ts;
    double dir, idx;
    double hi;
    int ls;
    grid *g;

    if ( griddef[sd].desc.ld == def ) return;

    autoguess(sd, idx, dir, hi, ts, ls, griddef[sd].c);

    while ( (idx - hi)*dir < epsilon ) {
	g = new grid(idx,&griddef[sd].desc,sd,0,
		     &griddef[sd].shift, griddef[sd].c);
	if ( griddef[sd].prt)
	    // g->prt = dblString(idx,griddef[sd].prt);
	    g->prt = new DisplayString(idx,griddef[sd].prt);
	gds.push_back(g);
	if ( ls ) idx *= 10;
	else idx += ts;
    }
}    

void Picframe::draw(frame *) {
// Draw the frame.  Autotick if necessary and draw the axes and
// tickmarks.  Straightforward application of the helpers above.  The
// result is a frame that is labelled for pic placement of other
// graphs in the same block.
    
    // functors to draw ticks and grids out of the lists.  

    draw_tick_f draw_tick(this);
    draw_grid_f draw_grid(this);

    cout << "Frame: [" << endl;
    cout << "Origin: " << endl;
    frame_line(0,ht,left_side);
    frame_line(wid,0,top_side);
    frame_line(0,-ht,right_side);
    frame_line(-wid,0,bottom_side);
    cout << "]" << endl;

    for ( int i = 0; i < 4 ; i++ ) {
	if ( label[(sides)i] )
	    label_line((sides)i);
	addautoticks((sides)i);
	addautogrids((sides)i);
    }

    for_each(tks.begin(), tks.end(), draw_tick);
    for_each(gds.begin(), gds.end(), draw_grid);
}

bool Piclinesegment::clipx(double& x1, double& y1, double& x2, double& y2) {
// Clip the line to x = 0 and x = 1.  We use the parametric
// representation of the line for simplicity of calculation.  This
// gets called with the coordinates reversed to do the y-axis clip.

    // the line is p + tv where x1, y1 is t==0 and x2, y2 is t==1

    double px = x1;		// Point coordinate
    double py = y1;		// Point coordinate
    double vx = x2 - x1;	// vector component
    double vy = y2 - y1;	// vector component
    double t;			// The parameter


    // The line is parallel to the x axis.  It's either all valid or
    // all invalid.  We use epsilon again here to be conservative.
    if ( vx > -epsilon && vx < epsilon )
	if ( inbox(px) ) return true;
	else return false;

    // Do the x = 0 intercept

    t = -px / vx;

    // The semantics of inbox here mean that the line has been
    // clipped.  The intersection with x = 0 is between x1, y1 (t==0)
    // and x2, y2 (t==1).
    if ( inbox(t) ) {
	// This is the zero intercept, and one point has been clipped,
	// so if the first hasn't been clipped, the second must have.
	// We recalculate the parametric representation so we can
	// repeat the clip for x == 1.  We use epsilon here because we have to
	// use it by definition in the t==1 half.
	if ( px < epsilon ) {
	    x1 = px + t * vx;
	    y1 = py + t * vy;
	    px = x1;
	    py = y1;
	}
	else {
	    x2 = px + t * vx;
	    y2 = py + t * vy;
	}
	vx = x2 - x1;
	vy = y2 - y1;
    }
    // repeat for 1

    t = (1 - px) / vx;
	    
    // The semantics of inbox here mean that the line has been
    // clipped.
    if ( inbox(t) ) {
	// This is the 1 intercept, and one point has been clipped,
	// so if the first hasn't been clipped, the second must have.
	if ( px > 1 - epsilon ) {
	    x1 = px + t * vx;
	    y1 = py + t * vy;
	}
	else {
	    x2 = px + t * vx;
	    y2 = py + t * vy;
	}
    }
    // If both x points are clipped to inside the box, we have a line,
    // otherwise, the whole line is invalid.
    return inbox(x1) && inbox(x2);
}    
    
bool Piclinesegment::clip(double& x1, double& y1, double& x2, double& y2) {
// If all 4 points are in the frame, return true.  If not call
// clip twice to clip the lines, and return true only if both
// clips return valid lines.  There is a little sleight of hand
// there: the && guarantees that we only keep clipping while there
// is a line to clip.

    if ( inbox(x1) && inbox(x2) && inbox(y1) && inbox(y2) ) return true;
    else return clipx(x1, y1, x2, y2) && clipx(y1, x1, y2, x2);
}

void Piclinesegment::draw(frame *f) {
// Draw this line segment.  Clip the line segment according to the
// point's coordinates, then put them into the graph.  There are some
// details to laying out the styles and poltting strings correctly.
    double lastx, lasty;		// The last point plotted (if any)
    double x,y;				// The current point's coordinates
    double lastcx, lastcy;		// The last point plotted post clipping
    double cx,cy;			// The current point post clipping

    try {
	x = to.c->map(to.x,x_axis);
	y = to.c->map(to.y,y_axis);
    }
    catch (range_error &e) {
	cerr << "Unable to map point: (" << to.x << ", " << to.y 
	     << ") : " << e.what() << endl;
	return;
    }

    if ( from ) {
	try { 
	    lastcx = from->c->map(from->x, x_axis);
	    lastcy = from->c->map(from->y, y_axis);
	}
	catch (range_error &e) {
	    cerr << "Unable to map point: (" << to.x << ", " << to.y 
		 << ") : " << e.what() << endl;
	    return;
	}
    }
    else {
	lastx = lasty = 0.0;
    }
	
    cx = x;
    cy = y;
    if ( !from || clip(lastcx, lastcy, cx, cy) ) {
	// If clipping has left us a (partial) line to draw, do
	// so.  This also is invoked on the first point of a line.
	    
	if ( !from ) {
	    if ( inbox(x) && inbox(y) )
		cout << "move to Frame.Origin + (" << x * f->wid << ", "
		     << y * f->ht << ")" << endl;
	}
	else {
	    // Chop off the arrowhead if the line is clipped
	    if ( arrow && inbox(x) && inbox(y) ) cout << "arrow ";
	    else cout << "line ";
	    switch (desc.ld) {
		case invis:
		    cout << "invis ";
		    break;
		case solid:
		default:
		    break;
		case dotted:
		    cout << "dotted ";
		    if ( desc.param ) cout << desc.param << " ";
		    break;
		case dashed:
		    cout << "dashed ";
		    if ( desc.param ) cout << desc.param << " ";
		    break;
	    }
	    if ( !compat_mode ) {
		if ( desc.color ) cout << " color " << *desc.color << " " ;
		if ( desc.thick ) cout << " thickness " << desc.thick << " " ;
	    }
	    cout << "from Frame.Origin + (" << lastcx * f->wid << ", "
		 << lastcy * f->ht << ") ";
	    cout << "to Frame.Origin + (" << cx * f->wid << ", "
		 << cy * f->ht << ")" << endl;
	}
	// if a plot string has been specified and the point has
	// not been clipped, put the plotstring out.
	if ( plotstr && inbox(x) && inbox(y) ) {
	    PicDisplayString pstr(*plotstr);
	    pstr.draw(f);
	    if ( !from ) 
		cout << " at Frame.Origin + (" << x * f->wid << ", "
		     << y * f->ht << ")" << endl;
	    else cout << " at last line.end" << endl;
	}
    }
}

void Pictick::draw(frame *f) {
// Actually draw a tick mark.  Map it into the appropriate coordinate
// space and draw and label the line.  The translation from data
// structure to pic is straightforward.
    
    double a,b;	    // x and y offsets from the origin
    string dir;	    // Direction of the tick mark
    string just;    // placement of the label relative to the end of the tick
    Picshiftdraw sd(cout); // Functor to put out multiple tick shifts

    try {
	switch (side) {
	    default:
	    case left_side:
		a = 0;
		b = c->map(where,y_axis);
		dir = "left";
		just = "rjust";
		break;
	    case right_side:
		a = 1;
		b = c->map(where,y_axis);
		dir = "right";
		just = "ljust";
		break;
	    case top_side:
		a = c->map(where,x_axis);
		b = 1;
		dir = "up";
		just = "above";
		break;
	    case bottom_side:
		a  = c->map(where,x_axis);
		b = 0;
		dir = "down";
		just = "below";
		break;
	}
    }
    catch (range_error& e) {
	cerr << "failed to map tick value: " << where << ": " 
	     << e.what() << endl;
	return;
    }
    // epsilons for floating point weirdness
    if ( a < -epsilon || a > 1+epsilon ) return;
    else a *= f->wid;
    if ( b < -epsilon || b > 1+epsilon ) return;
    else b *= f->ht;
    cout << "line from Frame.Origin + (" << a << ", " << b;
    cout << ") then " << dir << " ";
    cout << size << endl;
    if ( prt ) {
	double dist;
	if ( size > 0 ) dist = 1.2 * size;
	else dist = 0;
	
	cout << "move from Frame.Origin + (" << a << ", " << b;
	cout << ") then " << dir << " ";
	cout << dist << endl;

	for_each(shift.begin(), shift.end(), sd);

	quote(prt);
	PicDisplayString pprt(*prt);
	pprt.draw(f);
	cout << " " << just << " at Here" << endl;
    }
}
    
void Picgrid::draw(frame *f) {
// Draw a grid line.  As usual very similar to a tick.
    double a,b;
    double len;
    string dir;
    Picshiftdraw sd(cout); // Functor to put out multiple tick shifts

    try { 
	switch (side) {
	    default:
	    case left_side:
		a = 0;
		b = c->map(where,y_axis);
		dir = "right";
		len = f->wid;
		break;
	    case right_side:
		a = 1;
		b = c->map(where,y_axis);
		dir = "left";
		len = f->wid;
		break;
	    case top_side:
		a = c->map(where,x_axis);
		b = 1;
		dir = "down";
		len = f->ht;
		break;
	    case bottom_side:
		a  = c->map(where,x_axis);
		b = 0;
		dir = "up";
		len = f->ht;
		break;
	}
    }
    catch (range_error& e) {
	cerr << "failed to map grid value: " << where << ": " 
	     << e.what() << endl;
	return;
    }
    if ( a < 0 || a > 1 ) return;
    else a *= f->wid;
    if ( b < 0 || b > 1 ) return;
    else b *= f->ht;
    cout << "line ";
    switch (desc.ld) {
	case invis:
	    cout << "invis ";
	    break;
	case solid:
	default:
	    break;
	case dotted:
	    cout << "dotted ";
	    if ( desc.param )
		cout << desc.param << " ";
	    break;
	case dashed:
	    cout << "dashed ";
	    if ( desc.param )
		cout << desc.param << " ";
	    break;
    }
    if ( !compat_mode ) {
	if ( desc.color ) cout << " color " << *desc.color << " ";
	if ( desc.thick ) cout << " thickness " << desc.thick << " ";
    }
    cout << "from Frame.Origin + (" << a << ", " << b;
    cout << ") then " << dir << " ";
    cout << len << endl;
    if ( prt ) {
	cout << "move from Frame.Origin + (" << a << ", " << b;
	cout << ") then " << dir << " ";
	cout << -0.125 << endl;

	for_each(shift.begin(), shift.end(), sd);

	quote(prt);
	PicDisplayString pprt(*prt);
	pprt.draw(f);
	cout << " at Here" << endl;
    }
}
    
void Piccircle::draw(frame *f) {
// Plot a circle.  Strightforward.
    double x,y;	// To transform the point into device coordinates

    try {
	x = center.c->map(center.x,x_axis);
	y = center.c->map(center.y,y_axis);
    }
    catch (range_error& e) {
	cerr << "Unable to map circle at (" << center.x << ", " 
	     << center.y << ") into " << "log coordinates: " 
	     << e.what() << endl;
	return;
    }
   
    // Again, epsilon is correct because it's needed for the 1+ and symmetry.
    if ( x > 1+epsilon || x < 0-epsilon ) {
	cerr << "Circle outside coordinates:" << center.x << ", ";
	cerr << center.y << endl;
	return;
    }
    if ( y > 1+epsilon || y < 0-epsilon ) {
	cerr << "Circle outside coordinates:" << center.x << ", ";
	cerr << center.y << endl;
	return;
    }
    x *= f->wid;
    y *= f->ht;
    cout << "circle at Frame.Origin + (" << x << ", " << y << ")";
    cout << " rad " << rad ;
    switch (ld.ld) {
	case invis:
	    cout << " invis ";
	    break;
	case solid:
	default:
	    break;
	case dotted:
	    cout << " dotted ";
	    if ( ld.param )
		cout << ld.param << " ";
	    break;
	case dashed:
	    cout << " dashed ";
	    if ( ld.param )
		cout << ld.param << " ";
	    break;
    }
    if ( !compat_mode ) {
	if ( ld.fillcolor ) {
	    // fillcolor takes precedence over fill - if fillcolor is not
	    // null, we draw one box filled with that color, and then a
	    // second unfilled one in color (black is none specified)

	    ld.fill = 0;
	    cout << " shaded " << *ld.fillcolor << " ";
	}	

	// Draw the circle with appropriate line style, fill, and color
	if ( ld.color ) cout << " outline " << *ld.color << " ";
	if ( ld.thick ) cout << " thick " << ld.thick << " " ;
    }

    if ( ld.fill ) cout << " fill " << ld.fill;
    cout << endl;
}

void Picbox::draw(frame *f) {
    // Plot the box.  If there is a fill color, plot it twice so that
    // the box and edge can be different colors
    double x1,y1, x2,y2;	// The box edges in device coords.
    double ht, wid;		// height and width in device units (inches)

    try {
	x1 = p1.c->map(p1.x,x_axis);
	y1 = p1.c->map(p1.y,y_axis);
	x2 = p2.c->map(p2.x,x_axis);
	y2 = p2.c->map(p2.y,y_axis);
    } 
    catch (range_error& e) {
	cerr << "Unable to map box [(" << p1.x << ", " << p1.y << "), ("
	     << p2.x << ", " << p2.y << ")] into logscale : " 
	     << e.what() << endl;
	return;
    }

    // make (x1,y1) upper right and (x2,y2) lower left
    if ( x1 < x2 ) swap(x1,x2);
    if ( y1 < y2) swap(y1,y2);

    // Clip the box

    // If the box is entirely out of frame, ignore it.  epsilon for 1+ and
    // symmetry.
    if ( (x1 > 1+epsilon && x2 > 1+epsilon) ||
	 (x1 <-epsilon && x2 < -epsilon ) ) return;
    if ( (y1 > 1+epsilon && y2 > 1+epsilon) ||
	 (y1 <-epsilon && y2 < -epsilon ) ) return;

    // Box is at least partially in frame - clip it
    if ( x1 > 1+epsilon) x1 = 1;
    if ( y1 > 1+epsilon) y1 = 1;
    if ( x2 < -epsilon) x2 = 0;
    if ( y2 < -epsilon) y2 = 0;

    x1 *= f->wid;
    y1 *= f->ht;
    x2 *= f->wid;
    y2 *= f->ht;

    wid = fabs(x1-x2);
    ht = fabs(y1-y2);

    cout << "box ht " << ht << " wid " << wid ;
    cout << " with .ne at Frame.Origin + (" << x1 << ", " << y1 << ")";
    
    switch (ld.ld) {
	case invis:
	    cout << " invis ";
	    break;
	case solid:
	default:
	    break;
	case dotted:
	    cout << " dotted ";
	    if ( ld.param )
		cout << ld.param << " ";
	    break;
	case dashed:
	    cout << " dashed ";
	    if ( ld.param )
		cout << ld.param << " ";
	    break;
    }

    if ( !compat_mode ) {
	if ( ld.fillcolor ) {
	    // fillcolor takes precedence over fill - if fillcolor is not
	    // null, we draw one box filled with that color, and then a
	    // second unfilled one in color (black is none specified)

	    ld.fill = 0;
	    cout << " shaded " << *ld.fillcolor << " ";
	}	

	if ( ld.color ) cout << " outline " << *ld.color << " " ;
	if ( ld.thick ) cout << " thickness " << ld.thick << " " ;
    }

    if ( ld.fill ) cout << " fill " << ld.fill;
    cout << endl;
}

void Picplot::draw(frame *f) {
// Slightly trickier than the circle because we have to output a list
// of strings instead of one.  A functor to convert the DisplayStrings
// to PicDisplayStrings and plot them simplifies matters.
    double x, y;  // To transform the point into device coordinates
    bool in_frame = true;

    // To print a set of strings
    draw_string_f draw_string(f);

    if ( !strs || !loc ) return;

    try {
	x = f->wid * loc->c->map(loc->x,x_axis);
	y = f->ht * loc->c->map(loc->y,y_axis);
    }
    catch (range_error& e) {
	cerr << "Unable to place string at (" << loc->x << ", " << loc->y 
	     << "): " << e.what() << endl;
	return;
    }

    // Clip strings to lie in the graph (if requested)

    if ( x < -epsilon || x > f->wid + epsilon ) in_frame = false;
    if ( y < -epsilon || y > f->ht + epsilon ) in_frame = false;

    // Make a copy of all the DisplayStrings that are really displayed - either
    // all of them, if the plot is in the graph, or the unclipped ones if the
    // plot is off the graph.
    stringlist v;

    if ( in_frame ) 
	copy(strs->begin(), strs->end(), back_inserter(v));
    else
	remove_copy_if(strs->begin(), strs->end(), back_inserter(v), clipped);

    // If there are strings to show, show them.
    if ( v.size() ) {
	for_each(v.begin(), v.end(), draw_string);

	cout << "at Frame.Origin + (" << x << ", " << y << ")" << endl;
    }
    // Now v will go out of scope and disappear, leaving the object itself
    // alone.
}
