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
#include <ostream.h>
#include <sys/param.h>
#include "grap.h"
#include "grap_data.h"
#include "grap_draw.h" 
#include "y.tab.h"

//#define LEX_DEBUG
#ifndef LEX_DEBUG
#define DEBUG(a,b) {}
#else
#define DEBUG(a,b) fprintf(stderr,a,b);
#endif

int return_macro = 0;
int slashcount = 0;
int macro_end = 0;
String *macrotext;
int in_str = 0;
int braces = 0;
int stack_init =0;
int copystate =0;
int continuation =0;
unsigned int tokenpos =0;

int lex_expand_macro =1;

linelist *sl=0;
String *copy_end, *copy_backstop;

String linebuf; 

extern macroDictionary macros;
extern graph *the_graph;
extern stringSequence path;
extern bool compat_mode; 

int include_string(String *, struct for_descriptor *f=0, grap_input i=GMACRO);
void lex_begin_macro_text();
void macro_args(macro*);
void newline();
#ifndef HAVE_STRDUP
char *strdup(const char *);
#endif 

char *f0names[NF0] = { "rand" };
char *f1names[NF1] = { "log", "exp", "int", "sin", "cos", "sqrt","eexp" };
char *f2names[NF2] = { "atan2", "min", "max" };

#define	ECHO	/* */

%}
%x GRAP
%x COORD_STATE
%x MACROTEXT
%x COPYSTATE
%x HUNTMACRO
%x RESTOFLINE
%%
<INITIAL>{
^.*$ 	{
          linebuf = yytext;
	  tokenpos = 0;
	  REJECT;
        }
\n	{
          DEBUG("<INITIAL> %s","newline");
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
	    yylval.string =  ( *c != '\0' ) ? new String(yytext+3) : 0;
	}
	else
	    yylval.string = 0;
	tokenpos += yyleng;
	BEGIN(GRAP);
	DEBUG("START\n",0); return START;
	}
