/* This code is (c) 1998-2001 Ted Faber see COPYRIGHT
   for the full copyright and limitations of liabilities. */
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#ifdef STDC_HEADERS
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#endif
#if defined(STDC_HEADERS) | defined(HAVE_STDLIB_H)
#include <stdlib.h>
#endif
#include <iostream>
#include <sys/param.h>
#include <set> 
#include "grap.h"
#include "grap_data.h"
#include "grap_draw.h" 
#include "y.tab.h"

// Keywords recognized in the initial GRAP state (AT, SPRINTF and all
// the string modifiers are there for implicit PLOT statements).
string gk[] = {
    "copy", "next", "draw", "new", "line", "define", "arrow", "circle",
    "plot", "at", "frame", "graph", "coord", "for", "if", "print", "sprintf",
    "ticks", "tick", "label", "grid", "pic", "sh", "bar", "ljust", "rjust",
    "above", "below", "aligned", "unaligned", "size", "undefine", "clipped",
    "unclipped"
};

// These are the keywords recognized by any keyword that takes a line
// descriptor:
string lk[] = {
    "invis", "solid", "dotted", "dashed", "fill", "fillcolor", "color"
};

// Keywords recognized for sting modifiers 
string sk[] = {
    "ljust", "rjust", "above", "below", "aligned", "unaligned", "size", 
    "clipped", "unclipped", "color"
};

// Keywords recognized by ticks and graph
string tk[] = {
    "left", "right", "up", "down", "bottom", "bot", "top", "in", "out",
    "from", "to", "by", "at", "off", "on", "auto", "sprintf", "color"
};


// Vector versions of these
vector<string> grap_keys(gk, gk+sizeof(gk)/sizeof(string));
vector<string> linedesc_keys(lk, lk+sizeof(lk)/sizeof(string));
vector<string> strmod_keys(sk, sk+sizeof(sk)/sizeof(string));
vector<string> tick_keys(tk, tk+sizeof(tk)/sizeof(string));

// The data structure encapsulating the keyword handling algorithms
keywordDictionary keywords;

// This builds a large hash table encapsulating the actions to take
// when a keyword is parsed.  This is one big static data structure,
// and should just be statically initialized, but is complex enough
// that building it is easier to maintain.  It's split into
// subfunctions primarily because the gcc optimizer has a terrible
// time with the one big function, and partially to make it easier to
// maintain.

// All these can appear multiple times in a command
void init_multiples() {
    vector<string> empty;

    keywords["above"] = keyword(empty, empty, false, ABOVE);
    keywords["top"] = keyword(empty, empty, false, TOP);
    keywords["bot"] = keywords["bottom"] =
	keyword(empty, empty, false, BOTTOM);
    keywords["left"] = keyword(empty, empty, false, LEFT);
    keywords["right"] = keyword(empty, empty, false, RIGHT);
    keywords["up"] = keyword(empty, empty, false, UP);
    keywords["down"] = keyword(empty, empty, false, DOWN);
    keywords["ljust"] = keyword(empty, empty, false, LJUST);
    keywords["rjust"] = keyword(empty, empty, false, RJUST);
    keywords["below"] = keyword(empty, empty, false, BELOW);
    keywords["aligned"] = keyword(empty, empty, false, ALIGNED);
    keywords["unaligned"] = keyword(empty, empty, false, UNALIGNED);
    keywords["clipped"] = keyword(empty, empty, false, CLIPPED);
    keywords["unclipped"] = keyword(empty, empty, false, UNCLIPPED);
    keywords["size"] = keyword(empty, empty, false, SIZE);
    keywords["in"] = keyword(empty, empty, false, IN);
    keywords["out"] = keyword(empty, empty, false, OUT);
    keywords["off"] = keyword(empty, empty, false, OFF);
    keywords["on"] = keywords["auto"] = keyword(empty, empty, false, ON);
    keywords["fill"] = keyword(empty, empty, false, FILL);
    keywords["invis"] = keyword(empty, empty, false, INVIS);
    keywords["solid"] = keyword(empty, empty, false, SOLID);
    keywords["dotted"] = keyword(empty, empty, false, DOTTED);
    keywords["dashed"] = keyword(empty, empty, false, DASHED);
    keywords["fillcolor"] = keyword(empty, empty, false, FILLCOLOR);
    keywords["color"] = keyword(empty, empty, false, COLOR);

}

// These are all one time command modifiers
void init_only_once() {
    vector<string> empty;
    vector<string> temp;

    // temp.clear();
    temp.push_back("radius");
    temp.push_back("rad");
    keywords["radius"] = keywords["rad"] = keyword(empty, temp, false, RADIUS);

    temp.clear();
    temp.push_back("from");
    keywords["from"] = keyword(empty, temp, false, FROM);

    temp.clear();
    temp.push_back("thru");
    temp.push_back("through");
    keywords["thru"] = keywords["through"] = keyword(empty, temp, false, THRU);

    temp.clear();
    temp.push_back("to");
    keywords["to"] = keyword(empty, temp, false, TO);

    temp.clear();
    temp.push_back("by");
    keywords["by"] = keyword(empty, temp, false, BY);

    temp.clear();
    temp.push_back("until");
    keywords["until"] = keyword(empty, temp, false, UNTIL);

    temp.clear();
    temp.push_back("do");
    keywords["do"] = keyword(empty, temp, false, DO);

    temp.clear();
    temp.push_back("x");
    keywords["x"] = keyword(empty, temp, false, XDIM);

    temp.clear();
    temp.push_back("y");
    keywords["y"] = keyword(empty, temp, false, YDIM);

    temp.clear();
    temp.push_back("base");
    keywords["base"] = keyword(empty, temp, false, BASE);

    temp.clear();
    temp.push_back("ht");
    keywords["ht"] = keyword(empty, temp, false, HT);

    temp.clear();
    temp.push_back("wid");
    keywords["wid"] = keyword(empty, temp, false, WID);

    temp.clear();
    temp.push_back("at");
    keywords["plot"] = keyword(temp, empty, true, PLOT);
}

