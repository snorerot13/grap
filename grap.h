#ifndef GRAP_H
#define GRAP_H
// This file is (c) 1998 Ted Faber (faber@lunabase.org)

// No, I don't know why...
#define UnaryFunction unary_function

#include "grap_data.h"
class DisplayString;
class line;
class coord;
class macro;
class plot;
class tick;
class grid;
class circle;

typedef less<String> Strcmp;

typedef map<String, double *, Strcmp> doubleDictionary;
typedef map<String, coord *, Strcmp> coordinateDictionary;
typedef map<String, line *, Strcmp> lineDictionary;
typedef map<String, macro *, Strcmp> macroDictionary;
typedef list<plot *> plotSequence;
typedef list<double> doublelist;
typedef list<tick *> ticklist;
typedef list<grid *> gridlist;
typedef list<String *> linelist;
typedef list<String *> stringSequence;
typedef list<circle *> circleSequence;
typedef list<struct grap_buffer_state*> lexStack;
typedef list<DisplayString *> stringlist;

#include "grap_draw.h"
#include "grap_pic.h"


#define RAND 0

#define LOGFCN 0
#define EXP 1
#define INT 2
#define SIN 3
#define COS 4
#define SQRT 5
#define EEXP 6

#define ATAN2 0
#define MINFUNC 1
#define MAXFUNC 2

enum size { ht = 0, wid};


typedef struct {
    int op;
    double expr;
} bydesc;

typedef struct {
    axis which;
    double min;
    double max;
} axisdesc;

typedef struct {
    double size;
    int rel;
    int just;
} strmod;

struct for_descriptor {
    double *loop_var;
    int dir;
    double limit;
    double by;
    int by_op;
    String *anything;
};

typedef enum { GFILE=1,  GMACRO, GINTERNAL } grap_input;

struct grap_buffer_state {
    struct yy_buffer_state *yy;
    struct for_descriptor *f;
    String *name;
    int line;
    int report_start;
    grap_input type;
};


extern lexStack lexstack;

#define EPSILON	1e-6

#endif
