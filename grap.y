/* -*-c++-*- */
%{
/* This code is (c) 1998-2001 Ted Faber (faber@lunabase.org) see the
   COPYRIGHT file for the full copyright and limitations of
   liabilities. */
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#include <stdio.h>
#include <iostream>
#include <stack>
#include <math.h>
#ifdef STDC_HEADERS
#include <limits.h>
#else
// Best guess, really - limits should exist
#ifndef LONG_MAX
#define LONG_MAX        0x7fffffffL
#endif
#endif
#if defined(STDC_HEADERS) | defined(HAVE_STDLIB_H)
#include <stdlib.h>
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#include "grap.h"
#include "grap_data.h"
#include "grap_draw.h"

doubleDictionary vars;
graph *the_graph =0;
lexStack lexstack;
macroDictionary macros;
stringSequence path;
bool first_line;
bool unaligned_default = false;	// Should strings be unaligned by default 
bool clip_default = true;	// Should strings be clipped by default 
extern bool do_sprintf;		// true if it's acceptable to parse sprintf

line* defline;
coord *defcoord;
string *graph_name;
string *graph_pos;
string *ps_param;
// number of lines in a number list (used in grap_parse.cc) 
int nlines;

// bison wants these defined....
int yyerror(char*);
int yylex();
void init_dict(); 

// defined in grap_lex.l
extern bool include_file(string *, bool =false, bool=true);
extern void lex_no_macro_expansion(); 
extern void lex_macro_expansion_ok(); 
extern void lex_begin_macro_text(); 
extern void lex_begin_rest_of_line();
extern void lex_no_coord();
extern void lex_coord_ok();
extern void lex_begin_copy( string*s=0);
extern int include_string(string *,struct for_descriptor *f=0,
			  grap_input i=GMACRO);
extern void lex_hunt_macro();
extern int yyparse(void);	// To shut yacc (vs. bison) up.
void draw_graph();
void init_graph();

// Parsing utilities in grap_parse.cc.  Locating them there reduces
// compilation time (this file was getting very large) and eliminates
// some code redundancy.
extern graph *initial_graph(); 
extern linedesc* combine_linedesc(linedesc *, linedesc*);
extern axis combine_logs(axis, axis);
extern void draw_statement(string *, linedesc *, DisplayString *);
extern void num_list(doublelist *);
extern double assignment_statement(string *, double);
extern stringlist *combine_strings(stringlist *, string *, strmod &);
extern void plot_statement(double, DisplayString *, point *); 
extern void next_statement(string *, point *, linedesc *);
extern ticklist *ticklist_elem(double, DisplayString *, ticklist *);
extern ticklist *tick_for(coord *, double, double, bydesc, DisplayString *);
extern void ticks_statement(sides, double, shiftlist *, ticklist *);
extern void grid_statement(sides, int, linedesc *, shiftlist *, ticklist *);
extern void line_statement(int, linedesc *, point *, point *, linedesc *);
extern axisdesc axis_description(axis, double, double );
extern void coord_statement(string *, axisdesc&, axisdesc&, axis);
extern void coord_statement(coord *, axisdesc&, axisdesc&, axis);
extern void for_statement(string *, double, double, bydesc, string *);
extern void process_frame(linedesc *, frame *, frame *);
extern void define_macro(string *, string*);
extern void bar_statement(coord *, sides, double, double, double,
		   double, linedesc *); 
void init_dict(); 

// adapters to return complex (complex-ish) functions
void grap_srandom(double x) { srandom(static_cast<unsigned int>(x)); }
double grap_random() {
    return static_cast<double>(random())/(static_cast<double>(LONG_MAX)+1e-6);
}
double grap_getpid() { return static_cast<double>(getpid());} 
double pow10(double x) { return pow(10,x); }
double toint(double x) { return static_cast<double>(int(x)); }
double grap_min(double a, double b) { return (a<b) ? a : b; } 
double grap_max(double a, double b) { return (a>b) ? a : b; } 
 
typedef void (*vfunction1)(double);
typedef double (*function0)();
typedef double (*function1)(double);
typedef double (*function2)(double, double);
// jump tables for dispatching internal functions
vfunction1 jtvf1[NVF1] = { grap_srandom };
function0 jtf0[NF0] = { grap_random, grap_getpid };
function1 jtf1[NF1] = { log10, pow10, toint, sin, cos, sqrt, exp, log };
function2 jtf2[NF2] = { atan2, grap_min, grap_max};
%}
%token NUMBER START END IDENT COPY SEP STRING COORD_NAME UNDEFINE
%token SOLID INVIS DOTTED DASHED DRAW LPAREN RPAREN FUNC0 FUNC1 FUNC2 COMMA
%token LINE PLOT FROM TO AT NEXT FRAME LEFT RIGHT TOP BOTTOM UP DOWN HT WID
%token IN OUT NONE TICKS OFF BY GRID LJUST RJUST ABOVE BELOW ALIGNED
%token PLUS MINUS TIMES DIV CARAT EQUALS SIZE UNALIGNED LABEL RADIUS CIRCLE
%token ARROW XDIM YDIM LOG_X LOG_Y LOG_LOG COORD TEXT DEFINE IF THEN ELSE
%token EQ NEQ LT GT LTE GTE NOT OR AND FOR DO MACRO COPYTEXT THRU
%token GRAPH REST PRINT PIC TROFF UNTIL COLOR SPRINTF SH BAR FILL FILLCOLOR
%token BASE ON LHS VFUNC1 CLIPPED UNCLIPPED THICKNESS
%start graphs
%union {
    int val;
    double num;
    string *String;
    DisplayString *ds;
    frame *frameptr;
    shiftdesc *shift;
    shiftlist *shift_list;
    point *pt;
    linedesc *lined;
    stringlist *string_list;
    linelist *line_list;
    ticklist *tick_list;
    doublelist *double_list;
    doublevec *double_vec;
    macro *macro_val;
    coord *coordptr;
    line *lineptr;
    sides side;
    bydesc by;
    axisdesc axistype;
    axis axisname;
    strmod stringmod;
    copydesc *copyd;
    bar_param *bar_p;
}
%type <num> NUMBER num_line_elem expr opt_expr direction radius_spec
%type <num> assignment_statement lexpr pure_lexpr right_hand_side
%type <stringmod> strmod
%type <String> IDENT STRING opt_ident TEXT else_clause REST TROFF
%type <String> START string LHS
%type <ds> opt_display_string
%type <val>  VFUNC1 FUNC0 FUNC1 FUNC2 tickdir opt_tick_off line_token
%type <coordptr> opt_coordname COORD_NAME autotick
%type <side>  side  bar_dir
%type <frameptr> sides size size_elem final_size
%type <lined> linedesc_elem linedesc opt_linedesc
%type <string_list> strlist
%type <double_list> num_line
%type <double_vec> expr_list
%type <tick_list> ticklist tickat tickfor tickdesc
%type <pt> point coord_pair
%type <shift_list> opt_shift
%type <shift> shift 
%type <by> by_clause
%type <axistype> x_axis_desc y_axis_desc
%type <axisname> log_list log_desc
%type <line_list> COPYTEXT
%type <macro_val> MACRO
%type <copyd> until_clause
%type <bar_p> bar_param bar_params
%left OR AND
%right NOT
%left EQ NEQ LT GT LTE GTE
%left PLUS MINUS
%left TIMES DIV
%left CARAT
%%

