// -*-c++-*-
#ifndef GRAP_DRAW_H
#define GRAP_DRAW_H
// This file is (c) 1998 Ted Faber (faber@lunabase.org) see COPYRIGHT
// for the full copyright and limitations of liabilities.

// Names for the sides of graphs
typedef enum { top=0, bottom,left, right} sides;

// Styles of drawing lines
typedef enum { solid, dotted, dashed, invis, def } linetype;

// The axes of graphs
typedef enum { none = 0, x_axis = 1, y_axis = 2, both=3} axis;

// Justifications for strings, powers of two so we con combine them
typedef enum { ljust = 1, rjust = 2, above = 4, below = 8, aligned = 16,
	       unaligned=32} just;

typedef struct {
    axis which;
    double min;
    double max;
} axisdesc;

typedef struct {
    double size;
    int rel;
    int just;
} strmod;

class linedesc  {
    // Basic class features for line descriptions: constructors,
    // destructor, and assignment
public:
    linetype ld;	// The basic style
    double param;	// Some styles have parameters e.g., dotted 0.3
    double fill;	// Used for drawing solids, e.g. box
    string *color;	// The name of a color for the line
    string *fillcolor ;	// The color to fill a solid

    linedesc(linetype l=def, double p=0, string *c=0, double f=0,
		  string *fc=0) :
	ld(l), param(p), fill(f), color(0), fillcolor(0) {
	    if ( c ) color = new string(*c);
	    if ( fc ) fillcolor = new string(*fc);
    }

    linedesc(linedesc *l) {
	if ( l) {
	    ld = l->ld;
	    param = l->param;
	    fill = l->fill;
	    if ( l->color ) color = new string(*l->color);
	    else color = 0;
	    if ( l->fillcolor ) fillcolor = new string(*l->fillcolor);
	    else fillcolor = 0;
	}
	else {
	    ld = def;
	    param = 0;
	    color = 0;
	    fillcolor = 0;
	    fill = 0;
	}
    }

    linedesc(const linedesc& ldc) :
	ld(ldc.ld), param(ldc.param), fill(ldc.fill), color(0), fillcolor(0) {
	    if ( ldc.color ) color = new string(*ldc.color);
	    if ( ldc.fillcolor ) fillcolor = new string(*ldc.fillcolor);
    }
    // Make a new linedescriptor that combines the properites in ld1 and
    // ld2.
    linedesc(const linedesc* ld1, const linedesc* ld2) :
	ld(def), param(0), fill(0), color(0), fillcolor(0) {
	if ( ld1 ) *this = *ld1;
	if ( ld2 && ld2->ld != def ) {
	    ld = ld2->ld;
	    param = ld2->param;
	}
	if ( ld2 && ld2->color ) color = new string(*ld2->color);
    }

    ~linedesc() {
	if ( color ) { delete color; color = 0; }
	if ( fillcolor ) { delete fillcolor; fillcolor = 0; }
    }

    linedesc& operator=(const linedesc &l) {
	ld = l.ld;
	param= l.param;
	fill = l.fill;
	if ( color ) { delete color; color = 0;}
	if ( l.color ) color = new string(*l.color);
	if ( fillcolor ) { delete fillcolor; fillcolor = 0;}
	if ( l.fillcolor ) fillcolor = new string(*l.fillcolor);
	return *this;
    }
    
} ;


class shiftdesc  {
    // Basic class features for shift descriptions: constructors,
    // destructor, and assignment
public:
    sides dir;		// Direction to shift this label
    double param;	// Amount to shift

    shiftdesc(sides s=top, double p=0) : dir(s), param(p) { }
    
    shiftdesc(shiftdesc *sh ) {
	if ( sh ) {
	    dir = sh->dir;
	    param = sh->param;
	}
	else {
	    dir = top;
	    param = 0;
	}
    }
};

// This functor copies one shiftlist into another, making copies of
// each shiftdesc on the list.  It's used by various objects that have
// shiftlists in them.  Each element is inserted at the back
class shiftcpy : public unary_function<shiftdesc*, int> {
protected:
    shiftlist *s;	// The new shiftlist
public:
    shiftcpy(shiftlist *ss) : s(ss) { }
    int operator() (shiftdesc *sd) {
	shiftdesc *sd2 = new shiftdesc(sd);
	s->push_back(sd2);
	return 1;
    }
};

