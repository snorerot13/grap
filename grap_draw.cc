#include <stdio.h>
#include <iostream.h>
#include <math.h>
#include "grap.h"

void coord::newpt(double x, double y) {
    newx(x);
    newy(y);
}
void coord::newx(double x) {
    if ( xautoscale == 2) {
	xmax = (x > xmax ) ? x : xmax;
	xmin = (x < xmin ) ? x : xmin;
    }

    if ( xautoscale == 1 ) {
	// first point

	xmax = xmin = x;
	xautoscale = 2;
    }
    if ( (logscale & x_axis) ) {
	if ( xmin  < EPSILON ) {
	    xmin = EPSILON;
	    cerr << "Logscale with negative value" << endl;
	}
	if ( xmax  < EPSILON ) {
	    xmax = EPSILON;
	    cerr << "Logscale with negative value" << endl;
	}
    }
}

void coord::newy(double y) {
    if ( yautoscale == 2) {
	ymax = (y > ymax ) ? y : ymax;
	ymin = (y < ymin ) ? y : ymin;
    }

    if ( yautoscale == 1 ) {
	// first point

	ymax = ymin = y;
	yautoscale = 2;
    }
    if ( (logscale & y_axis) ) {
	if ( ymin  < EPSILON ) {
	    ymin = EPSILON;
	    cerr << "Logscale with negative value" << endl;
	}
	if ( ymax  < EPSILON ) {
	    ymax = EPSILON;
	    cerr << "Logscale with negative value" << endl;
	}
    }
}

void coord::addmargin(double mf) {
    double range;

    // Log sale must be positive
    
    if ( (logscale & x_axis) ) {
	if ( xmin  < EPSILON ) xmin = EPSILON;
	if ( xmax  < EPSILON ) xmax = EPSILON;
    }
    if ( (logscale & y_axis) ) {
	if ( ymin  < EPSILON ) ymin = EPSILON;
	if ( ymax  < EPSILON ) ymax = EPSILON;
    }
    
    if ( xautoscale ) {

	if ( logscale & x_axis) {
	    double b, t;

	    // Solving the log mapping equation for 1+mf and -mf
	    // Isn't math cool?
	    
	    b = pow(xmax,-mf) / pow(xmin,(-mf-1));
	    t = pow(xmax,1+mf) / pow(xmin,mf);
	    xmin = b; xmax = t;
	} else {
	    range = xmax - xmin;
	    xmin = xmin - mf * range;
	    xmax = xmax + mf * range;
	}
    }
    
    if ( yautoscale ) {

	if ( logscale & y_axis) {
	    double b, t;

	    // Solving the log mapping equation for 1+mf and -mf
	    // Isn't math cool?
	    
	    b = pow(ymax,-mf) / pow(ymin,(-mf-1));
	    t = pow(ymax,1+mf) / pow(ymin,mf);
	    ymin = b; ymax = t;
	} else {
	    range = ymax - ymin;
	    ymin = ymin - mf * range;
	    ymax = ymax + mf * range;
	}
    }
    if ( xmax == xmin) xmax += 1.0;
    if ( ymax == ymin) ymax += 1.0;
}


double coord::map(double v, axis ax ) {
    switch ( ax ) {
	case x_axis:
	    if (logscale & x_axis ) {
		if ( v < EPSILON )
		    return -1;
		else
		    return ((log(v) -log(xmin)) / (log(xmax)-log(xmin)));
	    }
	    else return ( (v - xmin) / (xmax - xmin ) );
	    break;
	case y_axis:
	    if (logscale & y_axis ) {
		if ( v < EPSILON ) return -1;
		else return ((log(v) -log(ymin)) / (log(ymax)-log(ymin)));
	    }
	    else return ( (v - ymin) / (ymax - ymin ) );
	    break;
	default:
	    return -1;
	    break;
    }
}

line::linepoint::linepoint(double xx, double yy, coord* cc, line *ll,
			   String *s, linedescval *l, int a=0)
    : point(xx,yy,cc) {


	// If a null linedescval is passed in, use the one in the line
	
	if ( !l ) l = &ll->desc;
	
	desc.ld = l->ld;
	desc.param = l->param;
	
	if ( l-> color ) 
	    desc.color = new String(l->color);
	else
	    desc.color = 0;
	
	if ( s ) plotstr = new String(*s);
	else {
	    if ( ll->plotstr ) plotstr = new String(*ll->plotstr);
	    else plotstr = 0;
	}
	initial = ll->initial;
	ll->initial = 0;
	arrow = a;
}

