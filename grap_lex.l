/* -*-c++-*- */
%{
/* This code is (c) 1998 Ted Faber see COPYRIGHT
   for the full copyright and limitations of liabilities. */
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#ifdef STDC_HEADERS
#include <stdlib.h>
#else
extern "C" {
    void free(void*);
};
#endif
#include <iostream>
#include <sys/param.h>
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

%}
%x GRAP
%x MACROTEXT
%x COPYSTATE
%x HUNTMACRO
%x RESTOFLINE
%X EXPRESSION

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
	debug("START"); return START;
	}
.+	{
		tokenpos += yyleng;
		cout << yytext;
	}
}
<GRAP,EXPRESSION>{
^.*$			{
                          linebuf = yytext;
			  tokenpos = 0;
			  REJECT;
			}
\\\n 			{ newline(); tokenpos = 0;} 
\n			{
                          tokenpos = 0;
			  newline();
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
<EXPRESSION>{
{identifier}		{ 
                            debug("ident: ", yytext);
			    string *id = new string(yytext);
			    doubleDictionary::iterator di;
		
			    if ( (di = vars.find(*id)) != vars.end()) {
				yylval.String = id;
				return IDENT;
			    }
			    else {
				delete id;
				debug("<EXPRESSION>Rejected identitier: ",
				      yytext);
				lex_end_expr();
				REJECT;
			    }

                        }
    
}
<GRAP,EXPRESSION>{
;			{
			  tokenpos += yyleng;
                          debug("SEP");
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
\=			tokenpos += yyleng; debug("EQUALS"); return EQUALS;
\=\=			tokenpos += yyleng; debug("EQ"); return EQ;
\!\=			tokenpos += yyleng; debug("NEQ"); return NEQ;
\<			tokenpos += yyleng; debug("LT"); return LT;
\>			tokenpos += yyleng; debug("GT"); return GT;
\<\=			tokenpos += yyleng; debug("LTE"); return LTE;
\>\=			tokenpos += yyleng; debug("GTE"); return GTE;
\&\&			tokenpos += yyleng; debug("AND"); return AND;
\|\|			tokenpos += yyleng; debug("OR"); return OR;
\!			tokenpos += yyleng; debug("NOT"); return NOT;
copy			tokenpos += yyleng; debug("COPY"); return COPY;
next			tokenpos += yyleng; debug("NEXT"); return NEXT;
draw|new		tokenpos += yyleng; debug("DRAW"); return DRAW;
line			tokenpos += yyleng; debug("LINE"); return LINE;
define			tokenpos += yyleng; debug("DEFINE"); return DEFINE;
arrow			tokenpos += yyleng; debug("ARROW"); return ARROW;
circle			tokenpos += yyleng; debug("CIRCLE"); return CIRCLE;
radius|rad		tokenpos += yyleng; debug("RADIUS"); return RADIUS;
plot			tokenpos += yyleng; debug("PLOT"); return PLOT;
frame			tokenpos += yyleng; debug("FRAME"); return FRAME;
graph			tokenpos += yyleng; debug("GRAPH"); return GRAPH;
coord			tokenpos += yyleng; debug("COORD"); return COORD;
for			tokenpos += yyleng; debug("FOR"); return FOR;
from			tokenpos += yyleng; debug("FROM"); return FROM;
thru|through		tokenpos += yyleng; debug("THRU"); return THRU;
to			tokenpos += yyleng; debug("TO"); return TO;
at			tokenpos += yyleng; debug("AT"); return AT;
by			tokenpos += yyleng; debug("BY"); return BY;
until			tokenpos += yyleng; debug("UNTIL"); return UNTIL;
do			tokenpos += yyleng; debug("DO"); return DO;
if			tokenpos += yyleng; debug("IF"); return IF;
then			tokenpos += yyleng; debug("THEN"); return THEN;
else			tokenpos += yyleng; debug("ELSE"); return ELSE;	
print			tokenpos += yyleng; debug("PRINT"); return PRINT;	
sprintf			tokenpos += yyleng; debug("SPRINTF"); return SPRINTF;
x			tokenpos += yyleng; debug("XDIM"); return XDIM;
y			tokenpos += yyleng; debug("YDIM"); return YDIM;
log[ \t]+x			tokenpos += yyleng; debug("LOG_X"); return LOG_X;
log[ \t]+y			tokenpos += yyleng; debug("LOG_Y"); return LOG_Y;
log[ \t]+log			tokenpos += yyleng; debug("LOG_LOG"); return LOG_LOG;
ticks|tick			tokenpos += yyleng; debug("TICKS"); return TICKS;
label			tokenpos += yyleng; debug("LABEL"); return LABEL;
grid			tokenpos += yyleng; debug("GRID"); return GRID;
pic			tokenpos += yyleng; debug("PIC"); return PIC;
top			tokenpos += yyleng; debug("TOP"); return TOP;
bottom|bot		tokenpos += yyleng; debug("BOTTOM"); return BOTTOM;
left			tokenpos += yyleng; debug("LEFT"); return LEFT;
right			tokenpos += yyleng; debug("RIGHT"); return RIGHT;
up			tokenpos += yyleng; debug("UP"); return UP;
down			tokenpos += yyleng; debug("DOWN"); return DOWN;
ljust			tokenpos += yyleng; debug("LJUST"); return LJUST;
rjust			tokenpos += yyleng; debug("RJUST"); return RJUST;
above			tokenpos += yyleng; debug("ABOVE",0); return ABOVE;
below			tokenpos += yyleng; debug("BELOW"); return BELOW;
aligned			tokenpos += yyleng; debug("ALIGNED"); return ALIGNED;
unaligned		tokenpos += yyleng; debug("UNALIGNED"); return UNALIGNED;
size			tokenpos += yyleng; debug("SIZE"); return SIZE;
sh			tokenpos += yyleng; debug("SH"); return SH;
in			tokenpos += yyleng; debug("IN"); return IN;
out			tokenpos += yyleng; debug("OUT"); return OUT;
off			tokenpos += yyleng; debug("OFF"); return OFF;
on|auto			tokenpos += yyleng; debug("ON"); return ON;
bar			tokenpos += yyleng; debug("BAR"); return BAR;
fill			tokenpos += yyleng; debug("FILL"); return FILL;
base			tokenpos += yyleng; debug("BASE"); return BASE;
ht			tokenpos += yyleng; debug("HT"); return HT;
wid			tokenpos += yyleng; debug("WID"); return WID;
invis			tokenpos += yyleng; debug("INVIS"); return INVIS;
solid			tokenpos += yyleng; debug("SOLID"); return SOLID;
dotted			tokenpos += yyleng; debug("DOTTED"); return DOTTED;
dashed			tokenpos += yyleng; debug("DASHED"); return DASHED;
fillcolor		tokenpos += yyleng; debug("FILLCOLOR"); return FILLCOLOR;
color			tokenpos += yyleng; debug("COLOR"); return COLOR;
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
			if ( lex_expand_macro &&
			     ( mi = macros.find(*id)) != macros.end() ) {
                                tokenpos+= yyleng;
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
			    tokenpos += yyleng;
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
                cerr << "Can't open " << *s << " ";
		perror(0);
		return 0;
	    }
	    g->yy = yy_create_buffer(f,YY_BUF_SIZE);
	    g->name = new string(*s);
	}
	else {
	    g->yy = yy_create_buffer(stdin,YY_BUF_SIZE);
	    g->name = new string("stdin");
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

void lex_begin_expr() {
	BEGIN(EXPRESSION);
	debug("<EXPRESSION> lex_begin_expr");
}

void lex_end_expr() {
	BEGIN(GRAP);
	debug("<GRAP> lex_end_expr");
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

    if ( lexstack.empty() ) return 1;
    else {
	g = lexstack.front();
        tokenpos = g->tokenpos;
	yy_switch_to_buffer(g->yy);
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
