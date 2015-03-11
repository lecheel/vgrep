/* -*- mode: cr; indent-width: 4; -*-
 * GRIEF macros to support GNU grep (grp)
 *
 *
 */

#include "../grief.h"

#define MODENAME "GRP"

static int          _grp_keyboard;

void
main()
{
    create_syntax(MODENAME);

    /*
     *  operators etc
     */
    syntax_token(SYNT_COMMENT,      "File");
    syntax_token(SYNT_PREPROCESSOR, ":");
    syntax_token(SYNT_NUMERIC,      "0-9");

    /*
     *  options
     */
    set_syntax_flags(SYNF_COMMENTS_CSTYLE);

    /*
     *  keywords
     */
    define_keywords(SYNK_PRIMARY,   ".File", 5);

    keyboard_push();
    assign_to_key("<Enter>",        "_grp_line");
    _grp_keyboard = inq_keyboard();
    keyboard_pop(1);
}

int 
_grp_line(void)
{
    int curr_line, curr_col, GotName=0, RealLine;
    int i,j;
    string TmpStr,RealName,TarLine;
    if (! inq_mode()) {
        end_of_line();
    }
    beginning_of_line();
    inq_position(curr_line, curr_col);
    TmpStr = read(); 
    i = index(TmpStr,":");                  // Search First Blank Occour
    if (i!=0) {
	TarLine = substr(TmpStr,1,i-1);         // Locate the Target Name
	if (TarLine == "File") {
	    RealName=substr(TmpStr,7,strlen(TmpStr)-7);
	    GotName=1;
            message("GotName");
	} else {
	    RealLine=atoi(TarLine);
            message("GotLine");
	}
	if (!GotName) {
	    for (j=curr_line;j>0;j--) {
		TmpStr = read();
		i = index(TmpStr,"File:");
		if (i==1) {
		    GotName=1;
		    break;
		}
		up();
	    }
	    j = strlen(TmpStr)-7;
	    RealName=substr(TmpStr,7,j);
	}
    } 
    if (GotName) {
	goto_line(curr_line);
	edit_file(RealName);
	if (RealLine>0) goto_line(RealLine);
    } else {
	message("Invaild line");
    }		 

}

string
_grp_mode()
{
    return "grp";                               /* return package extension */
}


string
_grp_highlight_first()
{
    attach_syntax(MODENAME);                    /* attach colorizer */
    return "";
}

string
_grp_smart_first()
{
    use_local_keyboard( _grp_keyboard );
    return "";
}


string
_grp_template_first()
{
    return _grp_smart_first();
}


string
_grp_regular_first()
{
    return _grp_smart_first();
}


/*end*/