// These all signal the start of a command
void init_line_starters() {
    vector<string> empty;
    vector<string> temp;

    temp.clear();
    temp.push_back("thru");
    temp.push_back("through");
    temp.push_back("until");
    keywords["copy"] = keyword(temp, empty, true, COPY);

    temp = linedesc_keys;
    temp.push_back("at");
    temp.push_back("sprintf");
    keywords["next"] = keyword(temp, empty, true, NEXT);

    temp = linedesc_keys;
    temp.insert(temp.end(), strmod_keys.begin(), strmod_keys.end());
    temp.push_back("sprintf");
    keywords["draw"] = keywords["new"] = keyword(temp, empty, true, DRAW);
    
    temp = linedesc_keys;
    temp.push_back("from");
    temp.push_back("to");
    keywords["line"] = keyword(temp, empty, true, LINE);

    temp = linedesc_keys;
    temp.push_back("from");
    temp.push_back("to");
    keywords["arrow"] = keyword(temp, empty, true, ARROW);
    
    temp = linedesc_keys;
    temp.push_back("at");
    temp.push_back("radius");
    temp.push_back("rad");
    keywords["circle"] = keyword(temp, empty, true, CIRCLE);

    temp = linedesc_keys;
    temp.push_back("top");
    temp.push_back("bottom");
    temp.push_back("bot");
    temp.push_back("left");
    temp.push_back("right");
    temp.push_back("ht");
    temp.push_back("wid");
    keywords["frame"] = keyword(temp, empty, true, FRAME);

    temp.clear();
    temp.push_back("x");
    temp.push_back("y");
    temp.push_back("log");
    keywords["coord"] = keyword(temp, empty, true, COORD);

    temp.clear();
    temp.push_back("from");
    temp.push_back("to");
    temp.push_back("by");
    temp.push_back("do");
    keywords["for"] = keyword(temp, empty, true, FOR);

    temp.clear();
    temp.push_back("then");
    keywords["if"] = keyword(temp, empty, true, IF);

    temp.clear();
    temp.push_back("else");
    keywords["then"] = keyword(temp, empty, true, THEN);

    temp = tick_keys;
    temp.insert(temp.end(), strmod_keys.begin(), strmod_keys.end());
    keywords["tick"] = keywords["ticks"] = keyword(temp, empty, true, TICKS);

    temp = strmod_keys;
    temp.push_back("left");
    temp.push_back("right");
    temp.push_back("up");
    temp.push_back("down");
    temp.push_back("bottom");
    temp.push_back("bot");
    temp.push_back("top");
    temp.push_back("sprintf");
    keywords["label"] = keyword(temp, empty, true, LABEL);

    temp = linedesc_keys;
    temp.insert(temp.end(), tick_keys.begin(), tick_keys.end());
    temp.insert(temp.end(), strmod_keys.begin(), strmod_keys.end());
    temp.push_back("ticks");
    temp.push_back("tick");
    keywords["grid"] = keyword(temp, empty, true, GRID);

    temp = linedesc_keys;
    temp.push_back("ht");
    temp.push_back("wid");
    temp.push_back("up");
    temp.push_back("right");
    temp.push_back("base");
    keywords["bar"] = keyword(temp, empty, true, BAR);

}

// These have special parsing rules.  They clear the active commands.
void init_wipers() {
    vector<string> empty;
    keywords["define"] = keyword(empty, empty, true, DEFINE);
    keywords["undefine"] = keyword(empty, empty, true, UNDEFINE);
    keywords["graph"] = keyword(empty, empty, true, GRAPH);
    keywords["else"] = keyword(empty, empty, true, ELSE);
    keywords["print"] = keyword(empty, empty, true, PRINT);
    keywords["pic"] = keyword(empty, empty, true, PIC);
    keywords["sh"] = keyword(empty, empty, true, SH);
}

// This are used in parsing multi-element matches for macros.

bool id_letter[256];

// set up the table to scan for embedded macros
void init_id() {
    int i;	// Scratch
    for (i = 0; i < 256; i++ ) id_letter[i] = false;

    // assumes letters are contiugous.  Is there still any character set
    // for this which doesn't hold?
    
    for ( i = 'a'; i <= 'z' ; i++ ) id_letter[i] = true;
    for ( i = 'A'; i <= 'Z' ; i++ ) id_letter[i] = true;
    for ( i = '0'; i <= '9' ; i++ ) id_letter[i] = true;
    id_letter['_'] = true;
}

// Initialize the table of keywords.
void init_keywords() {
    vector<string> empty;

    init_multiples();
    init_only_once();
    init_line_starters();
    init_wipers();

    // Sprintf is unusual in that it doesn't alter the parse state at
    // all.
    keywords["sprintf"] = keyword(empty, empty, false, SPRINTF);

    // init the table
    init_id();
}
