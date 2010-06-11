/*
  VGREP.C - VISUAL SELECTOR FOR Generic GREP.

  Jason Hood, 27 JULY, 2002.
  Lechee.Lai, 22, AUG, 2002.

  Uses Lcc-Win32 & tcconio.h I believe tcconio is availabe for MinGW32, but
  it's not in my distribution. No idea what VC++ has.

  Assumes the -nc- options of SemWare grep have been used and the output
  has been redirected to c:\fte.grp.
  grep -i -n -s "pattern" *.c *.cpp ... >c:\fte.grp

  --history--
  1.00 primary release many thanks Jason hood found the great compiler and
       make visual display in console mode

  1.01 support parameter --grep --whereis --oemtree
       vgrep better set env(bhome) env(bmask) are recommend
       --------------------------------------------------------
       set bhome=xxxxx
       set bmask=*.c *.cc *.cpp
       --------------------------------------------------------
       three batch script h.bat v.bat w.bat are available

  1.02 support three popular console editor tde,fte and tse for visual selector
       all information from vgrep.ini
       --------------------------------------------------------
       editor=
       loadstyle=1     # 1=fte 2=tse 3=tde 4=qe 5=fed 6=brief

       EndOfConfig
       --------------------------------------------------------
   1.03 support --grep [pattern] [dir] [mask]
   1.04 support --mru  for tde dir ring list
   1.05 support --atags [pattern]      Phoenix atags pattern via tagv2.dat
                --ctags [pattern]      Exuberant ctags via tags
   1.06         --btags                back atags/ctags
   1.07 some bugfix
	grep_style=1           # 1=semware  2=oakGrep   3=gnuGrep   4=TurboGrep
        grepcmd=grep -i -n -s
   1.08 minor bugfix for atagsWrite
        remove tab2space when push_list
        add "fed/qe" loadstyle
        add --sgrep force semware grep
   1.09 add brief 3.1
        simply syntax for file separate via ini synFile/synLine/synNorm/synAColor/synBColor

*/

#include <string.h>
#include <stdio.h>
#if defined (_BCC32_) || defined (_BC31_)
  #include <conio.h>
#else
  #include <tcconio.h>
#endif
#include <malloc.h>
#include <stdlib.h>
#include <io.h>
#include <fcntl.h>
#include <direct.h>
#include <errno.h>
#define MAXSTR    	512
#define TRUE       	1
#define FALSE      	0
#define FMODE_READ      1
#define FMODE_WRITE     2
#define VERSION 	"1.09"

#if defined (_BC31_)
 #define BYTE unsigned char
 #define WORD unsigned int
#endif

#define DIRS 5000                           /* Depth of directory stacking */
#define DEPTH 50                            /* Depth of scanner recursion  */

unsigned
      dirptr = 0,                           /* Directory stacking level    */
      level = 0;                            /* Function recursion level    */

char
      *parg = 0,                            /* Path argument               */
      path[MAX_PATH],                       /* Final path specification    */
      full = 0,                             /* Full listing specified      */
      dirstack[DIRS][MAXSTR],               /* Stack of directory names    */
      *actstack[DEPTH];                     /* Stack of active levels      */

char
      *Vline = "\xB3\x20\x20",              /* Vertical line               */
      *Vtee  = "\xC3\xC4\xC4",              /* Vertical/Horizonal tee      */
      *Corn  = "\xC0\xC4\xC4",              /* Vertical/Horizontal corner  */
      *Hline = "\xC4\xC4\xC4";              /* Horizontal line             */


typedef struct FFDATA
{
  long hFile;
  struct _finddata_t ffd;
} FFDATA;



#define findFirst(filespec, ffdata) ((((ffdata)->hFile = _findfirst(filespec, &((ffdata)->ffd))) == -1L) ? -1 : 0)
#define findNext(ffdata)  ((_findnext((ffdata)->hFile, &((ffdata)->ffd)) != 0) ? -1 : 0)
#define findClose(ffdata) _findclose((ffdata)->hFile)

#define FF_GetFileName(ffdata) (ffdata)->ffd.name
#define FF_GetAttributes(ffdata) (ffdata)->ffd.attrib

typedef unsigned long FSIZE_T;
#define FF_GetFileSize(ffdata) (FSIZE_T)((ffdata)->ffd.size)

#define FF_GETVOLLBL_WITH_W32GETVOLINFO
#define FF_GETSERIAL_WIN32


#define FF_A_LABEL     0x08  /* NOTE: Win32 API should ignore LABEL flag for findfile*/
#define FF_A_DIRECTORY FILE_ATTRIBUTE_DIRECTORY /* 0x10 */
#define FF_A_ARCHIVE   FILE_ATTRIBUTE_ARCHIVE   /* 0x20 */
#define FF_A_READONLY  FILE_ATTRIBUTE_READONLY  /* 0x01 */
#define FF_A_HIDDEN    FILE_ATTRIBUTE_HIDDEN    /* 0x02 */
#define FF_A_SYSTEM    FILE_ATTRIBUTE_SYSTEM    /* 0x04 */
#define FF_A_NORMAL    0x00 /* FILE_ATTRIBUTE_NORMAL 0x80 */

#define FF_FINDFILE_ATTR (FF_A_DIRECTORY | FF_A_ARCHIVE | FF_A_READONLY | FF_A_HIDDEN | FF_A_SYSTEM | FF_A_NORMAL)


int errno;
int HaveTAB=0;

char *GetTmpDir(void);



#ifndef _BC31_
typedef struct CONFIG
{
    char editor[80];       // editor
    int  edt_type;         // editor open style
    int  grep_style;       // grep support semware/oak/gnu/turbo
    char grepcmd[80];      // Grep cmd argument
    int  synFile;          // File Syntax Color
    int  synLine;
    int  synNorm;
    int  synBColor;        // BackGround Color
    int  synAColor;        // Active Item Color
} CONFIG;
CONFIG config;
#endif

typedef struct filespec_list *PLIST;

typedef struct filespec_list
{
  char ldata[MAXSTR];
  PLIST next_ptr;
  PLIST prev_ptr;
}
FL;

typedef struct list_ctrl
{
  PLIST head_ptr;
  PLIST tail_ptr;
  int	longest;
  int	count;
}
LIST_CTRL;

typedef LIST_CTRL *PLIST_CTRL;

LIST_CTRL fl;

typedef struct file_line
{
  char *file;
  long	line;
}
FILE_LINE;

typedef FILE_LINE *PFILE_LINE;

/* ------------------------------------------ */
int init_list(PLIST_CTRL lc)
{
  /* initialize linked list with a dummy header node */
  int lOk = FALSE;
  PLIST new_ptr;

  lc->head_ptr = lc->tail_ptr = NULL;

  new_ptr = (PLIST) malloc(sizeof(FL));
  if (new_ptr != NULL)
  {
    lOk = TRUE;
    new_ptr->ldata[0] = '\0';
    new_ptr->next_ptr = new_ptr->prev_ptr = NULL;
    lc->head_ptr = lc->tail_ptr = new_ptr;
    lc->count = 0;
    lc->longest = 0;
  }

  return (lOk);
}

