/* -*-c++-*- */
%{
/* This code is (c) 1998 Ted Faber (faber@lunabase.org) see the
   COPYRIGHT file for the full copyright and limitations of
   liabilities. */
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#include <stdio.h>
#include <iostream.h>
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

#ifndef RANDOM_DECLARED
long random();
#endif 

#include "grap.h"
#include "grap_data.h"
#include "grap_draw.h"
#include "grap_pic.h" 

doubleDictionary vars;
graph *the_graph =0;
lexStack lexstack;
macroDictionary macros;
int first_line;
bool unaligned_default = 0;	// Should strings be unaligned by default 

extern int lex_expand_macro;
extern char *version; 

line* defline;
coord *defcoord;
String *graph_name;
String *graph_pos;
String *ps_param;

// bison wants these defined....
int yyerror(char*);
int yylex();
void init_dict(); 

void process_frame(linedesc *, frame *, frame *);

// defined in grap_lex.l
extern bool include_file(String *, int i=0);
extern void lex_begin_macro_text();
extern void lex_begin_rest_of_line();
extern void lex_begin_copy( String*s=0);
extern int include_string(String *,struct for_descriptor *f=0,
			  grap_input i=GMACRO);
extern void lex_hunt_macro();
extern int yyparse(void);	// To shut yacc (vs. bison) up.
void draw_graph();
void init_graph();
extern String pre_context(void);
extern char *token_context(void);
extern String post_context(void);
    
int nlines;
int in_copy=0;

//  extern char *optarg;
//  extern int optind;

const char *opts = "d:lDvu";

// Classes for various for_each calls

// print the next number in a sprintf
class num_to_str_f : public UnaryFunction<double,int> {
    grap_sprintf_String *s;
public:
    num_to_str_f(grap_sprintf_String *ss) : s(ss) {};
    int operator()(double d) { s->next_number(d); return 0;}
};

// This collects the modifiers for other strings in
// a string list to construct the modifiers for the next string
class modaccumulator :
    public UnaryFunction <DisplayString *, int > {
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

// To assign the coordate system to all the ticks in
// the queue
class coord_to_tick : public UnaryFunction<coord *,int> {
public:
    coord *c;
    coord_to_tick(coord *cc) : c(cc) {};
    int operator() (tick *t) { t->c = c; return 0;}
};

// Add a tick to the graph
class add_tick_f : public UnaryFunction<tick*, int> {
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
	if ( t->side == top || t->side == bottom )
	    t->c->newx(t->where);
	else 
	    t->c->newy(t->where);
	return 0;
    }
};


// Align a list of strings
class align_string :
    public UnaryFunction<DisplayString *,int> {
public:
	int operator() (DisplayString *ds) {
	    if ( ! (ds->j & unaligned) ) ds->j |= aligned;
	    return 0;
	}
};
%}
%token NUMBER START END IDENT COPY SEP COPY_END STRING LINE_NAME COORD_NAME
%token SOLID INVIS DOTTED DASHED DRAW LPAREN RPAREN FUNC0 FUNC1 FUNC2 COMMA
%token LINE PLOT FROM TO AT NEXT FRAME LEFT RIGHT TOP BOTTOM UP DOWN HT WID
%token IN OUT TICKS OFF BY GRID LJUST RJUST ABOVE BELOW ALIGNED
%token PLUS MINUS TIMES DIV CARAT EQUALS SIZE UNALIGNED LABEL RADIUS CIRCLE
%token ARROW XDIM YDIM LOG_X LOG_Y LOG_LOG COORD TEXT DEFINE IF THEN ELSE
%token EQ NEQ LT GT LTE GTE NOT OR AND FOR DO MACRO COPYTEXT THRU
%token GRAPH REST PRINT PIC TROFF UNTIL COLOR SPRINTF SH BAR FILL FILLCOLOR
%token BASE
%start graphs
%union {
    int val;
    double num;
    String *string;
    frame *frameptr;
    shiftdesc *shift;
    shiftlist *shift_list;
    point *pt;
    linedesc *lined;
    stringlist *string_list;
    linelist *line_list;
    ticklist *tick_list;
    doublelist *double_list;
    macro *macro_val;
    coord *coordptr;
    line *lineptr;
    sides side;
    bydesc by;
    axisdesc axistype;
    axis axisname;
    strmod stringmod;
    copydesc *copyd;
}
%type <num> NUMBER num_line_elem expr opt_expr direction radius_spec bar_base
%type <num> opt_wid assignment_statement if_expr
%type <stringmod> strmod
%type <string> IDENT STRING opt_string opt_ident TEXT else_clause REST TROFF
%type <string> START string
%type <val>  FUNC0 FUNC1 FUNC2 tickdir opt_tick_off
%type <val>  line_token
%type <coordptr> opt_coordname COORD_NAME
%type <side>  side  bar_dir
%type <frameptr> sides size size_elem final_size
%type <lined> linedesc_elem linedesc opt_linedesc
%type <string_list> strlist
%type <double_list> num_line expr_list
%type <tick_list> ticklist tickat tickfor tickdesc
%type <pt> point
%type <shift_list> opt_shift
%type <shift> shift 
%type <by> by_clause
%type <axistype> x_axis_desc y_axis_desc
%type <axisname> log_desc
%type <line_list> COPYTEXT
%type <macro_val> MACRO
%type <copyd> until_clause
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
                if ( !the_graph) the_graph = new Picgraph;
		the_graph->init();
		init_dict();
		first_line = 1;
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
	    { first_line = 0;}