graphs:
|	graphs graph
;

graph :
	    START {
                if ( !the_graph)
		    the_graph = initial_graph();
		the_graph->init();
		init_dict();
		first_line = true;
		the_graph->begin_block($1);
	    } prog END
            {
		the_graph->draw(0);
		the_graph->end_block();
	    }
;
prog :
    { }
|	prog statement
	    { }
;
statement:
	assignment_statement
	    { first_line = false;}
|	num_list
	    { first_line = false; the_graph->is_visible(true);}
|	frame_statement
	    {
		first_line = false;
		the_graph->queue_frame();
		the_graph->is_visible(true);
	    }
|	draw_statement
	    { first_line = false; }
|	next_statement
	    { first_line = false; the_graph->is_visible(true);}
|	plot_statement
	    { first_line = false; the_graph->is_visible(true);}
|	ticks_statement
	    { first_line = false; the_graph->is_visible(true);}
|	grid_statement
	    { first_line = false; the_graph->is_visible(true);}
|	label_statement
	    { first_line = false; the_graph->is_visible(true);}
|	circle_statement
	    { first_line = false; the_graph->is_visible(true);}
|	bar_statement
	    { first_line = false; the_graph->is_visible(true);}
|	line_statement
	    { first_line = false; the_graph->is_visible(true);}
|	coord_statement
	    { first_line = false;}
|	copy_statement
	    { first_line = false;}
|	define_statement
	    { first_line = false;}
|	undefine_statement
	    { first_line = false;}
|	if_statement
	    { first_line = false;}
|	for_statement
	    { first_line = false;}
|	graph_statement
	    { first_line = false;}
