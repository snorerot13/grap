/* -*-c++-*- */
/* This code is (c) 1998-2001 Ted Faber (faber@lunabase.org) see the
   COPYRIGHT file for the full copyright and limitations of
   liabilities. */
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#include <stdio.h>
#include <iostream>
#include <math.h>
#ifdef STDC_HEADERS
#include <stdlib.h>
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifndef HAVE_OPTARG
extern "C" {
    extern char *optarg;
    extern int optind;
    int getopt(int, char * const [], const char *);
};
#endif

#include "grap.h"
#include "grap_data.h"
#include "grap_draw.h"
#include "grap_pic.h"
#include "y.tab.h"

extern doubleDictionary vars;
extern stringSequence path; 
extern graph *the_graph;
extern bool unaligned_default;	// Should strings be unaligned by default
extern bool print_lex_debug;

extern line* defline;
extern coord *defcoord;
//string version = ; 
bool compat_mode=false;			//  Compatibility mode

// defined in grap_lex.l
extern int include_string(string *,struct for_descriptor *f=0,
			  grap_input i=GMACRO);
extern string pre_context(void);
extern char *token_context(void);
extern string post_context(void);
extern bool include_file(string *, bool =false, bool=true);
extern void init_keywords();
extern int yyparse();
extern int nlines;

extern macroDictionary macros;
const char *opts = "d:lDvuM:CV";

// Classes for various for_each calls

// This collects the modifiers for other strings in
// a string list to construct the modifiers for the next string
class modaccumulator :
    public unary_function <DisplayString *, int > {
public:
	int just;
	double size;
	int rel;
	modaccumulator() : just(0), size(0), rel(0) {};
	int operator()(DisplayString* s) {
	    just = s->j;
	    size = s->size;
	    rel = s->relsz;
	    return 0;
	}
};


// Add a tick to the graph
class add_tick_f : public unary_function<tick*, int> {
    sides side;
    double size;
    shiftlist shift;
public:
    add_tick_f(sides sd, double sz, shiftlist *s) :
	side(sd), size(sz), shift() {
	shiftcpy sc(&shift);

	for_each(s->begin(), s->end(), sc);
    };
    int operator()(tick *t) {
	shiftcpy sc(&t->shift);
	t->side = side;
	t->size = size;

	for_each(shift.begin(), shift.end(), sc);

	the_graph->base->tks.push_back(t);
	if ( t->side == top_side || t->side == bottom_side )
	    t->c->newx(t->where);
	else 
	    t->c->newy(t->where);
	return 0;
    }
};

// Allocate a new graph (at this point always a Picgraph.  This is
// here so we don't have to include grap_pic in grap.y.
graph *initial_graph() { return (graph *) new Picgraph; }

// Combine a pair of line descriptions.  Non-defaults in elem override
// those features in desc.  The function returns desc and frees elem,
// so the programmer can treat it as freeing its parameters and
// returning a new linedesc.  (desc and elem should have been
// allocated by new).
linedesc* combine_linedesc(linedesc *desc, linedesc* elem) {
    if ( elem->ld != def ) {
	desc->ld = elem->ld;
	desc->param = elem->param;
    }
    if ( elem->fill ) desc->fill = elem->fill;
    if ( elem->color ) {
	if ( desc->color ) delete desc->color;
	desc->color = elem->color;
	// Don't let the destructor delete the color in desc.
	elem->color = 0;
    }
    if ( elem->fillcolor ) {
	if ( desc->fillcolor ) delete desc->fillcolor;
	desc->fillcolor = elem->fillcolor;
	// Don't let the destructor delete the fillcolor
	// in desc.
	elem->fillcolor = 0;
    }
    delete elem;
    return desc;
}