/* ------------------------------------------ */
int push_list(PLIST_CTRL lc, char *data)
{
  /* add new item to the end of the list */
  int lOk = FALSE;
  PLIST new_ptr;
  char *s;

  new_ptr = (PLIST) malloc(sizeof(FL));
  if (new_ptr != NULL)
  {
    lOk = TRUE;
    strcpy(new_ptr->ldata, data);
    /* translate tabs to spaces */
    if (!HaveTAB) {
     for (s = new_ptr->ldata; *s; ++s)
      if (*s == '\t')
	*s = ' ';
    }
    new_ptr->next_ptr = NULL;
    new_ptr->prev_ptr = lc->tail_ptr;
    lc->tail_ptr->next_ptr = new_ptr;
    lc->tail_ptr = new_ptr;
    ++lc->count;
    if (strlen(data) > lc->longest)
      lc->longest = strlen(data);
  }

  return (lOk);
}

/* --for Semware Grep------------------------ */
PLIST find_File(PLIST pl)
{
  /* search backwards from pl to find the corresponding "File:" item */
  /* assumes it can be found */

  while (strncmp(pl->ldata, "File: ", 6) != 0)
    pl = pl->prev_ptr;

  return (pl);
}


/* --for TurboGrep-------------------------- */
PLIST find_FileT(PLIST pl)
{
  /* search backwards from pl to find the corresponding "File " item */
  /* assumes it can be found */

  while (strncmp(pl->ldata, "File ", 5) != 0)
    pl = pl->prev_ptr;

  return (pl);
}

/* --for OakGrep-------------------------- */
PLIST find_FileO(PLIST pl)
{
  /* search backwards from pl to find the corresponding "File " item */
  /* assumes it can be found */

  while (strncmp(pl->ldata, "--------- ", 10) != 0)
    pl = pl->prev_ptr;

  return (pl);
}


char *get_line(FILE * pfile, int continue_ch)
{
  char *str;			/* string that we will return   */
  char *tmp_str;
  int str_len;			/* current length of the string */
  int str_size;			/* malloc size of the string */
  int ch;
  int last_ch;

  /* this function will malloc memory for the string.  the calling
     function must free() the string. */

  str_len = 0;
  str_size = 10;
  str = malloc(sizeof(char) * str_size);

  if (!str)
  {
    /* failed! */
    return (str);
  }

  /* now, read the string */

  last_ch = '\0';
  while ((ch = fgetc(pfile)) != EOF)
  {
    /* do we have enough room in the str for this ch? */

    if (str_len >= str_size)
    {
      /* reallocate memory */

      str_size *= 2;
      tmp_str = realloc(str, sizeof(char) * str_size);

      if (tmp_str)
      {
	/* move the pointer */
	str = tmp_str;
      }

      else
      {
	/* failure!  return what we have */
	str[str_len] = '\0';
	return (str);
      }
    }

    /* add the ch to the str */

    if (ch == '\n')
    {
      /* is the string terminated? */

      if (last_ch == continue_ch)
      {
	/* string is continued on next line ... ignore this ch
	   and erase last_ch in the string */
	str_len--;
      }

      else
      {
	/* string is terminated.  return it. */
	str[str_len++] = '\0';
	return (str);
      }
    }

    else
    {
      str[str_len++] = ch;
      last_ch = ch;
    }

  }				/* while */

  /* we hit eof without eol.  return what we have. */

  return (NULL);
}

int Tab2Spc(char *tmp)
{
    char *s;
    /* translate tabs to spaces */
    for (s = tmp; *s; ++s)
      if (*s == '\t')
	*s = ' ';
    tmp = s;
    return 0;
}

void ltrim(char *str)
{
    BYTE c=0,i;
    BYTE len=strlen(str);
    if (!str[0]==0)
    {
      while ((c < len) && ((str[c] == ' ') || (str[c] == '\t')))
        c++;
    }
    for (i=0;i<len-c;i++)
      str[i]=str[c+i];
    str[i] = 0;
}

void ltrims(char *str,char spc)
{
    BYTE c=0,i;
    BYTE len=strlen(str);
    if (!str[0]==0)
    {
      while ((c < len) && ((str[c] != spc) ))
        c++;
    }
    for (i=0;i<len-c;i++)
      str[i]=str[c+i];
    str[i] = 0;
}

char *rtrims( char *str, char spc)
{
    int len=strlen(str);
    if (!str[0]==0)
    {
      while ((len>0)&&((str[len]!=spc)))
        len--;
    }
    str[len]=0;
    return str;
}

int Get_Token(char *Tmp, char *Out, int Idx)
{
    WORD i=0;
    char *pp=NULL;
    char *Chk;
    char inStr[256];
    strcpy(inStr,Tmp);
    Chk = strtok(inStr," ");
    while (Chk != NULL)
    {
      if (Idx==i)
        pp = strdup(Chk);
      Chk = strtok(NULL, " ");
      i++;
    }
    if (pp!=NULL)
      strcpy(Out,pp);
    return 0;
}

void instead_slash(char *tmp)
{
    int i;
     for (i=0;i<strlen(tmp);i++)
        if (tmp[i]=='\\') tmp[i]='/';
}

void instead_bslash(char *tmp)
{
    int i;
     for (i=0;i<strlen(tmp);i++)
        if (tmp[i]=='/') tmp[i]='\\';
}


/*
 * Name:    get_full_path
 * Purpose: retrieve the fully-qualified path name for a file
 * Date:    August 10, 2002
 * Passed:  in_path:  path to be canonicalized
 *          out_path: canonicalized path
 * Notes:   out_path is assumed to be PATH_MAX characters.
 *          leave UNC paths alone.
 *          I'm sure I'm doing this wrong, but I was unable to find an
 *           API function that guaranteed a long name.
 */
void get_full_path( char *in_path, char *out_path )
{
char fullpath[MAX_PATH];
char *name, *part;
WIN32_FIND_DATA wfd;
HANDLE h;

   if ((in_path[0] == '/' || in_path[0] == '\\')  &&
       (in_path[1] == '/' || in_path[1] == '\\')) {
      do
         *out_path++ = (*in_path == '/') ? '\\' : *in_path;
      while (*in_path++);

   } else if (GetFullPathName(in_path, sizeof(fullpath), fullpath, &name) == 0)
      strcpy( out_path, in_path );

   else {
      out_path[0] = (*fullpath < 'a') ? *fullpath + 32 : *fullpath;
      out_path[1] = ':';
      out_path[2] = '\0';
      part = fullpath + 2;
      for (;;) {
         strcat( out_path, "/" );
         part = strchr( part+1, '\\' );
         if (part != NULL)
            *part = '\0';
         h = FindFirstFile( fullpath, &wfd );
         if (h == INVALID_HANDLE_VALUE) {
            if (name != NULL)
               strcat( out_path, name );
            break;
         } else
            FindClose( h );
         strcat( out_path, wfd.cFileName );
         if (part == NULL)
            break;
         *part = '\\';
      }
   }
}


/*
 * Name:    get_current_directory
 * Purpose: get current directory
 * Date:    August 6, 2002
 * Passed:  path:  pointer to buffer to store path
 *          drive: drive to get current directory (unused)
 * Notes:   append a trailing slash ('/') if it's not root
 *          path is expected to be at least PATH_MAX long
 */
int  get_current_directory( char FAR *path, int drive )
{
int  len;

   if (GetCurrentDirectory( MAX_PATH, path ) == 0)
      return( -1 );
   get_full_path( path, path );

   len = strlen( path );
   if (path[len-1] != '/') {
      path[len++] = '/';
      path[len] = '\0';
   }

   return( 0 );
}

