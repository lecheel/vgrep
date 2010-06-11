%
% vgrep for jed
% 
% Yet another grep mode. with visual and wide
%
% Feature:
%   - patch gnu output format in wide mode more easy for your eye
%   - grep output store in file more easy for looking
%   
% Version:
% 1.00 by Lechee Lai, lecheel@gmail.com
% 1.01 use dfa for simple syntax
% base on Milde, Günter grep.sl 
%
% ----- Autoload for functions defined in vgrep.sl -----
%
%$0 = _stkdepth ();
%_autoload(
%          	"vgrep", 			"vgrep",
%     		"vgrep_viewer", 		"vgrep",
%          (_stkdepth () - $0) / 2  %  matches start of _autoload
%	  );%
%

autoload("ll_read_mini","leutil");
autoload("ll_mini_init","leutil");
provide("vgrep");
private variable mode = "vgrep";

variable Grep_Buffer = "*vgrep*";
variable Grep_Targets = Null_String;
variable Grep_Mask = Null_String;
variable Grep_Current_Directory = Null_String;
variable Grep_Reg_Exp = Null_String;
variable LAST_VLINE=1;
custom_variable("Grep_Cache_File", "fte.grp");   %  default 'fte.grp' for compatible
custom_variable("Save_Cache_File", 1);
custom_variable("External_Vgrep",0);
custom_variable("Grep_Option","-irn");   % <-------- change here as you want to make default "n" is necessary

create_syntax_table (mode);
define_syntax('\'', '"', mode);	       % string
define_syntax ('"', '"', mode);	       % string
define_syntax("([{", ")]}", '(', mode);% matching brackets
%set_syntax_flags (mode, 1 | 2);

!if (keymap_p (mode)) make_keymap (mode);
definekey ("vgrep_open",   "\r","vgrep");
definekey ("vgrep_open",   "e", "vgrep");
definekey ("vgrep_exit",   "q", "vgrep");
definekey ("vgrep_exit",   "x", "vgrep");
definekey ("ll_mini_init", "^[\\", "Mini_Map");

#ifdef HAS_DFA_SYNTAX

static define setup_dfa_callback (name)
{
   %%% DFA_CACHE_BEGIN %%%
   dfa_enable_highlight_cache("vgrep.dfa", name);
   dfa_define_highlight_rule("^File:.*$",       "comment",  name);
   dfa_define_highlight_rule("^[0-9]+:",        "number",   name);
   %%% DFA_CACHE_END %%%
   dfa_build_highlight_table(name);
}
dfa_set_init_callback(&setup_dfa_callback, mode);
% Highlighting NEEDS dfa for this mode to work.
enable_dfa_syntax_for_mode(mode);
#endif


% expand the cache file path
#ifdef UNIX
!if (path_is_absolute(Grep_Cache_File))
  Grep_Cache_File = dircat(Jed_Home_Directory, Grep_Cache_File);
#endif
#ifdef WIN32
!if (path_is_absolute (Grep_Cache_File))
    Grep_Cache_File = dircat("c:\\", Grep_Cache_File);   %  also for compatible
#endif

define vgrep_exit()
{
   call ("delete_window");
}

define vgrep_format ()
{
   variable pat, not_found = 1;
   variable ch, len;
   variable vname,lastname="";

   bob ();
   do
     {
	bol();
#ifdef WIN32
	go_right(ffind (":"));
#endif  
	ffind (":");
	push_mark();
	bol();
	vname = bufsubstr();
	bol();
	push_mark();
#ifdef WIN32
	go_right(ffind (":"));
#endif  	

	go_right(ffind (":"));
	del_region();
	if (strlen(vname)) {
	   if (strcmp(vname,lastname)) 
	     {
		lastname = vname;
		insert ("File: ");
		insert ("%s",vname);
		newline();
	     }
	}
     }
   while (down (1));
   if (Save_Cache_File)
     {
	if (what_line()>1) 
	  {
	     write_buffer(Grep_Cache_File);
	  }
     }
}  