|	num_list
	    { first_line = 0; the_graph->visible = 1;}
|	frame_statement
	    { first_line = 0; the_graph->visible = 1;}
|	draw_statement
	    { first_line = 0; the_graph->visible = 1;}
|	next_statement
	    { first_line = 0; the_graph->visible = 1;}
|	plot_statement
	    { first_line = 0; the_graph->visible = 1;}
|	ticks_statement
	    { first_line = 0; the_graph->visible = 1;}
|	grid_statement
	    { first_line = 0; the_graph->visible = 1;}
|	label_statement
	    { first_line = 0; the_graph->visible = 1;}
|	circle_statement
	    { first_line = 0; the_graph->visible = 1;}
|	bar_statement
	    { first_line = 0; the_graph->visible = 1;}
|	line_statement
	    { first_line = 0; the_graph->visible = 1;}
|	coord_statement
	    { first_line = 0; the_graph->visible = 1;}
|	copy_statement
	    { first_line = 0;}
|	define_statement
	    { first_line = 0;}
|	if_statement
	    { first_line = 0;}
|	for_statement
	    { first_line = 0;}
|	graph_statement
	    { first_line = 0;}
|	print_statement
	    { first_line = 0;}
|	sh_statement
	    { first_line = 0;}
|	pic_statement
	    { first_line = 0;}
|	troff_line
	    { first_line = 0;}
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

opt_string:
	    { $$ = 0; } 
|	string
	    { $$ = $1; }
;

string:
	STRING
             { $$ = $1; }
|       SPRINTF LPAREN STRING COMMA expr_list RPAREN
             {
		 grap_sprintf_String *s = new grap_sprintf_String($3);
		 num_to_str_f num_to_str(s);    

		 for_each($5->begin(), $5->end(), num_to_str);
		 s->finish_fmt();
		 delete $5;
		 delete $3;

		 $$ = (String *) s;
	     }
;