//
//
// Write vGrep sytle output which support lunach and switch directory via ve.bat
//
//
int vgrepWrite(char *fname, int fline,int func)
{
    char *D;
    char BatScript[MAXSTR];
    FILE *cBAT;
    sprintf(BatScript,"%s\\ve.bat",GetTmpDir());
    cBAT = fopen(BatScript,"wt");
    D = getenv("KCEDIT");
    if (!D) D=strdup("f");
    if (!func) {
      if (fline)
        fprintf(cBAT,"%s -l%ld %s\n",D,fline,fname);
      else
        fprintf(cBAT,"%s %s\n",D,fname);
    } else {
      fprintf(cBAT,"%c:\n",fname[0]);
      fprintf(cBAT,"cd \"%s\"",fname);
    }
    fclose(cBAT);
    return 1;
}

//
//
// Write WhereIS style output
//
//
int whereWrite(char *fname,int func)
{
    char *D;
    char BatScript[MAXSTR];
    FILE *cBAT;
    sprintf(BatScript,"%s\\ve.bat",GetTmpDir());
    cBAT = fopen(BatScript,"wt");
    D = getenv("KCEDIT");
    if (!D) D=strdup("f");
    if (!func)
      fprintf(cBAT,"%s %s\n",D,fname);
    else {
      fprintf(cBAT,"%c:\n",fname[0]);
      rtrims(fname,'\\');
      fprintf(cBAT,"cd \"%s\"",fname);
    }
    fclose(cBAT);
    return 1;
}

//
//
// Write ATags style output
//
int atagsWrite(char *fname,int func, char *bufstr)
{
    char *D;
    char *p;
    char BatScript[MAXSTR];
    char bakstr[MAXSTR];
    char sym1[MAXSTR],sym2[MAXSTR],sym3[MAXSTR];
    FILE *cBAT;
    sym1[0]=0;
    sym2[0]=0;
    sym3[0]=0;
    sprintf(BatScript,"%s\\ve.dat",GetTmpDir());
    cBAT = fopen(BatScript,"wt");
    D = getenv("KCEDIT");
    if (!D) D=strdup("f");
//    Tab2Spc(fname);
    Get_Token(fname,sym1,0);

    p = strstr(fname," ");
    if (p!=NULL) {
      strcpy(bakstr,p+1);
      p = strstr(fname," ");

      Get_Token(fname,sym2,1);
      if (!strlen(sym2))  sprintf(sym2,"%s:",bufstr);
      Get_Token(fname,sym3,2);

      if (!func) {
          fprintf(cBAT,"%s %s --%s\0",D,sym1,p+1);
        }
      else {
        fprintf(cBAT,"%c:\n",sym1[0]);
        rtrims(sym1,'\\');
        fprintf(cBAT,"cd \"%s\"",sym1);
      }
    } else {   // seems label founded.
           fprintf(cBAT,"%s %s --%s:\0",D,sym1,bufstr);
        }
    fclose(cBAT);
    return 1;
}

//
//
// Write CTags style output
//
int ctagsWrite(char *fname,int func, char *bufstr)
{
    char *D;
    char *p;
    char BatScript[MAXSTR];
    char loadname[MAXSTR];
    char sym1[MAXSTR];
    int i=0;
    FILE *cBAT;
    sym1[0]=0;
    sprintf(BatScript,"%s\\ve.dat",GetTmpDir());
    cBAT = fopen(BatScript,"wt");
    D = getenv("KCEDIT");      // for batch script use
    if (!D) D=strdup("f");

    strcpy(loadname,fname);
    for (i=0;i<strlen(fname);i++)
        if ((loadname[i]==0x09)||(loadname[i]==0x20)) {
           loadname[i]=0;
           break;
        }
    p = strstr(fname,"/^");
    if (p != NULL) {   // function founded.
      strcpy(sym1,p+2);
      p = strtok(sym1,"$/");
    } else {           // equation founded.
      p = strstr(fname,";\"");
      if (p!=NULL) {
         *p=0;
          while (((*p)!=' ')&&((*p)!='\t')) p--;
      }
    }

    if (!func) {
        fprintf(cBAT,"%s --%s",loadname,p);
      }
    else {
      fprintf(cBAT,"%c:\n",sym1[0]);
      rtrims(sym1,'\\');
      fprintf(cBAT,"cd \"%s\"",sym1);
    }
    fclose(cBAT);
    return 1;
}


/* ------------------------------------------ */
int catread(char *catfile)
{
  FILE *pfile;			/* pointer to the catfile */
  char *str;			/* the string read from the file */

  /* Open the catfile for reading */

  pfile = fopen(catfile, "r");
  if (!pfile)
  {
    /* Cannot open the file.  Return failure */
    return (0);
  }

  /* Read the file into memory */

  while ((str = get_line(pfile, 0)) != NULL)
  {
    push_list(&fl, str);
    free(str);
  }				/* while */

  fclose(pfile);

  /* Return success */

  return (1);
}

int catread_1(char *catfile)
{
  FILE *pfile;			/* pointer to the catfile */
  char *str;			/* the string read from the file */
  char *p;

  /* Open the catfile for reading */

  pfile = fopen(catfile, "r");
  if (!pfile)
  {
    /* Cannot open the file.  Return failure */
    return (0);
  }

  /* Read the file into memory */

  while ((str = get_line(pfile, 0)) != NULL)
  {
    ltrim(str);
    p=strstr(str," ");
    if (p==NULL) p=strstr(str,"\t");
    strcpy(str,p+1);
    push_list(&fl, str);
    free(str);
  }				/* while */

  fclose(pfile);

  /* Return success */

  return (1);
}

int catread_2(char *catfile)
{
  FILE *pfile;			/* pointer to the catfile */
  char *str;			/* the string read from the file */

  /* Open the catfile for reading */

  pfile = fopen(catfile, "r");
  if (!pfile)
  {
    /* Cannot open the file.  Return failure */
    return (0);
  }

  /* Read the file into memory */

  while ((str = get_line(pfile, 0)) != NULL)
  {
    ltrims(str,0x09);
    push_list(&fl, str+1);
    free(str);
  }				/* while */

  fclose(pfile);

  /* Return success */

  return (1);
}


/* ------------------------------------------ */
void display(PLIST pl, int x, int y, int cnt, int wid)
{
  /* display cnt items, starting at (x,y), using wid characters */
  while (cnt-- > 0)
  {
  gotoxy(x, y++);
  if (HaveTAB)
    cprintf("%s", pl->ldata);
  else {
      if (pl->ldata[0] == 'F') {
          textcolor(config.synFile);
          cprintf("%-*.*s", wid, wid, pl->ldata);
          textcolor(config.synNorm);
      } else
          cprintf("%-*.*s", wid, wid, pl->ldata);

    }
    pl = pl->next_ptr;
  }
}