define vgrep ()
{
   variable prompt,prompt1, file, flags;
   variable grpHome = Null_String;
   variable sdir = getcwd();
   variable smask = Null_String;
   variable kmap=mode;
   variable vpat = "0-9A-Z_a-z", cbuf = whatbuf ();
   grpHome = Grep_Cache_File;
#ifdef VMS
   vpat = strcat (vpat, "$");
#endif
   push_spot ();
   skip_white ();
   bskip_chars (vpat);
   push_mark ();
   skip_chars (vpat);
   vpat = bufsubstr ();		% leave on the stack
   pop_spot ();

   smask = strcat("*",path_extname(whatbuf()));
   
%   Grep_Reg_Exp = read_mini("vGrep:", vpat, Null_String);
   Grep_Reg_Exp = ll_read_mini("vGrep:", vpat);
   !if (strlen (Grep_Reg_Exp)) return;

   prompt = strcat (strcat ("vGrep: '", Grep_Reg_Exp), "' ");

%   Grep_Targets = read_mini(prompt,sdir,Null_String);
   Grep_Targets = ll_read_mini(prompt,sdir);
   prompt1 = strcat(strcat (prompt, " '",Grep_Targets,"' "));
%   Grep_Mask = read_mini(prompt1,smask,Null_String);
   Grep_Mask = ll_read_mini(prompt1,smask);
   if (strlen(Grep_Mask)) {
#ifdef UNIX
       Grep_Mask=strcat("\\",Grep_Mask);
#endif
   }
   pop2buf (Grep_Buffer);
   (file,,,flags) = getbuf_info ();
   setbuf_info (file, Grep_Targets, Grep_Buffer, flags);
   set_status_line (" vGrep: %b   (%m%n)  (%p)", 0);
   set_readonly (0);
   erase_buffer ();

   use_keymap (mode);
   set_mode(mode,0);
   use_syntax_table (mode);
   run_mode_hooks("vgrep_mode_hook");
#ifdef UNIX
   if (External_Vgrep) shell_cmd (sprintf ("vgrep --grep %s %s \\%s",Grep_Reg_Exp, Grep_Targets, Grep_Mask));
   else shell_cmd (sprintf ("grep --include=\%s %s %s %s 2>%s",Grep_Mask,Grep_Option,Grep_Reg_Exp, Grep_Targets,Grep_Cache_File));
#else
   if (External_Vgrep) shell_cmd (sprintf ("vgrep --grep %s %s %s",Grep_Reg_Exp, Grep_Targets, Grep_Mask));
   else shell_cmd (sprintf ("ggrep --include=%s %s %s %s%s >%s",Grep_Mask,Grep_Option,Grep_Reg_Exp, Grep_Targets,Grep_Mask,Grep_Cache_File));
#endif
   if (insert_file (grpHome) < 0) error ("Error load fte.grp!");
   !if (External_Vgrep) vgrep_format();
   goto_line (LAST_VLINE);   
   set_buffer_modified_flag (0); set_readonly(1);
   flush (Null_String);
}

define vgrep_viewer()
{
   variable flags,file;
   variable kmap="vgrep";
   variable grpHome = Null_String;
   grpHome = Grep_Cache_File;
   pop2buf (Grep_Buffer);
   (file,,,flags) = getbuf_info ();
   setbuf_info (file, Grep_Targets, Grep_Buffer, flags);
   set_status_line (" vGrep: %b   (%m%n)  (%p)", 0);
   set_readonly (0);
   erase_buffer ();

   use_keymap (mode);
   set_mode(mode,0);
   use_syntax_table (kmap);
   run_mode_hooks("vgrep_mode_hook");
   if (insert_file (grpHome) < 0) error ("fte.grp No Context!");
   goto_line (LAST_VLINE);
   set_buffer_modified_flag (0); set_readonly(1);
   flush (Null_String);

}

define vgrep_open ()
{
   variable name, lineno="1";
   variable noFile=1;

   LAST_VLINE = what_line();
   bol();
   push_mark();
   go_right (ffind (":"));
   go_left_1();
   lineno = bufsubstr();
   !if (strcmp(lineno, "File")) {
       lineno="1";
       eol();
   }
	push_spot();

   if (bsearch("File: ")) {
      go_right (ffind (": "));
      push_mark();
      eol();
      name = bufsubstr();
   }
   pop_spot();
   !if ( read_file (name) ) error ("Unable to read file.");
   pop2buf (whatbuf ());
   goto_line (integer(lineno));
   call ("other_window");
   call ("delete_window");
} 

