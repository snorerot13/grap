#ifndef GRAP_PIC_H
#define GRAP_PIC_H
#include <iostream.h>

class PicDisplayString : public DisplayString, public drawable {
public:
    PicDisplayString(DisplayString& ds) :
	DisplayString(ds) { }
    void draw(frame *);
};

class Pictick : public tick, public drawable {
public:
    Pictick(tick& t) : tick(t) { };
    void draw(frame *); 
};

class Picgrid: public grid, public drawable {
public:
    Picgrid(grid &g) : grid(g) { }
    void draw(frame *); 
};

class Picframe: public frame, public drawable {
public:
    void draw(frame *) ;
protected:
    void addautoticks(sides);
    void addautogrids(sides);
    void frame_line(double, double, sides);
    void label_line(sides);
};

class Picline : public line, public drawable {
public:
    Picline(line &l) : line(l) { };
    void draw(frame *);
};

// Sequence is defined in grap_data.h
class Picplot: public plot, public drawable {
public:
    Picplot(plot& p) : plot(p) { }
    void draw(frame *);
};

class Piccircle: public circle, public drawable {
public:
    Piccircle(circle& c) : circle(c) { }
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
    void init(String *n=0, String* p=0) {
	graph::init();	// Init the base classes parameters

	if ( pframe) {
	    delete pframe;
	    pframe = 0; base = 0; the_frame = 0;
	}

	if ( (pframe = new Picframe) ) {
	    base = pframe;
	    the_frame = pframe;
	}
	if ( n ) name = new String(n);
	if ( p ) pos = new String(p);
    }
	
    Picgraph() :
	graph(), ps_param(0), name(0), pos(0), pic(), troff(), graphs(0) {}
    
    ~Picgraph() {
	class sfree_f : UnaryFunction<String *, int> {
	public:
	    int operator()(String *s) { delete s; }
	} sfree;

	if ( ps_param ) delete ps_param;
	if ( name ) delete name;
	if ( pos ) delete pos;
	if ( !troff.empty )
	    for_each(troff.begin(), troff.end(), sfree);
	if ( !pic.empty )
	    for_each(pic.begin(), pic.end(), sfree);
    }
	    

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
	
    void draw() {

	class string_out_f : public UnaryFunction<String*, int> {
	    ostream &f;
	public:
	    int operator()(String *s) { f << *s << endl; }
	    string_out_f(ostream& ff) : f(ff) {};
	} string_out(cout);

	class string_del_f : public UnaryFunction<String*, int> {
	public:
	    int operator()(String *s) { delete s; }
	} string_del;

	class line_convert_f :
              public UnaryFunction<lineDictionary::value_type,int> {
	    graph *g;
	public:
	    line_convert_f(graph *gg) : g(gg) { }
	    int operator()(lineDictionary::value_type li) {
		line *l = (li).second;
		Picline *pl = new Picline(*l);
		g->objs.push_back(pl);
	    }
	} line_convert(this);
		

	// Put adapters into the object list to draw lines

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
	    if ( !troff.empty() ) 
		for_each(troff.begin(), troff.end(), string_out);
	    if ( name ) {
		cout << *name << ": ";
		delete name;
		name = 0;
	    }
	    cout << "[" << endl;
	    graph::draw();
	    cout << "]";
	    if ( pos ) {
		cout << " " << *pos << endl;
		delete pos;
		pos = 0;
	    }
	    else cout << endl;
	    if ( !pic.empty() ) 
		for_each(pic.begin(), pic.end(), string_out);
	}
	if ( !troff.empty() ) {
	    for_each(troff.begin(), troff.end(), string_del);
	    troff.erase(troff.begin(), troff.end());
	}
	if ( !pic.empty() ) {
	    for_each(pic.begin(), pic.end(), string_del);
	    pic.erase(pic.begin(), pic.end());
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
};
#endif