/* ------------------------------------------ */
int select(PLIST_CTRL lc, PFILE_LINE sel, int TYP)
{
  /* select an item, placing it in sel and returning TRUE; */
  /* returns FALSE if ESC was pressed.			   */
  int x, y, row, oldrow;
  int wid, hyt;
  PLIST cur, oldcur, beg, end;
  struct text_info ti;
  int key;
  char line[MAXSTR];
  char fname[MAXSTR];
  void *buffer;
  int refresh;
  int j,subFunc=0;
  char *p;
  char editor[6][10]={"fte","tse","tde","qe","fed","brf"};
  char *grep[4]={"SemwareGrep","OakGrep","GnuGrep","TurboGrep"};


  gettextinfo(&ti);
  textbackground(config.synBColor);
//  wid = ti.screenwidth * 3 / 4;
  wid = ti.screenwidth -6;

//  if (wid > lc->longest)
//    wid = lc->longest;
  wid += 4;
  hyt = ti.screenheight * 2 / 3;
  if (hyt > lc->count)
    hyt = lc->count;
  hyt += 2;
  x = (ti.screenwidth - wid) / 2 + 1;
  y = (ti.screenheight - hyt) / 2 + 1;
  buffer = malloc(wid * hyt * sizeof(char) * 2);
  if (!buffer)
    return (FALSE);
  gettext(x, y, x+wid-1, y+hyt-1, buffer);
  _setcursortype(_NOCURSOR);

  textcolor(config.synNorm);
  line[wid] = 0;
#ifdef _BCC32_
  line[0] = '*'; line[wid-1] = '*';
  memset(line+1, '-', wid-2);
#else
  line[0] = 'Ú'; line[wid-1] = '¿';
  memset(line+1, 'Ä', wid-2);
#endif
  gotoxy(x, y); cputs(line);
  textcolor(YELLOW);
  gotoxy(x+3,y); cputs("VGREP(   )");
  textcolor(0x0D);
  if ((config.edt_type>0)&&(config.edt_type<7)) {
    gotoxy(x+9,y); cputs(editor[config.edt_type-1]);
  }
  gotoxy(x+14,y);
  textcolor(config.synNorm);
  cputs(grep[config.grep_style-1]);
#ifdef _BCC32_
  line[0] = '*'; line[wid-1] = '*';
#else
  line[0] = 'À'; line[wid-1] = 'Ù';
#endif
  gotoxy(x, y+hyt-1); cputs(line);
  textcolor(LIGHTCYAN);
  gotoxy(x+3, y+hyt-1); cputs("Power by Jason Hood & Lechee.Lai v"VERSION);
  textcolor(config.synNorm);
#ifdef _BCC32_
  line[0] = line[wid-1] = '|';
#else
  line[0] = line[wid-1] = '³';
#endif
  memset(line+1, ' ', wid-2);
  for (j = y+1; j < y+hyt-1; ++j)
  {
    gotoxy(x, j); cputs(line);
  }

  oldcur = cur = beg = lc->head_ptr->next_ptr;

  /* determine the start of the last page */
  end = lc->tail_ptr;
  for (j = hyt-2; j > 1; --j)
    end = end->prev_ptr;

  oldrow = row = y+1;
  refresh = 1;
  for (;;)
  {
    if (refresh)
    {
      display(beg, x+2, y+1, hyt-2, wid-4);
      refresh = 0;
    }
    else if (row != oldrow)
    {
      gotoxy(x+2, oldrow);
      textcolor(config.synNorm);
      if (oldcur->ldata[0] == 'F') {
          textcolor(config.synFile);
      	  cprintf("%-.*s", wid-4, oldcur->ldata);
          textcolor(config.synNorm);
      } else
      	cprintf("%-.*s", wid-4, oldcur->ldata);
    }
    gotoxy(x+2, row);
    textbackground(config.synAColor);
    textcolor(config.synLine);
    cprintf("%-.*s", wid-4, cur->ldata);
    textbackground(config.synBColor);
    textcolor(config.synNorm);
    oldrow = row;
    oldcur = cur;

    key = getch(); if (key==0) key=getch();
    if (kbhit())
      {  key = getch(); if (key==0) key=getch(); }


    if (key == 27) /* Esc */
      break;

    if ((key == 13)||(key==0x0a)) /* Enter / Ctrl-Enter */
    {
      if (key==13) subFunc = 0;
      else subFunc = 1;

      if (TYP==0) {
          switch (config.grep_style) {
              case 1:  // SemwareGrep
                     beg = find_File(cur);
        	     sel->file = beg->ldata + 6;
                     break;
              case 2:  // OakGrep
                     beg = find_FileO(cur);
                     get_current_directory(fname,0);
                     strcpy(line,beg->ldata+10);
                     sprintf(beg->ldata,"%s%s",fname,line);
                     sel->file = beg->ldata;
                     break;
              case 3:  // GnuGrep
                     beg = find_File(cur);
        	     sel->file = beg->ldata + 6;
                     break;
              case 4:  // TurboGrep
                     beg = find_FileT(cur);
                     get_current_directory(fname,0);
                     strcpy(line,beg->ldata+5);
                     p = strstr(line,":");
                     *p=0;
                     sprintf(beg->ldata,"%s%s",fname,line);
                     sel->file = beg->ldata;
                    break;
              default:
                     beg = find_File(cur);
        	     sel->file = beg->ldata + 6;
                     break;
          }
        instead_bslash(sel->file);
        if (beg == cur)
          sel->line = 0;
        else {
          switch (config.grep_style) {
              case 2:
                 sscanf(cur->ldata+1,"%ld", &sel->line);
                 break;
              default:
                 sscanf(cur->ldata, "%ld", &sel->line);
                 break;
             }
          }
      } else if ((TYP==1)||(TYP==2)) {
          sel->file = cur->ldata;
          sel->line = 0;
      } else if (TYP==3) {
          sel->file=cur->ldata;
          p = strtok(sel->file,":");
          sel->file=0;
          sel->line = atoi(p);
      }
      break;
    }

    switch (key)
    {
      case 72: /* Up */
	if (cur->prev_ptr != lc->head_ptr)
	{
	  cur = cur->prev_ptr;
	  if (row == y+1)
	    beg = cur, refresh = 1;
	  else
	    --row;
	}
	break;

      case 80: /* Down */
	if (cur != lc->tail_ptr)
	{
	  cur = cur->next_ptr;
	  if (row == y+hyt-2)
	    beg = beg->next_ptr, refresh = 1;
	  else
	    ++row;
	}
	break;

      case 73: /* PageUp */
	if (beg != lc->head_ptr->next_ptr)
	{
	  for (j = hyt-1; j > 1; --j)
	  {
	    cur = cur->prev_ptr;
	    beg = beg->prev_ptr;
	    if (beg == lc->head_ptr->next_ptr)
	      break;
	  }
	  refresh = 1;
	}
	break;

      case 81: /* PageDown */
	if (beg != end)
	{
	  for (j = hyt-1; j > 1; --j)
	  {
	    cur = cur->next_ptr;
	    beg = beg->next_ptr;
	    if (beg == end)
	      break;
	  }
	  refresh = 1;
	}
	break;

      case 71: /* Home */
	if (cur != beg)
	{
	  cur = beg;
	  row = y+1;
	}
	break;

      case 79: /* End */
      {
	PLIST pl = beg;
	for (j = hyt-2; j > 1; --j)
	  pl = pl->next_ptr;
	if (cur != pl)
	{
	  cur = pl;
	  row = y+hyt-2;
	}
	break;
      }

      case 134: /* LeftCtrl+PageUp */
      case 119: /* LeftCtrl+Home */
	if (cur != lc->head_ptr->next_ptr)
	{
	  cur = lc->head_ptr->next_ptr;
	  row = y+1;
	  if (beg != cur)
	    beg = cur, refresh = 1;
	}
	break;

      case 118: /* LeftCtrl+PageDown */
      case 117: /* LeftCtrl+End */
	if (cur != lc->tail_ptr)
	{
	  cur = lc->tail_ptr;
	  row = y+hyt-2;
	  if (beg != end)
	    beg = end, refresh = 1;
	}
	break;
    }
  }

  puttext(x, y, x+wid-1, y+hyt-1, buffer);
  gotoxy(ti.curx, ti.cury);
  textattr(ti.normattr);
  _setcursortype(_NORMALCURSOR);
  if (key == 0x0D) return (1); /* Enter      */
  if (key == 0x0A) return (2); /* Ctrl-Enter */
  return (0);
}

