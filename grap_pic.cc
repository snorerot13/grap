#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#include <stdio.h>
#include <iostream.h>
#include <math.h>
#include "grap.h"
#include "grap_data.h"
#include "grap_draw.h"
#include "grap_pic.h"

// This file is (c) 1998 Ted Faber (faber@lunabase.org) see COPYRIGHT
// for the full copyright and limitations of liabilities.


// Lots of functors to output, convert aand delete list elements

// Output a string (from a pointer)
class string_out_f : public UnaryFunction<String*, int> {
    ostream &f;
public:
    int operator()(String *s) { f << *s << endl; return 0;}
    string_out_f(ostream& ff) : f(ff) {};
};

// Delete a string (from a pointer)
class string_del_f : public UnaryFunction<String*, int> {
public:
    int operator()(String *s) { delete s; return 0;}
};

// Convert a line to a Picline
class line_convert_f :
    public UnaryFunction<lineDictionary::value_type,int> {
	graph *g;
public:
	line_convert_f(graph *gg) : g(gg) { }
	int operator()(lineDictionary::value_type li) {
	    line *l = (li).second;
	    g->add_line(*l);
	    return 0;
	}
};
		
// convert a DisplayString to a PicdisplayString and print it
class display_f : public UnaryFunction<DisplayString*, int> {
public:
    int operator() (DisplayString *str) {
	PicDisplayString *p = new PicDisplayString(*str);
	p->draw(0);
	delete p;
	return 0;
    }
};

// draw ticks and grids.  We generate temporary Pic objects and plot them.
class draw_tick_f : public UnaryFunction<tick *, int> {
    frame *f;
public:
    draw_tick_f(frame *fr) : f(fr) {};
    int operator()(tick* t) {
	Pictick *pt = new Pictick(*t);
	pt->draw(f);
	free(pt);
	return 0;
    }
};

class draw_grid_f : public UnaryFunction<grid *, int> {
    frame *f;
public:
    draw_grid_f(frame *fr) : f(fr) {};
    int operator()(grid* t) {
	Picgrid *pt = new Picgrid(*t);
	pt->draw(f);
	free(pt);
	return 0;
    }
};

void Picgraph::init(String *n=0, String* p=0) {
    // Start a new graph, but maybe not a new block.
    
    graph::init();	// clear the base classes parameters

    if ( !base ) 
	base = pframe = new Picframe;
    if ( n ) name = new String(*n);
    if ( p ) pos = new String(*p);
}
	
void Picgraph::draw(frame *) {
// Do the work of drawing the current graph.  Convert non-drawable
// lines to Piclines, and put them in the object list for this graph.
// Do pic specific setup for the graph, and let the base class plot
// all the elements (they're all pic objects by now).  This also
// clears out the pic specific data structures as they're drawn.

    // Lots of functors to output, convert, draw and delete list elements
    
    displayer_f displayer(pframe); 	// call draw on the object.  This is
                                        // an embedded class of graph.
    string_out_f string_out(cout);	// output a string
    string_del_f string_del;		// delete a string
    line_convert_f line_convert(this);  // convert a generic line to
	                                // a pic line
		

    // Hook the lines up
    if ( !lines.empty() ) 
	for_each(lines.begin(), lines.end(), line_convert);

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
	// Print any saved embedded troff
	
	if ( !troff.empty() ) 
	    for_each(troff.begin(), troff.end(), string_out);

	// if we have a name, use it
	if ( name ) {
	    cout << *name << ": ";
	    delete name;
	    name = 0;
	}

	// The graph itself
	cout << "[" << endl;

	for_each(coords.begin(), coords.end(), addmargin);
	if ( visible ) {
	    pframe->draw(pframe);
	    for_each(objs.begin(), objs.end(), displayer);
	}
	cout << "]";

	// Positioning info relative to another graph in this block
	if ( pos ) {
	    cout << " " << *pos << endl;
	    delete pos;
	    pos = 0;
	}
	else cout << endl;

	// Saved pic commands
	if ( !pic.empty() ) 
	    for_each(pic.begin(), pic.end(), string_out);
    }

    // Clear out any saved pic/troff commands
    if ( !troff.empty() ) {
	for_each(troff.begin(), troff.end(), string_del);
	troff.erase(troff.begin(), troff.end());
    }
    if ( !pic.empty() ) {
	for_each(pic.begin(), pic.end(), string_del);
	pic.erase(pic.begin(), pic.end());
    }
	    
}