// Process a draw statement.  Create a new line description if this is
// a new name, assign the line description to it, and a plot string if
// necessary.
void draw_statement(string *ident, linedesc *ld, string *plot) {
    line *l;
    lineDictionary::iterator li;
    linedesc defld(invis,0,0);
    bool extant = false;	// True if this line was already defined.

    if ( ident ) {
	li = the_graph->lines.find(*ident);
	if ( li == the_graph->lines.end() ) {
	    macroDictionary::iterator md;
	    macro *m;
	    string *s;
	
	    // We need to create a new line with default parameters.
	    // Initialize the line to be invisible with a bullet
	    // plotting string.
	    if ( ( md = macros.find("bullet")) != macros.end()) {
		m = (*md).second;
		s = m->invoke();
	    }
	    else s = new string("\"\\(bu\"");

	    l = new line(&defld, s);
	    the_graph->lines[*ident] = l;
	    delete s;
	}
	else {
	    l = (*li).second;
	    extant = true;
	}
    } else {
	l = defline;
	// This is a bit of a kludge.  Don't reset any parameters of
	// the default line if new is given alone.
	if ( !ld && !plot ) extant = true;
    }

    // If a linedesc is specified, set the current line's description.
    if ( ld ) l->desc = *ld;

    if ( plot ) {
	if ( *plot != "" ) {
	    if ( l->plotstr ) *l->plotstr = *plot;
	    else l->plotstr = new string(*plot);
	}
	else {
	    // If the string is "", don't issue the pic commands to
	    // print it.
	    if (l->plotstr) {
		delete l->plotstr;
		l->plotstr = 0;
	    }
	}
    }
    else {
	// Only delete the plot string if this is the line definition.
	// (This makes draw solid do what's expected.)  To remove a
	// plot string, the user will have to explicitly specify an
	// empty plot string.
	if ( !extant ) {
	    if (l->plotstr) {
		delete l->plotstr;
		l->plotstr = 0;
	    }
	}
    }
    l->lastplotted(0);
    delete ident;
    delete plot;
    delete ld;
}

// Process a line of a number list.  dl is a list of numbers on this
// line.  If if at least an x and y are there, add those points to the
// current line and coords.  If only one number is given, use the
// number of lines processed so far as the x value and the given
// number as the y.
void num_list(doublelist *dl) {
    double x, y;

    if ( dl->empty() )
	exit(20);
    else {
	x = dl->front();
	dl->pop_front();
    }
		
    if ( dl->empty() ) {
	the_graph->new_linesegment(nlines, x, defcoord, defline);
    }
    else {
	while ( !dl->empty() ) {
	    y = dl->front();
	    dl->pop_front();
	    the_graph->new_linesegment(x, y, defcoord, defline);
	}
    }
    delete dl;
    nlines++;
}

// Assign the double to the variable named by ident.  If no such
// variable exists, create it.
double assignment_statement(string *ident, double val) {
    double *d;
    doubleDictionary::iterator di;
		
    if ( ( di = vars.find(*ident)) != vars.end() ) {
	d = (*di).second;
	*d = val;
    }
    else {
	d = new double(val);
	vars[*ident] = d;
    }
    // XXX: Again, shouldn't this go away?
    delete ident;
    return *d;
}
/*
// Create an new point and return it.  Also note the new point with
// its coordinate system so that automatic coordinates work right.
point *new_point(coord *c, double x, double y) {
    c->newpt(x, y);
    return new point(x, y, c);
}
*/
// This collects the modifiers for other strings in the list to
// construct the modifiers for the current string.
stringlist *combine_strings(stringlist *sl, string *st, strmod &sm)  {
    modaccumulator last;
    DisplayString *s;
			
    last = for_each(sl->begin(), sl->end(), modaccumulator());

    // If unaligned_default is set, then treat unaligned
    // strings as unmodified strings
		
    if ( sm.just != (unaligned_default ? unaligned : 0) )
	last.just = sm.just;
		
    if ( sm.size != 0 ) {
	last.size = sm.size;
	last.rel = sm.rel;
    }

    s = new DisplayString(*st,last.just,last.size,last.rel);
    delete st;
    sl->push_back(s);
    return sl;
}

// Create a new plot, that is a string created from a double, and add
// it to the current graph.
void plot_statement(double val, string *fmt, point *pt) {
    stringlist *seq = new stringlist;
    DisplayString *s;

    if ( fmt ) {
	unquote(fmt);
	s = new DisplayString(val,fmt);
	delete fmt;
    }
    else s = new DisplayString(val);

    quote(s);
    seq->push_back(s);

    the_graph->new_plot(seq,pt);
    delete pt;
}