/* ------------------------------------------ */
int selects(PLIST_CTRL lc, PFILE_LINE sel, int TYP, char *buf)
{
  /* select an item, placing it in sel and returning TRUE; */
  /* returns FALSE if ESC was pressed.			   */
  int x, y, row, oldrow;
  int wid, hyt;
  PLIST cur, oldcur, beg, end;
  struct text_info ti;
  int key;
  char line[MAXSTR];
  void *buffer;
  int refresh;
  int j,subFunc=0;
  char editor[6][10]={"fte","tse","tde","qe","fed","brf"};
  char *grep[4]={"SemwareGrep","OakGrep","GnuGrep","TurboGrep"};


  gettextinfo(&ti);
  textbackground(config.synBColor);
//  wid = ti.screenwidth * 3 / 4;
  wid = ti.screenwidth -6;

//  if (wid > lc->longest)
//    wid = lc->longest;
  wid += 4;
  hyt = ti.screenheight * 2 / 3;
  if (hyt > lc->count)
    hyt = lc->count;
  hyt += 2;
  x = (ti.screenwidth - wid) / 2 + 1;
  y = (ti.screenheight - hyt) / 2 + 1;
  buffer = malloc(wid * hyt * sizeof(char) * 2);
  if (!buffer)
    return (FALSE);
  gettext(x, y, x+wid-1, y+hyt-1, buffer);
  _setcursortype(_NOCURSOR);

  textcolor(config.synNorm);
  line[wid] = 0;
#ifdef _BCC32_
  line[0] = '*'; line[wid-1] = '*';
  memset(line+1, '-', wid-2);
#else
  line[0] = 'Ú'; line[wid-1] = '¿';
  memset(line+1, 'Ä', wid-2);
#endif
  gotoxy(x, y); cputs(line);
  textcolor(YELLOW);
  gotoxy(x+3,y); cputs("VGREP(   )");
  textcolor(0x0D);
  if ((config.edt_type>0)&&(config.edt_type<7)) {
    gotoxy(x+9,y); cputs(editor[config.edt_type-1]);
  }
  gotoxy(x+14,y);
  textcolor(config.synNorm);
  cputs(grep[config.grep_style-1]);
#ifdef _BCC32_
  line[0] = '*'; line[wid-1] = '*';
#else
  line[0] = 'À'; line[wid-1] = 'Ù';
#endif
  gotoxy(x, y+hyt-1); cputs(line);
  textcolor(LIGHTCYAN);
  gotoxy(x+3, y+hyt-1); cputs("Power by Jason Hood & Lechee.Lai v"VERSION);
  textcolor(config.synNorm);
#ifdef _BCC32_
  line[0] = line[wid-1] = '|';
#else
  line[0] = line[wid-1] = '³';
#endif
  memset(line+1, ' ', wid-2);
  for (j = y+1; j < y+hyt-1; ++j)
  {
    gotoxy(x, j); cputs(line);
  }

  oldcur = cur = beg = lc->head_ptr->next_ptr;

  /* determine the start of the last page */
  end = lc->tail_ptr;
  for (j = hyt-2; j > 1; --j)
    end = end->prev_ptr;

  oldrow = row = y+1;
  refresh = 1;

  for (;;)
  {
    if (refresh)
    {
      display(beg, x+2, y+1, hyt-2, wid-4);
      refresh = 0;
    }
    else if (row != oldrow)
    {
      gotoxy(x+2, oldrow);
      textcolor(config.synNorm);
      if (oldcur->ldata[0] == 'F') {
          textcolor(config.synFile);
      	  cprintf("%-.*s", wid-4, oldcur->ldata);
          textcolor(config.synNorm);
      } else
      	cprintf("%-.*s", wid-4, oldcur->ldata);
    }
    gotoxy(x+2, row);
    textbackground(config.synAColor);
    textcolor(config.synLine);
    cprintf("%-.*s", wid-4, cur->ldata);
    textbackground(config.synBColor);
    textcolor(config.synNorm);
    oldrow = row;
    oldcur = cur;

    key = getch(); if (key==0) key=getch();
    if (kbhit())
      {  key = getch(); if (key==0) key=getch(); }

    if (key == 27) /* Esc */
      {
         if (TYP == 02) {
    		sprintf(line,"%s\\ve.bat",GetTmpDir());
              unlink(line);
                }
      		break;
      }

    if ((key == 13)||(key==0x0a)) /* Enter / Ctrl-Enter */
    {
      if (key==13) subFunc = 0;
      else subFunc = 1;
      switch (TYP)
          {
             case 0x0:   // vGrep
        		beg = find_File(cur);
        		sel->file = beg->ldata + 6;
        		if (beg == cur)
          		   sel->line = 0;
        		else
          		   sscanf(cur->ldata, "%ld", &sel->line);
//        		instead_bslash(sel->file);
                        vgrepWrite(sel->file,sel->line,subFunc);
                        break;
             case 0x01:  // where
          		sel->file = cur->ldata;
          		sel->line = 0;
//        		instead_bslash(sel->file);
                        whereWrite(sel->file,subFunc);
                        break;
             case 0x02:  // Atags
                        sel->file = cur->ldata;
                        sel->line = 0;
//        		instead_bslash(sel->file);
                        atagsWrite(sel->file,subFunc,buf);
                        break;
             case 0x03:  // Ctags
                        sel->file = cur->ldata;
                        sel->line = 0;
//        		instead_bslash(sel->file);
                        ctagsWrite(sel->file,subFunc,buf);
                        break;
          }
      break;
    }

    switch (key)
    {
      case 72: /* Up */
	if (cur->prev_ptr != lc->head_ptr)
	{
	  cur = cur->prev_ptr;
	  if (row == y+1)
	    beg = cur, refresh = 1;
	  else
	    --row;
	}
	break;

      case 80: /* Down */
	if (cur != lc->tail_ptr)
	{
	  cur = cur->next_ptr;
	  if (row == y+hyt-2)
	    beg = beg->next_ptr, refresh = 1;
	  else
	    ++row;
	}
	break;

      case 73: /* PageUp */
	if (beg != lc->head_ptr->next_ptr)
	{
	  for (j = hyt-1; j > 1; --j)
	  {
	    cur = cur->prev_ptr;
	    beg = beg->prev_ptr;
	    if (beg == lc->head_ptr->next_ptr)
	      break;
	  }
	  refresh = 1;
	}
	break;

      case 81: /* PageDown */
	if (beg != end)
	{
	  for (j = hyt-1; j > 1; --j)
	  {
	    cur = cur->next_ptr;
	    beg = beg->next_ptr;
	    if (beg == end)
	      break;
	  }
	  refresh = 1;
	}
	break;

      case 71: /* Home */
	if (cur != beg)
	{
	  cur = beg;
	  row = y+1;
	}
	break;

      case 79: /* End */
      {
	PLIST pl = beg;
	for (j = hyt-2; j > 1; --j)
	  pl = pl->next_ptr;
	if (cur != pl)
	{
	  cur = pl;
	  row = y+hyt-2;
	}
	break;
      }

      case 134: /* LeftCtrl+PageUp */
      case 119: /* LeftCtrl+Home */
	if (cur != lc->head_ptr->next_ptr)
	{
	  cur = lc->head_ptr->next_ptr;
	  row = y+1;
	  if (beg != cur)
	    beg = cur, refresh = 1;
	}
	break;

      case 118: /* LeftCtrl+PageDown */
      case 117: /* LeftCtrl+End */
	if (cur != lc->tail_ptr)
	{
	  cur = lc->tail_ptr;
	  row = y+hyt-2;
	  if (beg != end)
	    beg = end, refresh = 1;
	}
	break;
    }
  }
  puttext(x, y, x+wid-1, y+hyt-1, buffer);
  gotoxy(ti.curx, ti.cury);
  textattr(ti.normattr);
  _setcursortype(_NORMALCURSOR);
  if (key == 0x0D) return (1); /* Enter      */
  if (key == 0x0A) return (2); /* Ctrl-Enter */
  return (0);
}