void PicDisplayString::draw(frame *) {
// Draw a display string.  Basically just a straight translation into
// pic/troff idioms.
    
    if ( size ) {
	if ( relsz ) {
	    if (size > 0.0 )  {
		cout << "\"\\s+" << size;
	    }
	    else {
		cout << "\"\\s" << size;
	    }
	}
	else cout << "\"\\s" << size;
    }
    else cout << '"';

#ifdef USE_STD_STRING
    unquote(this);
#else
    unquote();
#endif
    
    cout << *(String*)this;

    if ( size ) cout << "\\s" << 0 << "\" ";
    else cout << "\" ";

    if ( j & (int) ljust ) cout << "ljust ";
    if ( j & (int) rjust ) cout << "rjust ";
    if ( j & (int) above ) cout << "above ";
    if ( j & (int) below ) cout << "below ";
    if ( j & (int) aligned ) cout << "aligned ";
}


void Picframe::frame_line(double x2, double y2, sides s) {
// straightforward line drawing of one frame line

    if ( desc[s].color ) {
	unquote(desc[s].color);
	cout << ".grap_color " << *desc[s].color << endl;
    }
    switch (s) {
	case left:
	    cout << "Left: ";
	    break;
	case right:
	    cout << "Right: ";
	    break;
	case top:
	    cout << "Top: ";
	    break;
	case bottom:
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
    cout << "right " << x2 << " up " << y2 << endl;
    if ( desc[s].color ) {
	cout << ".grap_color prev" << endl;
    }
}

void Picframe::label_line(sides s) {
// Label a graph side.  We rely heavily on pic tricks here.  The C++
// is straightforward.

    // Functor to convert a DisplayString to a PicdisplayString and print it
    display_f display;
    double dx, dy; // Used to place the alignment line relative to the axis
    shiftlist::const_iterator csi;

    switch (s) {
	case left:
	    dx = -0.4; dy = 0;
	    break;
	case right:
	    dx = 0.4; dy = 0;
	    break;
	case top:
	    dx = 0; dy = 0.4;
	    break;
	case bottom:
	    dx = 0; dy = -0.4;
	    break;
	default: // to keep the compiler quiet
	    dx = dy = 0;
	    break;
    }

    for (csi = lshift[s]->begin(); csi != lshift[s]->end(); csi++) {
	switch ((*csi)->dir) {
	    case left:
		dx -= (*csi)->param;
		break;
	    case right:
		dx += (*csi)->param;
		break;
	    case top:
		dy += (*csi)->param;
		break;
	    case bottom:
		dy -= (*csi)->param;
		break;
	}
    }
	    
    cout << "line invis ";

    for_each(label[s]->begin(), label[s]->end(), display);

    switch (s) {
	case left:
	    cout << "from Frame.Left.start + (" << dx << ", " << dy << ") " ;
	    cout << "to Frame.Left.end + (" << dx << ", " << dy << ") " ;
	    break;
	case right:
	    cout << "from Frame.Right.start + (" << dx << ", " << dy << ") " ;
	    cout << "to Frame.Right.end + (" << dx <<  ", " << dy << ") " ;
	    break;
	case bottom:
	    cout << "from Frame.Bottom.end + (" << dx <<  ", " << dy << ") " ;
	    cout << "to Frame.Bottom.start + (" << dx <<  ", " << dy << ") " ;
	    break;
	case top:
	    cout << "from Frame.Top.start + (" << dx <<  ", " << dy << ") " ;
	    cout << "to Frame.Top.end + (" << dx << ", " << dy << ") " ;
	    break;
	default:
	    break;
    }
    cout << endl;
}

void Picframe::autoguess(sides sd, double &idx, double& dir, double& lim,
			 double &ts, int& ls) {
// Calculate a reasonable placement of tickmarks if the user has not
// specified one.  We aim for 5.  The algorithm is heuristic.
    
    double lo, hi;	// Low and high tickmarks
    double range;	// the range of the coordinate system

    // determine the range of the axes
    
    if ( sd == bottom || sd == top ) {
	lo = tickdef[sd].c->xmin;
	hi = tickdef[sd].c->xmax;
	ls = (tickdef[sd].c->logscale & x_axis);
    } else {
	lo = tickdef[sd].c->ymin;
	hi = tickdef[sd].c->ymax;
	ls = (tickdef[sd].c->logscale & y_axis);
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

    autoguess(sd, idx, dir, hi, ts, ls);
 
    while ( idx - hi < EPSILON*dir ) {
	t = new tick(idx,tickdef[sd].size,sd,0, &tickdef[sd].shift,
		     tickdef[sd].c);
	if ( tickdef[sd].prt)
	    t->prt = dblString(idx,tickdef[sd].prt);
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

    autoguess(sd, idx, dir, hi, ts, ls);

    while ( idx - hi < EPSILON*dir ) {
	g = new grid(idx,&griddef[sd].desc,sd,0,
		     &griddef[sd].shift, griddef[sd].c);
	if ( griddef[sd].prt)
	    g->prt = dblString(idx,griddef[sd].prt);
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
    frame_line(0,ht,left);
    frame_line(wid,0,top);
    frame_line(0,-ht,right);
    frame_line(-wid,0,bottom);
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

void Picline::draw(frame *f) {
// Iterate through the points in the line and draw them.  Map them
// according to the point's coordinates, then put them into the graph.
// There are some details to laying out the styles and poltting
// strings correctly.
    list<line::linepoint*>::iterator lpi;// An iterator to traverse the list
    linepoint *lp;			// The current point
    double x,y;				// Scratch

    if ( pts.empty() ) return;

    for ( lpi = pts.begin(); lpi != pts.end(); lpi++ ) {
	lp = *lpi;
	x = lp->c->map(lp->x,x_axis);
	y = lp->c->map(lp->y,y_axis);
	if ( x > 1+EPSILON || x < 0-EPSILON ) {
	    cerr << "Point outside coordinates: " << lp->x << ", " << lp->y;
	    cerr << endl;
	    continue;
	}
	if ( y > 1+EPSILON || y < 0-EPSILON ) {
	    cerr << "Point outside coordinates: " << lp->x << ", " << lp->y;
	    cerr << endl;
	    continue;
	}
	x *= f->wid;
	y *= f->ht;
	if ( lp->desc.color ) {
	    unquote(lp->desc.color);
	    cout << ".grap_color " << *lp->desc.color << endl;
	}
	if ( lp->initial ) cout << "move ";
	else {
	    if ( lp->arrow ) cout << "arrow ";
	    else cout << "line ";
	    switch (lp->desc.ld) {
		case invis:
		    cout << "invis ";
		    break;
		case solid:
		default:
		    break;
		case dotted:
		    cout << "dotted ";
		    if ( lp->desc.param ) cout << lp->desc.param << " ";
		    break;
		case dashed:
		    cout << "dashed ";
		    if ( lp->desc.param ) cout << lp->desc.param << " ";
		    break;
	    }
	}
	cout << "to Frame.Origin + (" << x << ", " << y << ")";
	cout << endl;
	if ( lp->plotstr ) {
	    cout <<  *lp->plotstr ;
	    if ( lp->initial ) cout << " at Here" << endl;
	    else cout << " at last line.end" << endl;
	}
	if ( lp->desc.color )
	    cout << ".grap_color prev" << endl;
    }
}

void Pictick::draw(frame *f) {
// Actually draw a tick mark.  Map it into the appropriate coordinate
// space and draw and label the line.  The translation from data
// structure to pic is straightforward.
    
    double a,b;	// x and y offsets from the origin
    char *dir;	// Direction of the tick mark
    char *just;	// placement of the label relative to the end of the tick
    Picshiftdraw sd(cout); // Functor to put out multiple tick shifts
	
    switch (side) {
	default:
	case left:
	    a = 0;
	    b = c->map(where,y_axis);
	    dir = "left";
	    just = "rjust";
	    break;
	case right:
	    a = 1;
	    b = c->map(where,y_axis);
	    dir = "right";
	    just = "ljust";
	    break;
	case top:
	    a = c->map(where,x_axis);
	    b = 1;
	    dir = "up";
	    just = "above";
	    break;
	case bottom:
	    a  = c->map(where,x_axis);
	    b = 0;
	    dir = "down";
	    just = "below";
	    break;
    }
    if ( a < 0 || a > 1 ) return;
    else a *= f->wid;
    if ( b < 0 || b > 1 ) return;
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
	cout << *prt << " " << just << " at Here" << endl;
    }
}
    
void Picgrid::draw(frame *f) {
// Draw a grid line.  As usual very similar to a tick.
    double a,b;
    double len;
    char *dir;
    Picshiftdraw sd(cout); // Functor to put out multiple tick shifts
	
    switch (side) {
	default:
	case left:
	    a = 0;
	    b = c->map(where,y_axis);
	    dir = "right";
	    len = f->wid;
	    break;
	case right:
	    a = 1;
	    b = c->map(where,y_axis);
	    dir = "left";
	    len = f->wid;
	    break;
	case top:
	    a = c->map(where,x_axis);
	    b = 1;
	    dir = "down";
	    len = f->ht;
	    break;
	case bottom:
	    a  = c->map(where,x_axis);
	    b = 0;
	    dir = "up";
	    len = f->ht;
	    break;
    }
    if ( a < 0 || a > 1 ) return;
    else a *= f->wid;
    if ( b < 0 || b > 1 ) return;
    else b *= f->ht;
    if ( desc.color ) {
	unquote(desc.color);
	cout << ".grap_color " << *desc.color << endl;
    }
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
    cout << "from Frame.Origin + (" << a << ", " << b;
    cout << ") then " << dir << " ";
    cout << len << endl;
    if ( desc.color ) cout << ".grap_color prev" << endl;
    if ( prt ) {
	cout << "move from Frame.Origin + (" << a << ", " << b;
	cout << ") then " << dir << " ";
	cout << -0.125 << endl;

	for_each(shift.begin(), shift.end(), sd);

	quote(prt);
	cout << *prt << " at Here" << endl;
    }
}
    
void Piccircle::draw(frame *f) {
// Plot a circle.  Strightforward.
    double x,y;	// To transform the point into device coordinates
	
    x = center.c->map(center.x,x_axis);
    y = center.c->map(center.y,y_axis);
    
    if ( x > 1+EPSILON || x < 0-EPSILON ) {
	cerr << "Circle outside coordinates:" << center.x << ", ";
	cerr << center.y << endl;
	return;
    }
    if ( y > 1+EPSILON || y < 0-EPSILON ) {
	cerr << "Circle outside coordinates:" << center.x << ", ";
	cerr << center.y << endl;
	return;
    }
    x *= f->wid;
    y *= f->ht;
    if ( ld.fillcolor ) {
	// fillcolor takes precedence over fill - if fillcolor is not
	// null, we draw one box filled with that color, and then a
	// second unfilled one in color (black is none specified)

	ld.fill = 0;
	unquote(ld.fillcolor);
	cout << ".grap_color " << *ld.fillcolor << endl;
	cout << "circle at Frame.Origin + (" << x << ", " << y << ")";
	cout << " rad " << rad << " invis fill 10" << endl;
	cout << ".grap_color prev" << endl;
    }	

    // Draw the circle with appropriate line style, fill, and color
    if ( ld.color ) {
	unquote(ld.color);
	cout << ".grap_color " << *ld.color << endl;
    }
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

    if ( ld.fill ) cout << " fill " << ld.fill;
    cout << endl;
    if ( ld.color )
	cout << ".grap_color prev" << endl;
}

void Picbox::draw(frame *f) {
    // Plot the box.  If there is a fill color, plot it twice so that
    // the box and edge can be different colors
    double x1,y1, x2,y2;	// The box edges in device coords.
    double ht, wid;		// height and width in device units (inches)

    x1 = p1.c->map(p1.x,x_axis) * f->wid;
    y1 = p1.c->map(p1.y,y_axis) * f->ht;
    x2 = p2.c->map(p2.x,x_axis) * f->wid;
    y2 = p2.c->map(p2.y,y_axis) * f->ht;

    // make (x1,y1) upper right and (x2,y2) lower left
    if ( x1 < x2 ) swap(x1,x2);
    if ( y1 < y2) swap(y1,y2);

    wid = fabs(x1-x2);
    ht = fabs(y1-y2);

    if ( ld.fillcolor ) {
	// fillcolor takes precedence over fill - if fillcolor is not
	// null, we draw one box filled with that color, and then a
	// second unfilled one in color (black is none specified)

	ld.fill = 0;
	unquote(ld.fillcolor);
	cout << ".grap_color " << *ld.fillcolor << endl;
	cout << "box ht " << ht << " wid " << wid ;
	cout << " with .ne at Frame.Origin + (" << x1 << ", " << y1 << ")";
	cout << " invis fill 10" << endl;
	cout << ".grap_color prev" << endl;
    }	

    if ( ld.color ) {
	unquote(ld.color);
	cout << ".grap_color " << *ld.color << endl;
    }
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

    if ( ld.fill ) cout << " fill " << ld.fill;
    cout << endl;
    if ( ld.color )
	cout << ".grap_color prev" << endl;
}

void Picplot::draw(frame *f) {
// Slightly trickier than the circle because we have to output a list
// of strings instead of one.  A functor to convert the DisplayStrings
// to PicDisplayStrings and plot them simplifies matters.
    double x, y;  // To transform the point into device coordinates

    // To print a set of strings
    class display_f display;

    if ( !strs || !loc ) return;

    for_each(strs->begin(), strs->end(), display);

    x = f->wid * loc->c->map(loc->x,x_axis);
    y = f->ht * loc->c->map(loc->y,y_axis);

    cout << "at Frame.Origin + (" << x << ", " << y << ")" << endl;
}
