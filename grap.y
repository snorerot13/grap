%{
#include <stdio.h>
#include <iostream.h>
#include <math.h>
#include <stdlib.h>
#include "grap.h"

#ifndef DEFINES
#define DEFINES "/usr/share/grap/grap.defines"
#endif

doubleDictionary vars;
coordinateDictionary coordinates;
lineDictionary lines;
plotSequence plots;
circleSequence circles;
stringSequence pic;
stringSequence troff;
frame the_frame;
lexStack lexstack;
macroDictionary macros;
int visible;
int first_line;
int graphs;

extern int lex_expand_macro;

line* defline;
coord *defcoord;
String *graph_name;
String *graph_pos;
String *ps_param;

// defined in grap_lex.l
extern bool include_file(String *, int i=0);
extern void lex_begin_macro_text();
extern void lex_begin_rest_of_line();
extern void lex_begin_copy( String*s=0);
extern int include_string(String *,struct for_descriptor *f=0,
			  grap_input i=GMACRO);
extern void lex_hunt_macro();
void draw_graph();
void init_graph();

int nlines;
int in_copy=0;

extern char *optarg;
extern int optind;
extern int optopt;
extern int opterr;
extern int optreset;

const char *opts = "d:D";

%}
%token NUMBER START END IDENT COPY SEP COPY_END STRING LINE_NAME COORD_NAME
%token SOLID INVIS DOTTED DASHED DRAW LPAREN RPAREN FUNC0 FUNC1 FUNC2 COMMA
%token LINE PLOT FROM TO AT NEXT FRAME LEFT RIGHT TOP BOTTOM UP DOWN FRAMESIZE
%token UP DOWN IN OUT TICKS OFF BY GRID LJUST RJUST ABOVE BELOW ALIGNED
%token PLUS MINUS TIMES DIV CARAT EQUALS SIZE UNALIGNED LABEL RADIUS CIRCLE
%token LINE ARROW X Y LOG_X LOG_Y LOG_LOG COORD TEXT DEFINE IF THEN ELSE
%token EQ NEQ LT GT LTE GTE NOT OR AND FOR DO MACRO COPYTEXT THRU
%token GRAPH REST PRINT PIC TROFF UNTIL COLOR
%start graphs
%union {
    int val;
    double num;
    String *string;
    frame *frameptr;
    shiftdesc shift;
    point *pt;
    linedescval linedesc;
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
}
%type <num> NUMBER expr opt_expr direction radius_spec
%type <stringmod> strmod
%type <string> IDENT STRING opt_string opt_ident TEXT else_clause REST TROFF
%type <string> until_clause START
%type <val>  FRAMESIZE FUNC0 FUNC1 FUNC2 tickdir opt_tick_off
%type <val>  line_token
%type <coordptr> opt_coordname COORD_NAME
%type <side>  side
%type <frameptr> sides size
%type <linedesc> linedesc_elem linedesc opt_linedesc
%type <string_list> strlist
%type <double_list> num_line 
%type <tick_list> ticklist tickat tickfor tickdesc
%type <pt> point
%type <shift> shift opt_shift
%type <by> by_clause
%type <axistype> x_axis_desc y_axis_desc
%type <axisname> log_desc
%type <line_list> COPYTEXT
%type <macro_val> MACRO
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
                init_graph();
		first_line = 1;
		graphs = 0;
		if ( $1 ) ps_param = $1;
		else ps_param = 0;
	    } prog END
            {
		draw_graph();
		if ( graphs ) cout << ".PE" << endl;
		if ( ps_param ) {
		    delete ps_param;
		    ps_param = 0;
		}
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
	    { first_line = 0; visible = 1;}
|	frame_statement
	    { first_line = 0; visible = 1;}
|	draw_statement
	    { first_line = 0; visible = 1;}
|	next_statement
	    { first_line = 0; visible = 1;}
|	plot_statement
	    { first_line = 0; visible = 1;}
|	ticks_statement
	    { first_line = 0; visible = 1;}
|	grid_statement
	    { first_line = 0; visible = 1;}
|	label_statement
	    { first_line = 0; visible = 1;}
|	circle_statement
	    { first_line = 0; visible = 1;}
|	line_statement
	    { first_line = 0; visible = 1;}
|	coord_statement
	    { first_line = 0; visible = 1;}
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
|	STRING
	    { $$ = $1; }
;


opt_expr:
            { $$ = 0; }
|	NUMBER
	    { $$ = $1; }
;

opt_linedesc:
            { $$.ld = def; $$.param = 0; $$.color = 0;}
|	linedesc
	    {  $$ = $1;}
;

opt_shift:
            { $$.dir = top; $$.param = 0; }
|	 shift
	    { $$ = $1; }
;


linedesc_elem:
	INVIS
	    { $$.ld = invis; $$.param = 0; $$.color = 0;}
|	 SOLID
	    { $$.ld = solid;  $$.param = 0; $$.color = 0;}
|	 DOTTED opt_expr
	    { $$.ld = dotted; $$.param = $2; $$.color = 0;}
|	 DASHED opt_expr
	    { $$.ld = dashed; $$.param = $2; $$.color = 0;}
|	 COLOR STRING
	    { $$.ld = def; $$.color = $2; }
;

linedesc:
	 linedesc_elem
	    { $$ = $1; }
|	 linedesc linedesc_elem
            {
		$$ = $1;
		if ( $2.ld != def ) {
		    $$.ld = $2.ld;
		    $$.param = $2.param;
		}
		if ( $2.color ) {
		    if ( $$.color ) delete $$.color;
		    $$.color = $2.color;
		}
	    }
;

draw_statement:
	DRAW opt_ident linedesc opt_string SEP
	    {
		line *l;
		linedescval defld = { invis,0,0 };

		if ( $2 ) {
		    if ( !lines.find($2,l) ) {
			l = new line(&defld,&String("\"\\(bu\""));
			lines.insert($2,l);
		    }
		} else l = defline;

		l->desc = $3;

		if ( $4 ) {
		    if ( l->plotstr ) *l->plotstr = *$4;
		    else l->plotstr = new String($4);
		    delete $4;
		}
		else {
		    if (l->plotstr) {
			delete l->plotstr;
			l->plotstr = 0;
		    }
		}
		l->initial = 1;
		
	    }
;

num_list:
	num_line SEP
	    {
		double x, y;
		int gn;

		gn = $1->first(x);
		if ( !gn ) exit(20);
		if ( !$1->next(y) ) {
		    defline->addpoint(nlines,x,defcoord);
		    defcoord->newpt(nlines,x);
		} else {
		    while ( gn ) {
			defline->addpoint(x,y,defcoord);
			defcoord->newpt(x,y);
			gn = $1->next(y);
		    }
		}
		delete $1;
		nlines++;
	    }
;

num_line:
	NUMBER
	    {
		$$ = new doublelist;
		$$->insert($1);
	    }
|	num_line NUMBER
	    {
		$$ = $1;
		$$->insert($2);
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
|	STRING EQ STRING
            { $$ = ($1 == $3); }
|	STRING NEQ STRING
            { $$ = ($1 != $3); }
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
		
		if ( vars.find($1,d)) $$ = *d;
		else cout << "Can't find " << $1 << endl;

		delete $1;
	     }
|	NUMBER
	    { $$ = $1; }
;

assignment_statement:
	IDENT EQUALS expr SEP
	    {
		double *d;
		
		if ( vars.find($1,d) ) *d = $3;
		else {
		    d = new double($3);
		    vars.insert($1,d);
		}
	    }

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
	    { $$.size = 0; $$.rel =0; $$.just =0; }
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
|	strmod ALIGNED;
	    { $$.just |= (int) aligned; }
|	strmod UNALIGNED;
	    { $$.just |= (int) unaligned; }
;

strlist:
	STRING strmod
	    {
		DisplayString *s;

		s = new DisplayString($1,$2.just,$2.size, $2.rel);
		delete $1;
		$$ = new stringlist;
		$$->insert(s);
	    }
|	strlist STRING strmod
	    {
		DisplayString *s;
		int just;
		double size;
		int rel;
		int gn;

		for ( gn = $1->first(s); gn; gn = $1->next(s) ) {
		    just = s->j;
		    size = s->size;
		    rel = s->relsz;
		}
		
		if ( $3.just != 0 )
		    just = $3.just;
		
		if ( $3.size != 0 ) {
		    size = $3.size;
		    rel = $3.rel;
		}

		s = new DisplayString($2,just,size,rel);
		delete $2;
		$$ = $1;
		$$->insert(s);
	    }
;

plot_statement:
	strlist AT point SEP
	    {
		plot *p = new plot($1,$3);
		plots.insert(p);
	    }
|	PLOT expr opt_string AT point SEP
	    {
		stringlist *seq = new stringlist;
		DisplayString *s;
		plot *p;

		if ( $3 ) {
		    $3->unquote();
		    s = new DisplayString($2,$3);
		    delete $3;
		}
		else s = new DisplayString($2);

		s->quote();
		seq->insert(s);

		p = new plot(seq,$5);
		plots.insert(p);
		    
	    }
;

next_statement:
	NEXT opt_ident AT point opt_linedesc SEP
	    {
		line *l;

		if ( $2 ) {
		    if ( !lines.find($2,l) ) {
			l = new line((linedescval *)0, &String("\"\\(bu\"") );
			lines.insert($2,l);
		    }
		} else l = defline;
		
		if ( $5.ld != def )
		    l->addpoint($4->x,$4->y,$4->c,0,&$5);
		else 
		    l->addpoint($4->x,$4->y,$4->c);
		
		delete $4;
	    }
;

size:
	    { $$ = 0;}
|	size FRAMESIZE expr
	    {
		if ( !$1 ) 
		    $$ = new frame;
		else 
		    $$ = $1;
		
		switch ($2) {
		    case ht:
			$$->ht = $3;
			break;
		    case wid:
			$$->wid = $3;
			break;
		}
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
sides:
	    {
		$$ = 0;
	    }
|	sides side linedesc
	    {
		if ( !$1 ) $$ = new frame;
		else $$ = $1;
		
		$$->desc[$2] = $3;
	    }
;

frame_statement:
	FRAME opt_linedesc size sides SEP
	    {
		int i;

		if ( $2.ld != def ) {
		    for ( i = 0 ; i < 4; i++ ) {
			the_frame.desc[i] = $2;
		    }
		}
		
		if ( $3 ) {
		    the_frame.ht = $3->ht;
		    the_frame.wid = $3->wid;
		    delete $3;
		}
		
		if ( $4 ) {
		    for ( i = 0 ; i < 4; i++ ) {
			if ( $4->desc[i].ld != def )
			    the_frame.desc[i] = (linedescval) $4->desc[i];
		    }
		    delete $4;
		}
	    }
;

shift:
	UP expr
	    { $$.dir = top; $$.param = $2;}
|	DOWN expr
	    { $$.dir = bottom; $$.param = $2;}
|	LEFT expr
	    { $$.dir = left; $$.param = $2;}
|	RIGHT expr
	    { $$.dir = right; $$.param = $2;}
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
		tick *t = new tick($1,0,top,0, 0, 0);
 		String *s;

		if ( $2 ) {
		    $2->unquote();
		    s = new String($1,$2);
		}
		else s = new String($1);

		t->prt = s;
		delete $2;
		
		$$ = new ticklist;
		$$->insert(t);
	    }
|	ticklist COMMA expr opt_string
	    {
		tick *t = new tick($3,0,top,0,0, 0);
 		String *s;

		if ( $4 ) {
		    $4->unquote();
		    s = new String($3,$4);
		}
		else s = new String($3);

		t->prt = s;
		delete $4;
		
		$$ = $1;
		$$->insert(t);
		
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
|	BY MINUS expr
	    { $$.op = MINUS; $$.expr = $3; }
|	BY TIMES expr
	    { $$.op = TIMES; $$.expr = $3; }
|	BY DIV expr
	    { $$.op = DIV; $$.expr = $3; }
;

tickat:
	AT opt_coordname ticklist
	    {
		tick *t;
		int gn;

		$$ = $3;
		
		for ( gn  = $3->first(t); gn ; gn = $3->next(t)) {
		    t->c = $2;
		}
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
		    $7->unquote();
		    fmt = new String($7);
		    delete $7;
		} else
		    fmt = new String("%g");
		
		if ( $5 - $3 > 0 ) dir = 1;
		else dir = -1;
		
		idx = $3;
		while ( (idx - $5) *dir  < EPSILON ) {
		    t = new tick(idx,0,top,0,0, 0);
		    t->c = $2;

		    s = new String(idx,fmt);
		    t->prt = s;
		    $$->insert(t);

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
		tick *t;
		int gn;

		the_frame.tickdef[$2].side = $2;
		the_frame.tickdef[$2].size = $3;
		the_frame.tickdef[$2].shift = $4;

		for ( gn = $5 && $5->first(t); gn ; gn = $5->next(t)) {
		    the_frame.tickdef[$2].size = 0;
		    t->side = $2;
		    t->size = $3;
		    t->shift = $4;
		    the_frame.tks.insert(t);
		    if ( t->side == top || t->side == bottom )
			t->c->newx(t->where);
		    else 
			t->c->newy(t->where);
		}
		if ( $5 ) delete $5;
	    }
| 	TICKS OFF SEP
	    {
		for ( int i = 0; i< 4; i++ )
		    the_frame.tickdef[i].size = 0;
	    }
| 	TICKS side OFF SEP
	    {
		    the_frame.tickdef[$2].size = 0;
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
		int gn;
		linedescval defgrid = { dotted, 0,0 };

		// Turning on a grid turns off default ticks on that side
		
		the_frame.tickdef[$2].size = 0;
		
		if ( $4.ld != def ) 
		    the_frame.griddef[$2].desc = $4;
		else {
		    defgrid.color = $4.color;
		    the_frame.griddef[$2].desc = defgrid;
		    defgrid.color = 0;
		}


		the_frame.griddef[$2].shift = $5;

		if ( $3 ) {
		    if ( the_frame.griddef[$2].prt )
			delete the_frame.griddef[$2].prt;
		    the_frame.griddef[$2].prt = 0;
		}
		for ( gn = $6 && $6->first(t); gn ; gn = $6->next(t)) {
		    the_frame.griddef[$2].desc.ld = def;
		    g = new grid(t);
		    g->side = $2;
		    if ( $4.ld != def )
			g->desc = $4;
		    else {
			defgrid.color = $4.color;
			g->desc = defgrid;
			defgrid.color = 0;
		    }
		    
		    g->shift = $5;

		    if ( $3 ) {
			if ( g->prt ) delete g->prt;
			g->prt = 0;
		    }
		    the_frame.gds.insert(g);
		    if ( g->side == top || g->side == bottom )
			g->c->newx(g->where);
		    else 
			g->c->newy(g->where);
		    delete t;
		}
		if ( $6) delete $6;
	    }
;

label_statement:
	LABEL side strlist opt_shift SEP
	    {
		int gn;
		DisplayString *ds;

		for ( gn = $3->first(ds); gn ; gn = $3->next(ds) )
		    if ( ! (ds->j & unaligned) ) ds->j |= aligned;
		
		the_frame.label[$2] = $3;
		if ( $4.param != 0 ) {
		    the_frame.lshift[$2] = $4;
		}
		else {
		    the_frame.lshift[$2].dir = $2;
		    the_frame.lshift[$2].param = 0.4;
		}
	    }
;
radius_spec:
	    { $$ = 0.025; }
|	RADIUS expr
	    { $$ = $2; }
;

circle_statement:
	CIRCLE AT point radius_spec SEP
	    {
		circle *c = new circle($3,$4);
		circles.insert(c);
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
		linedescval des;

		if ( !lines.find("grap.internal", l) ) {
		    des.ld = solid;
		    des.param = 0;
		    des.color = 0;
		    l = new line(&des);
		    lines.insert("grap.internal",l);
		}

		des = $2;
		if ( $7.ld != def ) {
		    des.ld = $7.ld;
		    des.param = $7.param;
		}

		if ( $7.color ) des.color = $7.color;
		    
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
	    }
;

x_axis_desc:
	    { $$.which=none; }
|	X expr COMMA expr
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
|	Y expr COMMA expr
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
		if ($2) {
		    if (!coordinates.find($2,c)) {
			c = new coord;
			coordinates.insert($2,(coord *) c);
		    }
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
|	UNTIL STRING
	    {
		$2->unquote();
		$$ = $2;
	    }
;

copy_statement:
	COPY STRING SEP
	    {
		$2->unquote();
		if (!include_file($2)) return 0;
	    }
|	COPY opt_string until_clause THRU { lex_hunt_macro(); } MACRO SEP
	    {
		if ( $2 && $3 ) {
		    yyerror("Can't specify both filename and until");
		}
		lex_begin_copy($3);
		if ( $2 ) {
		    $2->unquote();
		    include_file($2);
		    delete $2;
		}
	    }
	COPYTEXT
	    {
		String *s;
		String *t;
		String *expand;
		int gn;

		expand = new String;
		
		for ( gn = $9->first(s); gn ; gn = $9->next(s) ) {
		    int i = 0;
		    t = new String;
		    
		    while ( (*s)[i] != '\0' ) {
			if ( (*s)[i] == ' ' || (*s)[i] == '\t' ) {
			    if ( t->strlen() ) {
				if ( $6->add_arg(t)) 
				    t = new String;
			    }
			} else *t += (*s)[i];
			i++;
		    }
		    if ( t->strlen() ) $6->add_arg(t);
		    t = $6->invoke();
		    *expand += t;
		    delete t;
		}
		include_string(expand,0,GMACRO);
		delete expand;
		delete $9;
		delete $6;
	    }
;

define_statement:
	DEFINE { lex_expand_macro = 0;} IDENT { lex_begin_macro_text(); } TEXT SEP
	    {
		macro *m;
		if ( macros.find($3,m) ) {
		    if ( m->text ) {
			delete m->text;
			m->text = $5;
		    }
		} else {
		    m = new macro($5);
		    macros.insert($3,m);
		}
	    }
;

else_clause:
	    { $$ = 0; }
| 	ELSE {lex_begin_macro_text(); } TEXT
	    { $$ = $3; }
;

if_statement:
	IF expr THEN { lex_begin_macro_text(); } TEXT else_clause SEP
	    {
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
		double *d;
		
		f = new (struct for_descriptor);

		if ( vars.find($2,d) ) *d = $4;
		else {
		    d = new double($4);
		    vars.insert($2,d);
		}
		f->loop_var = d;
		if ( $6 -$4 > 0 ) f->dir = 1;
		else f->dir = -1;

		f->limit = $6;
		f->by = $7.expr;
		f->by_op = $7.op;
		
		f->anything = $10;
		include_string($10,f,GINTERNAL);
	    }
;

graph_statement:
	GRAPH IDENT { lex_begin_rest_of_line(); } REST SEP
	    {
		if ( !first_line ) {
		    draw_graph();
		    init_graph();
		}

		graph_name = new String($2);
		if ( $4 ) graph_pos = new String($4);
		delete $2;
		delete $4;
	    }
;

print_statement:
	PRINT STRING SEP
	    {
		$2->unquote();
		cerr <<  *$2 << endl;
	    }
|	PRINT expr SEP
	    {
		cerr << $2 << endl;
	    }
;

pic_statement:
	PIC { lex_begin_rest_of_line(); } REST SEP
	    { pic.insert($3); }
;
troff_line:
	TROFF SEP
	    { troff.insert($1); }
;
%%

int yyerror(char *s) {
    grap_buffer_state *g = 0;

    while ( !lexstack.empty() ) {
	    g = lexstack.pop();
	    switch ( g->type) {
		case GFILE:
		    cerr << "At line " << g->line << " " ;
		    if ( g->name ) cerr << "in file " << *g->name << endl;
		    break;
		case GMACRO:
		    cerr << "At line " << g->line << " " ;
		    cerr << "of macro"  << endl;
		    break;
	    }
	    if ( g->f ) delete g->f;
	    if ( g->name ) delete g->name;
	    delete g;
    }
    cerr << s << endl;
    cerr << "Bailing out" << endl;
    return 0;
}

int yyparse();

extern int yylex();

void draw_graph() {
    int gn;
    coord *c;
    line *l;
    plot *p;
    circle *cir;
    String *s;

    for ( gn = coordinates.first(c); gn; gn = coordinates.next(c)) 
	c->addmargin(0.07);
    if ( !coordinates.find("grap.internal.default",c) ) {
	cerr << "Lost default coords!!" << endl;
	exit(20);
    }
    if ( visible ) {
	if ( !graphs++ ) {
	    cout << ".PS";
	    if (ps_param ) cout << *ps_param;
	    cout << endl;
	}
	for ( gn = troff.first(s); gn; gn = troff.next(s)) 
	    cout << *s << endl;
	if ( graph_name ) cout << *graph_name << ": ";
	cout << "[" << endl;
	the_frame.draw();
	for ( gn = lines.first(l); gn; gn = lines.next(l))
	    l->draw(&the_frame);
	for ( gn = plots.first(p); gn; gn = plots.next(p))
	    p->draw(&the_frame);
	for ( gn = circles.first(cir); gn; gn = circles.next(cir))
	    cir->draw(&the_frame);
	cout << "]";
	if ( graph_pos ) cout << " " << *graph_pos << endl;
	else cout << endl;
	for ( gn = pic.first(s); gn; gn = pic.next(s)) 
	    cout << *s << endl;
    }
    if ( graph_name ) {
	delete graph_name;
	graph_name = 0;
    }
    if ( graph_pos ) {
	delete graph_pos;
	graph_pos = 0;
    }
}

void init_graph() {
    int gotnext;
    coord *c;
    line *l;
    plot *p;
    circle *cir;
    String *s;
    linedescval defld = { invis,0,0 };

    visible = 0;

    for ( gotnext = coordinates.first(c); gotnext ;
	  gotnext = coordinates.next(c)) 
	delete c;
    for ( gotnext = lines.first(l); gotnext; gotnext = lines.next(l))
	delete l;
    for ( gotnext = plots.first(p); gotnext; gotnext = plots.next(p))
	delete p;
    for ( gotnext = circles.first(cir); gotnext; gotnext = circles.next(cir))
	delete cir;
    for ( gotnext = pic.first(s); gotnext; gotnext= pic.next(s))
	delete s;
    for ( gotnext = troff.first(s); gotnext; gotnext= troff.next(s))
	delete s;

    coordinates.clear();
    lines.clear();
    plots.clear();
    circles.clear();
    pic.clear();
    troff.clear();
    the_frame.clear();
		
    defcoord = new coord;
    coordinates.insert("grap.internal.default",defcoord);
    for ( int i = 0 ; i < 4; i++) {
	the_frame.tickdef[i].c = defcoord;
	the_frame.griddef[i].c = defcoord;
    }
    defline = new line(&defld,&String("\"\\(bu\"") );
    lines.insert("grap.internal.default",defline);
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
	    case 'D':
		use_defines = 0;
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