|	print_statement
	    { first_line = false;}
|	sh_statement
	    { first_line = false;}
|	pic_statement
	    { first_line = false;}
|	troff_line
	    { first_line = false;}
|	void_function
	    { first_line = false;}
|	SEP
;

from:
	FROM
|	EQUALS
;
opt_coordname:
            { $$= defcoord; }
|	COORD_NAME
	    { $$= $1;}
;

opt_ident:
	    { $$ = 0; } 
|	IDENT
	    { $$ = $1; }
;

opt_display_string:
	    { $$ = 0; } 
|	string strmod
	    {
		$$ = new DisplayString(*$1, $2.just, $2.size, $2.rel, 
		    $2.clip, $2.color);
	    }
;

string:
	STRING
             { $$ = $1; }
|       SPRINTF LPAREN STRING COMMA expr_list RPAREN
             {
		 if ( do_sprintf ) {
		     const int len = $3->length() < 128 ? 256 : 2*$3->length();
		     char *buf = new char[len];

		     // I really dislike this, but I dislike trying to do it
		     // incrementally more.
		     switch ($5->size()) {
			case 0:
			    snprintf(buf, len, $3->c_str());
			    break;
			case 1:
			    snprintf(buf, len, $3->c_str(), (*$5)[0]);
			    break;
			case 2:
			    snprintf(buf, len, $3->c_str(), (*$5)[0], (*$5)[1]);
			    break;
			case 3:
			    snprintf(buf, len, $3->c_str(), (*$5)[0], (*$5)[1], 
				(*$5)[2]);
			    break;
			case 4:
			    snprintf(buf, len, $3->c_str(), (*$5)[0], (*$5)[1], 
				(*$5)[2], (*$5)[3]);
			    break;
			case 5:
			    snprintf(buf, len, $3->c_str(), (*$5)[0], (*$5)[1], 
				(*$5)[2], (*$5)[3], (*$5)[4]);
			    break;
			case 6:
			    snprintf(buf, len, $3->c_str(), (*$5)[0], (*$5)[1], 
				(*$5)[2], (*$5)[3], (*$5)[4], (*$5)[5]);
			    break;
			case 7:
			    snprintf(buf, len, $3->c_str(), (*$5)[0], (*$5)[1], 
				(*$5)[2], (*$5)[3], (*$5)[4], (*$5)[5], 
				(*$5)[6]);
			    break;
			case 8:
			    snprintf(buf, len, $3->c_str(), (*$5)[0], (*$5)[1], 
				(*$5)[2], (*$5)[3], (*$5)[4], (*$5)[5], 
				(*$5)[6], (*$5)[7]);
			    break;
			case 9:
			    snprintf(buf, len, $3->c_str(), (*$5)[0], (*$5)[1], 
				(*$5)[2], (*$5)[3], (*$5)[4], (*$5)[5], 
				(*$5)[6], (*$5)[7], (*$5)[8]);
			    break;
			default:
			    cerr << "more that 10 arguments to sprintf.  " << 
				"Ignoring more than 10." << endl;
			case 10:
			    snprintf(buf, len, $3->c_str(), (*$5)[0], (*$5)[1], 
				(*$5)[2], (*$5)[3], (*$5)[4], (*$5)[5], 
				(*$5)[6], (*$5)[7], (*$5)[8], (*$5)[9]);
			    break;
		     }
		     delete $5; delete $3;

		     $$ = new string(buf);
		     delete[] buf;
		 }
		 else $$ = $3;
	     }
;

expr_list:
	expr
            {
		$$ = new doublevec;
		$$->push_back($1);
	    }
|       expr_list COMMA expr
            {
		$$ = $1;
		$$->push_back($3);
	    }
;

opt_expr:
            { $$ = 0; }
|	expr
	    { $$ = $1; }
;

opt_linedesc:
            { $$ = new linedesc; $$ = 0;}
|	linedesc
	    {  $$ = $1;}
;

opt_shift:
            { $$ = new shiftlist;}
|	 shift opt_shift 
	    {
		$$ = $2;
		$$->push_back($1);
	    }
;


linedesc_elem:
	INVIS
            { $$ = new linedesc(invis); }
|	 SOLID
            { $$ = new linedesc(solid); }
|	 DOTTED opt_expr
            { $$ = new linedesc(dotted, $2); }
|	 DASHED opt_expr
            { $$ = new linedesc(dashed, $2); }
|	 COLOR string
            { $$ = new linedesc(def, 0, $2); }
|	 FILL opt_expr
            { $$ = new linedesc(def, 0, 0, $2); }
