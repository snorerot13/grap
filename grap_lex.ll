/* -*-c++-*- */
%{
/* This code is (c) 1998-2001 Ted Faber see COPYRIGHT
   for the full copyright and limitations of liabilities. */
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#ifdef STDC_HEADERS
#include <string.h>
#include <ctype.h>
#endif
#if defined(STDC_HEADERS) | defined(HAVE_STDLIB_H)
#include <stdlib.h>
#else
extern "C" {
    void free(void*);
};
#endif
#include <iostream>
#include <sys/param.h>
#include <set> 
#include <map> 
#include "grap.h"
#include "grap_data.h"
#include "grap_draw.h" 
#include "y.tab.h"

extern int errno;

#ifndef STRERROR_DECLARED
#if HAVE_STRERROR 
extern "C" { 
     char *strerror(int errnum);
}
#else
extern char *strerror(int errnum);
#endif
#endif 
// CGYWIN needs errno if we have it:
#ifdef HAVE_ERRNO_H
#include <errno.h>
#endif

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

bool lex_expand_macro = true;

linelist *sl=0;
string *copy_end, *copy_backstop;

string linebuf; 

extern macroDictionary macros;
extern doubleDictionary vars;
extern graph *the_graph;
extern stringSequence path;
extern bool compat_mode;
extern bool id_letter[]; 

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

int include_string(string *, struct for_descriptor *f=0, grap_input i=GMACRO);
void lex_begin_macro_text();
void lex_end_expr(); 
void macro_args(macro*);
void expand_macro(macro*);
bool is_macro(const string&);
void newline();
#ifndef HAVE_STRDUP
char *strdup(const char *);
#endif 

const char *vf1names[NVF1] = { "srand" };
const char *f0names[NF0] = { "rand", "getpid" };
const char *f1names[NF1] = { "log", "exp", "int", "sin", "cos", "sqrt",
		       "eexp","ln" };
const char *f2names[NF2] = { "atan2", "min", "max" };

#define	ECHO	/* */

// Set of currently active keywords 
set<string> active;

// Commonly used keyword sets
extern vector<string> grap_keys;
extern keywordDictionary keywords; 
// There are a couple times when the possiblity of a COORD_NAME can be
// ruled out.  If this is set, this is one of those times.
bool no_coord=false;
 
%}
%x GRAP
%x REJECTED_COORD
%x MACROTEXT
%x COPYSTATE
%x HUNTMACRO
%x RESTOFLINE

identifier	[A-Za-z][A-Za-z0-9_]*

keyword		above|aligned|arrow|auto|bar|base|below|bot|bottom|by|circle|color|coord|copy|dashed|define|do|dotted|down|draw|else|fill|fillcolor|for|frame|from|graph|grid|ht|if|in|invis|label|left|line|ljust|new|next|off|on|out|pic|plot|print|rad|radius|right|rjust|sh|size|solid|sprintf|then|through|thru|tick|ticks|to|top|unaligned|until|up|wid|x|y|undefine|clipped|unclipped|thickness
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
	active.insert(grap_keys.begin(), grap_keys.end());
	return START;
	}
.+	{
		tokenpos += yyleng;
		cout << yytext;
	}
}
<GRAP,REJECTED_COORD>{
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
			  active.insert(grap_keys.begin(), grap_keys.end());
                          debug("SEP");
			  BEGIN(GRAP);
			  return SEP; 
			}
\#.*$
[ \t]+			tokenpos += yyleng;

 ([0-9]*\.?[0-9]+)|([0-9]*\.?[0-9]+[eE](\+|\-)?[0-9]+)|([0-9]+\.)	{ 
			debug("Number: ",yytext);
			yylval.num = atof(yytext);
			tokenpos += yyleng;
			BEGIN(GRAP);
			return NUMBER;
			}

 {identifier}[ \t]*=/[^=] {
                           if ( is_macro(yytext) ) 
			       REJECT;

                           // in a for statement, identifier = is a
                           // synonym for identifier FROM, so don't
                           // identify it as a LHS.
                           if ( active.count("do") && active.count("from"))
				REJECT;
                           tokenpos += yyleng;
                           for ( int i = 0; i < yyleng; i++ )
                               if ( yytext[i] == ' ' || yytext[i] == '\t' ||
				    yytext[i] == '=' ) {
				   yytext[i] = '\0';
				   break;
			       }
			   yylval.String = new string(yytext);
			   debug("LHS: ", yytext);
			   BEGIN(GRAP);
			   return LHS;
                        }
;			{
			  tokenpos += yyleng;
                          debug("SEP");
			  // Back to square 1 after a SEP
			  active.clear();
			  active.insert(grap_keys.begin(), grap_keys.end());
			  BEGIN(GRAP);
			  return SEP; 
                        }
