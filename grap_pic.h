// -*-c++-*-
#ifndef GRAP_PIC_H
#define GRAP_PIC_H
#include <iostream.h>
// This file is (c) 1998 Ted Faber (faber@lunabase.org) see COPYRIGHT
// for the full copyright and limitations of liabilities.


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
    void autoguess(sides, double &, double&, double&, double &, int&);
    void addautoticks(sides);
    void addautogrids(sides);
    void frame_line(double, double, sides);
    void label_line(sides);
};

class Picline : public line, public drawable {
public:
    Picline(line &l) : line(l) { };
    ~Picline() { }
    void draw(frame *);
};

// Sequence is defined in grap_data.h
class Picplot: public plot, public drawable {
public:
    Picplot(plot& p) : plot(p) { }
    ~Picplot() { cerr << "pic plot destructor" << endl; }
    void draw(frame *);
};

class Piccircle: public circle, public drawable {
public:
    Piccircle(circle& c) : circle(c) { }
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
    ~Picbox() { }
    void draw(frame *);
};

class Picgraph : public graph {
    String *ps_param;		// The params to .G1
    String *name;		// The name of the graph
    String *pos;		// the position of the graph (in pic)
    stringSequence pic;		// Pic commands encountered in the code
    stringSequence troff;	// troff commands encountered in the code
    int graphs;			// the number of graphs drawn this block
    Picframe *pframe;		// The pic frame for deallocation

    // To delete strings
    class sfree_f : UnaryFunction<String *, int> {
    public:
	int operator()(String *s) { delete s; return 0;}
    };
    
public:
    Picgraph() :
	graph(), ps_param(0), name(0), pos(0), pic(), troff(), graphs(0),
	pframe(0) {}
    
    
    ~Picgraph() {
	sfree_f sfree;

	if ( ps_param ) delete ps_param;
	if ( name ) delete name;
	if ( pos ) delete pos;
	if ( !troff.empty() )
	    for_each(troff.begin(), troff.end(), sfree);
	if ( !pic.empty() )
	    for_each(pic.begin(), pic.end(), sfree);
    }

    // overload the virtual functions in graph
    
    void init(String * =0, String* =0);
    void begin_block(String *param) { graphs = 0; ps_param = param; }
    void end_block() { if ( graphs ) cout << ".PE" << endl; }
    void troff_string(String *s) {
	String *t = new String(s);
	troff.push_back(t);
    }
	
    void pic_string(String *s) {
	String *p = new String(s);
	pic.push_back(p);
    }
	
    void add_line(line &l) {
	Picline *pl = new Picline(l);
	objs.push_back(pl);
    }

    void add_plot(plot &p) {
	Picplot *pp = new Picplot(p);
	objs.push_back(pp);
    }

    void add_circle(circle &c) {
	Piccircle *pc = new Piccircle(c);
	objs.push_back(pc);
    }
    void add_box(box &b) {
	Picbox *pb = new Picbox(b);
	objs.push_back(pb);
    }
    void draw();
};
#endif