|	 FILLCOLOR string
            { $$ = new linedesc(def, 0, 0, 0, $2); }
|	 THICKNESS opt_expr
            { $$ = new linedesc(def, 0, 0, 0, 0, $2); }
;

linedesc:
	 linedesc_elem
	    { $$ = $1; }
|	 linedesc linedesc_elem
            { $$ = combine_linedesc($1, $2); }
;

draw_statement:
	DRAW { lex_no_coord(); } opt_ident opt_linedesc opt_display_string SEP
	    { draw_statement($3, $4, $5); lex_coord_ok(); }
;

num_list:
	num_line SEP
            { num_list($1); }
;

num_line_elem:
	NUMBER
	    { $$ = $1; }
|
	MINUS NUMBER
	    { $$ = -$2; }
;

num_line:
	num_line_elem
	    {
		$$ = new doublelist;
		$$->push_back($1);
	    }
|	num_line num_line_elem
	    {
		$$ = $1;
		$$->push_back($2);
	    }
|	num_line COMMA num_line_elem
	    {
		$$ = $1;
		$$->push_back($3);
	    }
;

expr:
	expr PLUS expr
	    { $$ = $1 + $3; }
|	expr MINUS expr
            { $$ = $1 - $3; }
|	expr TIMES expr
	    { $$ = $1 * $3; }
|	expr DIV expr
	    { $$ = $1 / $3; }
|	expr CARAT expr
	    { $$ = pow($1,$3);}
|	MINUS expr %prec CARAT
	    { $$ = - $2;}
|	FUNC0 LPAREN RPAREN
	    { $$ = ( $1 >=0 && $1 < NF0 ) ? jtf0[$1]() : 0; }
|	FUNC1 LPAREN expr RPAREN
 	    { $$ = ( $1 >=0 && $1 < NF1 ) ? jtf1[$1]($3) : 0; }
|	FUNC2 LPAREN expr COMMA expr RPAREN
	    { $$ = ( $1 >=0 && $1 < NF2 ) ? jtf2[$1]($3, $5) : 0; }
|	LPAREN expr RPAREN
 	    { $$ = $2; }
|	IDENT
 	    {
		doubleDictionary::iterator di;
		
		if ( (di = vars.find(*$1)) != vars.end())
		    $$ = *(*di).second;
		else {
		    cerr << *$1 << " is uninitialized, using 0.0" << endl;
		    $$ = 0.0;
		}

		delete $1;
	     }
|	NUMBER
	    { $$ = $1; }
;

lexpr:
	expr
            { $$ = $1; }
|	LPAREN pure_lexpr RPAREN
            { $$ = $2; }
|	pure_lexpr
            { $$ = $1; }
;

pure_lexpr:
	lexpr EQ lexpr
            { $$ = ($1 == $3); }
|	lexpr NEQ lexpr
            { $$ = ($1 != $3); }
|	lexpr LT lexpr
            { $$ = ($1 < $3); }
|	lexpr GT lexpr
            { $$ = ($1 > $3); }
|	lexpr LTE lexpr
            { $$ = ($1 <= $3); }
|	lexpr GTE lexpr
            { $$ = ($1 >= $3); }
|	lexpr AND lexpr
            { $$ = ($1 && $3); }
|	lexpr OR lexpr
            { $$ = ($1 || $3); }
|	NOT lexpr %prec PLUS
            { $$ = ! ( (int) $2); }
|	string EQ string
            { $$ = (*$1 == *$3); delete $1; delete $3; }
|	string NEQ string
            { $$ = (*$1 != *$3); delete $1; delete $3; }
;

right_hand_side:
        expr SEP { $$ = $1; }
|	assignment_statement { $$ = $1; }
;

assignment_statement:
	LHS right_hand_side
            { $$ = assignment_statement($1, $2);  }
;

coord_pair:
        expr COMMA expr
            { $$ = new point($1, $3, 0); }
|       LPAREN expr COMMA expr RPAREN
            { $$ = new point($2, $4, 0); }
;
point:
	opt_coordname coord_pair
            { $$ = new point($2->x, $2->y, $1); delete $2; }
;

strmod:
	    {
		$$.size = 0;
		$$.rel =0;
		$$.just = (unaligned_default) ? unaligned : 0;
		$$.clip = clip_default;
		$$.color = 0;
	    }
| 	strmod SIZE expr
	    { $$.size = $3; $$.rel = ($3<0); }
| 	strmod SIZE PLUS expr
	    { $$.size = $4; $$.rel = 1; }
|	strmod LJUST
	    { $$.just |= (int) ljust; }