// Add a point to the current line (or the named line if ident is
// non-0).  It may also include a pointer to a linedesc, wich should be
// passed on if non-0.
void next_statement(string *ident, point *p, linedesc* ld) {
    line *l;
    lineDictionary::iterator li;

    if ( ident) {
	li = the_graph->lines.find(*ident);
	if ( li == the_graph->lines.end() ) {
	    macroDictionary::iterator md;
	    macro *m;
	    string *s;
	
	    // We need to create a new line with default perameters.
	    // Initialize the line to be invisible with a bullet
	    // plotting string.
	    if ( ( md = macros.find("bullet")) != macros.end()) {
		m = (*md).second;
		s = m->invoke();
	    }
	    else s = new string("\"\\(bu\"");
	    l = new line((linedesc *)0, s );
	    the_graph->lines[*ident] = l;
	    delete s;
	}
	else { l = (*li).second; }
    } else l = defline;
    delete ident;
		
    if ( ld )
	the_graph->new_linesegment(p->x, p->y, p->c, l, 0, ld);
    else 
	the_graph->new_linesegment(p->x, p->y, p->c, l);
		
    delete p;
    delete ld;
}

// Create a new tick with the given format (if any) and add it to the
// current ticklist (which we're creating as we go).  If no such list
// exists, create it.
ticklist *ticklist_elem(double d, string *fmt, ticklist *tl) {
    tick *t = new tick(d,0,top_side,0, (shiftlist *) 0, 0);
    string *s;

    if ( fmt ) {
	unquote(fmt);
	s = dblString(d, fmt);
	delete fmt;
    }
    else s = dblString(d);
    t->prt = s;

    if ( !tl ) tl = new ticklist;
    tl->push_back(t);
    return tl;
}

// Convert a for description of a set of ticks into a list of ticks,
// including the coordinate system to put the ticks in, the beginning
// and ending ticks, a general increment descriptor (by) and a string
// to format each tick value.  Return the list.
ticklist *tick_for(coord *c, double from, double to, bydesc by, string *rfmt) {
    tick *t;
    string *s;
    string *fmt;
    double idx;
    int dir;
    ticklist *tl;

    tl = new ticklist;
    if ( rfmt ) {
	unquote(rfmt);
	fmt = new string(*rfmt);
	delete rfmt;
    } else
	fmt = new string("%g");
		
    if ( to - from >= 0 ) dir = 1;
    else dir = -1;
		
    idx = from;
    while ( (idx - to) *dir  < EPSILON ) {
	t = new tick(idx, 0, top_side, 0, (shiftlist *) 0, 0);
	t->c = c;

	s = dblString(idx,fmt);
	t->prt = s;
	tl->push_back(t);

	switch (by.op ) {
	    case PLUS:
		idx += by.expr;
		break;
	    case MINUS:
		idx -= by.expr;
		break;
	    case TIMES:
		idx *= by.expr;
		break;
	    case DIV:
		idx /= by.expr;
		break;
	}
    }
    delete fmt;
    return tl;
}

// Process the most complicated form of tick description.  Add a list
// of ticks to the current graph.
void ticks_statement(sides side, double dir, shiftlist *sl, ticklist *tl ) {
    shiftdesc *sd;
    shiftcpy sc(&the_graph->base->tickdef[side].shift);
		
    add_tick_f add_tick(side, dir, sl);

    the_graph->base->tickdef[side].side = side;

    for_each(sl->begin(), sl->end(), sc);

    if ( !tl || tl->empty() ) {
	the_graph->base->tickdef[side].size = dir;
    }
    else
	the_graph->base->tickdef[side].size = 0;

    if ( tl ) {
	for_each(tl->begin(), tl->end(), add_tick);
	delete tl;
    }
    while (!sl->empty()) {
	sd = sl->front();
	sl->pop_front();
	delete sd;
    }
    delete sl;
}

