// -*-c++-*-
#ifndef GRAP_PIC_H
#define GRAP_PIC_H
// This file is (c) 1998-2001 Ted Faber (faber@lunabase.org) see COPYRIGHT
// for the full copyright and limitations of liabilities.


// This is used by Pictick and Picgrid to iterate across their shifts
class Picshiftdraw : unary_function<shiftdesc*, int> {
protected:
    ostream &f;	// The output ostream
public:
    Picshiftdraw(ostream& ff) : f(ff) { }
    int operator()(shiftdesc *sd) {
	if ( sd->param != 0 ) {
	    f << "move " ;
	    switch (sd->dir) {
		case left_side:
		    f << "left ";
		    break;
		case right_side:
		    f << "right ";
		    break;
		case top_side:
		    f << "up ";
		    break;
		case bottom_side:
		    f << "down ";
		    break;
	    }
	    f << sd->param << endl;
	}
	return 1;
    }
};

class PicDisplayString : public DisplayString, public drawable {
public:
    PicDisplayString(DisplayString& ds) :
	DisplayString(ds) { }
    void draw(frame *);
    ~PicDisplayString() { };
};

class Pictick : public tick, public drawable {
public:
    Pictick(tick& t) : tick(t) { };
    void draw(frame *);
    ~Pictick() { }
};

class Picgrid: public grid, public drawable {
public:
    Picgrid(grid &g) : grid(g) { }
    void draw(frame *);
    ~Picgrid() { }
};

class Picframe: public frame, public drawable {
public:
    void draw(frame *) ;
    ~Picframe() { }
protected:
    void autoguess(sides, double &, double&, double&, double &, int&, coord *);
    void addautoticks(sides);
    void addautogrids(sides);
    void frame_line(double, double, sides);
    void label_line(sides);
};

class Piclinesegment : public linesegment, public drawable {
protected:
    // Returns true if the coordinate is between 0 and 1 (withing tolerance).
    inline bool inbox(double a) {
	return ( a < 1+EPSILON && a > 0-EPSILON );
    }
    bool clipx( double &, double &, double &, double &);
    bool clip( double &, double &, double &, double &);
public:
    Piclinesegment(linesegment &ls) : linesegment(ls) { }
    Piclinesegment(double x, double y, coord* c, line *l, string *s=0,
		   linedesc *ld=0, bool a=false) :
	linesegment(x, y, c, l, s, ld, a) { }
    ~Piclinesegment() { }
    void draw(frame *);
};

// Sequence is defined in grap_data.h
class Picplot: public plot, public drawable {
public:
    Picplot(plot& p) : plot(p) { }
    Picplot(stringlist *s =0, point *p=0) : plot(s, p) { }
    ~Picplot() { }
    void draw(frame *);
};

class Piccircle: public circle, public drawable {
public:
    Piccircle(circle& c) : circle(c) { }
    Piccircle(point *p, double r, linedesc *l=0) : circle(p, r, l) { }
    ~Piccircle() { }
    void draw(frame *);
};

class Picbox: public box, public drawable {
protected:
    void swap(double &a, double &b) {
	double h = a;
	a =b ;
	b =h;
    }
public:
    Picbox(box& b) : box(b) { }
    Picbox(point *p1, point *p2, linedesc *l) : box(p1, p2, l) { }
    ~Picbox() { }
    void draw(frame *);
};

class Picthrustring : public string, public drawable {
public:
    Picthrustring(const string &s) : string(s) { }
    ~Picthrustring() { }
    void draw(frame *) {
	cout << *this << endl;
    }
};

class Picgraph : public graph {
    string *ps_param;		// The params to .G1
    string *name;		// The name of the graph
    string *pos;		// the position of the graph (in pic)
    int graphs;			// the number of graphs drawn this block
    bool frame_queued;		// The frame is on the object list
    Picframe *pframe;		// The pic frame for deallocation

public:
    // regular member functions 
    Picgraph() :
	graph(), ps_param(0), name(0), pos(0), graphs(0), pframe(0)
	{ }
    
    
    ~Picgraph() {
	// pframe should always be a copy of base, so don't delete it.
	// It will be deallocated by graph::init.
	delete ps_param;
	ps_param = 0;

	delete name;
	name = 0;

	delete pos;
	pos = 0;
    }

    // overload the virtual functions in graph
    
    void init(string * =0, string* =0);
    void begin_block(string *param) { graphs = 0; ps_param = param; }
    void end_block() { if ( graphs ) cout << ".PE" << endl; }
    void passthru_string(const string& s) {
	Picthrustring *t = new Picthrustring(s);
	if ( t ) objs.push_back(t);
    }

    virtual linesegment *new_linesegment(double x, double y, coord* c, line *l,
					 string *s=0, linedesc *ld=0,
					 bool a=false) {
	Piclinesegment *pls = new Piclinesegment(x, y, c, l, s, ld, a);
	queue_frame();
	if (pls) objs.push_back(pls);
	return pls;
    }

    virtual plot *new_plot(stringlist *s =0, point *p=0) {
	Picplot *pl = new Picplot(s, p);
	queue_frame();
	if ( pl ) objs.push_back(pl);

	return pl;
    }
    virtual circle *new_circle(point *p, double r, linedesc *l=0) {
	Piccircle *c = new Piccircle(p, r, l);
	queue_frame();
	if ( c ) objs.push_back(c);

	return c;
    }
    virtual box *new_box(point *p1, point *p2, linedesc *l) {
	Picbox *b = new Picbox(p1, p2, l);
	queue_frame();
	if ( b ) objs.push_back(b);

	return b;
    }

    virtual void queue_frame() {
	if ( !frame_queued ) {
	    objs.push_back(pframe);
	    frame_queued = true;
	}
    }

    void draw(frame *);
};

class Piccoord: public coord, public drawable {
public:
    Piccoord(const coord& c) : coord(c) { }
    ~Piccoord() { }
    void draw(frame *f) {
	const string& nm = (name != "") ? name : "gg";
	
	cout << "define x_"<< nm << "{ ( Frame.Origin.x + ( ( $1 - " << xmin
	     << ") / " << xmax-xmin << ") * " << f->wid << " ) }" << endl;
	cout << "define y_"<< nm << "{ ( Frame.Origin.y + ( ( $1 - " << ymin
	     << ") / " << ymax-ymin << ") * " << f->ht << " ) }" << endl;
	cout << "define xy_" << nm << "{ x_" << nm << "($1), "
	     << "y_"<< nm << "($2) }" << endl; 
    }
};

#endif
