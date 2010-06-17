/*
 *  vGrep support for Epsilon 8.x-13.x
 *
 *
 *  Author: Lechee.Lai 2oo2 Dec
 *
 *
 *  http://lecheel.dyndns.org
 *
 *  vGrep http://githuh.com/lecheel/vgrep
 *  Epsilon http://www.lugaru.com/
 *
 *
 *  Initial Revision
 *
 */

#define LOCAL_VGREP 1        // for single Vgrep.e Release

#include "eel.h"
#include "colcode.h"

#if LOCAL_VGREP
#else
#include "lechee.h"
#endif
keytable vgrep_tab;
#if LOCAL_VGREP
#define WORDPTRSTD "[a-zA-Z0-9_?@]+"
#endif
char _vgrep_mode_name[] = "vGrep";
color_asm_range(from, to); // recolor just this section

command mark_word()
{
	set_region_type(REGNORM);
	point--;
	re_search(1, WORDPTRSTD);
	re_search(-1, WORDPTRSTD);
	mark = matchstart;
	grab(point, mark, _default_search);
	strcpy(_default_regex_search, _default_search);
}

/*
 * vgrep support routines
 *
 *-------------------------------------------------
 */
command vgrep_prompt()
{
	char spat[FNAMELEN];
	char sfil[FNAMELEN];
	char sdir[FNAMELEN];
	char cdir[FNAMELEN];
        char cmd[FNAMELEN];
        char cext[10];
//	char prog[300];

	int old_point;
	old_point = point;
	mark_word();
	point = old_point;
	get_strdef(spat,"vGrep Find",_default_regex_search);
#if LOCAL_VGREP
//	get_strdef(sdir,"sDir",getenv("bhome"));
//	get_strdef(sfil,"Mask",getenv("bmask"));
        getcd(cdir);
        sprintf(cext,"*%s",get_extension(filename));
        get_strdef(sdir,"sDir",cdir);
        get_strdef(sfil,"Mask",cext);
#else   // restore from ini or registry
        if (is_gui || !strcmp(vgrep,"1")) {
            get_strdef(sdir,"sDir",vdirs);
	        get_strdef(sfil,"Mask",vmask);
        } else {
        if (!strcmp(benv,"1")) {  
                if (!strcmp(oemtip,"1")) {
                  if (getenv("bhome")!=NULL) {
                    sprintf(cmd,"%s",getenv("bhome"));
                    rtrims(cmd,'\\');
                  }
		  get_strdef(sdir,"sDir",cmd);
                } else
                  if (getenv("bhome")!=NULL)
                  get_strdef(sdir,"sDir",getenv("bhome"));
                if (getenv("bmask")!=NULL)
		get_strdef(sfil,"Mask",getenv("bmask"));
        }
        else {	  
            get_strdef(sdir,"sDir",bhome);
	    get_strdef(sfil,"Mask",vmask);
        }					   
		}
	strcpy(vfind,spat);
	strcpy(vdirs,sdir);
	strcpy(vmask,sfil);
#endif	   
	sprintf(cmd,"vgrep --grep \"%s\" %s \\%s",spat,sdir,sfil);
//	do_push(cmd,0,0);
	shell("",cmd,"");
	say("vgrep done!! <F11> for selection");
//		get_executable_directory(prog);
//		strcat(prog, "vgrep.exe");
//		winexec(prog, cmd, SW_SHOWMINNOACTIVE, 0);
	full_redraw = 1;
	refresh();
}
			 

command vgrep_view()
{
  struct file_info ts;
  int i;
  char cmd[FNAMELEN];
  sprintf(cmd,"%s/fte.grp",getenv("HOME"));
  if (check_file(cmd,&ts))
      {
          if (ts.fsize<5) {
              say("File Removed");
              delete_file(cmd);
          }				
	save_var bufnum = zap("-vgrep");
	i = read_file(cmd,FILETYPE_AUTO);
       if (i) {
			restore_vars();
			delete_buffer("-vgrep");
			quick_abort();
        } else {
                   vgrep_mode();
				   to_buffer("-vgrep");
		}
      }
  else						
      say("Empty History");

}

when_loading()
{
	fix_key_table(reg_tab, (short) normal_character, vgrep_tab, -1);
	set_list_keys(vgrep_tab);
	fix_key_table(dired_tab, (short) dired_examine_in_window,
		vgrep_tab, (short) dired_examine_in_window);
}
	
vgrep_mode()
{
	do_mode_default_settings(1);
	mode_keys = vgrep_tab;
	major_mode = _vgrep_mode_name;
	mouse_dbl_selects = 1;
	strcpy(comment_start, "File:[ \t]*");
	strcpy(comment_pattern, "File:.*$");
	strcpy(comment_begin, "File: ");
	strcpy(comment_end, "");
	recolor_range = color_c_range;	// set up coloring rules
	recolor_from_here = recolor_by_lines;
	if (want_code_coloring)		// maybe turn on coloring
	when_setting_want_code_coloring();
	drop_all_colored_regions();
	make_mode();
}

vgrep_examine() on vgrep_tab[' '], vgrep_tab['\n'],
		   vgrep_tab['e'], vgrep_tab['\r'], vgrep_tab[GREYENTER]
{
        char vpat[FNAMELEN];
        int gotname=0;
		int gotLine=0;
		int i;
		int startPos;
		
		startPos = point;
		for (;;) {
		if (gotname) break;
    		to_begin_line();
			while (isspace(curchar())) point++;
			mark = point;
        	if (!search(1, ":")) error("Error vGrep Format");
        	else point--;
			grab(point,mark, vpat);
            if (!strcmp(vpat,"File")) {
				gotname=1;
				mark = point+=2;
				to_end_line();
				grab(point,mark,vpat);
			}
			else {
				if (gotLine==0) gotLine=strtoi(vpat,10);
				nl_reverse();
			}
				  
		}							   
		point = startPos;
		i=find_it(vpat, ask_line_translate());
		if ((i==0)&&(gotLine!=0)) go_line(gotLine);
		
}