expr_list:
	expr
            {
		$$ = new doublelist;
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
            { $$ = new linedesc; }
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
;

linedesc:
	 linedesc_elem
	    { $$ = $1; }
|	 linedesc linedesc_elem
            {
		$$ = $1;
		if ( $2->ld != def ) {
		    $$->ld = $2->ld;
		    $$->param = $2->param;
		}
		if ( $2->fill ) $$->fill = $2->fill;
		if ( $2->color ) {
		    if ( $$->color ) delete $$->color;
		    $$->color = $2->color;
		    // Don't let the destructor delete the color in $$.
		    $2->color = 0;
		}
		if ( $2->fillcolor ) {
		    if ( $$->fillcolor ) delete $$->fillcolor;
		    $$->fillcolor = $2->fillcolor;
		    // Don't let the destructor delete the fillcolor
		    // in $$.
		    $2->fillcolor = 0;
		}
		delete $2;
	    }
;

draw_statement:
	DRAW opt_ident linedesc opt_string SEP
	    {
		line *l;
		lineDictionary::iterator li;
		linedesc defld(invis,0,0);
		String s = "\"\\(bu\"";

		if ( $2 ) {
		    li = the_graph->lines.find(*$2);
		    if ( li == the_graph->lines.end() ) {
			l = new line(&defld,&s);
			the_graph->lines[*$2] = l;
		    }
		    else {
			l = (*li).second;
		    }
		} else l = defline;

		l->desc = *$3;

		if ( $4 ) {
		    if ( l->plotstr ) *l->plotstr = *$4;
		    else l->plotstr = new String(*$4);
		    delete $4;
		}
		else {
		    if (l->plotstr) {
			delete l->plotstr;
			l->plotstr = 0;
		    }
		}
		l->initial = 1;
		delete $3;
	    }
;

num_list:
	num_line SEP
	    {
		double x, y;

		if ( $1->empty() )
		    exit(20);
		else {
		    x = $1->front();
		    $1->pop_front();
		}
		
		if ( $1->empty() ) {
		    defline->addpoint(nlines,x,defcoord);
		    defcoord->newpt(nlines,x);
		}
		else {
		    while ( !$1->empty() ) {
			y = $1->front();
			$1->pop_front();
			defline->addpoint(x,y,defcoord);
			defcoord->newpt(x,y);
		    }
		}
		delete $1;
		nlines++;
	    }
;

num_line_elem:
	NUMBER
	    {
		$$ = $1;
	    }
|
	MINUS NUMBER
	    {
		$$ = -$2;
	    }
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
|	expr EQ expr
            { $$ = ($1 == $3); }
|	expr NEQ expr
            { $$ = ($1 != $3); }
|	expr LT expr
            { $$ = ($1 < $3); }
|	expr GT expr
            { $$ = ($1 > $3); }
|	expr LTE expr
            { $$ = ($1 <= $3); }
|	expr GTE expr
            { $$ = ($1 >= $3); }
|	expr AND expr
            { $$ = ($1 && $3); }
|	expr OR expr
            { $$ = ($1 || $3); }
|	NOT expr %prec PLUS
            { $$ = ! ( (int) $2); }
|	FUNC0 LPAREN RPAREN
	    {
		switch ($1) {
		    case RAND:
			$$ = double(random()) / (pow(2,32)-1);
			break;
		    default:
			$$ = 0;
			break;
		}
	    }
|	FUNC1 LPAREN expr RPAREN
 	    {
		switch ($1) {
		    case LOGFCN:
			$$ = log10($3);
			break;
		    case EXP:
			$$ = pow(10,$3);
			break;
		    case EEXP:
			$$ = exp($3);
			break;
		    case INT:
			$$ = int($3);
			break;
		    case SIN:
			$$ = sin($3);
			break;
		    case COS:
			$$ = cos($3);
			break;
		    case SQRT:
			$$ = sqrt($3);
			break;
		    default:
			$$ = 0;
			break;
		}
	    }
|	FUNC2 LPAREN expr COMMA expr RPAREN
	    {

		switch ($1) {
		    case MAXFUNC:
			$$ = ($3 > $5 ) ? $3 : $5;
			break;
		    case MINFUNC:
			$$ = ($3 < $5 ) ? $3 : $5;
			break;
		    case ATAN2:
			$$ = atan2($3,$5);
			break;
		    default:
			$$ = 0;
			break;
		}
	    }
|	LPAREN expr RPAREN
 	    { $$ = $2; }
|	IDENT
 	    {
		double *d;
		doubleDictionary::iterator di;
		
		if ( (di = vars.find(*$1)) != vars.end()) {
		    d = (*di).second;
		    $$ = *d;
		}
		else {
		    cerr << *$1 << " is uninitialized, using 0.0" << endl;
		    $$ = 0.0;
		}

		delete $1;
	     }
|	NUMBER
	    { $$ = $1; }
;

if_expr:
	if_expr PLUS if_expr
	    { $$ = $1 + $3; }
|	if_expr MINUS if_expr
            { $$ = $1 - $3; }
|	if_expr TIMES if_expr
	    { $$ = $1 * $3; }
|	if_expr DIV if_expr
	    { $$ = $1 / $3; }
|	if_expr CARAT if_expr
	    { $$ = pow($1,$3);}
|	MINUS if_expr %prec CARAT
	    { $$ = - $2;}
|	if_expr EQ if_expr
            { $$ = ($1 == $3); }
|	if_expr NEQ if_expr
            { $$ = ($1 != $3); }
|	if_expr LT if_expr
            { $$ = ($1 < $3); }
|	if_expr GT if_expr
            { $$ = ($1 > $3); }
|	if_expr LTE if_expr
            { $$ = ($1 <= $3); }
|	if_expr GTE if_expr
            { $$ = ($1 >= $3); }
|	if_expr AND if_expr
            { $$ = ($1 && $3); }
|	if_expr OR if_expr
            { $$ = ($1 || $3); }
|	NOT if_expr %prec PLUS
            { $$ = ! ( (int) $2); }
|	FUNC0 LPAREN RPAREN
	    {
		switch ($1) {
		    case RAND:
			$$ = double(random()) / (pow(2,32)-1);
			break;
		    default:
			$$ = 0;
			break;
		}
	    }
|	FUNC1 LPAREN if_expr RPAREN
 	    {
		switch ($1) {
		    case LOGFCN:
			$$ = log10($3);
			break;
		    case EXP:
			$$ = pow(10,$3);
			break;
		    case EEXP:
			$$ = exp($3);
			break;
		    case INT:
			$$ = int($3);
			break;
		    case SIN:
			$$ = sin($3);
			break;
		    case COS:
			$$ = cos($3);
			break;
		    case SQRT:
			$$ = sqrt($3);
			break;
		    default:
			$$ = 0;
			break;
		}
	    }
|	FUNC2 LPAREN if_expr COMMA if_expr RPAREN
	    {

		switch ($1) {
		    case MAXFUNC:
			$$ = ($3 > $5 ) ? $3 : $5;
			break;
		    case MINFUNC:
			$$ = ($3 < $5 ) ? $3 : $5;
			break;
		    case ATAN2:
			$$ = atan2($3,$5);
			break;
		    default:
			$$ = 0;
			break;
		}
	    }
|	LPAREN if_expr RPAREN
 	    { $$ = $2; }
|	IDENT
 	    {
		double *d;
		doubleDictionary::iterator di;
		
		if ( (di = vars.find(*$1)) != vars.end()) {
		    d = (*di).second;
		    $$ = *d;
		}
		else {
		    cerr << *$1 << " is uninitialized, using 0.0" << endl;
		    $$ = 0.0;
		}

		delete $1;
	     }
|	NUMBER
	    { $$ = $1; }
|	string EQ string
            { $$ = (*$1 == *$3); }
|	string NEQ string
            { $$ = (*$1 != *$3); }
;

assignment_statement:
	IDENT EQUALS expr SEP
	    {
		double *d;
		doubleDictionary::iterator di;
		
		if ( ( di = vars.find(*$1)) != vars.end() ) {
		    d = (*di).second;
		    *d = $3;
		}
		else {
		    d = new double($3);
		    vars[*$1] = d;
		}
		$$ = *d;
	    }
|	IDENT EQUALS assignment_statement
 	    {
 		double *d;
 		doubleDictionary::iterator di;
 		
 		if ( ( di = vars.find(*$1)) != vars.end() ) {
 		    d = (*di).second;
 		    *d = $3;
 		}
 		else {
 		    d = new double($3);
 		    vars[*$1] = d;
 		}
 		$$ = *d;
  	    }
;

point:
	opt_coordname expr COMMA expr
	    {
		$$ = new point($2,$4,$1);
		$1->newpt($2,$4);
	    }
|	opt_coordname LPAREN expr COMMA expr RPAREN
	    {
		$$ = new point($3,$5,$1);
		$1->newpt($3,$5);
	    }
;

strmod:
	    {
		$$.size = 0;
		$$.rel =0;
		$$.just = (unaligned_default) ? unaligned : 0;
	    }
| 	strmod SIZE expr
	    { $$.size = $3; $$.rel = ($3<0);}
| 	strmod SIZE PLUS expr
	    { $$.size = $4; $$.rel = 1;}
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
;

strlist:
	string strmod
	    {
		DisplayString *s;

		s = new DisplayString(*$1,$2.just,$2.size, $2.rel);
		delete $1;
		$$ = new stringlist;
		$$->push_back(s);
	    }
|	strlist string strmod
	    {
		// This collects the modifiers for other strings in
		// the list to construct the modifiers for this string
		modaccumulator last;
		DisplayString *s;
			
		last = for_each($1->begin(), $1->end(), modaccumulator());

		// If unaligned_default is set, then treat unaligned
		// strings as unmodified strings
		
		if ( $3.just != (unaligned_default ? unaligned : 0) )
		    last.just = $3.just;
		
		if ( $3.size != 0 ) {
		    last.size = $3.size;
		    last.rel = $3.rel;
		}

		s = new DisplayString(*$2,last.just,last.size,last.rel);
		delete $2;
		$$ = $1;
		$$->push_back(s);
	    }
;

plot_statement:
	strlist AT point SEP
	    {
		plot *p = new plot($1,$3);
		the_graph->add_plot(*p);
		delete p;
	    }
|	PLOT expr opt_string AT point SEP
	    {
		stringlist *seq = new stringlist;
		DisplayString *s;
		plot *p;

		if ( $3 ) {
		    unquote($3);
		    s = new DisplayString($2,$3);
		    delete $3;
		}
		else s = new DisplayString($2);

		quote(s);
		seq->push_back(s);

		p = new plot(seq,$5);
		the_graph->add_plot(*p);
		delete p;
	    }
;

next_statement:
	NEXT opt_ident AT point opt_linedesc SEP
	    {
		line *l;
		lineDictionary::iterator li;
		String s = "\"\\(bu\"";

		if ( $2 ) {
		    li = the_graph->lines.find(*$2);
		    if ( li == the_graph->lines.end() ) {
			l = new line((linedesc *)0, &s );
			the_graph->lines[*$2] = l;
		    }
		    else { l = (*li).second; }
		} else l = defline;
		
		if ( $5->ld != def )
		    l->addpoint($4->x,$4->y,$4->c,0,$5);
		else 
		    l->addpoint($4->x,$4->y,$4->c);
		
		delete $4;
		delete $5;
	    }
;

size_elem:
	HT expr
            {
		$$ = new frame;
		$$->ht = $2;
		$$->wid = 0;
	    }
|	WID expr
            {
		$$ = new frame;
		$$->wid = $2;
		$$->ht = 0;
	    }
;

size:
	size_elem
            {
		$$ = $1;
	    }
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
	    { $$ = top;}
|	BOTTOM
	    { $$= bottom;}
|	LEFT
	    { $$ = left;}
|	RIGHT
	    { $$ = right; }
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
            { $$ = new shiftdesc(top, $2);}
|	DOWN expr
            { $$ = new shiftdesc(bottom, $2);}
|	LEFT expr
            { $$ = new shiftdesc(left, $2);}
|	RIGHT expr
            { $$ = new shiftdesc(right, $2);}
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
	expr opt_string
	    {
		tick *t = new tick($1,0,top,0, (shiftlist *) 0, 0);
 		String *s;

		if ( $2 ) {
		    unquote($2);
		    s = dblString($1,$2);
		}
		else s = dblString($1);

		t->prt = s;
		delete $2;
		
		$$ = new ticklist;
		$$->push_back(t);
	    }
|	ticklist COMMA expr opt_string
	    {
		tick *t = new tick($3,0,top,0,(shiftlist *) 0, 0);
 		String *s;

		if ( $4 ) {
		    unquote($4);
		    s = dblString($3,$4);
		}
		else s = dblString($3);

		t->prt = s;
		delete $4;
		
		$$ = $1;
		$$->push_back(t);
		
	    }
;

by_clause:
	    { $$.op = PLUS; $$.expr = 1; }
|	BY opt_expr
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
		for_each($3->begin(), $3->end(), coord_to_tick($2));
	    }