char *GetTmpDir(void)
{
	static char *p;

	p = getenv("TMP");
	if( !p ) p = getenv("TEMP");
	return p;
}

//
// Check Null file or Size less than ??
//
//
int ChkNul_INF(char *chk, long LSize)
{

        int handle;
        if (!access(chk,0))
                {
                        handle = open(chk, O_RDONLY);
                        if (handle != -1) {
                        if (filelength(handle)>LSize) {
                                close(handle);
                                return 2;
                                }
                        else
                                                                {
                                        close(handle);
                                        unlink(chk);
                                        return 1;
                                }
                        } // End of correct file
                } // End of File Found
        return 0;
}


int get_char(FILE *f)
{
   int c = fgetc(f);

   if (c == EOF)
      errno = EOF;

   return c;
}



int peek_char(FILE *f)
{
   int c;

   c = fgetc(f);
   ungetc(c, f);

   if (c == EOF)
      errno = EOF;

   return c;
}

int check_int(char *buf, char *prompt, int *ret, int min, int max)
{
   char b[40];
   int len = 0;
   int v;

   if (strstr(buf, prompt) != buf)
      return TRUE;

   b[0] = 0;
   buf += strlen(prompt);

   while ((*buf == '-') || ((*buf >= '0') && (*buf <= '9'))) {
      b[len++] = *(buf++);
      b[len] = 0;
   }

   v = atoi(b);
   if (( v >= min) && (v <= max)) {
      *ret = v;
      return TRUE;
   }

   printf("\nError in config file:\nValue of %s must be between %d and %d\n", prompt, min, max);
   return FALSE;
}



void check_string(char *buf, char *prompt, char *ret, int max)
{
   if (strstr(buf, prompt) == buf) {
      strncpy(ret, buf+strlen(prompt), max-1);
      ret[max-1] = 0;
   }
}

FILE *open_file(char *name, int mode)
{
   FILE *f;

   if (mode == FMODE_READ)
      f = fopen(name, "rb");
   else if (mode == FMODE_WRITE)
      f = fopen(name, "wb");
   else
      f = NULL;

   if (!f) {
      if (!errno)
	 errno = 1;
   }
   else
      errno = 0;

   return f;
}

int close_file(FILE *f)
{
   if (f) {
      fclose(f);
      return errno;
   }

   return 0;
}

void read_string(FILE *f, char *buf)
{
   int c = 0;
   int ch = get_char(f);

   buf[0] = 0;

   while ((errno == 0) && (ch != '\r') && (ch != '\n') && (c < 80)) {
      buf[c++] = ch;
      buf[c] = 0;
      ch = get_char(f);
   }

   ch = peek_char(f);
   if (ch == '\r') {
      get_char(f);
      ch = peek_char(f);
   }
   if (ch == '\n') {
      get_char(f);
      ch = peek_char(f);
   }
}

int read_config(char *filename)
{
    FILE *f;
    char buf[256];
    char buf2[256];
    f = open_file(filename, FMODE_READ);
    // default Color
        config.synFile=10;
        config.synLine=14;
        config.synNorm=7;
        config.synBColor=1;
        config.synAColor=2;
    // <--------- end of default color
    if (errno==1) {
        errno=0;
        return 0;
        }
    while (errno==0) {
        read_string(f, buf);
        strcpy(buf2,buf);
//      strlwr(buf);
        check_string(buf, "editor=", config.editor, 80);
	if (!check_int(buf, "loadstyle=", &config.edt_type, 0, 6))
            goto get_out;
	if (!check_int(buf, "synFile=", &config.synFile, 0, 15))
            goto get_out;
	if (!check_int(buf, "synLine=", &config.synLine, 0, 15))
            goto get_out;
	if (!check_int(buf, "synNorm=", &config.synNorm, 0, 15))
            goto get_out;
	if (!check_int(buf, "synBColor=", &config.synBColor, 0, 15))
            goto get_out;
	if (!check_int(buf, "synAColor=", &config.synAColor, 0, 15))
            goto get_out;
        if (!check_int(buf, "grep_style=", &config.grep_style, 0, 5))
            goto get_out;
        check_string(buf, "grepcmd=", config.grepcmd, 80);
//	if (!check_int(buf, "bioshome=", &config.edt_home, 0, 5))
//            goto get_out;
	if (strstr(buf, "EndOfConfig") == buf)
	    break;
      }
    close_file(f);
    return 1;
    get_out:
    close_file(f);
    return 0;
}

int changeDisk(char *drive)
{
      int destDisk = islower(*drive) ? *drive-'a' : *drive-'A';

      if (destDisk >= 0)
      {
        _chdrive(destDisk+1);
      }
      return(0);
}

//
// Change Current directory (path with driver letter)
//
int cdd(char *path)
{
        int rc=0;
		changeDisk(path);
        rc=chdir(path);
        return rc;
}

int Whereis(char *pat, char *dir)
{
    char CMD[MAXSTR];
    if (*dir != 0) cdd(dir);
    sprintf(CMD,"dir /B /S %s >c:\\fte.dir",pat);
    system(CMD);
    return 0;
}

int vGrep(char *pat, char *sdir, char *mask)
{
    char CMD[MAXSTR];
    char MSK[MAXSTR];
    char *D;
    if (*mask == 0) {
      D = getenv("bmask");
      if (D == NULL) strcpy(MSK,"*.c *.cpp *.cc");
      else strcpy(MSK,D);
    }
    else {
          strcpy(MSK,mask);
        }

    if (*sdir !=0 ) cdd(sdir);
    sprintf(CMD,"%s %s %s>c:\\fte.grp",config.grepcmd,pat,MSK);
    system(CMD);
    ChkNul_INF("c:\\fte.grp",5);
    return 0;
}

int aTags(char *pat)
{
    FILE_LINE sels;
    char cmd[MAXSTR];
    char *gcmd;
    char tmp_tagf[MAXSTR];
    char tagf[MAXSTR];
    char *d;
    int rcode=0;


    HaveTAB = 1;
    d = getenv("tagfile");
    sprintf(tmp_tagf,"%s\\edit.tag",GetTmpDir());
    if (d != NULL) {
        sprintf(tagf,"%s\\tagv2.dat",d);
        if (access(tagf,0)) return 0;
    } else {
       unlink(tmp_tagf);
       return 0;
    }

    gcmd=strstr(config.grepcmd," ");
    if (gcmd != NULL) *gcmd=0;
    switch (config.grep_style) {
        case 1: // semware grep
            sprintf(cmd,"%s -f- -i \"|%s|\" %s>%s",config.grepcmd,pat,tagf,tmp_tagf);
            break;
        case 2: // OakGrep
            sprintf(cmd,"%s -i \"|%s|\" %s>%s",config.grepcmd,pat,tagf,tmp_tagf);
            break;
        case 3: // GnuGrep
            sprintf(cmd,"%s -i \"|%s|\" %s>%s",config.grepcmd,pat,tagf,tmp_tagf);
            break;
        case 4: // TurboGrep
            sprintf(cmd,"%s -i \"|%s|\" %s>%s",config.grepcmd,pat,tagf,tmp_tagf);
            break;
        default: //
            sprintf(cmd,"grep -f- -i \"|%s|\" %s>%s",pat,tagf,tmp_tagf);
            break;
    }

    system(cmd);
    ChkNul_INF(tmp_tagf,5);
    if (!access(tmp_tagf,0)) {
        init_list(&fl);
        if (catread_1(tmp_tagf)) {
          rcode=selects(&fl, &sels,2,pat);
          if (!rcode) {
              sprintf(cmd,"%s\\ve.dat",GetTmpDir());
              unlink(cmd);
              }
        }
    }
    return rcode;
}