|	strmod RJUST
	    { $$.just |= (int) rjust; }
|	strmod ABOVE
	    { $$.just |= (int) above; }
|	strmod BELOW
	    { $$.just |= (int) below; }
|	strmod ALIGNED
	    { $$.just |= (int) aligned; }
|	strmod UNALIGNED
	    { $$.just |= (int) unaligned; }
|	strmod CLIPPED
	    { $$.clip = true; }
|	strmod UNCLIPPED
	    { $$.clip = false; }
|	strmod COLOR STRING
	    { $$.color = $3; }
;

strlist:
	string strmod
	    {
		DisplayString *s;

		s = new DisplayString(*$1,$2.just,$2.size, $2.rel, 
		    $2.clip, $2.color);
		delete $1;
		$$ = new stringlist;
		$$->push_back(s);
	    }
|	strlist string strmod
	    { $$ = combine_strings($1, $2, $3); }
;

plot_statement:
	strlist AT point SEP
	    {
  		the_graph->new_plot($1,$3);
	    }
|	PLOT opt_expr opt_display_string AT point SEP
	    { plot_statement($2, $3, $5); }
;

next_statement:
	NEXT opt_ident AT point opt_linedesc SEP
	    { next_statement($2, $4, $5); }
;

size_elem:
	HT expr
            {
		$$ = new frame;
		$$->ht = $2;
		$$->wid = 0;
	    }
|	WID  expr
            {
		$$ = new frame;
		$$->wid = $2;
		$$->ht = 0;
	    }
;

size:
	size_elem
            { $$ = $1; }
|	size size_elem
	    {
		$$ = $1;
		// Fill in non-default ht/wid
		
		if ( $2->ht != 0 ) $$->ht = $2->ht;
		if ( $2->wid != 0 ) $$->wid = $2->wid;
	    }
;

side:
	TOP
	    { $$ = top_side;}
|	BOTTOM
	    { $$= bottom_side;}
|	LEFT
	    { $$ = left_side;}
|	RIGHT
	    { $$ = right_side; }
;

final_size:
	size
            {
		// This rule combines the explicit size settings with
		// the defaults. We create a new frame to have access
		// to the default sizes without needing to code them
		// explicitly (they're always implicit in a default
		// frame). N. B. that frames created by size (and
		// size_elem) use 0 to indicate no change to the ht or
		// wid.
		
		$$ = new frame;

		if ( $1->ht != 0) $$->ht = $1->ht;
		if ( $1->wid != 0) $$->wid = $1->wid;
		delete $1;
	    }
;
sides:
	side linedesc {
		$$ = new frame;
		$$->desc[$1] = *$2;
		delete $2;
	    }
|	sides side linedesc
	    {
		if ( !$1 ) $$ = new frame;
		else $$ = $1;
		
		$$->desc[$2] = *$3;
		delete $3;
	    }
;

/* Though this looks kludgy as Hell, it's about as clean as I can make it.  Th
 * eproblem is that liesdescs are composed of lists of linedesc elements, and 2
 * linedescs next to each other are impossible to tell apart.  So, the global
 * linedesc for the frame cannot sit next to one of the linedescs for the
 * sides.  for example is 'frame top dotted color "green"' a green frame with a
 * dotted top or a frame with a dotted green top? Writing a single list rule to
 * capture that constraint requires you to know where the size elements appear
 * in that list and life is horrible and complex.  If it's even reasonably
 * tractable.  This enumeration captures many of the possibilities that are
 * sane and minimizes the code complexity.  You can't say things like 'frame
 * wid 3 dotted ht 5' to get a dotted 3x5 frame, but either 'frame dotted ht 3
 * wid 5' or 'frame wid 3 ht 5 dotted' work.
 * This comment is primarily here to prevent me from wasting another hour
 * trying to clean this up.
 */
frame_statement:
	FRAME SEP
	    { process_frame(0, 0, 0); }
|	FRAME linedesc SEP
	    { process_frame($2, 0, 0); }
|	FRAME final_size SEP
	    { process_frame(0, $2, 0); }
|	FRAME sides SEP
	    { process_frame(0, 0, $2); }
|	FRAME final_size sides SEP
	    { process_frame(0, $2, $3); }
|	FRAME linedesc sides SEP
	    { process_frame($2, 0, $3); }
|	FRAME linedesc final_size SEP
	    { process_frame($2, $3, 0); }
|	FRAME final_size linedesc SEP
	    { process_frame($3, $2, 0); }
|	FRAME linedesc final_size sides SEP
	    { process_frame($2, $3, $4);}