\(			tokenpos += yyleng; debug("LPAREN"); return LPAREN;
\)			tokenpos += yyleng; debug("RPAREN"); return RPAREN;
,			tokenpos += yyleng; debug("COMMA"); return COMMA;
\+			tokenpos += yyleng; debug("PLUS"); return PLUS;
\%			tokenpos += yyleng; debug("MOD"); return MOD;
\-			tokenpos += yyleng; debug("MINUS"); return MINUS;
\*			tokenpos += yyleng; debug("TIMES"); return TIMES;
\/			tokenpos += yyleng; debug("DIV"); return DIV;
\^			tokenpos += yyleng; debug("CARAT"); return CARAT;
\=			{
                          tokenpos += yyleng;
			  // if this is in a for statement, the EQUALS
			  // has taken the place of the from, so
			  // remove the from from active.
			  if ( active.count("do") && active.count("from"))
			      active.erase("from");
			  debug("EQUALS");
			  BEGIN(GRAP);
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
log[ \t]+(x|y|log)	{
                          int rc = LOG_LOG;
			  string ls(yytext);
			  
                          if (active.count("log") ) {
			      tokenpos += yyleng;
			      // LOG_whatever doesn't change the active
			      // state.
			      debug(yytext);
			      BEGIN(GRAP);
			      if ( ls.find('x') != string::npos ) rc = LOG_X;
			      else
				  if ( ls.find('y') != string::npos)
				      rc = LOG_Y;
			      return rc;
			  }
			  else {
			      debug(yytext, " not active");
			      REJECT;
			  }
			}
}
<GRAP>{identifier}[ \t][ \t]*{identifier} {
			   // The yyless/YY_BREAK allows us to redo the
                           // match under the new start condition.

			   debug("starting ident white ident");
                           if ( is_macro(yytext) ) {
			       BEGIN(REJECTED_COORD);
			       yyless(0);
			       YY_BREAK;
			   }
			   
                           // Early rejection if a COORD_NAME is
                           // illegal here.
                           if ( no_coord ) {
			       debug("<REJECTED_COORD>");
			       BEGIN(REJECTED_COORD);
			       yyless(0);
			       YY_BREAK;
			   }

			   
                           // Here we go - parse out the two
                           // identifiers.  If the first is an active
                           // keyword, REJECT.  If the second
                           // identifier is not an active keyword,
                           // then this is a coordinate name, so put
                           // the whitespace and the second identifier
                           // back into the input and return the
                           // coordinate name.  If no REJECT.

                           string first(yytext);	// first id
			   string second;
			   string::size_type f, l;
			   coordinateDictionary::iterator ci;
			   coord *c;

			   for (f = 0;isalnum(first[f]) ||first[f] == '_'; f++)
			       ;
			   // Now f is on the first whitespace character;
			   for (l = f; first[l] == ' '|| first[l] =='\t'; l++)
			       ;
			   // l is now the first character of the
			   // second identifier.
			   second = first.substr(l);
			   first.erase(f);
			   
			   debug("Coord search");
			   debug(first, second);
			   debug(active.count(first), active.count(second));
			   
			   if (active.count(first) || active.count(second)) {
			       debug("<REJECTED_COORD>");
			       BEGIN(REJECTED_COORD);
			       yyless(0);
			       YY_BREAK;
			   }
			   ci = the_graph->coords.find(first);
			   if ( ci != the_graph->coords.end()) {
			       c = (*ci).second;
			       yylval.coordptr = c;
			   }
			   else {
			       yylval.coordptr = new coord(first);
			       the_graph->coords[first] = yylval.coordptr;
			   }
			   yyless(first.length());
			   tokenpos += first.length();
			   debug("COORD_NAME");
			   return COORD_NAME;
                        }