// Process a grid statement.  This is similar to, but somewhat more
// complex than the ticks statement above.
void grid_statement(sides side, int ticks_off, linedesc *ld,
		    shiftlist *sl, ticklist *tl) {
    tick *t;
    grid *g;
    linedesc defgrid(dotted, 0, 0);
    shiftcpy sc(&the_graph->base->griddef[side].shift);
    shiftdesc *sd;

    // Turning on a grid turns off default ticks on that side
		
    the_graph->base->tickdef[side].size = 0;

    // All grids have a linedesc, so create one if the user didn't
    // specify one.
    if ( !ld ) ld = new linedesc;

    // The default for grids is dotted
    if ( ld->ld == def ) ld->ld = dotted;
    the_graph->base->griddef[side].desc = *ld;


    for_each(sl->begin(), sl->end(), sc);

    if ( ticks_off ) {
	if ( the_graph->base->griddef[side].prt )
	    delete the_graph->base->griddef[side].prt;
	the_graph->base->griddef[side].prt = 0;
    }
    if ( tl ) {
	the_graph->base->griddef[side].desc.ld = def;
	while (!tl->empty() ) {
	    t = tl->front();
	    tl->pop_front();
			
	    g = new grid(t);
	    g->side = side;
	    shiftcpy scy(&g->shift);

	    if ( ld ) {
		// The default for grids is dotted
		if ( ld->ld == def ) ld->ld = dotted;
  		g->desc = *ld;
	    }
		    
	    for_each(sl->begin(), sl->end(), scy);

	    if ( ticks_off ) {
		if ( g->prt ) delete g->prt;
		g->prt = 0;
	    }
	    the_graph->base->gds.push_back(g);
	    if ( g->side == top_side || g->side == bottom_side )
		g->c->newx(g->where);
	    else 
		g->c->newy(g->where);
	    delete t;
	}
	delete tl;
    }
    while ( !sl->empty() ) {
	sd = sl->front();
	sl->pop_front();
	delete sd;
    }
    delete sl;
    delete ld;
}

// Draw a line from p1 to p2.  If is_line is false, draw an arror
// instead.  Either ld1 or ld2 or both may be present.  If only one is
// non-default, it rules, otherwise ld2 counts.
void line_statement(int is_line, linedesc *ld1, point *p1,
		    point *p2, linedesc *ld2 ) {
    line *l;
    lineDictionary::iterator li;
    // This constructor combines the two linedescs
    linedesc des(ld1, ld2);

    // Basically this should never fail...
    li = the_graph->lines.find("grap.internal");
    if ( li == the_graph->lines.end() ) {
	des.ld = solid;
	l = new line(&des);
	the_graph->lines["grap.internal"] = l;
    }
    else { l = (*li).second; } 

    l->lastplotted(0);

    if ( des.ld != def || des.color) {
	the_graph->new_linesegment(p1->x, p1->y, p1->c, l, 0, &des);
	if ( is_line )
	    the_graph->new_linesegment(p2->x, p2->y, p2->c, l, 0, &des);
	else
	    the_graph->new_linesegment(p2->x, p2->y, p2->c, l, 0, &des, true);
    } else {
	the_graph->new_linesegment(p1->x, p1->y, p1->c, l);
	if (is_line) the_graph->new_linesegment(p2->x, p2->y, p2->c, l);
	else the_graph->new_linesegment(p2->x,p2->y,p2->c, l, 0, 0, true);
    }
    delete ld1; delete ld2;
    delete p1; delete p2;
}

// Create an axis description.  That is, tell which axis it is and the
// bounds.
axisdesc axis_description(axis which, double d1, double d2) {
    axisdesc a;
    
    a.which = which;
    if (d1 < d2 ) {
	a.min = d1; a.max = d2;
    } else {
	a.min = d2; a.max = d1;
    }
    return a;
}

// Create a coordinate object.  Assign the mins and maxes to the axes
// and tell which if any are logarithmic.
void coord_statement(string *ident, axisdesc& xa, axisdesc& ya, axis log) {
    coord *c;

    if (ident) {
	c = new coord;
	the_graph->coords[*ident] = c;
	delete ident;
    } else 
	c = defcoord;

    if ( xa.which != none ) {
	c->xmin = xa.min;
	c->xmax = xa.max;
	c->xautoscale = 0;
    }
    if ( ya.which != none ) {
	c->ymin = ya.min;
	c->ymax = ya.max;
	c->yautoscale = 0;
    }
    c->logscale = log;
}

