/* -*-c++-*- */
%{
/* This code is (c) 1998 Ted Faber see COPYRIGHT
   for the full copyright and limitations of liabilities. */
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#ifdef STDC_HEADERS
#include <stdlib.h>
#include <errno.h>
#else
extern "C" {
    void free(void*);
};
#endif
#include <iostream>
#include <sys/param.h>
#include <set> 
#include "grap.h"
#include "grap_data.h"
#include "grap_draw.h" 
#include "y.tab.h"

// Templates for debugging.  Print the parameters to cerr.  

//#define LEX_DEBUG
template <class T>
inline void debug(T p) {
    if ( print_lex_debug) cerr << p << endl;
}

template <class T, class U>
inline void debug(T p1, U p2) {
    if ( print_lex_debug) cerr << p1 << p2 << endl;
}

int return_macro = 0;
int slashcount = 0;
int macro_end = 0;
string *macrotext;
int in_str = 0;
int braces = 0;
int stack_init =0;
int copystate =0;
int continuation =0;
unsigned int tokenpos =0;
bool print_lex_debug = false;
// A little kludge to not recognize identifier = as a LHS in a for statement. 
bool in_for = false; 

int lex_expand_macro =1;

linelist *sl=0;
string *copy_end, *copy_backstop;

string linebuf; 

extern macroDictionary macros;
extern doubleDictionary vars;
extern graph *the_graph;
extern stringSequence path;
extern bool compat_mode; 

int include_string(string *, struct for_descriptor *f=0, grap_input i=GMACRO);
void lex_begin_macro_text();
void lex_end_expr(); 
void macro_args(macro*);
void newline();
#ifndef HAVE_STRDUP
char *strdup(const char *);
#endif 

char *f0names[NF0] = { "rand" };
char *f1names[NF1] = { "log", "exp", "int", "sin", "cos", "sqrt","eexp","ln" };
char *f2names[NF2] = { "atan2", "min", "max" };

#define	ECHO	/* */

set<int> active;
// Keywords recognized in the initial GRAP state (AT, SPRINTF and all
// the string modifiers are there for implicit PLOT statements).
int grap_keys[] = { COPY, NEXT, DRAW, LINE, DEFINE, ARROW, CIRCLE, PLOT, AT,
		    FRAME, GRAPH, COORD, FOR, IF, PRINT, SPRINTF, TICKS,
		    LABEL, GRID, PIC, SH, BAR, LJUST, RJUST, ABOVE, BELOW,
		    ALIGNED, UNALIGNED, SIZE };
// These are the keywords recognized by any keyword that takes a line
// descriptor:
int linedesc_keys[] = { INVIS, SOLID, DOTTED, DASHED, FILL, FILLCOLOR, COLOR };
// Keywords recognized for sting modifiers 
int strmod_keys[] = { LJUST, RJUST, ABOVE, BELOW, ALIGNED, UNALIGNED, SIZE };

%}
%x GRAP
%x MACROTEXT
%x COPYSTATE
%x HUNTMACRO
%x RESTOFLINE