;

tickfor:
	from opt_coordname expr TO expr by_clause opt_string
	    {
		tick *t;
 		String *s;
		String *fmt;
		double idx;
		int dir;

		$$ = new ticklist;
		if ( $7 ) {
		    unquote($7);
		    fmt = new String(*$7);
		    delete $7;
		} else
		    fmt = new String("%g");
		
		if ( $5 - $3 >= 0 ) dir = 1;
		else dir = -1;
		
		idx = $3;
		while ( (idx - $5) *dir  < EPSILON ) {
		    t = new tick(idx, 0, top, 0, (shiftlist *) 0, 0);
		    t->c = $2;

		    s = dblString(idx,fmt);
		    t->prt = s;
		    $$->push_back(t);

		    switch ($6.op ) {
			case PLUS:
			    idx += $6.expr;
			    break;
			case MINUS:
			    idx -= $6.expr;
			    break;
			case TIMES:
			    idx *= $6.expr;
			    break;
			case DIV:
			    idx /= $6.expr;
			    break;
		    }
		}
		delete fmt;
		    
	    }
;
tickdesc :
	    { $$ = 0;}
|	tickat
	    { $$ = $1;}
|	tickfor
	    { $$= $1; }
;

ticks_statement:
	TICKS side direction opt_shift tickdesc SEP
	    {
		shiftdesc *sd;
		shiftcpy sc(&the_graph->base->tickdef[$2].shift);
		
		add_tick_f add_tick($2,$3,$4);

		the_graph->base->tickdef[$2].side = $2;

		for_each($4->begin(), $4->end(), sc);

		if ( $5 && $5->empty() )
		    the_graph->base->tickdef[$2].size = $3;
		else
		    the_graph->base->tickdef[$2].size = 0;

		if ( $5 ) {
		    for_each($5->begin(), $5->end(), add_tick);
		    delete $5;
		}
		while (!$4->empty()) {
		    sd = $4->front();
		    $4->pop_front();
		    delete sd;
		}
		delete $4;
	    }
