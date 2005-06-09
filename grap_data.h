//-*-c++-*-
#ifndef GRAP_DATA_H
#define GRAP_DATA_H
// This file is (c) 1998-2001 Ted Faber (faber@lunabase.org) see COPYRIGHT
// for the full copyright and limitations of liabilities.
#ifdef STDC_HEADERS
#include <string.h>
#endif
#include <ctype.h>
#include <string>
#include <vector>

inline void unquote(string *s) {
    int i;
    if ( (*s)[0] == '"' ) s->erase(0,1);
    i = s->length()-1;
    if ( (*s)[i] == '"' ) s->erase(i,1);
}

inline void quote(string *s) {
    s->insert((string::size_type) 0,1,'"');
    s->append(1,'"');
}

class macro {
public:
    int next_arg;			// the index into the next argument
    string *text;			// the text of the macro
    vector<string *> arg;		// The current argument values
    string *name;			// the name of the macro if it's in a
                                        // dictionary.
    macro(string *t=0, string *n =0) : next_arg(0), text(t), arg(), name(n) { }
    ~macro() {
	delete text;
	text = 0;
	delete name;
	name = 0;
	while ( !arg.empty() ) {
	    string *d = arg.back();
	    arg.pop_back();
	    delete d;
	}
    }
    int add_arg(string *s ) {
	arg.push_back(s);
	return 1;
    }
    
    string *invoke() {
	string *s = new string;	// The expanded macro
	int argn =0;		// the number of the arg to interpolate
	int dig;		// Number of digits seen after this $
	int i=0;		// the current character offset
	const int lim=text->length();// number of characters to check

	while (i < lim ) {
	    switch ((*text)[i] ) {
		default:
		    *s += (*text)[i++];
		    break;
		case '$':
		    dig = 0;
		    i++;
		    while (isdigit((*text)[i])) {
			argn *= 10;
			argn += (*text)[i] - 0x30;
			i++; dig++;
		    }
		    if ( argn > 0 && argn <= (int) arg.size() ) {
			if ( arg[argn-1] )
			    *s += *(arg[argn-1]);
		    }
		    argn = 0;
		    // If there was no digit after the $ leave the $
		    // untouched and leave i as the offset of the
		    // character immediately following the $
		    
		    if ( !dig ) {
			*s += '$';
		    }
		    break;
	    }
	}
	next_arg = 0;
	while ( !arg.empty() ) {
	    string *d = arg.back();
	    arg.pop_back();
	    delete d;
	}
	return s;		
    }
};

class copydesc {
 public:
    typedef enum { fname, until} type;
    type t;
    string *s;
    copydesc() : t(fname), s(0) {} 
    ~copydesc() {
	if ( s ) {
	    delete s;
	    s = 0;
	}
    }
};

// encapsulate the information about the simple keyword tokens.
class keyword {
public:
    vector<string> add;		// make these keywords active
    vector<string> remove;	// make these keywords inactive
    bool clear;			// clear the active keyword list if this true
    int token;			// the lex token that corresponds to this
                                // string.

    keyword() : add(), remove(), clear(false), token(0) { }
    
    keyword(const keyword& k) :
	add(k.add), remove(k.remove), clear(k.clear), token(k.token) { }

    keyword(const vector<string>& a, const vector<string>& r, bool cl, int t) :
	add(a), remove(r), clear(cl), token(t) { }

    template <class I1, class I2>
    keyword(I1 sa, I1 ea, I2 sr, I2 er, bool cl, int t) :
	add(sa, ea), remove(sr, er), clear(cl), token(t) { }

    keyword& operator=(const keyword& k) {
	add = k.add;
	remove = k.remove;
	clear = k.clear;
	token = k.token;
	return *this;
    }

};


// we use this to make yacc happier
typedef pair<coord *, string *> coordid;
// bar parameter types
class bar_param {
    public:
	double x;
	double ht;
	double wid;
	double base;
	bool have_x;
	bool have_ht;
    bar_param() : x(0.0), ht(0.0), wid(1.0), base(0.0), 
		  have_x(false), have_ht(false) { }
};
#endif