// Assign to an old coordinate object.  Assign the mins and maxes to
// the axes and tell which if any are logarithmic.
void coord_statement(coord *co, axisdesc& xa, axisdesc& ya, axis log) {
    coord *c;
    
    if (co) c = co;
    else c = defcoord;
    
    if ( xa.which != none ) {
	c->xmin = xa.min;
	c->xmax = xa.max;
	c->xautoscale = 0;
    }
    if ( ya.which != none ) {
	c->ymin = ya.min;
	c->ymax = ya.max;
	c->yautoscale = 0;
    }
    if ( log != none ) c->logscale = log;
}

// Initiate a for statement by generating a for descriptor and
// including the string.  The body is captured by changing lex state
// in the middle of the for_statement yacc rule.
void for_statement(string *ident, double from, double to,
		   bydesc by, string *body) {
    struct for_descriptor *f;
    doubleDictionary::iterator di;
    double *d;
		
    f = new for_descriptor;

    if ( ( di = vars.find(*ident)) != vars.end() ) {
	d = (*di).second;
	*d = from;
    }
    else {
	d = new double(from);
	vars[*ident] = d;
    }
    // XXX: delete ident?
    if (ident) delete ident;
    
    f->loop_var = d;
    if ( to - from > 0 ) f->dir = 1;
    else f->dir = -1;

    f->limit = to;
    f->by = by.expr;
    f->by_op = by.op;
    // force "anything" to end with a sep
    *body += ';';
    f->anything = body;
    // include_string is responsible for deleting body
    include_string(body,f,GINTERNAL);
}

void process_frame(linedesc* d, frame *f, frame *s) {
    // it's inconvenient to write three forms of the frame statement
    // as one yacc rule, so I wrote the three rules explicitly and
    // extracted the action here.  The three arugments are the default
    // frame linedesc (d), the size of the frame (f), and individual
    // descriptions of the linedescs (s) of the sides.  Note that d,
    // f, and s are freed by this routine.
    
    int i;	// Scratch

    if ( d ) {
	// a default linedesc is possible, but unlikely (only a fill,
	// for example).
	if ( d->ld != def ) {
	    for ( i = 0 ; i < 4; i++ ) {
		the_graph->base->desc[i] = *d;
	    }
	}
	delete d;
    }

    if ( f ) {
	the_graph->base->ht = f->ht;
	the_graph->base->wid = f->wid;
	delete f;
    }
		
    if ( s ) {
	for ( i = 0 ; i < 4; i++ ) {
	    if ( s->desc[i].ld != def )
		the_graph->base->desc[i] = (linedesc) s->desc[i];
	}
	delete s;
    }
}
// Combine two log descriptions in a log list.  Old is the accumulated
// log state so far, and n is the latest state to merge.  Return the
// new combined state.  The new state is created by making the n axis
// a log axis if it is not already in that list.
axis combine_logs(axis old, axis n) {
    switch (old) {
	default:
	case none:
	    return n;
	case x_axis:
	    switch (n) {
		case x_axis:
		case none:
		    return x_axis;
		case y_axis:
		case both:
		default:
		    return both;
	    }
	case y_axis:
	    switch (n) {
		case y_axis:
		case none:
		    return y_axis;
		case x_axis:
		case both:
		default:
		    return both;
	    }
	case both:
	    return both;
    }
}
// If a macro with the given name is defined, redefine it to be text,
// otherwise create a new macro and define it to be text.
void define_macro(string *name, string *text) {
    macro *m;				// The new macro
    macroDictionary::iterator mi;	// To search defined macros
    
    if ( ( mi = macros.find(*name)) != macros.end() ) {
	m = (*mi).second;
	delete m->text;
	m->text = text;
    } else {
	m = new macro(text, name);
	macros[*name] = m;
    }
}

// Create a new bar with the given parameters and add it to the graph.
void bar_statement(coord *c, sides dir, double offset, double ht, double wid,
		   double base, linedesc *ld) {
    point *p1, *p2;		// The defining points of the box

    switch (dir) {
	case right_side:
	    p1 = new point(base, offset + wid/2, c);
	    p2 = new point(base + ht, offset - wid/2, c);
	    break;
	case top_side:
	default:
	    p1 = new point(offset + wid/2, base, c);
	    p2 = new point(offset - wid/2, base + ht, c);
	    break;
    }
		
    c->newpt(p1->x,p1->y);
    c->newpt(p2->x,p2->y);
		
    the_graph->new_box(p1, p2, ld);
    delete p1; delete p2; delete ld;
}