| 	TICKS OFF SEP
	    {
		for ( int i = 0; i< 4; i++ )
		    the_graph->base->tickdef[i].size = 0;
	    }
| 	TICKS side OFF SEP
	    {
		    the_graph->base->tickdef[$2].size = 0;
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
		tick *t;
		grid *g;
		linedesc defgrid(dotted, 0, 0);
		shiftcpy *sc;
		shiftdesc *sd;

		// Turning on a grid turns off default ticks on that side
		
		the_graph->base->tickdef[$2].size = 0;
		
		if ( $4->ld != def ) 
		    the_graph->base->griddef[$2].desc = *$4;
		else {
		    
		    // This is some dirty sleight of hand.  $4->color
		    // is only assigned to defgrid.color long enough
		    // to make these copies. XXX
		    
		    defgrid.color = $4->color;
		    the_graph->base->griddef[$2].desc = defgrid;
		    defgrid.color = 0;
		}

		sc = new shiftcpy(&the_graph->base->griddef[$2].shift);
		for_each($5->begin(), $5->end(), *sc);
		delete sc;

		if ( $3 ) {
		    if ( the_graph->base->griddef[$2].prt )
			delete the_graph->base->griddef[$2].prt;
		    the_graph->base->griddef[$2].prt = 0;
		}
		if ( $6 ) {
		    the_graph->base->griddef[$2].desc.ld = def;
		    while (!$6->empty() ) {
			t = $6->front();
			$6->pop_front();
			
			g = new grid(t);
			g->side = $2;
			if ( $4->ld != def )
			    g->desc = *$4;
			else {

			    // This is some dirty sleight of hand.
			    // $4->color is only assigned to
			    // defgrid.color long enough to make these
			    // copies. XXX
		    
			    defgrid.color = $4->color;
			    g->desc = defgrid;
			    defgrid.color = 0;
			}
		    
			sc = new shiftcpy(&g->shift);
			for_each($5->begin(), $5->end(), *sc);
			delete sc;

			if ( $3 ) {
			    if ( g->prt ) delete g->prt;
			    g->prt = 0;
			}
			the_graph->base->gds.push_back(g);
			if ( g->side == top || g->side == bottom )
			    g->c->newx(g->where);
			else 
			    g->c->newy(g->where);
			delete t;
		    }
		    delete $6;
		}
		while ( !$5->empty() ) {
		    sd = $5->front();
		    $5->pop_front();
		    delete sd;
		}
		delete $5;
		delete $4;
	    }