.+	{
		tokenpos += yyleng;
		cout << yytext;
	}
}
<COORD_STATE>{
x			tokenpos += yyleng; DEBUG("XDIM\n",0); return XDIM;
y			tokenpos += yyleng; DEBUG("YDIM\n",0); return YDIM;
}
<GRAP,COORD_STATE>{
^.*$			{
                          linebuf = yytext;
			  tokenpos = 0;
			  REJECT;
			}
\\\n 			{ newline(); tokenpos = 0;} 
\n			{
                          tokenpos = 0;
			  newline();
                          DEBUG("SEP\n",0);
			  return SEP; 
			}
\#.*$
[ \t]+			tokenpos += yyleng;
;			{
			  tokenpos += yyleng;
                          DEBUG("SEP\n",0);
			  return SEP; 
                        }
\(			tokenpos += yyleng; DEBUG("LPAREN\n",0); return LPAREN;
\)			tokenpos += yyleng; DEBUG("RPAREN\n",0); return RPAREN;
,			tokenpos += yyleng; DEBUG("COMMA\n",0); return COMMA;
copy			tokenpos += yyleng; DEBUG("COPY\n",0); return COPY;
\+			tokenpos += yyleng; DEBUG("PLUS\n",0); return PLUS;
\-			tokenpos += yyleng; DEBUG("MINUS\n",0); return MINUS;
\*			tokenpos += yyleng; DEBUG("TIMES\n",0); return TIMES;
\/			tokenpos += yyleng; DEBUG("DIV\n",0); return DIV;
\^			tokenpos += yyleng; DEBUG("CARAT\n",0); return CARAT;
\=			tokenpos += yyleng; DEBUG("EQUALS\n",0); return EQUALS;
\=\=			tokenpos += yyleng; DEBUG("EQ\n",0); return EQ;
\!\=			tokenpos += yyleng; DEBUG("NEQ\n",0); return NEQ;
\<			tokenpos += yyleng; DEBUG("LT\n",0); return LT;
\>			tokenpos += yyleng; DEBUG("GT\n",0); return GT;
\<\=			tokenpos += yyleng; DEBUG("LTE\n",0); return LTE;
\>\=			tokenpos += yyleng; DEBUG("GTE\n",0); return GTE;
\&\&			tokenpos += yyleng; DEBUG("AND\n",0); return AND;
\|\|			tokenpos += yyleng; DEBUG("OR\n",0); return OR;
\!			tokenpos += yyleng; DEBUG("NOT\n",0); return NOT;
next			tokenpos += yyleng; DEBUG("NEXT\n",0); return NEXT;
draw|new		tokenpos += yyleng; DEBUG("DRAW\n",0); return DRAW;
line			tokenpos += yyleng; DEBUG("LINE\n",0); return LINE;
define			tokenpos += yyleng; DEBUG("DEFINE\n",0); return DEFINE;
arrow			tokenpos += yyleng; DEBUG("ARROW\n",0); return ARROW;
circle			tokenpos += yyleng; DEBUG("CIRCLE\n",0); return CIRCLE;
radius|rad		tokenpos += yyleng; DEBUG("RADIUS\n",0); return RADIUS;
plot			tokenpos += yyleng; DEBUG("PLOT\n",0); return PLOT;
frame			tokenpos += yyleng; DEBUG("FRAME\n",0); return FRAME;
graph			tokenpos += yyleng; DEBUG("GRAPH\n",0); return GRAPH;
coord			tokenpos += yyleng; DEBUG("COORD\n",0); return COORD;
for			tokenpos += yyleng; DEBUG("FOR\n",0); return FOR;
from			tokenpos += yyleng; DEBUG("FROM\n",0); return FROM;
thru|through		tokenpos += yyleng; DEBUG("THRU\n",0); return THRU;
to			tokenpos += yyleng; DEBUG("TO\n",0); return TO;
at			tokenpos += yyleng; DEBUG("AT\n",0); return AT;
by			tokenpos += yyleng; DEBUG("BY\n",0); return BY;
until			tokenpos += yyleng; DEBUG("UNTIL\n",0); return UNTIL;
do			tokenpos += yyleng; DEBUG("DO\n",0); return DO;
if			tokenpos += yyleng; DEBUG("IF\n",0); return IF;
then			tokenpos += yyleng; DEBUG("THEN\n",0); return THEN;
else			tokenpos += yyleng; DEBUG("ELSE\n",0); return ELSE;	
print			tokenpos += yyleng; DEBUG("PRINT\n",0); return PRINT;	
sprintf			tokenpos += yyleng; DEBUG("SPRINTF\n",0); return SPRINTF;	
log[ \t]+x			tokenpos += yyleng; DEBUG("LOG_X\n",0); return LOG_X;
log[ \t]+y			tokenpos += yyleng; DEBUG("LOG_Y\n",0); return LOG_Y;
log[ \t]+log			tokenpos += yyleng; DEBUG("LOG_LOG\n",0); return LOG_LOG;
ticks|tick			tokenpos += yyleng; DEBUG("TICKS\n",0); return TICKS;
label			tokenpos += yyleng; DEBUG("LABEL\n",0); return LABEL;
grid			tokenpos += yyleng; DEBUG("GRID\n",0); return GRID;
pic			tokenpos += yyleng; DEBUG("PIC\n",0); return PIC;
top			tokenpos += yyleng; DEBUG("TOP\n",0); return TOP;
bottom|bot		tokenpos += yyleng; DEBUG("BOTTOM\n",0); return BOTTOM;
left			tokenpos += yyleng; DEBUG("LEFT\n",0); return LEFT;
right			tokenpos += yyleng; DEBUG("RIGHT\n",0); return RIGHT;
up			tokenpos += yyleng; DEBUG("UP\n",0); return UP;
down			tokenpos += yyleng; DEBUG("DOWN\n",0); return DOWN;
ljust			tokenpos += yyleng; DEBUG("LJUST\n",0); return LJUST;
rjust			tokenpos += yyleng; DEBUG("RJUST\n",0); return RJUST;
above			tokenpos += yyleng; DEBUG("ABOVE\n",0); return ABOVE;
below			tokenpos += yyleng; DEBUG("BELOW\n",0); return BELOW;
aligned			tokenpos += yyleng; DEBUG("ALIGNED\n",0); return ALIGNED;
unaligned		tokenpos += yyleng; DEBUG("UNALIGNED\n",0); return UNALIGNED;
size			tokenpos += yyleng; DEBUG("SIZE\n",0); return SIZE;
sh			tokenpos += yyleng; DEBUG("SH\n",0); return SH;
in			tokenpos += yyleng; DEBUG("IN\n",0); return IN;
out			tokenpos += yyleng; DEBUG("OUT\n",0); return OUT;
off			tokenpos += yyleng; DEBUG("OFF\n",0); return OFF;
on|auto			tokenpos += yyleng; DEBUG("ON\n",0); return ON;
bar			tokenpos += yyleng; DEBUG("BAR\n",0); return BAR;
fill			tokenpos += yyleng; DEBUG("FILL\n",0); return FILL;
base			tokenpos += yyleng; DEBUG("BASE\n",0); return BASE;
ht			tokenpos += yyleng; DEBUG("HT\n",0); return HT;
wid			tokenpos += yyleng; DEBUG("WID\n",0); return WID;
invis			tokenpos += yyleng; DEBUG("INVIS\n",0); return INVIS;
solid			tokenpos += yyleng; DEBUG("SOLID\n",0); return SOLID;
dotted			tokenpos += yyleng; DEBUG("DOTTED\n",0); return DOTTED;
dashed			tokenpos += yyleng; DEBUG("DASHED\n",0); return DASHED;
fillcolor		tokenpos += yyleng; DEBUG("fillcolor\n",0); return FILLCOLOR;
color			tokenpos += yyleng; DEBUG("color\n",0); return COLOR;
rand			{
			int i;

			DEBUG("FUNC0\n",0);
			for ( i = 0 ; i < NF0; i++ ) 
				if ( !strcmp(yytext,f0names[i]) )
					yylval.val = i;
			tokenpos += yyleng;
 			return FUNC0;
			}
log|exp|int|sin|cos|sqrt|rand|eexp	{
			int i;

			DEBUG("FUNC1\n",0);
			for ( i = 0 ; i < NF1; i++ ) 
				if ( !strcmp(yytext,f1names[i]) )
					yylval.val = i;
			tokenpos += yyleng;
 			return FUNC1;
			}
atan2|min|max		{
			int i;

			DEBUG("FUNC2\n",0);
			for ( i = 0 ; i < NF2; i++ ) 
				if ( !strcmp(yytext,f2names[i]) )
					yylval.val = i;
			tokenpos += yyleng;
			return FUNC2;
			}
([0-9]*\.?[0-9]+)|([0-9]*\.?[0-9]+[eE](\+|\-)?[0-9]+)|([0-9]+\.)	{ 
			DEBUG("Number: %s\n",yytext);
			yylval.num = atof(yytext);
			tokenpos += yyleng;
			return NUMBER;
			}
[.'][ \t]*[^\t 0-9].*$                  {
				tokenpos += yyleng;
				if ( !strncmp(".G1", yytext, 3) ) {
				    if ( lexstack.empty() ||
					 lexstack.front()->report_start == 1 )
				    {
					DEBUG("Start: %s\n",yytext); 
					return START;
				    }
				    else YY_BREAK;
				}
				if ( !strncmp(".G2", yytext, 3) ) {
				    if ( lexstack.empty() ||
					 lexstack.front()->report_start == 1) {

					DEBUG("<GRAP>End: %s\n",yytext);
					BEGIN(INITIAL);
                                        // Eat the newline
                                        yyinput();
					return END;
				    }
				    else YY_BREAK;
				}			
                                yylval.string = new String(yytext);
                                DEBUG("Troff: %s\n",yytext);
				return TROFF;
                        }
\"([^\"\n]|\\\")*\"	{ 
			DEBUG("String: %s\n",yytext);
			yylval.string = new String(yytext);
			tokenpos += yyleng;
			return STRING;
			}