identifier	[A-Za-z0-9_]*
%%
<INITIAL>{
^.*$ 	{
          linebuf = yytext;
	  tokenpos = 0;
	  REJECT;
        }
\n	{
          debug("<INITIAL> newline");
	  newline();
	  tokenpos += yyleng;
	  cout << yytext;
	}
.G1.* 	{

        if ( yyleng > 3 && yytext[3] != '\t' && yytext[3] != ' ' )
	    if ( !compat_mode ) REJECT;
        if ( yyleng > 3) {
	    // Some extra characters after the macro invocation (or an
	    // extension of the macro under compat mode).
	    char *c;

	    for (c = yytext; *c != '\t' && *c != ' '&& *c != '\0'; c++ )
		;
	    yylval.String =  ( *c != '\0' ) ? new string(yytext+3) : 0;
	}
	else
	    yylval.String = 0;
	tokenpos += yyleng;
	BEGIN(GRAP);
	debug("START");
	active.clear();
	active.insert(grap_keys, grap_keys+sizeof(grap_keys)/sizeof(int));
	return START;
	}
.+	{
		tokenpos += yyleng;
		cout << yytext;
	}
}
<GRAP>{
^.*$			{
                          linebuf = yytext;
			  tokenpos = 0;
			  REJECT;
			}
\\\n 			{ newline(); tokenpos = 0;} 
\n			{
                          tokenpos = 0;
			  newline();
			  // Back to square 1 after a SEP
			  active.clear();
			  active.insert(grap_keys,
					grap_keys+
					sizeof(grap_keys)/sizeof(int));
                          debug("SEP");
			  return SEP; 
			}
\#.*$
[ \t]+			tokenpos += yyleng;

 ([0-9]*\.?[0-9]+)|([0-9]*\.?[0-9]+[eE](\+|\-)?[0-9]+)|([0-9]+\.)	{ 
			debug("Number: ",yytext);
			yylval.num = atof(yytext);
			tokenpos += yyleng;
			return NUMBER;
			}

 {identifier}[ \t]*=/[^=] {
                           // in a for statement, identifier = is a
                           // synonym for identifier FROM, so don't
                           // identify it as a LHS.
                           if ( in_for ) REJECT;
                           tokenpos += yyleng;
                           for ( int i = 0; i < yyleng; i++ )
                               if ( yytext[i] == ' ' || yytext[i] == '\t' ||
				    yytext[i] == '=' ) {
				   yytext[i] = '\0';
				   break;
			       }
			   yylval.String = new string(yytext);
			   debug("LHS: ", yytext);
			   return LHS;
                        }
} 
<GRAP>{
;			{
			  tokenpos += yyleng;
                          debug("SEP");
			  // Back to square 1 after a SEP
			  active.clear();
			  active.insert(grap_keys,
					grap_keys+
					sizeof(grap_keys)/sizeof(int));
			  return SEP; 
                        }
\(			tokenpos += yyleng; debug("LPAREN"); return LPAREN;
\)			tokenpos += yyleng; debug("RPAREN"); return RPAREN;
,			tokenpos += yyleng; debug("COMMA"); return COMMA;
\+			tokenpos += yyleng; debug("PLUS"); return PLUS;
\-			tokenpos += yyleng; debug("MINUS"); return MINUS;
\*			tokenpos += yyleng; debug("TIMES"); return TIMES;
\/			tokenpos += yyleng; debug("DIV"); return DIV;
\^			tokenpos += yyleng; debug("CARAT"); return CARAT;
\=			{
                          tokenpos += yyleng;
			  // if this is in a for statement, the EQUALS
			  // has taken the place of the from, so
			  // remove the from from active.
			  if ( in_for ) active.erase(FROM);
			  debug("EQUALS");
			  return EQUALS;
                        }
\=\=			tokenpos += yyleng; debug("EQ"); return EQ;
\!\=			tokenpos += yyleng; debug("NEQ"); return NEQ;
\<			tokenpos += yyleng; debug("LT"); return LT;
\>			tokenpos += yyleng; debug("GT"); return GT;
\<\=			tokenpos += yyleng; debug("LTE"); return LTE;
\>\=			tokenpos += yyleng; debug("GTE"); return GTE;
\&\&			tokenpos += yyleng; debug("AND"); return AND;
\|\|			tokenpos += yyleng; debug("OR"); return OR;
\!			tokenpos += yyleng; debug("NOT"); return NOT;
copy			{
                          if ( active.count(COPY) ) {
 			      tokenpos += yyleng;
			      // Copy only needs to see UNTIL and THRU
			      active.clear();
			      active.insert(THRU);
			      active.insert(UNTIL);
			      debug("COPY");
			      return COPY;
			  }
			  else {
			      debug("COPY not active");
			      REJECT;
			  }
                        }
next			{
                          if (active.count(NEXT) ) {
			      tokenpos += yyleng;
			      // Next needs to see AT and linedescriptors
			      active.clear();
			      active.insert(AT);
			      active.insert(linedesc_keys,
					    linedesc_keys +
					    sizeof(linedesc_keys)/sizeof(int));
			      debug("NEXT");
			      return NEXT;
			  }
			  else {
			      debug("NEXT not active");
			      REJECT;
			  }
			}
draw|new		{
                          if (active.count(DRAW) ) {
			      tokenpos += yyleng;
			      // Draw needs to see linedescriptors and
			      // stringmodifiers
			      active.clear();
			      active.insert(linedesc_keys,
					    linedesc_keys +
					    sizeof(linedesc_keys)/sizeof(int));
			      active.insert(strmod_keys,
					    strmod_keys +
					    sizeof(strmod_keys)/sizeof(int));
			      debug("DRAW");
			      return DRAW;
			  }
			  else {
			      debug("DRAW not active");
			      REJECT;
			  }
			}
line			{
                          if (active.count(LINE) ) {
			      tokenpos += yyleng;
			      // Line needs to see linedescriptors and
			      // FROM/TO
			      active.clear();
			      active.insert(FROM);
			      active.insert(TO);
			      active.insert(linedesc_keys,
					    linedesc_keys +
					    sizeof(linedesc_keys)/sizeof(int));
			      debug("LINE");
			      return LINE;
			  }
			  else {
			      debug("LINE not active");
			      REJECT;
			  }
			}
define			{
                          if (active.count(DEFINE) ) {
			      tokenpos += yyleng;
			      // define doesn't need to parse, really
			      active.clear();
			      debug("DEFINE");
			      return DEFINE;
			  }
			  else {
			      debug("DEFINEnot active");
			      REJECT;
			  }
			}
arrow			{
                          if (active.count(ARROW) ) {
			      tokenpos += yyleng;
			      // Arrow needs to see linedescriptors and
			      // FROM/TO
			      active.clear();
			      active.insert(FROM);
			      active.insert(TO);
			      active.insert(linedesc_keys,
					    linedesc_keys +
					    sizeof(linedesc_keys)/sizeof(int));
			      debug("ARROW");
			      return ARROW;
			  }
			  else {
			      debug("ARROW not active");
			      REJECT;
			  }
			}
circle			{
                          if (active.count(CIRCLE) ) {
			      tokenpos += yyleng;
			      // circle needs to see linedescriptors and
			      // AT and RADIUS
			      active.clear();
			      active.insert(AT);
			      active.insert(RADIUS);
			      active.insert(linedesc_keys,
					    linedesc_keys +
					    sizeof(linedesc_keys)/sizeof(int));
			      debug("CIRCLE");
			      return CIRCLE;
			  }
			  else {
			      debug("CIRCLE not active");
			      REJECT;
			  }
			}
radius|rad		{
                          if (active.count(RADIUS) ) {
			      tokenpos += yyleng;
			      // RADIUS only appears once, so deactivate it.
			      active.erase(RADIUS);
			      debug("RADIUS");
			      return RADIUS;
			  }
			  else {
			      debug("RADIUS not active");
			      REJECT;
			  }
			}
plot			{
                          if (active.count(PLOT) ) {
			      tokenpos += yyleng;
			      // Plot needs to see AT
			      active.clear();
			      active.insert(AT);
			      debug("PLOT");
			      return PLOT;
			  }
			  else {
			      debug("PLOT not active");
			      REJECT;
			  }
			}
frame			{
                          if (active.count(FRAME) ) {
			      tokenpos += yyleng;
			      // FRAME needs to see ht/wid,
			      // linedescriptions, and multiple
			      // top/bottom/left/rights.
			      active.clear();
			      active.insert(TOP);
			      active.insert(BOTTOM);
			      active.insert(LEFT);
			      active.insert(RIGHT);
			      active.insert(HT);
			      active.insert(WID);
			      active.insert(linedesc_keys,
					    linedesc_keys +
					    sizeof(linedesc_keys)/sizeof(int));
			      debug("FRAME");
			      return FRAME;
			  }
			  else {
			      debug("FRAME not active");
			      REJECT;
			  }
			}
graph			{
                          if (active.count(GRAPH) ) {
			      tokenpos += yyleng;
			      // graph dosn't need to parse keywords
			      active.clear();
			      debug("GRAPH");
			      return GRAPH;
			  }
			  else {
			      debug("GRAPHnot active");
			      REJECT;
			  }
			}
coord			{
                          if (active.count(COORD) ) {
			      tokenpos += yyleng;
			      // Coord needs to see XDIM YDIM and
			      // the logscale indicators
			      active.clear();
			      active.insert(XDIM);
			      active.insert(YDIM);
			      active.insert(LOG_X);
			      active.insert(LOG_Y);
			      active.insert(LOG_LOG);
			      debug("COORD");
			      return COORD;
			  }
			  else {
			      debug("COORD not active");
			      REJECT;
			  }
			}
for			{
                          if (active.count(FOR) ) {
			      tokenpos += yyleng;
			      // FOR needs to see FROM/TO/BY/DO
			      active.clear();
			      active.insert(FROM);
			      active.insert(TO);
			      active.insert(BY);
			      active.insert(DO);
			      // don't recognize identifier= as an LHS
			      // while in the for statement.
			      in_for = true;
			      debug("FOR");
			      return FOR;
			  }
			  else {
			      debug("FOR not active");
			      REJECT;
			  }
			}
from			{
                          if (active.count(FROM) ) {
			      tokenpos += yyleng;
			      // There's only ever one from keyword
			      // per statement.
			      active.erase(FROM);
			      debug("FROM");
			      return FROM;
			  }
			  else {
			      debug("FROM not active");
			      REJECT;
			  }
			}
thru|through		{
                          if (active.count(THRU) ) {
			      tokenpos += yyleng;
			      // There's only ever one thru keyword
			      // per statement.
			      active.erase(THRU);
			      debug("THRU");
			      return THRU;
			  }
			  else {
			      debug("THRU not active");
			      REJECT;
			  }
			}
to			{
                          if (active.count(TO) ) {
			      tokenpos += yyleng;
			      // There's only ever one to keyword
			      // per statement.
			      active.erase(TO);
			      // If we see a TO, any potential
			      // misidentification of a LHS in a for
			      // loop has been avoided.
			      in_for = false;
			      debug("TO");
			      return TO;
			  }
			  else {
			      debug("TO not active");
			      REJECT;
			  }
			}
at			{
                          if (active.count(AT) ) {
			      tokenpos += yyleng;
			      // AT can be active for 2 reasons.  It's
			      // been found in an expression that
			      // recognizes AT, or it's following an
			      // implicit PLOT statement - "string" at
			      // x, y.  In the first case, no more
			      // keywords need to be detected.  In the
			      // second just delete the AT from the
			      // list.  If COPY, which doesn't take an
			      // AT, is in active, this is an implicit
			      // PLOT because active is in the initial
			      // state.

			      if ( active.count(COPY)) active.clear();
			      else active.erase(AT);
			      debug("AT");
			      return AT;
			  }
			  else {
			      debug("AT not active");
			      REJECT;
			  }
			}
by			{
                          if (active.count(BY) ) {
			      tokenpos += yyleng;
			      // There's only ever one BY keyword
			      // per statement.
			      active.erase(BY);
			      debug("BY");
			      return BY;
			  }
			  else {
			      debug("BY not active");
			      REJECT;
			  }
			}
until			{
                          if (active.count(UNTIL) ) {
			      tokenpos += yyleng;
			      // There's only ever one UNTIL keyword
			      // per statement.
			      active.erase(UNTIL);
			      debug("UNTIL");
			      return UNTIL;
			  }
			  else {
			      debug("UNTIL not active");
			      REJECT;
			  }
			}
do			{
                          if (active.count(DO) ) {
			      tokenpos += yyleng;
			      // There's only ever one DO keyword
			      // per statement.
			      active.erase(DO);
			      debug("DO");
			      return DO;
			  }
			  else {
			      debug("DO not active");
			      REJECT;
			  }
			}
if			{
                          if (active.count(IF) ) {
			      tokenpos += yyleng;
			      // if needs to see THEN
			      active.clear();
			      active.insert(THEN);
			      debug("IF");
			      return IF;
			  }
			  else {
			      debug("IF not active");
			      REJECT;
			  }
			}
then			{
                          if (active.count(THEN) ) {
			      tokenpos += yyleng;
			      // THEN needs to see ELSE
			      active.clear();
			      active.insert(ELSE);
			      debug("THEN");
			      return THEN;
			  }
			  else {
			      debug("THEN not active");
			      REJECT;
			  }
			}
else			{
                          if (active.count(ELSE) ) {
			      tokenpos += yyleng;
			      // Else doesn't need to see keywords
			      active.clear();
			      debug("ELSE");
			      return ELSE;
			  }
			  else {
			      debug("ELSE not active");
			      REJECT;
			  }
			}
print			{
                          if (active.count(PRINT) ) {
			      tokenpos += yyleng;
			      // Print doesn't need to see keywords
			      // FROM/TO
			      active.clear();
			      debug("PRINT");
			      return PRINT;
			  }
			  else {
			      debug("PRINT not active");
			      REJECT;
			  }
			}
sprintf			{
                          if (active.count(SPRINTF) ) {
			      tokenpos += yyleng;
			      // Sprintf behaves like a string, so it
			      // doesn't change the active state.
			      debug("SPRINTF");
			      return SPRINTF;
			  }
			  else {
			      debug("SPRINTF not active");
			      REJECT;
			  }
			}
x			{
                          if (active.count(XDIM) ) {
			      tokenpos += yyleng;
			      // There's only ever one from keyword
			      // per statement.
			      active.erase(XDIM);
			      debug("XDIM");
			      return XDIM;
			  }
			  else {
			      debug("XDIM not active");
			      REJECT;
			  }
			}
y			{
                          if (active.count(YDIM) ) {
			      tokenpos += yyleng;
			      // There's only ever one YDIM keyword
			      // per statement.
			      active.erase(YDIM);
			      debug("YDIM");
			      return YDIM;
			  }
			  else {
			      debug("YDIM not active");
			      REJECT;
			  }
			}
log[ \t]+x	        {
                          if (active.count(LOG_X) ) {
			      tokenpos += yyleng;
			      // LOG_X doesn't change the active
			      // state.
			      debug("LOG_X");
			      return LOG_X;
			  }
			  else {
			      debug("LOG_X not active");
			      REJECT;
			  }
			}
log[ \t]+y		{
                          if (active.count(LOG_Y) ) {
			      tokenpos += yyleng;
			      // LOG_Y doesn't change the active
			      // state.
			      debug("LOG_Y");
			      return LOG_Y;
			  }
			  else {
			      debug("LOG_Y not active");
			      REJECT;
			  }
			}
log[ \t]+log		{
                          if (active.count(LOG_LOG) ) {
			      tokenpos += yyleng;
			      // LOG_LOG doesn't change the active
			      // state.
			      debug("LOG_LOG");
			      return LOG_LOG;
			  }
			  else {
			      debug("LOG_LOG not active");
			      REJECT;
			  }
			}
ticks|tick		{
                          if (active.count(TICKS) ) {
			      tokenpos += yyleng;
			      // Ticks needs to see lots of keywords
			      active.clear();
			      active.insert(LEFT);
			      active.insert(RIGHT);
			      active.insert(UP);
			      active.insert(DOWN);
			      active.insert(BOTTOM);
			      active.insert(TOP);
			      active.insert(IN);
			      active.insert(OUT);
			      active.insert(FROM);
			      active.insert(TO);
			      active.insert(BY);
			      active.insert(AT);
			      active.insert(OFF);
			      active.insert(ON);
			      debug("TICKS");
			      return TICKS;
			  }
			  else {
			      debug("TICKS not active");
			      REJECT;
			  }
			}
label			{
                          if (active.count(LABEL) ) {
			      tokenpos += yyleng;
			      // Label needs to see string moifiers and
			      // a bunch of placement keywords
			      active.clear();
			      active.insert(LEFT);
			      active.insert(RIGHT);
			      active.insert(UP);
			      active.insert(DOWN);
			      active.insert(BOTTOM);
			      active.insert(TOP);
			      active.insert(strmod_keys,
					    strmod_keys +
					    sizeof(strmod_keys)/sizeof(int));
			      debug("LABEL");
			      return LABEL;
			  }
			  else {
			      debug("LABEL not active");
			      REJECT;
			  }
			}
grid			{
                          if (active.count(GRID) ) {
			      tokenpos += yyleng;
			      // Draw needs to see linedescriptors and
			      // everything TICK needs.  And TICK.
			      active.clear();
			      active.insert(LEFT);
			      active.insert(RIGHT);
			      active.insert(UP);
			      active.insert(DOWN);
			      active.insert(BOTTOM);
			      active.insert(TOP);
			      active.insert(IN);
			      active.insert(OUT);
			      active.insert(OFF);
			      active.insert(ON);
			      active.insert(FROM);
			      active.insert(TO);
			      active.insert(BY);
			      active.insert(AT);
			      active.insert(TICKS);
			      active.insert(linedesc_keys,
					    linedesc_keys +
					    sizeof(linedesc_keys)/sizeof(int));
			      debug("GRID");
			      return GRID;
			  }
			  else {
			      debug("GRID not active");
			      REJECT;
			  }
			}
pic			{
                          if (active.count(PIC) ) {
			      tokenpos += yyleng;
			      // Pic doesn't need to parse keywords
			      active.clear();
			      debug("PIC");
			      return PIC;
			  }
			  else {
			      debug("PIC not active");
			      REJECT;
			  }
			}
top			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(TOP) ) {
			      tokenpos += yyleng;
			      debug("TOP");
			      return TOP;
			  }
			  else {
			      debug("TOP not active");
			      REJECT;
			  }
			}