|	FRAME final_size linedesc sides SEP
	    { process_frame($3, $2, $4); }
;

shift:
	UP expr
            { $$ = new shiftdesc(top_side, $2); }
|	DOWN expr
            { $$ = new shiftdesc(bottom_side, $2); }
|	LEFT expr
            { $$ = new shiftdesc(left_side, $2); }
|	RIGHT expr
            { $$ = new shiftdesc(right_side, $2); }
;

tickdir:
	IN
	    { $$ = -1; }
|	OUT
	    { $$ = 1; }
;

direction:
	    { $$ = 0.125; }
|	tickdir opt_expr
	    {
		if ( $2 == 0 ) $$ = $1 * 0.125;
		else $$ = $1 * $2;
	    }
;

ticklist:
	expr opt_display_string
	    { $$ = ticklist_elem($1, $2, 0); }
|	ticklist COMMA expr opt_display_string
	    { $$ = ticklist_elem($3, $4, $1); }
;

by_clause:
	    { $$.op = PLUS; $$.expr = 1; }
|	BY expr
	    {
		$$.op = PLUS;
		if ( $2 != 0.0 ) $$.expr = $2;
		else $$.expr = 1;
	    }
|	BY PLUS expr
	    { $$.op = PLUS; $$.expr = $3; }
|	BY TIMES expr
	    { $$.op = TIMES; $$.expr = $3; }
|	BY DIV expr
	    { $$.op = DIV; $$.expr = $3; }
;

tickat:
	AT opt_coordname ticklist
	    {
		$$ = $3;
		for (ticklist::iterator t= $3->begin(); t != $3->end(); t++)
		    (*t)->c = $2;
	    }
;

tickfor:
	from opt_coordname expr TO expr by_clause opt_display_string
	    { $$ = tick_for($2, $3, $5, $6, $7); }
;
tickdesc :
	tickat
	    { $$ = $1;}
|	tickfor
	    { $$= $1; }
;

autotick:
	ON opt_ident
            {
		coordinateDictionary::iterator ci;

		if ( $2 ) {
		    ci = the_graph->coords.find(*$2);
		    if ( ci != the_graph->coords.end()) 
			$$ = (*ci).second;
		    else {
			yyerror("Name must name a coordinate space");
		    }
		}
		else $$ = 0;
		
	    }
|
            {
		$$ = 0;
            }
;	    

ticks_statement:
	TICKS side direction opt_shift tickdesc SEP
	    { ticks_statement($2, $3, $4, $5); }
| 	TICKS OFF SEP
	    {
		for ( int i = 0; i< 4; i++ )
		    the_graph->base->tickdef[i].size = 0;
	    }
| 	TICKS side OFF SEP
	    { the_graph->base->tickdef[$2].size = 0; }
| 	TICKS side direction autotick SEP
	    {
		the_graph->base->tickdef[$2].size = $3;
		if ( $4 ) the_graph->base->tickdef[$2].c = $4;
	    }
;

opt_tick_off:
	    { $$ = 0; }
|	TICKS OFF
	    { $$ = 1; }
;

grid_statement:
	GRID side opt_tick_off opt_linedesc opt_shift tickdesc SEP
	    {
		grid_statement($2, $3, $4, $5, $6);
	    }
|	GRID side opt_tick_off opt_linedesc opt_shift autotick SEP
	    {
		grid_statement($2, $3, $4, $5, 0);
		// Because turning on a grid on a given side disables
		// automatic tick generation there, this is sets up
		// that side with the proper coordinates.
		if ( $6 ) the_graph->base->griddef[$2].c = $6;
	    }
;

label_statement:
	LABEL side strlist opt_shift SEP
	    {
		shiftdesc *sd;

		for (stringlist::iterator s = $3->begin(); s != $3->end(); s++)
		    if ( ! ((*s)->j & unaligned) ) (*s)->j |= aligned;
		
		the_graph->base->label[$2] = $3;

		// Copy the label shifts into the frame
		while (!$4->empty() ) {
		    sd = $4->front();
		    $4->pop_front();
		    the_graph->base->lshift[$2]->push_back(sd);
		}
		delete $4;
	    }
;
radius_spec:
	    { $$ = 0.025; }
|	RADIUS expr
	    { $$ = $2; }
;

circle_statement:
	CIRCLE AT point radius_spec opt_linedesc SEP
	    {
		the_graph->new_circle($3,$4,$5);
		delete $3; delete $5;
	    }
;

line_token:
	LINE
	    { $$ = 1; }