<GRAP,REJECTED_COORD>{
{identifier}/[ \t][ \t]*-[ \t]*[0123456789\.(] {
			   // This is close to the case below, which is more
			   // clearly a coordinate space modifying a number.
			   // This case includes things like
			   //    ident -3
			   // It's often literally impossible to decide if that
			   // means -3 in the ident coordinate space or the
			   // variable ident minus 3.  This code rules that if
			   // ident is a keyword, macro, or initialized
			   // variable, ident will be treated as one of those,
			   // and this rule will be rejected.  Otherwise it is
			   // a coordinate space and, if neceaasry, a new space
			   // will be allocated for it.
			   //
			   // I don't expect that this is the last piece of
			   // pain to come from here.
			   coordinateDictionary::iterator ci;
			   coord *c;
			   
			   debug("testing (minus sign): ",yytext);
			   debug("count ", active.count(yytext));
                           if ( is_macro(yytext) ) 
			       REJECT;

			   if ( active.count(yytext) ) 
			       REJECT;

			   if ( vars.count(yytext) ) 
			   	REJECT;

			   ci = the_graph->coords.find(yytext);
			   if ( ci != the_graph->coords.end()) {
			       c = (*ci).second;
			       yylval.coordptr = c;
			   }
			   else {
			       yylval.coordptr = new coord(yytext);
			       the_graph->coords[yytext] = yylval.coordptr;
			   }
			   tokenpos += yyleng;
			   debug("COORD_NAME: ",yytext);
			   return COORD_NAME;
                        }
{identifier}/[ \t][ \t]*[0123456789\.(] {
			   coordinateDictionary::iterator ci;
			   coord *c;
			   
			   debug("testing: ",yytext);
			   debug("count ", active.count(yytext));
                           if ( is_macro(yytext) ) 
			       REJECT;

			   if ( active.count(yytext) ) 
			       REJECT;

			   ci = the_graph->coords.find(yytext);
			   if ( ci != the_graph->coords.end()) {
			       c = (*ci).second;
			       yylval.coordptr = c;
			   }
			   else {
			       yylval.coordptr = new coord(yytext);
			       the_graph->coords[yytext] = yylval.coordptr;
			   }
			   tokenpos += yyleng;
			   debug("COORD_NAME: ",yytext);
			   return COORD_NAME;
                        }
{keyword}               {
                           macroDictionary::iterator mi;
			   
			   if ( lex_expand_macro &&
				( mi = macros.find(yytext)) != macros.end() ) {
			       expand_macro((*mi).second);
			       tokenpos += yyleng;
			       BEGIN(GRAP);
			   }
			   else {
			       if (active.count(yytext) ) {
				   keywordDictionary::iterator ki;
				   unsigned int i;

				   if ( (ki = keywords.find(yytext))
					== keywords.end()) {
				       cerr << "keyword not in map!?" << endl;
				       return(0);
				   }
				   // The alias runs faster
				   const keyword& k = (*ki).second;
			       
				   if ( k.clear ) active.clear();
				   for ( i = 0; i < k.add.size(); i++ ) 
				       active.insert(k.add[i]);
				   for ( i = 0; i < k.remove.size(); i++) 
				       active.erase(k.remove[i]);

				   debug("keyword: ", yytext);
				   tokenpos += yyleng;
				   BEGIN(GRAP);
				   return(k.token);
			       }
			       else {
				   debug(yytext, " not active");
				   REJECT;
			       }
			   }
                        }
at			{
                          if (active.count(yytext) ) {
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

			      if ( active.count("plot")) active.clear();
			      else active.erase("at");
			      debug("AT");
			      BEGIN(GRAP);
			      return AT;
			  }
			  else {
			      debug("AT not active");
			      REJECT;
			  }
			}
srand			{
			debug("VFUNC1");
			for ( int i = 0 ; i < NVF1; i++ ) 
				if ( !strcmp(yytext,vf1names[i]) )
					yylval.val = i;
			tokenpos += yyleng;
			BEGIN(GRAP);
 			return VFUNC1;
			}
rand|getpid			{
			debug("FUNC0");
			for ( int i = 0 ; i < NF0; i++ ) 
				if ( !strcmp(yytext,f0names[i]) )
					yylval.val = i;
			tokenpos += yyleng;
			BEGIN(GRAP);
 			return FUNC0;
			}
log|exp|int|sin|cos|sqrt|eexp|ln	{
			debug("FUNC1");
			for ( int i = 0 ; i < NF1; i++ ) 
				if ( !strcmp(yytext,f1names[i]) )
					yylval.val = i;
			tokenpos += yyleng;
			BEGIN(GRAP);
 			return FUNC1;
			}
atan2|min|max		{
			debug("FUNC2");
			for ( int i = 0 ; i < NF2; i++ ) 
				if ( !strcmp(yytext,f2names[i]) )
					yylval.val = i;
			tokenpos += yyleng;
			BEGIN(GRAP);
			return FUNC2;
			}
[.\'][ \t]*[^\t 0-9].*$                  {
				tokenpos += yyleng;
				if ( !strncmp(".G1", yytext, 3) ) {
				    if ( lexstack.empty() ||
					 lexstack.front()->report_start == 1 )
				    {
					debug("Start: ", yytext);
					BEGIN(GRAP);
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
					newline();
					tokenpos = 0;
					return END;
				    }
				    else YY_BREAK;
				}			
                                yylval.String = new string(yytext);
                                debug("Troff: ", yytext);
				BEGIN(GRAP);
				return TROFF;
                        }
\"([^\"\n]|\\\")*\"	{ 
			debug("String: ", yytext);
			yylval.String = new string(yytext);
			tokenpos += yyleng;
			BEGIN(GRAP);
			return STRING;
			}
{identifier}		{ 
			macroDictionary::iterator mi;
			string *id;

			debug("ident: ", yytext);
			id = new string(yytext);
			if ( lex_expand_macro &&
			     ( mi = macros.find(*id)) != macros.end() ) {
			    delete id;
			    expand_macro((*mi).second);
			    tokenpos += yyleng;
			}
			else {
			    tokenpos += yyleng;
			    yylval.String = id;
			    BEGIN(GRAP);
			    return IDENT;
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

    no_coord = false;
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

// Most of these that begin with lex_ are an interface from the parser
// (grap.y)

// XXX: Store the line number info in the output text as a .lf.  This isn't
// quite right yet.  It's nulled out because it was worse than "not right" it
// was emitting text outside the PS/PE.
void linenum() { }

// Put the given file into the input stream.  If rs is true, report
// start tokens from that buffer.  If usepath is true the grap path is
// used to search for the file.
bool include_file(string *s, bool rs /* =false */ , bool usepath /* =true*/) {
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
	    g->name = new string("-");
	}
	lexstack.push_front(g);
	yy_switch_to_buffer(g->yy);
	return 1;
    }
    else return 0;
}

// Include the given string into the input stream.  Additional
// parameters are a for descriptor associated with the buffer (if its
// part of a for loop) and an input type (that's usualy GMACRO)
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

// Disable macro expansion of identifers (used in definingin new macros)
void lex_no_macro_expansion() { lex_expand_macro = false; }
// Disable macro expansion of identifers (used in definingin new macros)
void lex_macro_expansion_ok() { lex_expand_macro = true; }

// Begin parsing macro text.  Set the lexer into the appropriate start
// condition and initialize the appropriate internals.
void lex_begin_macro_text() {
	BEGIN(MACROTEXT);
	debug("<MACROTEXT> lex_begin_macro_text()");
	lex_expand_macro = true;
	slashcount = 0;
	macro_end = 0;
	return_macro=0;
	macrotext = new string;
	in_str = 0;
	braces = 0;
}

// Parse the arguments to a macro invocation and call macro::add_arg
// on them.
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

// prepare to copy text from the input for a copy statement.  Set the
// start condition and the internal state.
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

// Change start condition
void lex_hunt_macro() { BEGIN(HUNTMACRO); }
// Change start condition
void lex_begin_rest_of_line() { BEGIN(RESTOFLINE); }

// Tell if coordinate names are allowed here
void lex_no_coord() { no_coord = true; }
// Tell if coordinate names are allowed here
void lex_coord_ok() { no_coord = false; }

// This buffer is empty, go to the next one on the stack.  If there is
// an associated for descriptor, do the for processing and replace the
// buffer on the stack if the loop is continuing.
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
	    case MOD:
		*f->loop_var = static_cast<int>(*f->loop_var) % 
			static_cast<int>(f->by);
		break;
	}

	if ( (*f->loop_var - f->limit) * f->dir < epsilon ) {
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

    if ( lexstack.empty() ) {
	// groff line marker
	delete g;
	return 1;
    }
    else {
	grap_input closed = g->type;
	delete g;
	g = lexstack.front();
        tokenpos = g->tokenpos;
	yy_switch_to_buffer(g->yy);
    }

    return copystate ? 1 : 0;
}

// Newline processing.  Inrement the current line number
void newline() {
    if ( !lexstack.empty() ) {
	grap_buffer_state *g = lexstack.front();
	g->line++;
    }
}

// Error message printing.
string pre_context(void) {
    if (!tokenpos) return "";
    else return linebuf.substr(0,tokenpos-yyleng);
}

char *token_context(void) {
    return (yytext);
}

string post_context(void) {
    return (tokenpos < linebuf.size()) ? linebuf.substr(tokenpos) : "" ;
}


void expand_macro(macro *m) {
    char ch = yyinput();
    string *exp;
    
    if ( ch == '(') {
	macro_args(m);
	tokenpos++;
    }
    else {
// flex 2.3.51+ undefs yytext_ptr which breaks the unput macro outside the
// first %% section.  This is a kludge to expand the macro by hand if this bad
// thing has happened.  I think I'll try to convince them this is a bad idea.
#ifndef yytext_ptr
	yyunput(ch, yytext);
#else
	unput(ch);
#endif
    }
    exp = m->invoke();
    include_string(exp);
    delete exp;
}

bool is_macro(const string& s) {
    int i = (int) s.length()-1;
    string mname;

    while ( i >=0 && !id_letter[static_cast<unsigned int>(s[i])])
	i--;
    if ( i < 0 ) return false;

    mname = s.substr(0, i+1);
    return (macros.find(mname) != macros.end());
}