bottom|bot 		{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(BOTTOM) ) {
			      tokenpos += yyleng;
			      debug("BOTTOM");
			      return BOTTOM;
			  }
			  else {
			      debug("BOTTOM not active");
			      REJECT;
			  }
			}
left			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(LEFT) ) {
			      tokenpos += yyleng;
			      debug("LEFT");
			      return LEFT;
			  }
			  else {
			      debug("LEFT not active");
			      REJECT;
			  }
			}
right			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(RIGHT) ) {
			      tokenpos += yyleng;
			      debug("RIGHT");
			      return RIGHT;
			  }
			  else {
			      debug("RIGHT not active");
			      REJECT;
			  }
			}
up			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(UP) ) {
			      tokenpos += yyleng;
			      debug("UP");
			      return UP;
			  }
			  else {
			      debug("UP not active");
			      REJECT;
			  }
			}

down			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(DOWN) ) {
			      tokenpos += yyleng;
			      debug("DOWN");
			      return DOWN;
			  }
			  else {
			      debug("DOWN not active");
			      REJECT;
			  }
			}
ljust			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(LJUST) ) {
			      tokenpos += yyleng;
			      debug("LJUST");
			      return LJUST;
			  }
			  else {
			      debug("LJUST not active");
			      REJECT;
			  }
			}