[A-Za-z0-9_]*		{ 
			macro *m;
			macroDictionary::iterator mi;
			coordinateDictionary::iterator ci;
			coord *c;
			String *id;
			char ch;

			DEBUG("ident: %s\n",yytext);
			id = new String(yytext);
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
				yylval.string = id;
				return IDENT;
			    }
			}
                        }
.			tokenpos += yyleng; DEBUG("unknown: %s\n",yytext); return 0;
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
						yylval.string = macrotext;
						DEBUG("TEXT\n",0);
						return TEXT;
					    } else {
						macro *m = new macro(macrotext);

						yylval.macro_val = m;
						DEBUG("MACRO:%s\n",macrotext->c_str());
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
						yylval.string = macrotext;
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
    String *s;
    
    if ( *copy_end != yytext && *copy_backstop != yytext ) {
	s = new String(yytext);
	sl->push_back(s);
    }
    else {

	// If we're stopped by an END symbol, we have to put it back
	
	if ( !strncmp(".G2",yytext,3) ) {
	    DEBUG("<COPYSTATE>End: %s\n",yytext);
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
	DEBUG("COPYTEXT %d\n",yylval.line_list->size());
	return COPYTEXT;
    }
    }
}
<HUNTMACRO>{
[ \t]+	tokenpos += yyleng; 
[A-Za-z0-9_]* 	{
    macro *m;
    macroDictionary::iterator mi;
    
    String *id = new String(yytext);
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
    DEBUG("<HUNTMACRO> %s\n", yytext);
    unput(*yytext);
    lex_begin_macro_text();
    return_macro = 1;
   }
}
<RESTOFLINE>{
.*$ 		{
    BEGIN(GRAP);
    tokenpos += yyleng;
    DEBUG("REST:%s\n",yytext);
    if ( strcmp("\n",yytext) )
	yylval.string = new String(yytext);
    else
	yylval.string = 0;

    return REST;
    }
}
<<EOF>> 	{
    DEBUG("EOF\n",0);
    if ( copystate && !lexstack.empty()) {
	copystate = 0;
	tokenpos = 0;
	BEGIN(GRAP);
	yylval.line_list = sl;
	sl = 0;
	DEBUG("COPYTEXT(EOF)\n",0);
	return COPYTEXT;
    } else yyterminate();
}
%%
bool include_file(String *s, int rs=0, bool usepath=true) {
    FILE *f=0;
    struct grap_buffer_state *g = new grap_buffer_state(0, 0, 0, 1, rs, GFILE);
    grap_buffer_state *gg = lexstack.empty() ? 0 : lexstack.front();

    if ( s ) {
	DEBUG("include_file(%s)\n",s->c_str());
        if ( gg ) {
            gg->tokenpos = tokenpos;
            tokenpos = 0;
        }
	if ( *s != "-" ) {
            if ( (*s)[0] != '/' && usepath ) {
                // use path to look up relative path
                for ( stringSequence::iterator i = path.begin();
                      i != path.end(); i++) {
                    String str = *(*i);

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
	    g->name = new String(*s);
	}
	else {
	    g->yy = yy_create_buffer(stdin,YY_BUF_SIZE);
	    g->name = new String("stdin");
	}
	lexstack.push_front(g);
	yy_switch_to_buffer(g->yy);
	return 1;
    }
    else return 0;
}
	
void lex_begin_macro_text() {
	BEGIN(MACROTEXT);
	DEBUG("<MACROTEXT> lex_begin_macro_text()\n",0);
	lex_expand_macro = 1;
	slashcount = 0;
	macro_end = 0;
	return_macro=0;
	macrotext = new String;
	in_str = 0;
	braces = 0;
}

void lex_begin_coord() {
	BEGIN(COORD_STATE);
	DEBUG("<COORD> lex_begin_coord_param\n",0);
}

void lex_end_coord() {
	BEGIN(GRAP);
	DEBUG("<COORD> lex_end_coord_param\n",0);
}

int include_string(String *s, struct for_descriptor *f=0,
		   grap_input it=GMACRO) {
	char *cbuf;
        int len;
	grap_buffer_state *g;
        grap_buffer_state *gg = lexstack.empty() ? 0 : lexstack.front();

        DEBUG("include string %s\n",s->c_str());

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
    String *arg;
    int c;
    int parens = 0;
    int slashcount = 0;
    int in_str = 0;

    arg = new String;
    for ( c = yyinput(); c != EOF && ( c != ')' || parens ); c = yyinput()) {
	if ( c == ',' && !in_str && !parens) {
	    // End of arg
	    if ( m->add_arg(arg)) arg = new String;
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

void lex_begin_copy(String *s=0) {
    DEBUG("COPYSTATE (lex_begin_copy)\n",0);
    BEGIN(COPYSTATE);
    copystate = 1;
    if ( !copy_backstop ) copy_backstop = new String(".G2");
    if ( copy_end) delete copy_end;
    if ( s ) copy_end = s;
    else copy_end = new String(".G2");
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

    DEBUG("(yywrap)\n",0);
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

String pre_context(void) {
    if (!tokenpos) return "";
    else return linebuf.substr(0,tokenpos-yyleng);
}

char *token_context(void) {
    return (yytext);
}

String post_context(void) {
    return linebuf.substr(tokenpos);
}