class frame;

// An abstract class that means that an object is drawable, and
// priovides a method with which to draw itself.  Drawing is always
// relative to a frame.  Because drawable classes are managed by the
// graph structure, drawable also supplies a smart allocation system.
class drawable {
public:
    virtual void draw(frame *) = 0;
    // So we get the right size to delete (ick)
    virtual ~drawable() { }
};

typedef list<drawable *> objlist;

class DisplayString : public string {
    // These are primarily used to keep track of the extended string
    // info.  A drawable class is derived to display them.
public:
    int j;               // justification modifiers (should be just,
                        // but int supports | and &
    double size;	// Fontsize
    int relsz;		// True if the fintsize is relative

    DisplayString() : string(), j(none), size(0), relsz(0) {}
    DisplayString(string s, int ju=0, double sz=0, int rsz=0 ) :
	string(s), j(ju), size(sz), relsz(rsz) { }
    DisplayString(DisplayString& ds) :
	string(ds), j(ds.j), size(ds.size), relsz(ds.relsz) { }
    DisplayString(double e, const string *fmt=0) :
	j(0), size(0), relsz(0) {
	char *c = new char[64];
	int delf =0;

	if ( !fmt) {
	    fmt = new string("%g");
	    delf = 1;
	}

	snprintf(c,64,fmt->c_str(),e);
	*(string*)this = c;
	delete[] c;
	if ( delf ) delete fmt;
    }
};

// A grap coordinate system
class coord {
public:
    coord() :
	xmin(0), xmax(0),ymin(0), ymax(0), logscale(none),
	xautoscale(1), yautoscale(1) { }
    coord(axis ls) :
	xmin(0), xmax(0),ymin(0), ymax(0), logscale(ls),
	xautoscale(1), yautoscale(1) { }
    coord(double xi, double xa, double yi, double ya, axis ls) :
	xmin(xi), xmax(xa),ymin(yi), ymax(ya),logscale(ls),
	xautoscale(0), yautoscale(0) { }
    
    double xmin, xmax;	// x range
    double ymin, ymax;	// y range
    axis logscale;	// The axes that are logarithmic
    int xautoscale;	// True if the user has not given an explicit x range
    int yautoscale;	// True if the user has not given an explicit y range

    void coord::newpt(double x, double y) {
	newx(x); newy(y);
    }
    void newx(double);
    void newy(double);

    // Add a margin to the system (0.07 is 7%) handles log scales
    void addmargin(double);

    // Convert to [0,1]
    double map(double, axis);
		  
};


class tick {
public:
    double where;	// x or y value of the tick
    double size;	// how large a tick mark to make
    sides side;		// Which side of the graph the mark is on
    string *prt;	// The string to print next to the mark
    shiftlist shift;	// Shift information, to fine tune position of prt
    coord *c;		// The coordinate scale that the tick is in
    
    tick() : where(0), size(0), side(top), prt(0), shift(), c(0) { }
    tick(tick& t) :
	where(t.where), size(t.size), side(t.side), shift(), c(t.c) {
	shiftcpy sc(&shift);
	
	if ( t.prt ) prt = new string(*t.prt);
	else prt =0;
	for_each(t.shift.begin(), t.shift.end(), sc);
    }
    tick(double w, double s, sides sd, string *p, shiftlist *sh,
	 coord *co) : where(w), size(s), side(sd), shift(), c(co) {
	shiftcpy sc(&shift);

	if ( p ) prt = new string(*p);
	else prt =0;
	if ( sh ) 
	    for_each(sh->begin(), sh->end(), sc);
    }

    ~tick() {
	shiftdesc *s;
	if ( prt) {
	    delete prt;
	    prt = 0;
	}
	while ( !shift.empty() ) {
	    s = shift.front();
	    shift.pop_front();
	    delete s;
	}
    }

