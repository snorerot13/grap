#ifndef GRAP_DRAW_H
#define GRAP_DRAW_H
#include <iostream.h>
#include <stl.h>

// Names for the sides of graphs
typedef enum { top=0, bottom,left, right} sides;

// Styles of drawing lines
typedef enum { solid, dotted, dashed, invis, def } linedesc;

// The axes of graphs
typedef enum { none = 0, x_axis = 1, y_axis = 2, both=3} axis;

// Justifications for strings, powers of two so we con combine them
typedef enum { ljust = 1, rjust = 2, above = 4, below = 8, aligned = 16,
	       unaligned=32} just;

// These should be classes, but they're used by yacc as union
// members, and thererefore need versions without constructors

typedef  struct {
    linedesc ld;	// The basic style
    double param;	// Some styles hava parameters e.g., dotted 0.3
    String *color;	// The name of a color for the line
} linedescval;		// Description of the style a line is drawn in

class linedescclass : public linedescval {
    // Basic class features for line descriptions: constructors,
    // destructor, and assignment
public:
    linedescclass(linedesc l=def, double p=0, String *c=0) {
	    ld = l;
	    param = p;
	    if ( c ) color = new String(c);
	    else color = 0;
    }
    
    linedescclass(linedescval *l) {
	if ( l) {
	    ld = l->ld;
	    param = l->param;
	    if ( l->color ) color = new String(l->color);
	    else color = 0;
	}
	else {
	    ld = def;
	    param = 0;
	    color = 0;
	}
    }
    
    linedescclass(linedescclass& ldc) {
	    ld = ldc.ld;
	    param = ldc.param;
	    if ( ldc.color ) color = new String(ldc.color);
	    else color = 0;
    }

    ~linedescclass() {
	if ( color ) {
	    delete color;
	    color = 0;
	}
    }

    linedescclass& operator=(const linedescval &l) {
	ld = l.ld;
	param= l.param;
	if ( color ) { delete color; color = 0;}
	if ( l.color ) color = new String(l.color);
    }
    
} ;


typedef struct {
    sides dir;		// Direction to shift this label
    double param;	// Amount to shift
} shiftdesc;		// A description of a label shift

class shiftclass : public shiftdesc {
    // Basic class features for shift descriptions: constructors,
    // destructor, and assignment
public:
    shiftclass(sides s=top, double p=0) {
	dir= s;
	param = p;
    }
    shiftclass(shiftdesc *sh ) {
	if ( sh ) {
	    dir = sh->dir;
	    param = sh->param;
	}
	else {
	    dir = top;
	    param = 0;
	}
    }
    shiftclass & operator=( const shiftdesc sh ) {
	dir = sh.dir;
	param = sh.param;
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

    // Allocation functions that ensure we delete what we allocated
    void *operator new(size_t s) {
	void *p = (void *) ::new char [s];
	return p;
    }
    void operator delete(void *p, size_t s) {
	::delete (char *)p;
    }
};

typedef list<drawable *> objlist;

class DisplayString : public String {
    // These are primarily used to keep track of the extended string
    // info.  A drawable class is derived to display them.
public:
    int j;               // justification modifiers (should be just,
                        // but int supports | and &
    double size;	// Fontsize
    int relsz;		// True if the fintsize is relative

    DisplayString() : String(), j(none), size(0), relsz(0) {}
    DisplayString(String s, int ju=0, double sz=0, int rsz=0 ) :
	String(s), j(ju), size(sz), relsz(rsz) { }
    DisplayString(DisplayString& ds) :
	String(ds.str), j(ds.j), size(ds.size), relsz(ds.relsz) { }
    DisplayString(double e, const String *fmt) :
	String(e,fmt), j(0), size(0), relsz(0) { }
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

    void newpt(double, double);
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
    String *prt;	// The string to print next to the mark
    shiftclass shift;	// Shift information, to fine tune position of prt
    coord *c;		// The coordinate scale that the tick is in
    
