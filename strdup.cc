#ifdef STDC_HEADERS
#include <sys/types.h>
#endif

extern "C" {
    void * malloc(size_t size);
};

char *strdup(const char *s) {
    int len = strlen(s)+1;
    char *t;
    int i;

    if ( !(t = (char *) malloc(len)) ) return 0;
    else
	for ( i = 0; i < len; i++ ) t[i] = s[i];

    return t;
}