    // Important safety tip:  Don't byte-copy string pointers.
    tick& operator=(const tick& t) {
	shiftcpy sc(&shift);

	where = t.where;
	size = t.size;
	side = t.side;
	shift = t.shift;
	c = t.c;
	if ( prt ) { delete prt; }
	if ( t.prt ) prt = new string(*t.prt);
	else prt = 0;
	for_each(t.shift.begin(), t.shift.end(), sc);
	return *this;
    }
	    
};

class grid {
public:
    double where;	// x or y value of the grid line
    linedesc desc;	// style of the grid line
    sides side;		// Side of the graph where line labels are printed
    string *prt;	// The label for this line
    shiftlist shift;	// Shift info for the label
    coord *c;		// Coordinate system for this line
    
    grid() : where(0), desc(dotted,0,0), side(top), prt(0), shift(), c(0) { }

    grid(double w, linedesc *l, sides sd, string *p, shiftlist *sh,
	 coord *co) :
	where(w), desc(l), side(sd), shift(), c(co) {
	shiftcpy sc(&shift);

	if ( p ) prt = new string(*p);
	else prt =0;
	if ( sh ) 
	    for_each(sh->begin(), sh->end(), sc);
    }

    // To allow ticks and grids to share parse rules
    grid(tick *t) : where(t->where),  desc(dotted,0,0), side(t->side),
	    shift(), c(t->c) {
	shiftcpy sc(&shift);

	if ( t->prt ) prt = new string(*t->prt);
	else prt =0;
	for_each(t->shift.begin(), t->shift.end(), sc);
    }

    grid(grid& g) : where(g.where), desc(g.desc), side(g.side),
		shift(), c(g.c) {
	shiftcpy sc(&shift);

	if ( g.prt ) prt = new string(*g.prt);
	else prt =0;
	for_each(g.shift.begin(), g.shift.end(), sc);
    }

    ~grid() {
	shiftdesc *s;
	
	if ( prt ) {
	    delete prt;
	    prt = 0;
	}
	while ( !shift.empty() ) {
	    s = shift.front();
	    shift.pop_front();
	    delete s;
	}
    }

    // Important safety tip:  Don't byte-copy string pointers.
    grid& operator=(const grid& g) {
	shiftcpy sc(&shift);

	where = g.where;
	desc = g.desc;
	side = g.side;
	shift = g.shift;
	c = g.c;
	if ( prt ) delete prt;
	if ( g.prt ) prt = new string(*g.prt);
	else prt = 0;
	for_each(g.shift.begin(), g.shift.end(), sc);
	return *this;
    }
};

class point {
public:
    double x,y;		// Point coordinates
    coord *c;		// system the coordinates are in

    point() : x(0), y(0), c(0) {}
    point(double xx, double yy, coord* cc) : x(xx), y(yy), c(cc) {
	if ( c ) c->newpt(x, y);
    }
    point(point *p) : x(p->x), y(p->y), c(p->c) {
	if ( c ) c->newpt(x, y);
    }
    point& operator=(point &p) {
	x = p.x; y = p.y; c = p.c;
	return *this;
    }
};

class frame {
    // The frame is the physical description of the graph axes.  It's
    // height and width are used by all drawable classes.
    
public:
    double ht;			// height of the graph
    double wid;			// width
    linedesc desc[4];		// The line styles for the axes
    stringlist *label[4];	// labels for the axes.  These are
                                // lists of DisplayStrings that must
                                // be translated by the associated
                                // drawable class
    shiftlist *lshift[4];	// positioning info for labels
    tick tickdef[4];		// default tick definitions
    grid griddef[4];		// default gridline definitions
    ticklist tks;		// the ticks to draw (generated from
                                // defaults if unspecified by the user)
    gridlist gds;		// gridlines to draw

    frame() : ht(2), wid(3), tks(), gds() {
	string g = "%g";
	
	for ( int i = 0 ; i < 4 ; i ++ ) {
	    desc[i] = linedesc(def,0,0);
	    label[i] = new stringlist;
	    lshift[i] = new shiftlist;
	    griddef[i] = grid(0.0,desc+i,top,&g,lshift[i],0);
	    tickdef[i] = tick(0.0,((i== bottom || i == left ) ? 0.125 : 0),
			      (sides) i, &g, lshift[i], 0);
	}
    }