rjust			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(RJUST) ) {
			      tokenpos += yyleng;
			      debug("RJUST");
			      return RJUST;
			  }
			  else {
			      debug("RJUST not active");
			      REJECT;
			  }
			}
above			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(ABOVE) ) {
			      tokenpos += yyleng;
			      debug("ABOVE");
			      return ABOVE;
			  }
			  else {
			      debug("ABOVE not active");
			      REJECT;
			  }
			}
below			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(BELOW) ) {
			      tokenpos += yyleng;
			      debug("BELOW");
			      return BELOW;
			  }
			  else {
			      debug("BELOW not active");
			      REJECT;
			  }
			}
aligned			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(ALIGNED) ) {
			      tokenpos += yyleng;
			      debug("ALIGNED");
			      return ALIGNED;
			  }
			  else {
			      debug("ALIGNED not active");
			      REJECT;
			  }
			}
unaligned		{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(UNALIGNED) ) {
			      tokenpos += yyleng;
			      debug("UNALIGNED");
			      return UNALIGNED;
			  }
			  else {
			      debug("UNALIGNED not active");
			      REJECT;
			  }
			}
size			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(SIZE) ) {
			      tokenpos += yyleng;
			      debug("SIZE");
			      return SIZE;
			  }
			  else {
			      debug("SIZE not active");
			      REJECT;
			  }
			}