|	ARROW
	    { $$ = 0; }
;

line_statement:
	line_token opt_linedesc FROM point TO point opt_linedesc SEP
	    { line_statement($1, $2, $4, $6, $7); }
;

x_axis_desc:
	    { $$.which=none; }
|	XDIM expr COMMA expr
	    { $$ = axis_description(x_axis, $2, $4); }
;
y_axis_desc:
	    { $$.which=none; }
|	YDIM expr COMMA expr
	    { $$ = axis_description(y_axis, $2, $4); }
;

log_list:
        log_list log_desc
            { $$ = combine_logs($1, $2); }
|
            { $$ = none; }
;

log_desc:
	LOG_X
	    { $$ = x_axis; }
|	LOG_Y
	    { $$ = y_axis; }
|	LOG_LOG
	    { $$ = both; }
;


coord_statement:
	COORD opt_ident x_axis_desc y_axis_desc log_list SEP
	    {
		coord_statement($2, $3, $4, $5);
		delete $2;
	    }
;

until_clause:
	    { $$ = 0; }
|	UNTIL string
	    {
		unquote($2);
		$$ = new copydesc;
		$$->t = copydesc::until;
		$$->s = $2;
	    }
| 	string
            {
		unquote($1);
		$$ = new copydesc;
		$$->t = copydesc::fname;
		$$->s = $1;
	    }
;

// This is probably long enough to merit being removed to
// grap_parse.cc, but because there are multiple actions in the same
// rule, I want to leave them here where I can see how they
// interrelate.

copy_statement:
	COPY string SEP
	    {
		unquote($2);
		if (!include_file($2, false)) return 0;
	    }
|	COPY UNTIL string SEP
            {
		unquote($3);
		lex_begin_copy($3);
	    }
        COPYTEXT
            {
		string s="";
		while ($6 && !$6->empty() ) {
		    string *ss;
		    ss = $6->front();
		    $6->pop_front();
		    if ( ss ) {
			s+= *ss;
			s+= '\n';
			delete ss;
			ss = 0;
		    }
		}
		include_string(&s, 0, GINTERNAL);
		delete $6;
	    }
|	COPY until_clause THRU { lex_hunt_macro(); } MACRO  until_clause SEP
	    {
		copydesc *c = 0; // To shut the compiler up about uninit
		if ( $2 && $6 ) {
		    delete $2;
		    delete $6;
		    yyerror("Only specify 1 until or filename\n");
		}
		else c = ($2) ? $2 : $6;
		// The else handles files with neither else clause, copying
		// text to the trailing .G2.  Fix from Bruce Lilly
		if ( c ) {
		    // lex_begin_copy takes command of the string that's
		    // passed to it, so don't delete it.  (I don't
		    // remember why I did that...)
		    if ( c->t == copydesc::until ) {
			lex_begin_copy(c->s);
			c->s = 0;
		    }
		    else {
			lex_begin_copy(0);
			include_file(c->s, false);
		    }
		    delete c;
		}
		else lex_begin_copy(0);
	    }
	COPYTEXT
	    {
		string *s;
		string *t;
		int lim;
		char end;
		stack<string *> st;

		while ( $9 && !$9->empty() ) {
		    int i = 0;
		    t = new string;
		    
		    s = $9->front();
		    $9->pop_front();
		    lim = s->length();
		    
		    while ( i < lim ) {
			if ( (*s)[i] == ' ' || (*s)[i] == '\t' ) {
			    if ( t->length() ) {
				if ( $5->add_arg(t)) 
				    t = new string;
			    }
			} else *t += (*s)[i];
			i++;
		    }
		    if ( t->length() ) $5->add_arg(t);
		    else if (t) delete t;
		    t = $5->invoke();
		    // "here" macros should end with a SEP.  If the
		    // user hasn't done so, we add a SEP for them.
		    // Even named macros should get a sep when they're
		    // copied through,

		    end = (*t)[t->length()-1];

		    if ( end != ';' && end != '\n' ) 
			*t += ';';
		    // Because include string stacks the strings, we stack them
		    // here and call include_string in reverse order to ensure
		    // correct ordered execution of multiple lines.
		    st.push(t);
		    delete s;
		}
		delete $9;
		while ( !st.empty() ) {
		    include_string(st.top(), 0, GMACRO);
		    delete st.top();
		    st.pop();
	        }
		// don't delete defined macros
		if ( !$5->name)
		    delete $5;
	    }
;

define_statement:
	DEFINE { lex_no_coord(); lex_no_macro_expansion();} 
	IDENT { lex_begin_macro_text(); } TEXT 
	SEP { lex_macro_expansion_ok(); lex_coord_ok(); define_macro($3, $5); }