    virtual ~frame() {
	for ( int i = 0; i < 4; i++ ) {
	    if ( label[i] ) {
		stringlist::iterator s;

		for (s = label[i]->begin(); s != label[i]->end(); s++)
		    delete (*s);
		label[i]->erase(label[i]->begin(), label[i]->end());
		delete label[i];
		label[i] =0;
	    }
	    if ( lshift[i] ) {
		shiftlist::iterator s;
		
		for (s = lshift[i]->begin(); s != lshift[i]->end(); s++)
		    delete (*s);
		lshift[i]->erase(lshift[i]->begin(), lshift[i]->end());
		delete lshift[i];
		lshift[i] =0;
	    }
	}
	    
	if ( !tks.empty() ) {
	    ticklist::iterator t;

	    for (t = tks.begin(); t != tks.end(); t++)
		delete (*t);
	    tks.erase(tks.begin(), tks.end());
	}

	if ( !gds.empty() ) {
	    gridlist::iterator g;

	    for (g = gds.begin(); g != gds.end(); g++)
		delete (*g);
	    gds.erase(gds.begin(), gds.end());
	}
    }
};

// A class that describes each point on the line.  Each can have a
// different plotting symbol or drawing style.
class linesegment {
public:
    point to;		// The end point of this segment
    point *from;	// the point this segment started from (if any)
    linedesc desc;	// style for the connection to this point
    string *plotstr;	// string to plot
    bool arrow;		// true if the connection ends with an arrow
	
    linesegment() : to(),  from(0), desc(invis, 0.0, 0),  plotstr(0),
		    arrow(false) { } ;
    linesegment(double xx, double yy, coord* cc, line *ll, string *s=0,
	      linedesc *l=0, bool a=0);
    linesegment(linesegment& ls) :
	to(ls.to), desc(ls.desc), plotstr(0) , arrow(ls.arrow) {
	if ( ls.from ) from = new point(ls.from);
	if ( ls.plotstr ) plotstr = new string(*ls.plotstr);
    }

    ~linesegment() {
	delete plotstr;
	plotstr = 0;
	delete from;
	from = 0;
    }
};

class line {
public:
    string *plotstr;		// default plotting string
    linedesc desc;		// Default connection style
    point *lastpoint;		// The last point plotted on the line

    line() : plotstr(0), desc(), lastpoint(0) {}

    line(linedesc *l, string *s=0 ) : plotstr(0), desc(l), lastpoint(0) {
	if (s) plotstr = new string(*s);
    }
    
    line(line& l) : plotstr(0), desc(l.desc),  lastpoint(0) {
	if ( l.plotstr ) {
	    plotstr = new string(*l.plotstr);
	}
    }

    ~line() {
	delete plotstr;
	plotstr = 0;
    }
    // Access to the last point plotted on the line, if any.
    point *lastplotted() { return lastpoint; }
    point *lastplotted(point *p) {
	if (!p) {
	    delete lastpoint;
	    lastpoint = 0;
	}
	else {
	    if ( !lastpoint ) lastpoint = new point(p);
	    else *lastpoint = *p;
	}
	return lastpoint;
    }
};

class plot {
    // A string or set of strings drawn on the graph
public:
    stringlist *strs;	// the strings to draw
    point* loc;		// The location to put them at
    
    plot(stringlist *s = 0, point *p =0) : strs(s), loc(p) { }
    // copy constructors have to copy ...
    plot( const plot& p ) : strs(0), loc(0) {
	if (p.loc) loc = new point(p.loc);

	if ( p.strs ) {
	    stringlist::iterator dsi;
	    strs = new stringlist();
	    
	    for ( dsi = p.strs->begin(); dsi != p.strs->end(); dsi++ ) {
		DisplayString *ds = *dsi;
		DisplayString *nds = new DisplayString(*ds);

		strs->push_back(nds);
	    }
	}
    }
    ~plot() {
	if ( strs ) {
	    DisplayString *ds;
	    while ( !strs->empty()) {
		ds = strs->front();
		strs->pop_front();
		delete ds;
	    }
	    delete strs;
	    strs = 0;
	}
	if ( loc ) {
	    delete loc ;
	    loc = 0;
	}
    }
};

class circle {
public:
    point center;	// center of the circle
    double rad;		// radius
    linedesc ld;
    