// Perhaps a misnomer.  Initialize the current frame default lines and
// coordinate systems.  The default line is initialized to be
// invisible and have a plotting string defined by the bullet macro,
// if it is defined or a bullet character if not.
void init_dict() {
    linedesc defld(invis,0,0);		// The default line descriptor
    macroDictionary::iterator md;	// An iterator to search for bullet
    macro *m;				// The bullet macro
    string *s;				// The plot string for the default line

    if ( ( md = macros.find("bullet")) != macros.end()) {
	m = (*md).second;
	s = m->invoke();
    }
    else s = new string("\"\\(bu\"");
    
    defcoord = new coord;
    the_graph->coords["grap.internal.default"] = defcoord;
    for ( int i = 0 ; i < 4; i++) {
	the_graph->base->tickdef[i].c = defcoord;
	the_graph->base->griddef[i].c = defcoord;
    }
    defline = new line(&defld,s);
    the_graph->lines["grap.internal.default"] = defline;
    nlines = 0;
    delete s;
}


int yyerror(char *s) {
    grap_buffer_state *g = 0;
    int tp= 0;

    cerr << "grap: " << s << endl;
    while ( !lexstack.empty() ) {
	g = lexstack.front();
	lexstack.pop_front();
	switch ( g->type) {
	    case GFILE:
		cerr << "Error near line " << g->line << ", " ;
		if ( g->name ) cerr << "file \"" << *g->name << "\"" << endl;
		break;
	    case GMACRO:
		cerr << "Error near line " << g->line << " " ;
		cerr << "of macro" << endl;
		break;
	    default:
		break;
	}
	tp = g->tokenpos;
	delete g;
    }
    cerr << " context is:" << endl << "        " << pre_context();
    cerr << " >>> " << token_context() << " <<< " << post_context() << endl;
    return 0;
}

int main(int argc, char** argv) {
    string defines=DEFINES;
    string fname;
    string pathstring;
    int use_defines = 1;
    int c;

    if (getenv("GRAP_DEFINES"))
	defines = getenv("GRAP_DEFINES");
    
    while ( ( c = getopt(argc,argv,opts)) != -1)
	switch (c) {
	    case 'd':
		defines = optarg;
		use_defines = 1;
		break;
	    case 'l':
	    case 'D':
		use_defines = 0;
		break;
	    case 'v':
		cout << "grap " << VERSION << " compiled under ";
		cout << OS_VERSION << endl;
		exit(0);
	    case 'V':
		print_lex_debug = true;
		break;
	    case 'u':
		unaligned_default = 1;
		break;
	    case 'M':
		pathstring = (pathstring + ":") + optarg;
		break;
	    case 'C':
		compat_mode = true;
		break;
	    case '?':
		exit(20);
	}
    pathstring += (pathstring.length() > 0) ? ":." : ".";

    // Convert the colon separated file path into a sequence
    while (pathstring.length()) {
	string::size_type p = pathstring.find(':');
	string *s;

	if ( pathstring[p] == ':' ) {
	    if ( p != 0 ) {
		s = new string(pathstring.substr(0,p));
		pathstring.erase(0,p+1);
	    }
	    else {
		pathstring.erase(0,1);
		continue;
	    }
	}
	else {
	    s = new string(pathstring);
	    pathstring.erase(0,string::npos);
	}
	path.push_back(s);
    }

    init_keywords();

    if ( argc == optind ) {
	fname = "-";
	include_file(&fname, true, false);
    }
    else {
	for ( int i = argc-1; i >= optind; i-- ) {
	    fname = argv[i];
	    include_file(&fname, true, false);
	}
    }
    if ( use_defines) include_file(&defines, true);
    yyparse();
    for (stringSequence::iterator i = path.begin(); i != path.end(); i++)
	delete (*i);
    path.erase(path.begin(),path.end());
    
}