    tick() : where(0), size(0), side(top), prt(0), shift(0), c(0) { }
    tick(tick& t) :
	where(t.where), size(t.size), side(t.side), shift(t.shift),
	c(t.c) {
 	    if ( t.prt ) prt = new String(t.prt);
	    else prt =0;
    }
    tick(double w, double s, sides sd, String *p, shiftdesc *sh,
	 coord *co) :
	where(w), size(s), side(sd), shift(sh), c(co) {
 	    if ( p ) prt = new String(p);
	    else prt =0;
    }
    tick(double w, double s, sides sd, String *p, shiftclass *sh,
	 coord *co) :
	where(w), size(s), side(sd), shift(sh), c(co) {
 	    if ( p ) prt = new String(p);
	    else prt =0;
    }
    ~tick() {
	if ( prt) {
	    delete prt;
	    prt = 0;
	}
    }

    // Important safety tip:  Don't byte-copy string pointers.
    tick& operator=(const tick& t) {
	where = t.where;
	size = t.size;
	side = t.side;
	shift = t.shift;
	c = t.c;
	if ( prt ) { delete prt; }
	if ( t.prt ) prt = new String(t.prt);
	else prt = 0;
	return *this;
    }
	    
};

class grid {
public:
    double where;	// x or y value of the grid line
    linedescclass desc;	// style of the grid line
    sides side;		// Side of the graph where line labels are printed
    String *prt;	// The label for this line
    shiftclass shift;	// Shift info for the label
    coord *c;		// Coordinate system for this line
    
    grid() : where(0), desc(dotted,0,0), side(top), prt(0), shift(0), c(0) { }
    grid(double w, linedescval *l, sides sd, String *p, shiftdesc *sh,
	 coord *co) :
	where(w), desc(l), side(sd), shift(sh), c(co) {
	    if ( p ) prt = new String(p);
	    else prt =0;
    }

    grid(double w, linedescclass *l, sides sd, String *p, shiftclass *sh,
	 coord *co) :
	where(w), desc(l), side(sd), shift(sh), c(co) {
	    if ( p ) prt = new String(p);
	    else prt =0;
    }
    // To allow ticks and grids to share parse rules
    grid(tick *t) : where(t->where), side(t->side), shift(&t->shift),
	    c(t->c), desc(dotted,0,0) {
	if ( t->prt ) prt = new String(t->prt);
	else prt =0;
    }
    grid(grid& g) : where(g.where), side(g.side), shift(&g.shift),
	    c(g.c), desc(g.desc) {
	if ( g.prt ) prt = new String(g.prt);
	else prt =0;
    }
    ~grid() {
	if ( prt ) {
	    delete prt;
	    prt = 0;
	}
    }

    // Important safety tip:  Don't byte-copy string pointers.
    grid& operator=(const grid& g) {
	where = g.where;
	desc = g.desc;
	side = g.side;
	shift = g.shift;
	c = g.c;
	if ( prt ) delete prt;
	if ( g.prt ) prt = new String(g.prt);
	else prt = 0;
    }
};

class point {
public:
    double x,y;		// Point coordinates
    coord *c;		// system the coordinates are in

    point() : x(0), y(0), c(0) {}
    point(double xx, double yy, coord* cc) : x(xx), y(yy), c(cc) { }
    point(point *p) : x(p->x), y(p->y), c(p->c) { }
};

class frame {
    // The frame is the physical description of the graph axes.  It's
    // height and width are used by all drawable classes.
    
protected:
    // functors to clear internal lists
    class free_tick_f : public UnaryFunction<tick *, int> {
    public:
	int operator() (tick *t) { delete t; }
    } free_tick;

    class free_grid_f : public UnaryFunction<grid *, int> {
    public:
	int operator() (grid *g) { delete g; }
    } free_grid;

