#ifndef GRAP_DATA_H
#define GRAP_DATA_H
// This file is (c) 1998 Ted Faber (faber@lunabase.org) see COPYRIGHT
// for the full copyright and limitations of liabilities.
#ifdef STDC_HEADERS
#include <string.h>
#endif

#include <stl.h>
#include <ctype.h>


// These should be replaced by the standard string library, but under
// g++ 2.7.2.1 that library is incompatible with the STL

static const int strchunk = 256;

class String {
protected:
    
#ifdef HAVE_SNPRINTF
    inline void snprintf(char *s, int l, char *f, double d) {
	::snprintf(s,l,f,d);
    }
#else 
    inline void snprintf(char *s, int, char *f, double d) {
	::sprintf(s,f,d);
    }
#endif
    
public:
    String() : str(0), len(0) { }

    String(const char *c) : str(0), len(0) {
	resize(::strlen(c)+1);
	strcpy(str,c);
    };

    String(const int i) : str(0), len(0) {
	resize(strchunk);
	snprintf(str,len,"%d",i);
    };

    String(const double d, const String *fmt = 0) : str(0), len(0) {
	resize(strchunk);
	
	if ( fmt ) snprintf(str,len,fmt->str,d);
	else snprintf(str,len,"%g",d);
    };

    String(const String* x) : str(0), len(0) {
	resize(x->len);
	strcpy(str,x->str);
    };

    String(const String& x) : str(0), len(0) {
	resize(x.len);
	strcpy(str,x.str);
    };

    ~String() {
	if ( str) {
	    delete str;
	    str = 0;
	}
	len = 0;
    };

    char& operator[](const int i) {
	if ( i < len ) return str[i];
	else {
	    resize(i+1);
	    return str[i];
	}
    };

    String& operator=(const String &s) {
	if ( len < s.len) resize(s.len);
	strcpy(str,s.str);
	return *this;
    };

    String& operator+=(const String& s) {
	int nlen = s.strlen() + strlen()+ 1;
	if ( len < nlen ) resize(nlen);
	strcat(str,s.str);
	return *this;
    }

    String& operator+=(const char *s) {
	int nlen = ::strlen(s) + strlen() + 1;

	if ( len < nlen ) resize(nlen);
	strcat(str,s);
	return *this;
    }

    String& operator+=(const char c) {
	int last = strlen();
	
	if ( len < last +2 ) resize(last+2);
	last=strlen();
	str[last] = c; str[last+1] = '\0';
	return *this;
    }

    int operator==(const String &s) const {
	return !strcmp(str,s.str);
    }

    int operator<(const String &s) const {
	return ( strcmp(str,s.str) < 0) ;
    }

    int operator==(const char *s) const {
	return !strcmp(str,s);
    }

    int operator!=(const String &s) const {
	return strcmp(str,s.str);
    }

    int operator!=(const char *s) const {
	return strcmp(str,s);
    }
    friend ostream& operator<<(ostream&, String&);

    void quote() {
	int l;
	if ( len < strlen()+3 ) resize(len+3);
	for ( int i = len-1; i >=1; i-- )
	    str[i] = str[i-1];
	l = strlen();
	if ( l == 0 ) l = 1;
	str[0] = '"'; str[l] = '"'; str[l+1] = '\0';
    }

    void unquote() {
	int i;
	if ( str[0] == '"' ) {
	    for ( i = 0; i < len-2; i++ ) str[i] = str[i+1];
	    str[strlen()-1] = '\0';
	}

	i = strlen();
	if ( str[i-1] == '"' ) str[i-1] = '\0';
    }

    void strncpy(char *s, int l) {
	::strncpy(s,str,l);
    }

    int strlen() const {
	return ( (str) ? ::strlen(str) : 0 );
    }
    
protected:
    char *str;
    int len;

    void resize(int ns) {
	char *c;
	int s;

	s =( ns/strchunk + (( ns % strchunk ) ? 1 : 0 )) * strchunk;

	c = new char[s];
	if ( len ) 
	    for ( int j = 0; j < len; j++) c[j] = str[j];
	else
	    c[0] = '\0';
	if ( str ) delete str;
	str = c;
	len = s;
    }
};

inline ostream& operator<<(ostream& f, String& s) { return f << s.str; }

class grap_sprintf_String : public String {
public:
    grap_sprintf_String(const char *f=0) : String(f) {}
    grap_sprintf_String(const String& f) : String(f) {}
    grap_sprintf_String(const String *f) : String(f) {}
    void next_number(double d) {
	char *c = str;
	char *fmt = new char[strlen() + strchunk];
	char *f;
	int first = 1;

	f = fmt;
	for(f=fmt; (*f = *c); c++,f++ ) {
	    if (*c == '%' ) {
		if ( first ) {
		    if ( c[1] == '%' ) {
			*++f = '%';
			*++f = '%';
			*++f = '%';
			c++;
		    }
		    else { first = 0; }
		} else { *++f = '%'; }
	    }
	}
	if ( len < (int) (2 * ::strlen(fmt)) ) resize(2*::strlen(fmt));
	snprintf(str,len,fmt,d);
	delete fmt;
    }
    