sh			{
                          if (active.count(SH) ) {
			      tokenpos += yyleng;
			      // SH doesn't need to parse keywords
			      active.clear();
			      debug("SH");
			      return SH;
			  }
			  else {
			      debug("SH not active");
			      REJECT;
			  }
			}
in			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(IN) ) {
			      tokenpos += yyleng;
			      debug("IN");
			      return IN;
			  }
			  else {
			      debug("IN not active");
			      REJECT;
			  }
			}
out			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(OUT) ) {
			      tokenpos += yyleng;
			      debug("OUT");
			      return OUT;
			  }
			  else {
			      debug("OUT not active");
			      REJECT;
			  }
			}
off			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(OFF) ) {
			      tokenpos += yyleng;
			      debug("OFF");
			      return OFF;
			  }
			  else {
			      debug("OFF not active");
			      REJECT;
			  }
			}
on|auto			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(ON) ) {
			      tokenpos += yyleng;
			      debug("ON");
			      return ON;
			  }
			  else {
			      debug("ON not active");
			      REJECT;
			  }
			}
bar			{
                          if (active.count(BAR) ) {
			      tokenpos += yyleng;
			      // BAR needs to see HT/WID, UP, RIGHT,
			      // BASE and line descriptors
			      active.clear();
			      active.insert(HT);
			      active.insert(WID);
			      active.insert(UP);
			      active.insert(RIGHT);
			      active.insert(BASE);
			      active.insert(linedesc_keys,
					    linedesc_keys +
					    sizeof(linedesc_keys)/sizeof(int));
			      debug("BAR");
			      return BAR;
			  }
			  else {
			      debug("BAR not active");
			      REJECT;
			  }
			}
fill			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(FILL) ) {
			      tokenpos += yyleng;
			      debug("FILL");
			      return FILL;
			  }
			  else {
			      debug("FILL not active");
			      REJECT;
			  }
			}
