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
static string get_word(void)
{	
    string	function;
    int i;
    save_position();
    re_search(SF_BACKWARDS, "<|{[^_A-Za-z0-9]\\c}");
    function = trim(read());
    i = re_search(NULL, "[^_A-Za-z0-9]", function);
    if (i > 0) {
        function = trim(substr(function, 1, i - 1));
    }
    restore_position();
    if (function == "") {
    }

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
    string function, opt, pattern, file, cdir, dir;
    string cmd,ext;
    int flags, param;

    param = flags = 0;

    function = get_word();
    while (1) {
	if (! get_parm(param++, opt, "vgrep for Pattern: ",NULL, function)) {
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