    class free_ds_f : public UnaryFunction<DisplayString *, int> {
    public:
	int operator() (DisplayString *ds) { delete ds; }
    } free_ds;
    
public:
    double ht;			// height of the graph
    double wid;			// width
    linedescclass desc[4];	// The line styles for the axes
    stringlist *label[4];	// labels for the axes.  These are
                                // lists of DisplayStrings that must
                                // be translated by the associated
                                // drawable class
    shiftclass lshift[4];	// positioning info for labels
    tick tickdef[4];		// default tick definitions
    grid griddef[4];		// default gridline definitions
    ticklist tks;		// the ticks to draw (generated from
                                // defaults if unspecified by the user)
    gridlist gds;		// gridlines to draw

    frame() : ht(2), wid(3), tks(), gds() {
	String g = "%g";
	
	for ( int i = 0 ; i < 4 ; i ++ ) {
	    desc[i] = linedescclass(def,0,0);
	    label[i] = new stringlist;
	    lshift[i] = shiftclass(top,0);
	    griddef[i] = grid(0.0,desc+i,top,&g,lshift+i,0);
	    tickdef[i] = tick(0.0,((i== bottom || i == left ) ? 0.125 : 0),
			      (sides) i, &g, lshift+i, 0);
	}
    }

    ~frame() {
	for ( int i = 0; i < 4; i++ ) {
	    if ( label[i] ) {
		if ( !label[i]->empty() ) 
		    for_each(label[i]->begin(), label[i]->end(), free_ds);
		delete label[i];
	    }
	}
	    
	if ( !tks.empty() )
	    for_each(tks.begin(), tks.end(), free_tick);
	if ( !gds.empty() )
	    for_each(gds.begin(), gds.end(), free_grid);
    }
};

class line {
protected:
    // An internal class that describes each point on the line.  Each
    // can have a different plotting symbol or drawing style.
    class linepoint : public point {
    public:
	linedescclass desc;	// style for the connection to this point
	String *plotstr;	// string to plot
	int initial;		// true if this is the first point in a segment
	int arrow;		// true if the connection ends with an arrow
	
	linepoint() : point(), desc(invis, 0.0, 0), initial(0), plotstr(0),
	    arrow(0)  { } ;
	linepoint(double xx, double yy, coord* cc, line *ll, String *s,
		  linedescval *l, int a=0);
	linepoint(linepoint& lp) :
	    point(lp.x,lp.y,lp.c), desc(lp.desc), plotstr(0),
	    initial(lp.initial), arrow(lp.arrow) {
		if ( lp.plotstr ) plotstr = new String(lp.plotstr);
	}

	~linepoint() {
	    if ( plotstr ) {
		delete plotstr;
		plotstr = 0;
	    }
	}
    };
public:
    String *plotstr;		// default plotting string
    linedescclass desc;		// Default connection style
    list<linepoint*> pts;	// the list of points
    int initial;		// the value of initial for the next point

    line() : plotstr(0), desc(), pts(),initial(1) {}

    line(linedescval *l, String *s ) : desc(l), initial(1), pts() {
	plotstr = new String(s);
    }
    
    line(linedescval *l) : desc(l),  initial(1), pts(), plotstr(0) { }
    line(line& l) : desc(l.desc),  initial(l.initial) {
	list<linepoint*>::iterator lpi;
	
	if ( l.plotstr ) {
	    plotstr = new String(l.plotstr);
	}
	// make a copy of the points as well as the list in pts

	for ( lpi = l.pts.begin(); lpi != l.pts.end(); lpi++ ) {
	    linepoint *lp = *lpi;
	    linepoint *nlp = new linepoint(*lp);

	    pts.push_back(nlp);
	}
	    
    }
    void addpoint(double x, double y, coord* c, String *s=0,
		  linedescval *l=0) {
	linepoint *lp;

	lp = new linepoint(x,y,c,this,s,l);
	pts.push_back(lp);
    }
    void addarrow(double x, double y, coord* c, String *s=0,
		  linedescval *l=0) {
	linepoint *lp;

	lp = new linepoint(x,y,c,this,s,l,1);
	pts.push_back(lp);
    }

};

class plot {
    // A string or set of strings drawn on the graph
public:
    stringlist *strs;	// the strings to draw
    point* loc;		// The location to put them at
    