base			{
                          if (active.count(BASE) ) {
			      tokenpos += yyleng;
			      // There's only ever one BASE keyword
			      // per statement.
			      active.erase(BASE);
			      debug("BASE");
			      return BASE;
			  }
			  else {
			      debug("BASE not active");
			      REJECT;
			  }
			}
ht			{
                          if (active.count(HT) ) {
			      tokenpos += yyleng;
			      // There's only ever one HT keyword
			      // per statement.
			      active.erase(HT);
			      debug("HT");
			      return HT;
			  }
			  else {
			      debug("HT not active");
			      REJECT;
			  }
			}
wid			{
                          if (active.count(WID) ) {
			      tokenpos += yyleng;
			      // There's only ever one WID keyword
			      // per statement.
			      active.erase(WID);
			      debug("WID");
			      return WID;
			  }
			  else {
			      debug("WID not active");
			      REJECT;
			  }
			}
invis			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(INVIS) ) {
			      tokenpos += yyleng;
			      debug("INVIS");
			      return INVIS;
			  }
			  else {
			      debug("INVIS not active");
			      REJECT;
			  }
			}
solid			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(SOLID) ) {
			      tokenpos += yyleng;
			      debug("SOLID");
			      return SOLID;
			  }
			  else {
			      debug("SOLID not active");
			      REJECT;
			  }
			}
dotted			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(DOTTED) ) {
			      tokenpos += yyleng;
			      debug("DOTTED");
			      return DOTTED;
			  }
			  else {
			      debug("DOTTED not active");
			      REJECT;
			  }
			}
dashed			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(DASHED) ) {
			      tokenpos += yyleng;
			      debug("DASHED");
			      return DASHED;
			  }
			  else {
			      debug("DASHED not active");
			      REJECT;
			  }
			}
fillcolor		{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(FILLCOLOR) ) {
			      tokenpos += yyleng;
			      debug("FILLCOLOR");
			      return FILLCOLOR;
			  }
			  else {
			      debug("FILLCOLOR not active");
			      REJECT;
			  }
			}
color			{
                          // Just report if this keyword is active and
                          // ignore if not.
                          if (active.count(COLOR) ) {
			      tokenpos += yyleng;
			      debug("COLOR");
			      return COLOR;
			  }
			  else {
			      debug("COLOR not active");
			      REJECT;
			  }
			}
rand			{
			int i;

			debug("FUNC0");
			for ( i = 0 ; i < NF0; i++ ) 
				if ( !strcmp(yytext,f0names[i]) )
					yylval.val = i;
			tokenpos += yyleng;
 			return FUNC0;
			}
log|exp|int|sin|cos|sqrt|rand|eexp|ln	{
			int i;

			debug("FUNC1");
			for ( i = 0 ; i < NF1; i++ ) 
				if ( !strcmp(yytext,f1names[i]) )
					yylval.val = i;
			tokenpos += yyleng;
 			return FUNC1;
			}
atan2|min|max		{
			int i;

			debug("FUNC2");
			for ( i = 0 ; i < NF2; i++ ) 
				if ( !strcmp(yytext,f2names[i]) )
					yylval.val = i;
			tokenpos += yyleng;
			return FUNC2;
			}
[.\'][ \t]*[^\t 0-9].*$                  {
				tokenpos += yyleng;
				if ( !strncmp(".G1", yytext, 3) ) {
				    if ( lexstack.empty() ||
					 lexstack.front()->report_start == 1 )
				    {
					debug("Start: ", yytext); 
					return START;
				    }
				    else YY_BREAK;
				}
				if ( !strncmp(".G2", yytext, 3) ) {
				    if ( lexstack.empty() ||
					 lexstack.front()->report_start == 1) {

					debug("<GRAP>End: ",yytext);
					BEGIN(INITIAL);
                                        // Eat the newline
                                        yyinput();
					return END;
				    }
				    else YY_BREAK;
				}			
                                yylval.String = new string(yytext);
                                debug("Troff: ", yytext);
				return TROFF;
                        }
\"([^\"\n]|\\\")*\"	{ 
			debug("String: ", yytext);
			yylval.String = new string(yytext);
			tokenpos += yyleng;
			return STRING;
			}
{identifier}		{ 
			macro *m;
			macroDictionary::iterator mi;
			coordinateDictionary::iterator ci;
			coord *c;
			string *id;
			char ch;

			debug("ident: ", yytext);
			id = new string(yytext);
			tokenpos += yyleng;
			if ( lex_expand_macro &&
			     ( mi = macros.find(*id)) != macros.end() ) {
			        m = (*mi).second;
				delete id;
				ch = yyinput();
				if ( ch == '(') {
                                    macro_args(m);
                                    tokenpos++;
                                }
				else unput(ch);
				id = m->invoke();
				include_string(id);
				delete id;
			        tokenpos += yyleng;
			}
			else {
			    ci = the_graph->coords.find(*id);
			    if ( ci != the_graph->coords.end()) {
				c = (*ci).second;
				yylval.coordptr = c;
				return COORD_NAME;
			    } else {
				yylval.String = id;
				return IDENT;
			    }
			}
                        }
.			tokenpos += yyleng; debug("unknown: ", yytext); return 0;
}

