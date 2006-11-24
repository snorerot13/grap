#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <stdio.h>
#include <iostream>
#include <math.h>
#include <stdexcept>
#include "grap.h"
#include "grap_data.h"
#include "grap_draw.h"

// This file is (c) 1998-2001 Ted Faber (faber@lunabase.org) see COPYRIGHT
// for the full copyright and limitations of liabilities.

void coord::newx(double x) {
// Specific code to add the x value.  If the axis is being autoscaled,
// see if this point expands it.  Otherwise, sanity check it.
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
	if ( xmin  < min_double ) {
	    cerr << "Logscale with non-positive value (within precision)"
		 << endl;
	    xmin = min_double;
	}
	if ( xmax  < min_double ) {
	    cerr << "Logscale with non-positive value (within precision)"
		 << endl;
	    xmax = min_double;
	}
    }
}

void coord::newy(double y) {
// Specific code to add the x value.  If the axis is being autoscaled,
// see if this point expands it.  Otherwise, sanity check it.
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
	if ( ymin  < min_double ) {
	    cerr << "Logscale with non-positive value (within precision)"
		 << endl;
	    ymin = min_double;
	}
	if ( ymax  < min_double ) {
	    cerr << "Logscale with non-positive value (within precision)"
		 << endl;
	    ymax = min_double;
	}
    }
}

void coord::addmargin(double mf) {
// Add a margin to the coordinate system to center the plot better.
// The margin factor(mf) is given as a multiplier to the current size
// (0.07 is 7% on either size).  If the axis is logarithmic, we have
// to work in that space.
    
    double range;	// The size of the axis we're working on

    // Log sale must be positive
    
    if ( (logscale & x_axis) ) {
	if ( xmin  < min_double ) xmin = min_double;
	if ( xmax  < min_double ) xmax = min_double;
    }
    if ( (logscale & y_axis) ) {
	if ( ymin  < min_double ) ymin = min_double;
	if ( ymax  < min_double ) ymax = min_double;
    }
    
    if ( xautoscale ) {

	if ( logscale & x_axis) {
	    double b, t;	// bottom and top of the logscale range

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
	    double b, t; 	// bottom and top of the logscale range

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

    // If they're too close together, just punt.  (Actually this is less a punt
    // than it looks like.  Adding 1 works if no points have been added that
    // would define a grid - xmin == xmax == 0 and if you do almost nothing you
    // get a (0,1) x (0,1) frame).
    
    if ( xmax == xmin) xmax += 1.0;
    if ( ymax == ymin) ymax += 1.0;
}


double coord::map(double v, axis ax ) {
// map the coordinate from data space to [0,1]. 1 is the top of the axis,
// 0 the bottom.  Do it right for logscale or cartesian coordinates
    switch ( ax ) {
	case x_axis:
	    if (logscale & x_axis ) {
		if ( v > min_double )
		    return ((log(v) -log(xmin)) / (log(xmax)-log(xmin)));
		else
		    throw range_error("Negative or zero logscale coordinate");
	    }
	    else return ( (v - xmin) / (xmax - xmin ) );
	    break;
	case y_axis:
	    if (logscale & y_axis ) {
		if ( v > min_double ) 
		    return ((log(v) -log(ymin)) / (log(ymax)-log(ymin)));
		else 
		    throw range_error("Negative or zero logscale coordinate");
	    }
	    else return ( (v - ymin) / (ymax - ymin ) );
	    break;
	default:
	    return -1;
	    break;
    }
}

// Linesegment constructor. Too long for a header, but
// straightforward.  Connect this segment to the previous point in the
// line.
linesegment::linesegment(double xx, double yy, coord* cc, line *ll,
			 DisplayString *s /* =0 */, linedesc *l /* =0 */,
			 bool a /* =false */)
    : to(xx,yy,cc), from(0) {
    point *p;	// The last point on line ll.
    
    // If a null linedesc is passed in, use the one in the line
    if ( l ) desc = *l;
    else desc = ll->desc;

    if ( s ) plotstr = new DisplayString(*s);
    else {
	if ( ll->plotstr ) plotstr = new DisplayString(*ll->plotstr);
	else plotstr = 0;
    }
    arrow = a;

    if ((p = ll->lastplotted())) 
	from = new point(p);
    
    ll->lastplotted(&to);
}