int cTags(char *pat)
{
    FILE_LINE sels;
    char cmd[MAXSTR];
    char *gcmd,*D;
    char tmp_tagf[MAXSTR];
    char tagf[MAXSTR]="tags";
    int rcode=0;

    if (access(tagf,0))  {
        D = getenv("tagfile");
        if (D != NULL)
          sprintf(tagf,"%s\\tags",D);
    }

    sprintf(tmp_tagf,"%s\\edit.tag",GetTmpDir());
    if (access(tagf,0)) return 0;

    gcmd=strstr(config.grepcmd," ");
    if (gcmd != NULL) *gcmd=0;

    switch (config.grep_style) {
        case 1: // semware grep
            sprintf(cmd,"%s -f- -w -x \"^%s\" %s>%s",config.grepcmd,pat,tagf,tmp_tagf);
            break;
        case 2: // OakGrep
            sprintf(cmd,"%s -Q -U \"^%s\" %s>%s",config.grepcmd,pat,tagf,tmp_tagf);
            break;
        case 3: // GnuGrep
            sprintf(cmd,"%s -w -e \"^%s\" %s>%s",config.grepcmd,pat,tagf,tmp_tagf);
            break;
        case 4: // TurboGrep
            sprintf(cmd,"%s -o+ -r+ \"^%s\" %s>%s",config.grepcmd,pat,tagf,tmp_tagf);
            break;
        default: //
            sprintf(cmd,"grep -f- -w -x \"%s\" %s>%s",pat,tagf,tmp_tagf);
            break;
    }

// Semware grep
//   sprintf(cmd,"grep -f- -w -x \"^%s\" %s>%s",pat,tagf,tmp_tagf);
// GNU grep
//  sprintf(cmd,"ggrep -w -e \"^%s\" %s>%s",pat,tagf,tmp_tagf);
    system(cmd);
    ChkNul_INF(tmp_tagf,5);
    if (!access(tmp_tagf,0)) {
        init_list(&fl);
        if (catread_2(tmp_tagf)) {
          rcode=selects(&fl, &sels,3,pat);
          if (!rcode) {
              sprintf(cmd,"%s\\ve.dat",GetTmpDir());
              unlink(cmd);
              }
        }
    }
    return rcode;
}

int BackTags(PLIST_CTRL lc)
{
    char FName[MAXSTR],TMP[MAXSTR];
    PLIST cur,scan;
    FILE *out;

    strcpy(TMP,GetTmpDir());
    sprintf(FName,"%s\\ve.dat",TMP);
    unlink(FName);
    sprintf(FName,"%s\\ve.idx",TMP);
    if (ChkNul_INF(FName,5)==2) {
      if (catread(FName)) {
        cur = lc->head_ptr->next_ptr;
        cur = lc->tail_ptr;    // point to end of item
      }

    sprintf(FName,"%s\\ve.dat",TMP);
    out = fopen(FName,"wt");
    fprintf(out,"%s\n",cur->ldata);
    fclose(out);

    sprintf(FName,"%s\\ve.idx",TMP);
    scan = lc->head_ptr->next_ptr;
    out = fopen(FName,"wt");
    for (;;)
        {
           if (scan==cur) break;
           fprintf(out,"%s\n",scan->ldata);
           scan = scan->next_ptr;
        }
    fclose(out);
    ChkNul_INF(FName,0);
    }
    return 1;
}

int SaveBacktag(char *name, char *line)
{
    char cmd[256];
    FILE *out;
    sprintf(cmd,"%s\\ve.dat",GetTmpDir());
    if (!access(cmd,0)) {
      sprintf(cmd,"%s\\ve.idx",GetTmpDir());
      out=fopen(cmd,"at");
      fprintf(out,"tde %s --%d\n",name, atoi(line));
      fclose(out);
    }
    return 0;
}

int cshow(char *symbol)
{
    char cmd[256];
    char cFile[256];
    FILE_LINE sels;
    sprintf(cFile,"%s\\ve.txt",GetTmpDir());
    sprintf(cmd,"cshow %s >%s",symbol,cFile);
    system(cmd);
    if (ChkNul_INF(cFile,0)>1) {
        init_list(&fl);
        if (catread(cFile)) {
          selects(&fl, &sels,2,"cshow");
        }
    }
    return 0;
}
 /**
 * Handle a single directory, recurse to do others
 */
void tree_path(FILE *fp)
{
      FFDATA ffdata;
      unsigned plen, dirbase, i, j;
      char *ptr;


      /* Get all subdirectory names in this dir */
      dirbase = dirptr;
      plen = strlen(path);
      strcpy(path+plen, "*.*");
      if (!findFirst(path, &ffdata))
      {
        do 
        {
          if (FF_GetAttributes(&ffdata) & FF_A_DIRECTORY)
          {
            if ( (strcmp(FF_GetFileName(&ffdata), ".") != 0) &&
                 (strcmp(FF_GetFileName(&ffdata), "..") != 0) )
            {
                  strcpy(dirstack[dirptr++], FF_GetFileName(&ffdata));
            }
          }
        } while(!findNext(&ffdata));
        findClose(&ffdata);
      }

      /* Display files in this dir if required */
      actstack[level++] = (dirbase == dirptr) ? "   " : Vline;
      if(full) 
      {
            i = 0;
		if(!findFirst(path, &ffdata))
            {
              do 
              {
                  if(FF_GetAttributes(&ffdata) & (FF_A_DIRECTORY|FF_A_LABEL))
                        continue;
                  for(j=0; j < level; ++j)
                        fputs(actstack[j], stdout);
                  i = -1;
                  printf("%s\n", FF_GetFileName(&ffdata));
              } while(!findNext(&ffdata));
              findClose(&ffdata);
            }

            if(i)
            {
                  for(j=0; j < level; ++j)
                        fputs(actstack[j], stdout);
                  putc('\n', stdout); 
            }
      }

      /* Recurse into subdirectories */
      for(i=dirbase; i < dirptr; ++i) 
      {
            actstack[level-1] = ((i+1) != dirptr) ? Vtee : Corn;
            for(j=0; j < level; ++j)
                  fputs(actstack[j], fp);
            actstack[level-1] = ((i+1) != dirptr) ? Vline : "   ";
            fprintf(fp,"%s\n", ptr = dirstack[i]);
            strcpy(path+plen, ptr);
            strcat(path, "\\");
            tree_path(fp);
      }

      /* Restore entry conditions and exit */
      path[plen] = 0;
      dirptr = dirbase;
      --level;
}

