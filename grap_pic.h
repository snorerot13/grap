// -*-c++-*-
#ifndef GRAP_PIC_H
#define GRAP_PIC_H
#include <iostream.h>
// This file is (c) 1998 Ted Faber (faber@lunabase.org) see COPYRIGHT
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
		case left:
		    f << "left ";
		    break;
		case right:
		    f << "right ";
		    break;
		case top:
		    f << "up ";
		    break;
		case bottom:
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

class Picline : public line, public drawable {
protected:
    // Returns true if the coordinate is between 0 and 1 (withing tolerance).
    inline bool Picline::inbox(double a) {
	return ( a < 1+EPSILON && a > 0-EPSILON );
    }
    bool clipx( double &, double &, double &, double &);
    bool clip( double &, double &, double &, double &);
public:
    Picline(line &l) : line(l) { };
    ~Picline() { }
    void draw(frame *);
};

// Sequence is defined in grap_data.h
class Picplot: public plot, public drawable {
public:
    Picplot(plot& p) : plot(p) { }
    ~Picplot() { }
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

public:
    // Lots of functors to output and convert objects

    // Convert lines to Piclines and add them to the given graph
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

    // Print strings to the given ostream.  These two are not strictly
    // beautiful things, but those above are, and mixing for_each and
    // direct iterator manipulation in Picgraph::draw is ugly.  This
    // avoids that ugliness at low cost.

    class print_string_f :
	public UnaryFunction<String *, int> {
	ostream &f;
    public:
	print_string_f(ostream& s) : f(s) { }
	int operator()(String *s) {
	    f << *s << endl;
	    return 0;
	}
    };

    // Free a string.  See above for justification.
    class free_string_f :
	public UnaryFunction<String *, int> {
    public:
	free_string_f() { }
	int operator()(String *s) {
	    delete s;
	    return 0;
	}
    };
   
    // regular member functions 
    Picgraph() :
	graph(), ps_param(0), name(0), pos(0), pic(), troff(), graphs(0),
	pframe(0)
	{ }
    
    
    ~Picgraph() {
	free_string_f free_string;	// We've defined this for use
	                                // elsewhere, so we'll use it here.

	// pframe should always be a copy of base, so don't delete it
	if ( ps_param ) {
	    delete ps_param;
	    ps_param = 0;
	}
	if ( name ) {
	    delete name;
	    name = 0;
	}
	if ( pos ) {
	    delete pos;
	    pos = 0;
	}
	for_each(troff.begin(), troff.end(), free_string);
	troff.erase(troff.begin(), troff.end());

	for_each(pic.begin(), pic.end(), free_string);
	pic.erase(pic.begin(), pic.end());
    }

    // overload the virtual functions in graph
    
    void init(String * =0, String* =0);
    void begin_block(String *param) { graphs = 0; ps_param = param; }
    void end_block() { if ( graphs ) cout << ".PE" << endl; }
    void troff_string(String *s) {
	String *t;
	if ( s ) {
	    t = new String(*s);
	    troff.push_back(t);
	}
    }
	
    void pic_string(String *s) {
	String *p;
	if ( s ) {
	    p = new String(*s);
	    pic.push_back(p);
	}
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
    void draw(frame *);
};
#endif
