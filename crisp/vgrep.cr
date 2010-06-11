/******************************************************************/
/*                                                                */
/* vGrep for CRiSP  (visual grep)                                 */
/* Author:  Lechee.Lai                                            */
/* Created: 23-Apr-2oo3                                           */
/*                                                                */
/* use extern vgrep.exe for generic grep support                  */
/* since most of grep have different output format                */
/*                                                                */
/******************************************************************/

# include	<crisp.h>
# include	<proto.h>

static string	get_word(string re, string& class_name);
static string	get_word_chars(int buf_id);
extern int      oemtip;
extern int      envBios;
extern int      envVgrep;
extern string   vgrep_dirs;
extern string   vgrep_mask;

void vlist()
{
    string vlistfile = "";
    string Home;
    if (CRISP_OPSYS != "UNIX") {
        vlistfile = "c:\\fte.grp";
    } else {
        Home = inq_environment("HOME");
        vlistfile = Home + "/fte.grp";
	}
    	
	if (exist(vlistfile)) {
          edit_file(vlistfile);                                  // Load founded Context
	  set_buffer_flags(NULL, inq_buffer_flags() | BF_READONLY);  // Set Read-only
	} else {
	  message("Empty Context.");
	}
}

void vwhere()
{
	if (exist("c:\\fte.dir")) {
          edit_file("c:\\fte.dir");                                  // Load founded Context
	  set_buffer_flags(NULL, inq_buffer_flags() | BF_READONLY);  // Set Read-only
	} else {
	  message("Empty Context.");
	}

}

void whereis()
{
	int ret_code,i;
	string prompt;
	string s;
        string bHome;
	sprintf(prompt,"whereis: ",s);
	ret_code=get_parm(0,s,prompt,NULL,s);
	if (ret_code&&strlen(s)) {
           	bHome = inq_environment("BHOME");
           	if (bHome == "")
             		getwd(NULL, bHome);
        	else {
                 if (oemtip) {
        	   i=rindex(bHome,"\\");
                   bHome = substr(bHome,1,i);
                 }
        	}
	   if (bHome==".") getwd(NULL, bHome);
	   sprintf(prompt, "DiRs:",bHome);
           ret_code=get_parm (0, bHome, prompt, NULL, bHome);	// accessing parameters passed to macro
	   if (ret_code) {
           	sprintf (prompt, "vgrep --where %s %s ",s,bHome);
              	shell (prompt,NULL,NULL,0);   
	   }
	} else {
	  message("Cancelled.");
	}
}

void vgrep()
{
	string s;
	string	class_name;
        string MaskFile;
	string bHome,prompt;
        int ret_code;
	int i;

	s = get_word_chars(inq_buffer());
	s = get_word("^|\\([^" + s + "]\\c\\)", class_name);
	if (envBios) {
   	MaskFile = inq_environment("BMASK");
   	if (MaskFile == "")
     		MaskFile = "*.ASM *.INC *.EQU *.CPP *.C *.CC";
	} else if (envVgrep) {
	    MaskFile = vgrep_mask;
	}
        if (envBios) {
   	bHome = inq_environment("BHOME");
   	if (bHome == "")
     		getwd(NULL, bHome);
	else {
         if (oemtip) {
	   i=rindex(bHome,"\\");
           bHome = substr(bHome,1,i);
         }
	}
        } else {

		if (envVgrep) {
		   bHome=vgrep_dirs;
	           if (bHome==".") getwd(NULL, bHome);
		} else getwd(NULL, bHome);
	}
        sprintf (prompt, "vGrep Word: ", s);      // Make Prompt
        ret_code=get_parm (0, s, prompt, NULL, s);	// accessing parameters passed to macro
	if (ret_code&&strlen(s)) {
	   sprintf(prompt, "DiRs:",bHome);
           ret_code=get_parm (0, bHome, prompt, NULL, bHome);	// accessing parameters passed to macro
	} else {
	   message("Cancelled.");
	   return;
	}
	if (ret_code) {
	   sprintf(prompt, "Mask:",MaskFile);
           ret_code=get_parm (0, MaskFile, prompt, NULL, MaskFile);	// accessing parameters passed to macro
	}
	if (ret_code) {
           sprintf (prompt, "vgrep --grep %s %s \"%s\"",s,bHome,MaskFile);
           shell (prompt,NULL,NULL,0);   
	   if (envVgrep&&!envBios) {
	     vgrep_dirs = bHome;
	     vgrep_mask = MaskFile;
	     write_setup_file();
           }
           if (CRISP_OPSYS != "UNIX") {
               if (exist("c:\\fte.grp",0)) {
                   message("Context founded. <F9>vlist");
               } else {
                   message("no <%s> are founded.",s);
               }
           } else {
               message("Context founded. <F9>vlist");
           }
	}


}
/**********************************************************************/
/*   Get the word under the cursor, possibly including the preceding  */
/*   class name so we can avoid too many duplicates.		      */
/**********************************************************************/
static string
get_word(string re, string& class_name)
{	string	function, s;
	int	i;

	save_position();
	re_search(SF_BACKWARDS | SF_UNIX, re);
	function = ltrim(trim(read()));
	s = get_word_chars(inq_buffer());
	i = re_search(NULL, "[^" + s + "]", function);
	if (i > 0)
		function = substr(function, 1, i - 1);
	restore_position();

	/***********************************************/
	/*   Look for a preceding CLASS:: spec.	       */
	/***********************************************/
	save_position();
	re_search(SF_BACKWARDS | SF_UNIX, re);
	if (re_search(SF_BACKWARDS | SF_UNIX, "^|::[ \t]*" + function) > 0 &&
	    read(2) == "::") {
	    	string	c;
	    	word_left();
		c = read();
		c = sub("^\\([A-Za-z_][A-Za-z_0-9]*\\).*$", "\\1", c);
		class_name = c;
	    	}
	restore_position();

	return function;
}
/**********************************************************************/
/*   Things  that  are a valid symbol depend on the language. Handle  */
/*   that here.							      */
/**********************************************************************/
static string
get_word_chars(int buf_id)
{
	switch (lower(inq_extension(buf_id))) {
	  case "el":
	  	return "-A-Za-z0-9_";
	  case "tex":
	  	return "-A-Za-z0-9_:";
	  case "asm":
	        return "A-Za-z0-9_@";
	  default:
	  	return "A-Za-z0-9_";
	  }
}


void vgrepEnter(int kind)
{
   int i,j,line;
   int RealLine;
   int GotName=0;
   string TmpStr;
   string TarLine;
   string RealName;


   if (kind==1) {
   beginning_of_line();
   inq_position (line);
   TmpStr = read();
//   TmpStr = Find_FileSymbol();
   i = index(TmpStr,":");                  // Search First Blank Occour
   if (i!=0) {
   TarLine = substr(TmpStr,1,i-1);         // Locate the Targe Name
   if (TarLine == "File") {
      RealName=substr(TmpStr,7,strlen(TmpStr)-7);
      GotName=1;
   } else {
     RealLine=atoi(TarLine);
   }

   if (!GotName) {
   for (j=line;j>0;j--) {
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
     goto_line(line);
     edit_file(RealName);
     if (RealLine>0) goto_line(RealLine);
//     message(RealName+" %d",RealLine);
   } else {
     message("Invaild line");
   }		 
   
   } else if (kind==2) {
     TmpStr = read();
     i = index(TmpStr,":");                  // Search First Blank Occour
     if (i==2) {
       RealName=substr(TmpStr,1,strlen(TmpStr)-1);
       edit_file(RealName);
     } else {
       message("Invaild filename.");
     }
   }

}

