#include <stdio.h>
#include <iostream.h>
#include <math.h>
#include "grap.h"
#include "grap_pic.h"

void PicDisplayString::draw(frame *) {
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

    unquote();
    cout << str;

    if ( size ) cout << "\\s" << 0 << "\" ";
    else cout << "\" ";

    if ( j & (int) ljust ) cout << "ljust ";
    if ( j & (int) rjust ) cout << "rjust ";
    if ( j & (int) above ) cout << "above ";
    if ( j & (int) below ) cout << "below ";
    if ( j & (int) aligned ) cout << "aligned ";
}


void Picframe::frame_line(double x2, double y2, sides s) {

    if ( desc[s].color ) {
	desc[s].color->unquote();
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
    int gn;
    DisplayString *str;
    // XXX this should be a member function of Display String

    class displaystring : public UnaryFunction<DisplayString*, int> {
    public:
	int operator() (DisplayString *str) {
	    PicDisplayString *p = new PicDisplayString(*str);
	    p->draw(0);
	}
    } display;
	    
    cout << "line invis ";

    for_each(label[s]->begin(), label[s]->end(), display);

    cout << "from Frame.";
    switch (lshift[s].dir) {
	case left:
	    cout << "Left.start - (" << lshift[s].param << ", 0) " ;
	    break;
	case right:
	    cout << "Right.start + (" << lshift[s].param << ", 0) " ;
	    break;
	case bottom:
	    cout << "Bottom.end - (0, " << lshift[s].param << ") " ;
	    break;
	case top:
	    cout << "Top.start + (0, " << lshift[s].param << ") " ;
	    break;
    }
    cout << "to Frame.";
    switch (lshift[s].dir) {
	case left:
	    cout << "Left.end - (" << lshift[s].param << ", 0) " ;
	    break;
	case right:
	    cout << "Right.end + (" << lshift[s].param << ", 0) " ;
	    break;
	case bottom:
	    cout << "Bottom.start - (0, " << lshift[s].param << ") " ;
	    break;
	case top:
	    cout << "Top.end + (0, " << lshift[s].param << ") " ;
	    break;
    }
    cout << endl;
}

void Picframe::addautoticks(sides sd) {
    double lo, hi;
    double range;
    double ts;
    double dir, idx;
    int ls;
    String *s;
    tick *t;

    if ( tickdef[sd].size == 0 ) return;

    if ( sd == bottom || sd == top ) {
	lo = tickdef[sd].c->xmin;
	hi = tickdef[sd].c->xmax;
	ls = (tickdef[sd].c->logscale & x_axis);
    } else {
	lo = tickdef[sd].c->ymin;
	hi = tickdef[sd].c->ymax;
	ls = (tickdef[sd].c->logscale & y_axis);
    }

    if ( !ls ) {
	range = fabs(hi - lo);
	
	ts = pow(10,floor(log10(range)));
	while ( range/ts > 4 ) ts *= 2;
	while ( range/ts < 3 ) ts /=2;
	idx = ts * ceil(lo/ts);
    } else {
	idx = pow(10,floor(log10(lo)));
    }

    if ( hi - lo < 0 ) dir = -1;
    else dir = 1;

    while ( idx - hi < EPSILON*dir ) {
	t = new tick(idx,tickdef[sd].size,sd,0, &tickdef[sd].shift,
		     tickdef[sd].c);
	if ( tickdef[sd].prt)
	    t->prt = new String(idx,tickdef[sd].prt);
	tks.push_back(t);
	if ( ls ) idx *= 10;
	else idx += ts;
    }
}
    
void Picframe::addautogrids(sides sd) {
    double lo, hi;
    double range;
    double ts;
    double dir, idx;
    int ls;
    String *s;
    grid *g;

    if ( griddef[sd].desc.ld == def ) return;

    if ( sd == bottom || sd == top ) {
	lo = griddef[sd].c->xmin;
	hi = griddef[sd].c->xmax;
	ls = (tickdef[sd].c->logscale & x_axis);
    } else {
	lo = griddef[sd].c->ymin;
	hi = griddef[sd].c->ymax;
	ls = (tickdef[sd].c->logscale & y_axis);
    }

    if ( !ls ) {
	range = fabs(hi - lo);
	ts = pow(10,floor(log10(range)));
	while ( range/ts > 6 ) ts *= 2;
	while ( range/ts < 4 ) ts /=2;
	idx = ts * ceil(lo/ts);
    } else {
	idx = pow(10,floor(log10(lo)));
    }

    if ( hi - lo < 0 ) dir = -1;
    else dir = 1;

    while ( idx - hi < EPSILON*dir ) {
	g = new grid(idx,&griddef[sd].desc,sd,0,
		     &griddef[sd].shift, griddef[sd].c);
	if ( griddef[sd].prt)
	    g->prt = new String(idx,griddef[sd].prt);
	gds.push_back(g);
	if ( ls ) idx *= 10;
	else idx += ts;
    }
}    

void Picframe::draw(frame *) {
    class draw_tick_f : public UnaryFunction<tick *, int> {
	frame *f;
    public:
	draw_tick_f(frame *fr) : f(fr) {};
	int operator()(tick* t) {
	    Pictick *pt = new Pictick(*t);
	    pt->draw(f);
	    free(pt);
	}
    } draw_tick(this);

    class draw_grid_f : public UnaryFunction<grid *, int> {
	frame *f;
    public:
	draw_grid_f(frame *fr) : f(fr) {};
	int operator()(grid* t) {
	    Picgrid *pt = new Picgrid(*t);
	    pt->draw(f);
	    free(pt);
	}
    } draw_grid(this);

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
    list<line::linepoint*>::iterator lpi;
    linepoint *lp;
    double x,y;

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
	    lp->desc.color->unquote();
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
    double a,b;
    char *dir;
    char *just;
	
    switch (side) {
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
	if ( shift.param != 0 ) {
	    cout << "move " ;
	    switch (shift.dir) {
		case left:
		    cout << "left ";
		    break;
		case right:
		    cout << "right ";
		    break;
		case top:
		    cout << "up ";
		    break;
		case bottom:
		    cout << "down ";
		    break;
	    }
	    cout << shift.param << endl;
	}
	prt->quote();
	cout << *prt << " " << just << " at Here" << endl;
    }
}
    
void Picgrid::draw(frame *f) {
    double a,b;
    double len;
    char *dir;
	
    switch (side) {
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
	desc.color->unquote();
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
	if ( shift.param != 0 ) {
	    cout << "move " ;
	    switch (shift.dir) {
		case left:
		    cout << "left ";
		    break;
		case right:
		    cout << "right ";
		    break;
		case top:
		    cout << "up ";
		    break;
		case bottom:
		    cout << "down ";
		    break;
	    }
	    cout << shift.param << endl;
	}
	prt->quote();
	cout << *prt << " at Here" << endl;
    }
}
    
void Piccircle::draw(frame *f) {
    double x,y;
    int gn;
	
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
    cout << "circle at Frame.Origin + (" << x << ", " << y << ")";
    cout << " rad " << rad << endl;
}

void Picplot::draw(frame *f) {
    DisplayString *s;
    double x, y;
    int gn;

    // XXX again, this should be a member of Display String

    class displaystring : public UnaryFunction<drawable*, int> {
    public:
	int operator() (DisplayString *s) {
	    PicDisplayString *ps = new PicDisplayString(*s);
	    
	    ps->draw(0);
	    delete ps;
	}
    } display;

    if ( !strs || !loc ) return;

    for_each(strs->begin(), strs->end(), display);

    x = f->wid * loc->c->map(loc->x,x_axis);
    y = f->ht * loc->c->map(loc->y,y_axis);

    cout << "at Frame.Origin + (" << x << ", " << y << ")" << endl;
}
