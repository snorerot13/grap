#ifndef GRAP_DRAW_H
#define GRAP_DRAW_H
#include <iostream.h>
#include <stl.h>

typedef enum { top=0, bottom,left, right} sides;
typedef enum { solid, dotted, dashed, invis, def } linedesc;
typedef enum { none = 0, x_axis = 1, y_axis = 2, both=3} axis;
typedef enum { ljust = 1, rjust = 2, above = 4, below = 8, aligned = 16,
	       unaligned=32} just;

// Thses should be classes, but they're used by yacc uas union
// members, and thererefore need versions without constructors

typedef struct {
    linedesc ld;	// The basic style
    double param;	// Some styles hava parameters e.g., dotted 0.3
    String *color;	// The name of a color for the line
} linedescval;		// Description of the style a line is drawn in

class linedescclass : public linedescval {
    // Basic class features for line descriptions: constructors,
    // destructor, and assignment
public:
    linedescclass(linedesc l=def, double p=0, String *c=0) :
	ld(l), param(p) {
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
    
    linedescclass(linedescclass& ldc) : ld(ldc.ld), param(ldc.param),
	color(0) {
	    if ( ldc.color ) color = new String(ldc.color);
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
    shiftclass(sides s=top, double p=0) : dir(s), param(p) {}
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

// An abstract class that means that an object is drawable, and
// priovides a method with which to draw itself.  Drawing is always
// relative to a frame.
class frame;

class drawable {
public:
    virtual void draw(frame *) = 0;
    // So we get the right size to delete (ick)
    virtual ~drawable() { }
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
public:
    int j;
    double size;
    int relsz;
    DisplayString() : String(), j(none), size(0), relsz(0) {}
    DisplayString(String s, int ju=0, double sz=0, int rsz=0 ) :
	String(s), j(ju), size(sz), relsz(rsz) { }
    DisplayString(DisplayString& ds) :
	String(ds.str), j(ds.j), size(ds.size), relsz(ds.relsz) { }
    DisplayString(double e, const String *fmt) :
	String(e,fmt), j(0), size(0), relsz(0) { }
};

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
    
    double xmin, xmax;
    double ymin, ymax;
    axis logscale;
    int xautoscale;
    int yautoscale;

    void newpt(double, double);
    void newx(double);
    void newy(double);
    void addmargin(double);
    double map(double, axis);
		  
};


class tick {
public:
    double where;
    double size;
    sides side;
    String *prt;
    shiftclass shift;
    coord *c;
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
    double where;
    linedescclass desc;
    sides side;
    String *prt;
    shiftclass shift;
    coord *c;
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
    point() : x(0), y(0), c(0) {}
    point(double xx, double yy, coord* cc) : x(xx), y(yy), c(cc) { }
    point(point *p) : x(p->x), y(p->y), c(p->c) { }
    double x,y;
    coord *c;
};

class frame {
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
    double ht;
    double wid;
    linedescclass desc[4];
    stringlist *label[4];
    shiftclass lshift[4];
    tick tickdef[4];
    grid griddef[4];
    ticklist tks;
    gridlist gds;

    frame() : ht(2), wid(3), tks(), gds() {
	for ( int i = 0 ; i < 4 ; i ++ ) {
	    desc[i] = linedescclass(def,0,0);
	    label[i] = new stringlist;
	    lshift[i] = shiftclass(top,0);
	    griddef[i] = grid(0.0,desc+i,top,&String("%g"),lshift+i,0);
	    tickdef[i] = tick(0.0,((i== bottom || i == left ) ? 0.125 : 0),
			      (sides) i, &String("%g"), lshift+i, 0);
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


//     void operator  delete(void *p, size_t s) {
// 	cerr << "frame delete " << p << " " << s << endl;
// 	::delete[] p;
//     }

//     frame() : tks(), gds() { clear() ; }

//     clear() {

// 	linedescval defline = { def, 0, 0};
// 	shiftdesc defshift = { top, 0 };

// //	for_each(tks.begin(), tks.end(), free_tick);
// //	for_each(gds.begin(), gds.end(), free_grid);
// //	tks.erase(tks.begin(), tks.end());
// //	gds.erase(gds.begin(), gds.end());
// 	ht = 2; wid = 3;
// 	for ( int i =0; i < 4 ; i ++ ) {
// 	    desc[i] = &defline;
// 	    label[i] = 0;
// 	    lshift[i]= defshift;
// 	    griddef[i] = grid(0,&defline,top,&String("%g"),&defshift,0);
// 	    tickdef[i] = tick(0,((i== bottom || i == left ) ? 0.125 : 0),
// 			      (sides) i, &String("%g"), &defshift, 0);
// 	}
//     }
};

class line {
protected:
    class linepoint : public point {
    public:
	linedescclass desc;
	String *plotstr;
	int initial;
	int arrow;
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

    String *plotstr;
    linedescclass desc;
    list<linepoint*> pts;
    int initial;
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

// Sequence is defined in grap_data.h
class plot {
public:
    stringlist *strs;
    point* loc;
    plot(stringlist *s = 0, point *p =0) : strs(s), loc(p) { }
    plot( plot& p ) : strs(p.strs), loc(p.loc) { }
};

class circle {
public:
    point center;
    double rad;
    circle() : center(0,0,0), rad(0) { }
    circle(point *p, double r) : center(p), rad(r) { }
    circle(circle& c) : center(&c.center), rad(c.rad) { }
};

class graph {
protected:
    // These are internal functors to delete and display lists
    
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

    // This should clear and re-initialize the frame fields ( and any
    // derived fields) (Takes the name and position of the new graph )
    
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
	// Subclasses must keep base & the_frame correct.
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