<MACROTEXT>{
^.*$			{
                          linebuf = yytext;
			  REJECT;
			}
[ \t]+			{
				slashcount = 0;
			        tokenpos += yyleng;
				if ( macro_end != 0)
					*macrotext += yytext;
			}
\\			{ 
				*macrotext += *yytext;
			        tokenpos += yyleng;
				slashcount ++;
			}
\"			{ 
				*macrotext += *yytext;
			        tokenpos += yyleng;
				if ( in_str ) { 
					if ( slashcount % 2 == 0) in_str=0;
				} 
				else {
					if ( slashcount % 2 == 0) in_str=1;
				}
				slashcount = 0;
			}
\{			{
				if ( macro_end == 0 ) {
					macro_end = '}';
					braces = 1;
				}
				else {
					if ( !in_str ) braces++;
					*macrotext += *yytext;
					slashcount =0;
				}
			        tokenpos += yyleng;
			}
\}			{
			        tokenpos += yyleng;
				if ( macro_end == 0 ) return 0;
				else {
					if ( !in_str ) braces--;
					if ( macro_end == '}' && !braces ) {
					    BEGIN(GRAP);
					    if ( !return_macro) {
						yylval.String = macrotext;
						debug("TEXT");
						return TEXT;
					    } else {
						macro *m = new macro(macrotext);

						yylval.macro_val = m;
						debug("MACRO: ",macrotext->c_str());
						macrotext = 0;
						return MACRO;
					    }
					}
					else {
					    *macrotext += *yytext;
					    slashcount =0;
					}
				}
			}
\n			{ 
			  *macrotext += *yytext;
			  slashcount =0;
			  tokenpos = 0;
			  newline();
			  // don't return SEP here
			}
.			{
			        tokenpos += yyleng;
				if ( macro_end == 0 ) macro_end = *yytext;
				else {
					if ( *yytext == macro_end ) {
					    BEGIN(GRAP);
					    if ( !return_macro ) {
						yylval.String = macrotext;
						return TEXT;
					    } else {
						macro *m = new macro(macrotext);
						yylval.macro_val = m;
						macrotext = 0;
						return MACRO;
					    }
					}
					else {
					    *macrotext += *yytext;
					    slashcount =0;
					}
				}
			}
}
<COPYSTATE>{
^.*$	{
          linebuf = yytext;
          REJECT;
	}
\n	{ 
	  tokenpos = 0;
	  newline();
	}
.+ 	{
    string *s;
    
    if ( *copy_end != yytext && *copy_backstop != yytext ) {
	s = new string(yytext);
	sl->push_back(s);
    }
    else {

	// If we're stopped by an END symbol, we have to put it back
	
	if ( !strncmp(".G2",yytext,3) ) {
	    debug("<COPYSTATE>End: ", yytext);
	    yyless(0);
	    unput('\n');
	    lexstack.front()->line--;
	    tokenpos = 0;
	} else
	    tokenpos += yyleng;
	BEGIN(GRAP);
	yylval.line_list = sl;
	sl = 0;
	copystate = 0;
	debug("COPYTEXT ", yylval.line_list->size());
	return COPYTEXT;
    }
    }
}
<HUNTMACRO>{
[ \t]+	tokenpos += yyleng; 
[A-Za-z0-9_]* 	{
    macro *m;
    macroDictionary::iterator mi;
    
    string *id = new string(yytext);
    if ( ( mi = macros.find(*id)) != macros.end()) {
	m = (*mi).second;
	delete id;
	tokenpos += yyleng;
	BEGIN(GRAP);
	yylval.macro_val = m;
	return MACRO;
    }
    else {
	char *c = strdup(yytext);

	delete id;
	lex_begin_macro_text();
	return_macro =1;
	yyless(0);
	free(c);
	tokenpos += yyleng;
    }
}
. {
    debug("<HUNTMACRO> ", yytext);
    unput(*yytext);
    lex_begin_macro_text();
    return_macro = 1;
   }
}
<RESTOFLINE>{
.*$ 		{
    BEGIN(GRAP);
    tokenpos += yyleng;
    debug("REST: ",yytext);
    if ( strcmp("\n",yytext) )
	yylval.String = new string(yytext);
    else
	yylval.String = 0;

    return REST;
    }
}
<<EOF>> 	{
    debug("EOF");
    if ( copystate && !lexstack.empty()) {
	copystate = 0;
	tokenpos = 0;
	BEGIN(GRAP);
	yylval.line_list = sl;
	sl = 0;
	debug("COPYTEXT(EOF)");
	return COPYTEXT;
    } else yyterminate();
}
%%
bool include_file(string *s, int rs, bool usepath) {
    FILE *f=0;
    struct grap_buffer_state *g = new grap_buffer_state(0, 0, 0, 1, rs, GFILE);
    grap_buffer_state *gg = lexstack.empty() ? 0 : lexstack.front();

    if ( s ) {
	debug("include_file: ",s->c_str());
        if ( gg ) {
            gg->tokenpos = tokenpos;
            tokenpos = 0;
        }
	if ( *s != "-" ) {
            if ( (*s)[0] != '/' && usepath ) {
                // use path to look up relative path
                for ( stringSequence::iterator i = path.begin();
                      i != path.end(); i++) {
                    string str = *(*i);

                    str += "/"; str += *s;
                    if ( ( f = fopen(str.c_str(),"r"))) break;
                }
            }
            else f = fopen(s->c_str(),"r");

            if ( !f ) {
                cerr << "Can't open " << *s << " " << strerror(errno) << endl;
		return 0;
	    }
	    g->yy = yy_create_buffer(f,YY_BUF_SIZE);
	    g->name = new string(*s);
	}
	else {
	    g->yy = yy_create_buffer(stdin,YY_BUF_SIZE);
	    g->name = new string("- <stdin>");
	}
	lexstack.push_front(g);
	yy_switch_to_buffer(g->yy);
	return 1;
    }
    else return 0;
}
	
