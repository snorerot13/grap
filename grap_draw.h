#ifndef GRAP_DRAW_H
#define GRAP_DRAW_H
#include <iostream.h>

typedef enum { top=0, bottom,left, right} sides;
typedef enum { solid, dotted, dashed, invis, def } linedesc;
typedef enum { none = 0, x_axis = 1, y_axis = 2, both=3} axis;
typedef enum { ljust = 1, rjust = 2, above = 4, below = 8, aligned = 16,
	       unaligned=32} just;
typedef struct {
    linedesc ld;
    double param;
    String *color;
} linedescval;

class linedescclass : public linedescval {
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
    sides dir;
    double param;
} shiftdesc;

class shiftclass : public shiftdesc {
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

class DisplayString : public String {
public:
    int j;
    double size;
    int relsz;
    DisplayString() : String(), j(none), size(0), relsz(0) {}
    DisplayString(String s, int ju=0, double sz=0, int rsz=0 ) :
	String(s), j(ju), size(sz), relsz(rsz) { }
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

class frame;

class tick {
public:
    double where;
    double size;
    sides side;
    String *prt;
    shiftclass shift;
    coord *c;
    tick() : where(0), size(0), side(top), prt(0), shift(0), c(0) { }
    tick(double w, double s, sides sd, String *p, shiftdesc *sh,
	 coord *co) :
	where(w), size(s), side(sd), shift(sh), c(co) {
	    if ( p ) prt = new String(p);
	    else prt =0;
    }
	    
    void draw(frame *); 
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
    // To allow ticks and grids to share parse rules
    grid(tick *t) : where(t->where), side(t->side), shift(&t->shift),
	    c(t->c), desc(dotted,0,0) {
	if ( t->prt ) prt = new String(t->prt);
	else prt =0;
    }
    void draw(frame *); 
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

    frame() { clear() ; }

    clear() {

	linedescval defline = { def, 0, 0};
	shiftdesc defshift = { top, 0 };
	
	tks.erase(tks.begin(), tks.end());
	gds.erase(gds.begin(), gds.end());
	ht = 2; wid = 3;
	for ( int i =0; i < 4 ; i ++ ) {
	    desc[i] = &defline;
	    label[i] = 0; lshift[i]= defshift;
	    griddef[i] = grid(0,&defline,top,&String("%g"),&defshift,0);
	    tickdef[i] = tick(0,((i== bottom || i == left ) ? 0.125 : 0),
			      (sides) i, &String("%g"), &defshift, 0);
	}
    }
    
    void draw() ;
protected:
    void addautoticks(sides);
    void addautogrids(sides);
    void frame_line(double, double, sides);
    void label_line(sides);
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
    
    String *plotstr;
    linedescclass desc;
    list<linepoint*> pts;
    int initial;
    void draw(frame *);
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
    void draw(frame *);
};

class circle {
public:
    point center;
    double rad;
    circle() : center(0,0,0), rad(0) { }
    circle(point *p, double r) : center(p), rad(r) { }
    void draw(frame *);
};
#endif
