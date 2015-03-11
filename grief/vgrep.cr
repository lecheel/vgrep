/******************************************************************/
/*                                                                */
/* vGrep for GRiEF  (visual grep)                                 */
/* Author:  Lechee.Lai                                            */
/* Created: 11-Mar-2o15                                           */
/*                                                                */
/* use extern vgrep for generic grep wrapper                      */
/* since most of grep have different output format                */
/* https://github.com/vim-scripts/vgrep                           */
/*                                                                */
/* INSTALL:                                                       */
/*   grief.cr                                                     */
/*     autoload("vgrep",                                          */
/*        "vgrep",                                                */
/*        "vlist");                                               */
/*                                                                */
/******************************************************************/
#include "grief.h"
#include "dialog.h"

#define FORWARD_SLASH       '/'
#define BACKWARD_SLASH      '\\'
#define WILD                "?*"
#define CURRENTDIR          "."

/**********************************************************************/
/*   Get the word under the cursor                                    */
/**********************************************************************/
static string get_word(string re)
{	string	function, s;
    int	i;

    save_position();
    right();
    objects("word_left");
    re_search (SF_BACKWARDS | SF_UNIX, re);
    function = ltrim(trim(read()));
    s="A-Za-z0-9_";
    i = re_search(NULL, "[^" + s + "]", function);
    if (i > 0)
	function = substr(function, 1, i - 1);
    restore_position();
    if (function) {
	message("<%s>",function);
    } else {
	message("...");
	function="";
    }

    /*
       save_position();
       re_search(SF_BACKWARDS | SF_UNIX, re);
       if (re_search(SF_BACKWARDS | SF_UNIX, "^|::[ \t]*" + function) > 0 &&
       read(2) == "::") {
       string	c;
       c = read();
       c = sub("^\\([A-Za-z_][A-Za-z_0-9]*\\).*$", "\\1", c);
       class_name = c;
       }
       restore_position();
       */
    return function;
}

void vlist()
{
    string hdir;
    string grp;
    hdir = getenv("HOME");
    sprintf(grp,"%s/fte.grp",hdir);
    //        sprintf(grp,"c:\\fte.grp");
    if (exist(grp)) {
	edit_file(grp);                                  // Load founded Context
	set_buffer_flags(NULL, inq_buffer_flags() | BF_READONLY);  // Set Read-only
    } else {
	message("Empty Context.");
    }
}

string vgrep(~string, ~string, ...)
{
    string s, opt, pattern, file, cdir, dir;
    string cmd,ext;
    int flags, param;

    param = flags = 0;

    s = get_word("^|\\([^" + s + "]\\c\\)");

    while (1) {
	if (! get_parm(param++, opt, "vgrep for Pattern: ",NULL, s)) {
	    return "";
	}
	if (opt == "--")  {
	    message("--");
	} else {
	    pattern = opt;
	    break;
	}

    }

    if (pattern == "") {
      message("Cancelled!");
      return "";
   }

    if ("" == dir) {
        getwd(NULL,cdir);
	if (! get_parm(param++, dir, "DIRs: ", NULL, cdir)) {
	    return "";
	}
    }

    if (dir == "") {
       message("Cancelled!");
       return "";
    }

    if ("" == file) {
       inq_names(file,ext);
       if (ext != "") {
	   sprintf(file,"*.%s",ext);
        } else {
           sprintf(file,"%s",WILD);
	}
	if (! get_parm(param++, file, "Filename: ", NULL, file)) {
	    return "";
	}
    }

    message("Check Result via <F10>vlist");
    sprintf(cmd,"vgrep --grep %s %s \\%s",pattern, cdir, file);
    shell(cmd,0);
}



