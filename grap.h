#ifndef GRAP_H
#define GRAP_H

#include "grap_data.h"
#include "grap_draw.h"

typedef Dictionary<double *> doubleDictionary;
typedef Dictionary<coord *> coordinateDictionary;
typedef Dictionary<line *> lineDictionary;
typedef Dictionary<macro *> macroDictionary;
typedef Sequence<plot *> plotSequence;
typedef Sequence<double> doublelist;
typedef Sequence<tick *> ticklist;
typedef Sequence<DisplayString *> stringlist;
typedef Sequence<String *> linelist;
typedef Sequence<String *> stringSequence;
typedef Sequence<circle *> circleSequence;
typedef Stack<struct grap_buffer_state*> lexStack;


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
#define NF0 1

static char *f0names[NF0] = {
"rand"
};

#define NF1 7

static char *f1names[NF1] = {
"log", "exp", "int", "sin", "cos", "sqrt","eexp"
};

#define NF2 3

static char *f2names[NF2] = {
"atan2", "min", "max"
};

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