    circle() : center(0,0,0), rad(0), ld(solid) { }
    circle(point *p, double r, linedesc *l=0) : center(p), rad(r), ld(solid) {
	if ( l ) ld = *l;
    }
    circle(circle& c) : center(&c.center), rad(c.rad), ld(c.ld) { }
};

class box {
public:
    point p1;		// upper left and 
    point p2;		// lower right points
    linedesc ld;	// Line style for the box
    box() : p1(), p2(), ld() { }
    box(point *pp1, point *pp2, linedesc *l) :
	p1(pp1), p2(pp2), ld(l) { }
    box(const box &b) : p1(b.p1), p2(b.p2), ld(b.ld) { }
};

class graph : public drawable {
    // Catchall data structure for each graph in progress.  It will be
    // the base class for various subclasses for specific output
    // devices
protected:
    // These are internal functors to delete and display lists.  
    
    class displayer_f : unary_function<drawable *,int> {
	frame *base;
    public:
	displayer_f(frame *f) : base(f) {} ;
	int operator()(drawable *d) { d->draw(base); return 0;}
    };

    class obj_freer_f : public unary_function<drawable *, int> {
    public:
	int operator()(drawable *d) {
	    delete d;
	    return 0;
	}
    } obj_freer;
    
    class coord_freer_f :
	public unary_function<coordinateDictionary::value_type, int> {
    public:
	int operator()(coordinateDictionary::value_type ci) {
	    coord *c = ci.second;
	    
	    delete c;
	    return 0;
	}
    } coord_freer;

    class line_freer_f :
	public unary_function<lineDictionary::value_type, int> {
    public:
	int operator()(lineDictionary::value_type li) {
	    line *l = li.second;
	    
	    delete l;
	    return 0;
	}
    } line_freer;
    
    class addmargin_f :
	public unary_function<coordinateDictionary::value_type, int> {
    public:
	    int operator() (coordinateDictionary::value_type cp) {
		coord *c = cp.second;
		c->addmargin(0.07);
		return 0;
	    }
    } addmargin;
    
public:
    objlist objs;		// The elements of the graph
    coordinateDictionary coords;// The coodrinate systems defined
    lineDictionary lines;	// The lines being defined for this graph
    frame *base;		// The frame surrounding this graph
    bool visible;		// is this graph visible?
    
    graph() : objs(), coords(), lines(), base(0), visible(0) { }
    virtual ~graph() { init();}

    // This clears graph parameters
    virtual void init(string * =0, string* =0 ) {
	objlist::iterator o;
	coordinateDictionary::iterator c;
	lineDictionary::iterator l;
	
	visible = false;

	for (o = objs.begin(); o != objs.end(); o++)
	    delete (*o);
	objs.erase(objs.begin(), objs.end());
	    
	for (c = coords.begin(); c != coords.end(); c++)
	    delete (*c).second;
	coords.erase(coords.begin(), coords.end());

	for (l = lines.begin(); l != lines.end(); l++)
	    delete (*l).second;
	lines.erase(lines.begin(), lines.end());
	
	delete base;
	base =0;

    }

    bool is_visible() { return visible; }
    bool is_visible(bool v) { return visible = v; }

    // Called when a .G1 is encountered
    
    virtual void begin_block(string *) { }
    
    // Called when a .G2 is encountered
    virtual void end_block() { }

    // Called when pic or troff strings are found
    virtual void passthru_string(string& ) { }

    // Virtual functions to allocate the proper subclassed elements.
    // Each real function should allocate an element and place it on
    // the objs list of the graph.  It returns the base class of the
    // object created.  The returned element is a pointer to the
    // object on the list.  Don't delete it, although you can modify
    // it.
    virtual linesegment *new_linesegment(double x, double y, coord* c, line *l,
					 string *s=0, linedesc *ld=0,
					 bool a=false) =0;
    virtual plot *new_plot(stringlist *s =0, point *p=0)  =0;
    virtual circle *new_circle(point *p, double r, linedesc *l=0) =0;
    virtual box *new_box(point *p1, point *p2, linedesc *l) = 0;

    // put a drawable version of the frame on the object list.
    virtual void queue_frame() =0;
};

#endif