;

undefine_statement:
	UNDEFINE { lex_no_coord(); lex_no_macro_expansion(); } IDENT SEP {
	    lex_coord_ok();
	    lex_macro_expansion_ok();
	    macros.erase(*$3);
	    delete $3;
	}
;

sh_statement: SH { lex_begin_macro_text(); } TEXT SEP
            {
		int len = $3->length()+1 ;
		char *sys = new char [len];
		int i=0;

		// String to char*
		       
		while ((sys[i] = (*$3)[i]))
		    i++;

		delete $3;
		
		system(sys);
	    }
;

else_clause:
	    { $$ = 0; }
| 	ELSE {lex_begin_macro_text(); } TEXT
	    {
		// force else clause to end with a SEP
		*$3+= ';';
		$$ = $3;
	    }
;

if_statement:
	IF lexpr THEN { lex_begin_macro_text(); } TEXT else_clause SEP
	    {
		// force all if blocks to be terminated by a SEP.  
		*$5 += ';';
		// We use epsilon in loop tests 
		if ( fabs($2) > epsilon ) include_string($5,0,GINTERNAL);
		else if ( $6 ) include_string($6,0,GINTERNAL);
		delete $5;
		if ( $6) delete $6;
	    }
;

for_statement:
	FOR IDENT from expr TO expr
            by_clause DO { lex_begin_macro_text(); } TEXT SEP
	    { for_statement($2, $4, $6, $7, $10); }
;

graph_statement:
	GRAPH { lex_no_coord(); } IDENT { lex_begin_rest_of_line(); } REST SEP
	    {
		if ( !first_line ) {
		    // Only draw the graph and clear its internals if
		    // it is visible.  This allows a user to declare
		    // things like coordinate spaces before the graph
		    // itself is named.  This is a compatibility
		    // feature for DWB grap.
		    if ( the_graph->is_visible() ) {
			the_graph->draw(0);
			the_graph->init($3, $5);
			init_dict();
		    }
		    else
			the_graph->setname($3);
		}
		else {
		    the_graph->init($3, $5);
		    init_dict();
		}
		    
		if ( $3 ) delete $3;
		if ( $5 ) delete $5;
	    }
;

print_statement:
	PRINT print_param SEP
;

print_param:
	string 
	    {
		unquote($1);
		cerr <<  *$1 << endl;
	    }
|	expr 
	    {
		cerr << $1 << endl;
	    }
;

pic_statement:
	PIC { lex_begin_rest_of_line(); } REST SEP
	    { the_graph->passthru_string(*$3); delete $3;}
;
troff_line:
	TROFF SEP
	    { the_graph->passthru_string(*$1); delete $1;}
;

bar_dir:
        RIGHT
            { $$ = right_side; } 
|       UP
             { $$ = top_side; } 
;

/* NB: the tokenizer only allows one instance of wid or base or ht per line
 * (you could have all 3) */
bar_param:
	HT expr { $$ = new bar_param; $$->ht = $2; $$->have_ht = true; }
|	WID expr { $$ = new bar_param; $$->wid = $2; }
|	BASE expr { $$ = new bar_param; $$->base = $2; }
;

bar_params:
	  bar_param { $$ = $1; }
| 	  bar_params bar_param { 
		$$ = $1;
		if ( $2 ) {
			if ($2->have_x ) { $$->x = $2->x; $$->have_x = true; }
			if ($2->have_ht ) { 
				$$->ht = $2->ht; $$->have_ht = true;
			}
			if ( $2->wid != 1.0 ) { $$->wid = $2->wid; }
			if ( $2->base != 0.0 ) { $$->base = $2->base; }
			delete $2;
		}
	}
;

bar_statement:
        BAR point COMMA point opt_linedesc SEP
            {
		// The point parsing has already autoscaled the
		// coordinate system to include those points.
		the_graph->new_box($2, $4, $5);
		delete $2; delete $4; delete $5;
	    }
|	BAR opt_coordname bar_dir expr bar_params opt_linedesc SEP
           { 
	   	if ( !$5 || !$5->have_ht ) {
			yyerror("bar must have a position and ht ");
		}
		else {
			bar_statement($2, $3, $4, $5->ht, $5->wid, 
				$5->base, $6);
		}
		delete $5;
	}
;

void_function:
	VFUNC1 LPAREN expr RPAREN
 	    { if ( $1 >=0 && $1 < NVF1 ) jtvf1[$1]($3); }
;
%%