void lex_begin_macro_text() {
	BEGIN(MACROTEXT);
	debug("<MACROTEXT> lex_begin_macro_text()");
	lex_expand_macro = 1;
	slashcount = 0;
	macro_end = 0;
	return_macro=0;
	macrotext = new string;
	in_str = 0;
	braces = 0;
}


int include_string(string *s, struct for_descriptor *f /* =0 */,
    grap_input it /*=GMACRO */) {
	char *cbuf;
        int len;
	grap_buffer_state *g;
        grap_buffer_state *gg = lexstack.empty() ? 0 : lexstack.front();

        debug("include string ",s->c_str());

        if ( gg ) {
            gg->tokenpos = tokenpos;
            tokenpos = 0;
        }

	g = new grap_buffer_state(0, f, 0, 1, 1, it);
	cbuf = new char[len = s->length()+1];

	strncpy(cbuf,s->c_str(),len-1);
	cbuf[len-1] = '\0';
	lexstack.push_front(g);
	g->yy = yy_scan_string(cbuf);
	delete cbuf;
	return 1;
}

void macro_args(macro *m) {
    string *arg;
    int c;
    int parens = 0;
    int slashcount = 0;
    int in_str = 0;

    arg = new string;
    for ( c = yyinput(); c != EOF && ( c != ')' || parens ); c = yyinput()) {
	if ( c == ',' && !in_str && !parens) {
	    // End of arg
	    if ( m->add_arg(arg)) arg = new string;
	    continue;
	}
	if ( c == '(' ) parens++;
	if ( c == ')' ) parens --;
	if ( c == '"' && (slashcount % 2 ) == 0 ) {
	    if ( in_str ) in_str = 0;
	    else in_str = 1;
	}
	if ( c == '\\' ) slashcount++;
	else slashcount = 0;
	*arg += (char) c;
        tokenpos++;
    }
    if ( c == ')' && arg->length() ) {
	if ( !m->add_arg(arg)) delete arg;
    }
    else
	if (arg) delete arg;
    tokenpos++;
}

void lex_begin_copy(string *s /* =0 */) {
    debug("COPYSTATE (lex_begin_copy)");
    BEGIN(COPYSTATE);
    copystate = 1;
    if ( !copy_backstop ) copy_backstop = new string(".G2");
    if ( copy_end) delete copy_end;
    if ( s ) copy_end = s;
    else copy_end = new string(".G2");
    if ( sl ) delete sl;
    sl = new linelist;
}

void lex_hunt_macro() {

    BEGIN(HUNTMACRO);
}
void lex_begin_rest_of_line() {

    BEGIN(RESTOFLINE);
}

int yywrap() {
    struct grap_buffer_state *g;

    debug("(yywrap)");
    if ( lexstack.empty() ) yyterminate();
    else {
	g = lexstack.front();
	lexstack.pop_front();
    }
    
    if ( g->f ) {

	struct for_descriptor *f = g->f;
	// we're processing a for statement


	switch (f->by_op ) {
	    case PLUS:
	    default:
		*f->loop_var += f->by;
		break;
	    case MINUS:
		*f->loop_var -= f->by;
		break;
	    case TIMES:
		*f->loop_var *= f->by;
		break;
	    case DIV:
		*f->loop_var /= f->by;
		break;
	}

	if ( (*f->loop_var - f->limit) * f->dir < EPSILON ) {
	    // still iterating redo this stack frame
	    yy_delete_buffer(g->yy);

	    // *do not delete g->f because include string will attach
	    // it to the new grap_buffer_state that it allocates.
	    g->f = 0;
	    
	    delete g;
	    include_string(f->anything, f);
	    return 0;
	}
    }
    // If we get here, we need to switch to the previous buffer

    yy_delete_buffer(g->yy);
    delete g;

    if ( lexstack.empty() ) {
	// groff line marker
	cout << ".lf " << g->line << endl;
	return 1;
    }
    else {
	g = lexstack.front();
        tokenpos = g->tokenpos;
	yy_switch_to_buffer(g->yy);
	// groff line marker
	cout << ".lf " << g->line << " " <<
	    ((g->name ) ? *g->name : "" ) << endl;
    }

    return copystate ? 1 : 0;
}

void newline() {
    if ( !lexstack.empty() ) {
	grap_buffer_state *g = lexstack.front();
	g->line++;
    }
}

string pre_context(void) {
    if (!tokenpos) return "";
    else return linebuf.substr(0,tokenpos-yyleng);
}

char *token_context(void) {
    return (yytext);
}

string post_context(void) {
    return linebuf.substr(tokenpos);
}