;

label_statement:
	LABEL side strlist opt_shift SEP
	    {
		align_string a;
		shiftdesc *sd;
			      
		for_each($3->begin(),  $3->end(), a);
		
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
		circle *c = new circle($3,$4,$5);
		the_graph->add_circle(*c);
		delete c; delete $3; delete $5;
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
	    {
		line *l;
		lineDictionary::iterator li;
		linedesc des;

		li = the_graph->lines.find("grap.internal");
		if ( li == the_graph->lines.end() ) {
		    des.ld = solid;
		    l = new line(&des);
		    the_graph->lines["grap.internal"] = l;
		}
		else { l = (*li).second; } 

		des = *$2;
		if ( $7->ld != def ) {
		    des.ld = $7->ld;
		    des.param = $7->param;
		}

		if ( $7->color ) des.color = new String(*$7->color);
		    
		l->initial = 1;

		if ( des.ld != def || des.color) {
		    l->addpoint($4->x,$4->y,$4->c,0,&des);
		    if ( $1 )
			l->addpoint($6->x,$6->y,$6->c,0,&des);
		    else
			l->addarrow($6->x,$6->y,$6->c,0,&des);
		} else {
		    l->addpoint($4->x,$4->y,$4->c);
		    if ($1) l->addpoint($6->x,$6->y,$6->c);
		    else l->addarrow($6->x,$6->y,$6->c);
		}
		delete $2; delete $7;
	    }
;

x_axis_desc:
	    { $$.which=none; }
|	XDIM expr COMMA expr
	    {
		$$.which = x_axis;
		if ($2 < $4 ) {
		    $$.min = $2; $$.max = $4;
		} else {
		    $$.min = $4; $$.max = $2;
		}
	    }
;
y_axis_desc:
	    { $$.which=none; }
|	YDIM expr COMMA expr
	    {
		$$.which = y_axis;
		if ($2 < $4 ) {
		    $$.min = $2; $$.max = $4;
		} else {
		    $$.min = $4; $$.max = $2;
		}
	    }
;

log_desc:
	    { $$ = none; }
|	LOG_X
	    { $$ = x_axis; }
|	LOG_Y
	    { $$ = y_axis; }
|	LOG_LOG
	    { $$ = both; }
;

coord_statement:
	COORD opt_ident x_axis_desc y_axis_desc log_desc SEP
	    {
		coord *c;
		coordinateDictionary::iterator ci;

		if ($2) {
		    ci = the_graph->coords.find(*$2);
		    
		    if (  ci == the_graph->coords.end()) {
			c = new coord;
			the_graph->coords[*$2] = c;
		    }
		    else { c = (*ci).second; }
		    delete $2;
		} else {
		    c = defcoord;
		}
		if ( $3.which != none ) {
		    c->xmin = $3.min;
		    c->xmax = $3.max;
		    c->xautoscale = 0;
		}
		if ( $4.which != none ) {
		    c->ymin = $4.min;
		    c->ymax = $4.max;
		    c->yautoscale = 0;
		}
		c->logscale = $5;
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

copy_statement:
	COPY string SEP
	    {
		unquote($2);
		if (!include_file($2, 0)) return 0;
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
		if ( c ) {
		    // lex_begin_copy takes command of the string that's
		    // passed to it, sio don't delete it.  (I don't
		    // remember why I did that...)
		    if ( c->t == copydesc::until ) lex_begin_copy(c->s);
		    else {
			lex_begin_copy(0);
			include_file(c->s, 0);
			delete c->s;
		    }
		    delete c;
		}
	    }
	COPYTEXT
	    {
		String *s;
		String *t;
		String *expand;
		int lim;
		char end;

		expand = new String;

		while ( $9 && !$9->empty() ) {
		    int i = 0;
		    t = new String;
		    
		    s = $9->front();
		    $9->pop_front();
		    lim = s->length();
		    
		    while ( i < lim ) {
			if ( (*s)[i] == ' ' || (*s)[i] == '\t' ) {
			    if ( t->length() ) {
				if ( $5->add_arg(t)) 
				    t = new String;
			    }
			} else *t += (*s)[i];
			i++;
		    }
		    if ( t->length() ) $5->add_arg(t);
		    else if (t) delete t;
		    t = $5->invoke();
		    *expand += *t;
		    // "here" macros should end with a SEP.  If the user
		    // hasn't done so, we add a SEP for them.  XXX this
		    // may be configuarble later

		    end = (*expand)[expand->length()-1];

		    if ( !$5->name && end != ';' && end != '\n' ) 
			*expand += ';';
		    delete t;
		    delete s;
		}
		
		include_string(expand,0,GMACRO);
		delete expand;
		delete $9;
		// don't delete defined macros
		if ( !$5->name)
		    delete $5;
	    }
;

define_statement:
	DEFINE { lex_expand_macro = 0;} IDENT { lex_begin_macro_text(); } TEXT SEP
	    {
		macro *m;
		macroDictionary::iterator mi;
		if ( ( mi = macros.find(*$3)) != macros.end() ) {
		    m = (*mi).second;
		    if ( m->text ) {
			delete m->text;
			m->text = $5;
		    }
		} else {
		    m = new macro($5,$3);
		    macros[*$3] = m;
		}
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
	IF if_expr THEN { lex_begin_macro_text(); } TEXT else_clause SEP
	    {
		// force all if blocks to be terminated by a SEP
		*$5 += ';';
		if ( fabs($2) > EPSILON ) include_string($5,0,GINTERNAL);
		else if ( $6 ) include_string($6,0,GINTERNAL);
		delete $5;
		if ( $6) delete $6;
	    }
;

for_statement:
	FOR IDENT from expr TO expr by_clause DO { lex_begin_macro_text(); } TEXT SEP
	    {
		struct for_descriptor *f;
		doubleDictionary::iterator di;
		double *d;
		
		f = new for_descriptor;

		if ( ( di = vars.find(*$2)) != vars.end() ) {
		    d = (*di).second;
		    *d = $4;
		}
		else {
		    d = new double($4);
		    vars[*$2] = d;
		}
		f->loop_var = d;
		if ( $6 -$4 > 0 ) f->dir = 1;
		else f->dir = -1;

		f->limit = $6;
		f->by = $7.expr;
		f->by_op = $7.op;
		// force "anything" to end with a sep
		*$10 += ';';
		f->anything = $10;
		include_string($10,f,GINTERNAL);
	    }
;

graph_statement:
	GRAPH IDENT { lex_begin_rest_of_line(); } REST SEP
	    {
		if ( !first_line ) {
		    the_graph->draw(0);
		    the_graph->init($2, $4);
		    init_dict();
		}
		else {
		    the_graph->init($2, $4);
		    init_dict();
		}
		    
		if ( $2 ) delete $2;
		if ( $4 ) delete $4;
	    }
;

print_statement:
	PRINT string SEP
	    {
		unquote($2);
		cerr <<  *$2 << endl;
	    }
|	PRINT expr SEP
	    {
		cerr << $2 << endl;
	    }
;

pic_statement:
	PIC { lex_begin_rest_of_line(); } REST SEP
	    { the_graph->pic_string($3); delete $3;}
;
troff_line:
	TROFF SEP
	    { the_graph->troff_string($1); delete $1;}
;

bar_dir:
        RIGHT
            { $$ = right; } 
|       UP
             { $$ = top; } 
;
bar_base:
	BASE expr
            { $$ = $2; }
|
            { $$ = 0; }
;

opt_wid:
	WID expr
            { $$=$2; }
|
            { $$ = 1; }
;
	
bar_statement:
        BAR point COMMA point opt_linedesc SEP
            {
		// The point parsing has already autoscaled the
		// coordinate system to include those points.
		box *b = new box($2, $4, $5);
		the_graph->add_box(*b);
		delete $2; delete $4; delete $5;
		delete b;
	    }
|	BAR opt_coordname bar_dir expr HT expr opt_wid bar_base opt_linedesc SEP
            {
		point *p1, *p2;		// The defining points of the box
		box *b;			// The new box

		switch ($3) {
		    case right:
			p1 = new point($8, $4 + $7/2, $2);
			p2 = new point($8 + $6, $4 - $7/2, $2);
			break;
		    case top:
		    default:
			p1 = new point($4 + $7/2, $8, $2);
			p2 = new point($4 - $7/2, $8 + $6, $2);
			break;
		}
		
		$2->newpt(p1->x,p1->y);
		$2->newpt(p2->x,p2->y);
		
		b = new box(p1, p2, $9);
		the_graph->add_box(*b);
		delete p1; delete p2; delete $9;
		delete b;
	    }
;
%%

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
    //abort();
    //exit (1);
    return 0;
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
void init_dict() {
    linedesc defld(invis,0,0);
    String s = "\"\\(bu\"";
    
    defcoord = new coord;
    the_graph->coords["grap.internal.default"] = defcoord;
    for ( int i = 0 ; i < 4; i++) {
	the_graph->base->tickdef[i].c = defcoord;
	the_graph->base->griddef[i].c = defcoord;
    }
    defline = new line(&defld,&s);
    the_graph->lines["grap.internal.default"] = defline;
    nlines = 0;
}

int main(int argc, char** argv) {
    String defines=DEFINES;
    String fname;
    int use_defines = 1;
    char c;

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
		cout << version << endl;
		exit(0);
	    case 'u':
		unaligned_default = 1;
		break;
	}
    if ( argc == optind ) {
	fname = "-";
	include_file(&fname,1);
    }
    else {
	for ( int i = argc-1; i >= optind; i-- ) {
	    fname = argv[i];
	    include_file(&fname,1);
	}
    }
    if ( use_defines) include_file(&defines,1);
    yyparse();
}