int main(int argc, char *argv[])
{
  FILE_LINE sel;
  FILE *pBAT;
  FILE *fp;
  int checkAction=0;
  int i,k=0;
  int more=0;
  int ChkItem=0;
  char BatScript[MAXSTR];
  char cFile[MAXSTR];
  char start_path[MAXSTR];
  char *p;
  int model=0;
  char *SpecItem[]={"--vgrep","--where","--oemtree","--grep",
                    "--mru","--atags","--btags","--fun",
                    "--ctags","--sgrep","--sidx","--cshow","--help",NULL};

  do {

  }
  while (SpecItem[k++]!=NULL);

  ChkItem=k-1;
  if (argc>=2) {
      strcpy(cFile,argv[1]);
      for (i=0;i<ChkItem;i++)
          if (!strcmpi(cFile,SpecItem[i])) {
              ChkItem=i;
              break;
          }
  GetModuleFileName(NULL,start_path,MAXSTR);
  p = strrchr(start_path,'\\');
  *(p+1)=0;

  strcpy(config.grepcmd,"grep -i -n -s ");
  config.grep_style=1;
  config.edt_type=1;
  sprintf(cFile,"%svgrep.ini",start_path);
  if(!read_config(cFile)) {
      printf("vgrep ini not founded\n");
      return 1;
  }

      switch (ChkItem) {
          case 0:  // --vgrep
              strcpy(cFile,"c:\\fte.grp");
              model=0;
              more=1;
              break;
          case 1:  // --where
              strcpy(cFile,"c:\\fte.dir");
              if (argc>2) {
                if (argc==3) {
                    Whereis(argv[2],"");
    	            ChkNul_INF(cFile,0);
                    more=0;
                    break;
                }
                if (argc==4) {
                    Whereis(argv[2],argv[3]);
    	            ChkNul_INF(cFile,0);
                    more=0;
                    break;
                }
              }
    	      ChkNul_INF(cFile,0);
              model=1;
              more=1;
              break;
          case 2:  // --oemtree

              if (argc==3) {
                if (!stricmp(argv[2],"scan")) {
                  fp=fopen("c:\\fte.dir","wt");
                  tree_path(fp);
                  ChkNul_INF("c:\\fte.dir",0);
                  fclose(fp);
              	  strcpy(cFile,"c:\\fte.dir");
                  model=2;
                  more=1;
                  }
              } else {
              strcpy(cFile,"c:\\fte.dir");
              model=2;   // whereis style
              more=1;
              }
              break;
          case 3:  // --grep
              if (argc>2) {
                if (argc==3) {
                     vGrep(argv[2],".","");
                     more=0;
                     break;
                     }
                if (argc==4) vGrep(argv[2],argv[3],"");
                else vGrep(argv[2],argv[3],argv[4]);
                }
              else  {
                puts("more parameter is need for search pattern");
                puts("vgrep --grep pattern");
                }
              more=0;
              break;
          case 4: // --mru
              sprintf(cFile,"%s\\edit.mru",GetTmpDir());
              model=1;
              more=1;
              break;
          case 5: // --atags
              if (argc>2) {
                  aTags(argv[2]);
              } else {
                puts("more parameter is need for atags search pattern");
                puts("vgrep --atags pattern");
              }
              more=0;
              break;
          case 6: // --btags
              init_list(&fl);
              BackTags(&fl);
              break;
          case 7: // --fun
              sprintf(cFile,"%s\\edit.fun",GetTmpDir());
              model=3;  // function routine style
              more=1;
              break;
          case 8: // --ctags
              if (argc>2) {
                  cTags(argv[2]);
              } else {
                puts("more parameter is need for ctags search pattern");
                puts("vgrep --ctags pattern");
              }
              more=0;
              break;
          case 9: // --sgrep
              if (argc>2) {
                config.grep_style=1;         // force assume in semware grep
  		strcpy(config.grepcmd,"grep -i -n -s ");
                if (argc==3) {
                     vGrep(argv[2],".","");
                     more=0;
                     break;
                     }
                if (argc==4) vGrep(argv[2],argv[3],"");
                else vGrep(argv[2],argv[3],argv[4]);
                }
              else  {
                puts("more parameter is need for search pattern");
                puts("vgrep --grep pattern");
                }
              more=0;
              break;
          case 10: // --sidx
              if (argc==4) {
                SaveBacktag(argv[2],argv[3]);
              }
              more=0;
              break;
          case 11: // --cshow
              if (argc==3) cshow(argv[2]);
              more=0;
              break;
          default: // --help
              textcolor(0x0a);
              puts("      .,                           vGrep v"VERSION" Power by Jason Hood & Lechee.Lai");  textcolor(0x07);
              puts("---(omOOmo)-------------------Any suggest is welcome mailto://lecheel@yahoo.com");  textcolor(0x0e);
              textcolor(0x07);
              puts("--help                          this help");
              puts("--grep     [pattern][dir][mask] do generic grep via .ini");
              puts("--sgrep    [pattern][dir][mask] do semware grep");
              puts("--vgrep                         show vgrep fte.grp");
              puts("--where    [file.*][dir]        show mini Whereis fte.dir");
              puts("--oemtree                       show oemtip Tree in fte.dir");
              puts("--mru                           show Most Recent Use in tmpDir");
              puts("--atags    [pattern]            go phoenix atags under cursor");
              puts("--btags                         go back atags/ctags");
              puts("--ctags    [pattern]            go Exuberant ctags under cursor");
              puts("--sidx     [filename][line]     Save backtag position");
              puts("--fun                           show function routine");
              puts("--cshow    [pattern]            cshow for routine");
              more=0;
              break;
      }



  if (more) {
  init_list(&fl);
  if (catread(cFile))
  {

    checkAction= select(&fl, &sel,model);
    sprintf(BatScript,"%s\\ve.bat",GetTmpDir());
    if (checkAction)
    {
      pBAT = fopen(BatScript, "wt");
      if (checkAction==1) {
        if ((model==0)|(model==1)) {
        if (sel.line)   {

            switch (config.edt_type) {
                case 1: // fte editor
                       fprintf(pBAT,"%s -l%ld %s \n",config.editor,sel.line,sel.file);
                       break;
                case 2: // tse editor
                       fprintf(pBAT,"%s -n%ld %s \n",config.editor,sel.line,sel.file);
                       break;
                case 3: // tde editor
                       fprintf(pBAT,"%s +%ld %s \n",config.editor,sel.line,sel.file);
                       break;
                case 4: // qe editor
                       fprintf(pBAT,"%s -n%ld %s \n",config.editor,sel.line-1,sel.file);
                       break;
                case 5: // fed editor
                       fprintf(pBAT,"%s -g%ld %s \n",config.editor,sel.line,sel.file);
                       break;
                case 6: // breif editor 3.1
                       fprintf(pBAT,"%s %s -m\"goto_line %ld\" \n",config.editor,sel.file,sel.line);
             }
          }
        else
          fprintf(pBAT,"%s %s \n",config.editor, sel.file);
        } else if (model==2) {
          fprintf(pBAT,"%c:\n",sel.file[0]);
          if (model==1) rtrims(sel.file,'\\');
          fprintf(pBAT,"cd \"%s\" ",sel.file);
        } else if (model==3) {
          fprintf(pBAT,"%d",sel.line);
        }
      } else if (checkAction==2) {
          fprintf(pBAT,"%c:\n",sel.file[0]);
          if ((model==1)||(model==0)) rtrims(sel.file,'\\');
          fprintf(pBAT,"cd \"%s\" ",sel.file);
        }
      fclose(pBAT);
    }
    else {
        unlink(BatScript);
        return (1);
      }
  }
  else {
    puts("VGREP information not founded.");
    return (1);
    }
  }
  } else {
     textcolor(0x0a);
     puts("      .,                           vGrep v"VERSION" Power by Jason Hood & Lechee.Lai");  textcolor(0x07);
     puts("---(omOOmo)-------------------Any suggest is welcome mailto://lecheel@yahoo.com");  textcolor(0x0e);
     puts("                                               http://www.geocities.com/lecheel");
     textcolor(0x07);
  }
  return (0);
}