    plot(stringlist *s = 0, point *p =0) : strs(s), loc(p) { }
    plot( plot& p ) : strs(p.strs), loc(p.loc) { }
};

class circle {
public:
    point center;	// center of the circle
    double rad;		// radius
    
    circle() : center(0,0,0), rad(0) { }
    circle(point *p, double r) : center(p), rad(r) { }
    circle(circle& c) : center(&c.center), rad(c.rad) { }
};

class graph {
    // Catchall data structure for each graph in progress.  It will be
    // the base class for various subclasses for specific output
    // devices
protected:
    // These are internal functors to delete and display lists.  
    
    class displayer_f : UnaryFunction<drawable *,int> {
	frame *base;
    public:
	displayer_f(frame *f) : base(f) {} ;
	int operator()(drawable *d) { d->draw(base); }
    };

    class obj_freer_f : public UnaryFunction<drawable *, int> {
    public:
	int operator()(drawable *d) {
	    delete d; }
    } obj_freer;
    
    class coord_freer_f :
	public UnaryFunction<coordinateDictionary::value_type, int> {
    public:
	int operator()(coordinateDictionary::value_type ci) {
	    coord *c = ci.second;
	    
	    delete c;
	}
    } coord_freer;

    class line_freer_f :
	public UnaryFunction<lineDictionary::value_type, int> {
    public:
	int operator()(lineDictionary::value_type li) {
	    line *l = li.second;
	    
	    delete l;
	}
    } line_freer;
    
    class addmargin_f :
	public UnaryFunction<coordinateDictionary::value_type, int> {
    public:
	    int operator() (coordinateDictionary::value_type cp) {
		coord *c = cp.second;
		c->addmargin(0.07);
	    }
    } addmargin;
    
public:
    objlist objs;		// The elements of the graph
    coordinateDictionary coords;// The coodrinate systems defined
    lineDictionary lines;	// The lines being defined for this graph
    frame *base;		// The frame surrounding this graph
    drawable *the_frame;	// This is the same as base, but drawable
    bool visible;		// is this graph visible?
    
    graph() : objs(), coords(), base(0), the_frame(0), visible(0) { }
    ~graph() { init();}

    virtual void draw() {
	displayer_f displayer(base);

	for_each(coords.begin(), coords.end(), addmargin);
	if ( visible ) {
	    the_frame->draw(base);
	    for_each(objs.begin(), objs.end(), displayer);
	}
    };

    // This clears graph parameters
    virtual void init(String * =0, String* =0 ) {
	visible = 0;
	if ( !objs.empty() ) {
	    for_each(objs.begin(), objs.end(), obj_freer);
	    objs.erase(objs.begin(), objs.end());
	}
	if ( !coords.empty() ) {
	    for_each(coords.begin(), coords.end(), coord_freer);
	    coords.erase(coords.begin(), coords.end());
	}
	if ( !lines.empty() ) {
	    for_each(lines.begin(), lines.end(), line_freer);
	    lines.erase(lines.begin(), lines.end());
	}
	// Subclasses allocate and release base & the_frame because
	// they depend on the drawing model
    }

    // Called when a .G1 is encountered
    
    virtual void begin_block(String *s) { }
    
    // Called when a .G2 is encountered
    virtual void end_block() { }

    // Called when pic ot troff strings are found

    virtual void pic_string(String *) { }
    virtual void troff_string(String *) { }

    // Virtual functions to allocate the proper subclassed elements.
    // Each real function should allocate an element and place it on
    // the objs list of the graph.
    
    virtual void add_line(line&) = 0;
    virtual void add_plot(plot&) = 0;
    virtual void add_circle(circle&) = 0;

};

#endif
