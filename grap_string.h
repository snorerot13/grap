#ifndef GRAP_STRING_H
#define GRAP_STRING_H

// These should be replaced by the standard string library, but under
// g++ 2.7.2.1 that library is incompatible with the STL

static const int strchunk = 256;

class String {
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

    int operator<(String& s) {
	return strcmp(str,s.str) < 0;
    }

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
    const char *c_str() const { return str;}
    int length() { return strlen();}

    ostream& print(ostream& f) const {
	return f << str;
    }

    String substr(int i, int n=0) {
	String s;

	s.resize(strlen());
	if ( n == 0 || n > strlen()-i )
	    n = strlen() - i;
	for ( int j = 0; j < n; j++ )
	    s.str[j] = str[i+j];
	s.str[n] = '\0';
	return s;
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

inline ostream& operator<<(ostream& f, const String& s) { return s.print(f); }

// These functions and classes are all duplicated for standard strings
// in grap_data.h.  The choice is to either support 2 versions of
// these functions or to make the emulation of standard strings better
// and support that.  Because this code was already written, I chose
// this.

inline String *dblString(double d, String *f=0) {
    return new String(d,f);
}

inline void unquote(String *s) {
    s->unquote();
}

inline void quote(String *s) {
    s->quote();
}


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
#endif