    void finish_fmt() {
        // next_number has to double %% throughout the string.  This
        // method removes those doubled % s
	
	char *n = new char[len];
	char *a, *b;

	for ( a = str, b = n; (*b = *a); a++, b++) {
	    if ( *a == '%' && a[1] == '%' ) a++;
	}
	delete str;
	str = n;
    }
};

// template <class objtype>
// class Dictionary {
// public:
//     Dictionary() : list(0), it(0) {};
//     ~Dictionary() { clear();}
//     int find(String n, objtype &found ) {
// 	node *v = list;
// 	while ( v != NULL && v->name != n )
// 	    v= v->next;
// 	if ( v )
// 	    found = v->obj;
// 	return (v) ? 1 : 0;
//     }
//     void insert(String n, objtype o) {
// 	node *v;
	
// 	if ( list ) {
// 	    for ( v = list; v->next != 0; v = v->next)
// 		;
// 	    v->next = new node(n,o);
// 	} else list = new node(n,o);
//     }
//     int first(objtype& found) {
// 	it = (list ) ? list->next : 0;
// 	if ( list) found = list->obj;
// 	return (list) ? 1 : 0;
//     }
//     int next(objtype& found) {
// 	node *i = it;
// 	if ( it ) found = it->obj;
// 	it = (it) ? it->next : 0;
// 	return (i) ? 1 : 0;
//     }
//     void clear() {
// 	node *v, *u;
//  	for ( v = list; v; v = u ) {
// 	    u = v->next;
// 	    delete v;
// 	}  
// 	list = it = 0;
//     } 

// protected:
//     class node {
//     public:
// 	node(String n, objtype o) : name(n), obj(o), next(0) {}
// 	String name;
// 	objtype obj;
// 	node *next;
//     };
//     node *list;
//     node *it;
// };
/*
template <class objtype>
class Sequence {
public:
    Sequence() : seq(0), it(0) {};

    ~Sequence() { clear(); }

    void clear() {
	node *v, *u;
 	for ( v = seq; v; v = u ) {
	    u = v->next;
	    delete v;
	}  
	seq = it = 0;
    } 

    int first(objtype& found) {
	it = (seq) ? seq->next : 0;
	
	if ( seq ) found = seq->obj;
	return (seq) ? 1 : 0;
    }
    
    int next(objtype& found) {
	node *i = it;
	if ( it ) found = it->obj;
	if ( it ) it = it->next;
	return (i) ?  1 : 0;
    }
    void insert(objtype o) {
	node *v;

	if ( seq ) {
	    for ( v = seq; v->next != 0; v = v->next)
		;
	    v->next = new node(o);
	} else seq = new node(o);
    }
protected:
    class node {
    public:
	node(objtype o) : obj(o), next(0) {}
	objtype obj;
	node *next;
    };
    node *seq;
    node *it;
};

template <class objtype>
class Stack : public Sequence<objtype> {
public:
    Stack() : Sequence<objtype>() {}
    objtype pop() {
	objtype o;
	node *s;
	if (seq) {
	    o = seq->obj;
	    s = seq;
	    seq = seq->next;
	    delete s;
	}
	return o;
    }

    objtype top() const {
	objtype o;
	if ( seq ) o = seq->obj;
	return o;
    }

    void push(objtype o) {
	node *n = new node(o);
	n->next = seq;
	seq = n;
    }

    bool empty() { return seq == 0; }

    int size() {
	int i = 0;
	node *v;
	
	if ( seq ) {
	    for ( v = seq; v != 0; v = v->next)
		i++;
	}
	return i;
    }
};
*/
class macro {
public:
    static const int numargs = 9;	// maximum number of arguments
    int next_arg;			// the index into the next argument
    String *text;			// the text of the macro
    String *arg[numargs];		// the current argument values
    String *name;			// the name of the macro if it's in a
                                        // dictionary.
    macro(String *t=0, String *n =0) : next_arg(0), text(t), name(n) {
	for ( int i = 0; i < numargs ; i++ )
	    arg[i] = 0;
    }
    ~macro() {
	if ( text ) {
	    delete text;
	    text = 0;
	}
	if ( name ) {
	    delete name;
	    name = 0;
	}
	for ( int i = 0; i < numargs ; i++ )
	    if ( arg[i] ) {
		delete arg[i];
		arg[i] = 0;
	    }
	
    }
    int add_arg(String *s ) {
	if ( next_arg < numargs ) {
	    if ( arg[next_arg] ) delete arg[next_arg];
	    arg[next_arg++] = s;
	    return 1;
	}
	else return 0;
    }
    
    String *invoke() {
	String *s = new String;	// The expanded macro
	int argn =0;		// the number of the arg to interpolate
	int dig;		// Number of digits seen after this $
	int i=0;		// the current character offset

	while ((*text)[i] != '\0' ) {
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
		    if ( argn > 0 && argn <= numargs ) {
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
	for ( i = 0 ; i < numargs; i ++ ) {
	    if ( arg[i] ) delete arg[i];
	    arg[i] =0;
	}
	return s;		
    }
};
#endif
