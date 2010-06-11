/*
  VGREP.S     ViewGREP support to TSE
  Author      Lechee.Lai

  Date:       May 5, 2oo2     - Preliminary Version

  Overview:

     This macro allows you to use semware Grep 2.00 via ASM.

  Keys:


  Usage notes:
  requirement:

    NOTE: This macro has been tested with Semware GREP 2.0

  There is no warranty of any kind related to this file.
  If you don't like that, don't use it.

*/


// todo: memory last select item for popup window via enter is pressed
// v1.01 Add history for "files, directorys" replace orginal from env(XXX)
//       env(XXX) only as default for first times
// v1.00 Enjoy VGREP With TSE

#ifdef WIN32
    constant MAXPATH = 255
#else
    constant MAXPATH = 80
#endif


///////////////////////////////////////////////////////////////////////////

// string StVer[]    = "v1.00"          // todo v1.00

string    fte_file[] = "FTE.GRP"        // default filename
string    GoName[MAXPATH]
integer   GoLine
integer   FTEClip,FTEList               // FTEClip for Real FTE CLIP

string search [128] = ""
string files  [128] = "*.c *.h *.cpp *.s *.asm *.inc *.equ"
string options[128] = "-i -n -s"
string directorys[128] = ""
integer next_state, state
#define sSEARCH         0
#define sFILES          1
#define sOPTIONS        2
#define sDIR            3
#define nSTATES         4
#define pSET_STATE      -3
#define pPREV_FIELD     -2
#define pNEXT_FIELD     -1
#define pABORT           0
#define pACCEPT          1


keydef    ListKeys                      // FTEList for Modify List
end

helpdef PopupHelp1
    TITLE = "ViewGREP Help"

    ""
    ' VGrep Power by Lechee.Lai Copyright(R) 2oo2 v1.01'
    "컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴"
    ' Files default can override through '
    ' set bMask=*.asm *.inc'
    "컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴"
    ' Dir also get default from TAGFILE or bHOME'
    ' set TAGFILE=c:\project'
    ' set bHOME=c:\project\oemtip'
    ' env(bHOME) have the high priority instead env(Tagfile) as default Dir'
    "컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴"
    ' Options'
    ' -i ignore case'
    ' -n display line numbers'
    ' -s search subdirectories'
    ' -1 display first maching line only'
    ' -w words only'
    "컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴"
    '<Escape>  Exit'
    ' Exit the prompt box without taking any action.'
    ''
    '<Tab>/<Shift><Tab>'
    ' Switch to next/previous field'
    "컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴"
    ''
end PopupHelp1

proc mPopupHelp(integer helptype)
    integer OldMenuTextAttr = Set(MenuTextAttr, Color(BRIGHT WHITE ON BLACK))
    integer OldMenuBorderAttr = Set(MenuBorderAttr, Color(BRIGHT WHITE ON BLACK))

    case helptype
        when 1
            QuickHelp(PopUpHelp1)
    endcase
    Set(MenuTextAttr, OldMenuTextAttr)
    Set(MenuBorderAttr, OldMenuBorderAttr)
end mPopupHelp


proc ListStartup()
    Unhook(ListStartup)
    if Enable(ListKeys)
        ListFooter("{Enter}-Goto  {Escape}-Cancel  {Power by Lechee.Lai} Copyright 2oo2" )
    endif
end

proc FTESymbol(integer Item)
    string GrepFILE[MAXPATH]
    integer i
        GoName = ""
        PushPosition()
        if FTEClip                      // if FTE.GRP Clip founded
            GotoBufferId(FTEClip)
            for i = Item+1 downto 1
                GotoLine(i)
                GrepFILE = GetToken(GetText(1,10),":",1)
                if GrepFILE == "File"
                        if CurrLineLen()>256
                          GoName=GetText(7,256)
                        else
                          GoName=GetText(7,CurrLineLen())
                        endif
                        break
                endif
            endfor
        endif
        PopPosition()
end FTESymbol

proc FTEWhere(integer Item)
    integer i
        PushPosition()
        if FTEClip                      // if FTE.GRP Clip founded
            GotoBufferId(FTEClip)
            GotoLine(Item)
            i = pos (")",GetText(1,20))
            GoName = GetText(i+1,CurrLineLen())
        endif
        PopPosition()
end  FTEWhere

proc CreateFTEList()
    integer i,k,j=0,CurrId
    string  StrLine[255]
    string  StrIdx[20]
    CurrId = GetBufferId()
    if not GotoBufferId(FTEList)
        FTEList = CreateTempBuffer()
    else
        EmptyBuffer(FTEList)
    endif
    if FileExists("C:\" + FTE_file)         // Check FTE file exist
        PushPosition()
        FTEClip=EditFile("C:\"+FTE_file)
        BufferType(_HIDDEN_)

        if FTEClip                         // Add context to hidden buffer lists
            BegFile()
            for i = 1 to NumLines()
                GotoLine(i)
                j = j + 1
                AddLine(Str(j)+") "+GetText(1,CurrLineLen()),FTEList)
            endfor
        endif
        PopPosition()
        GotoBufferId(FTEList)
        Hook(_LIST_STARTUP_, ListStartup)  // Hooks the StatusLine
        GoName = ""                                // Initialize Blank Name
        if List("TSE/FTE Lists via SemWare GREP v2.0",Query(ScreenCols))
            StrLine = GetText(1,128)
            StrIdx = GetToken(StrLine,")",1)
            j = Val(StrIdx) - 1                   // Convert Correct Index
            k = pos(")",StrLine)
            StrLine = GetToken(GetText(k+1,30),":",1)
            if StrLine <> "File"
              GoLine = Val(StrLine)
            else
              GoLine = 1                          // Initialize Line number
            endif
            FTESymbol(j)                          // Return the Valid FileName
            GotoBufferId(CurrId)
        else
            Message("VGrep Canceled.")
        endif // End of List
        if Length(GoName)                          // NoZero File Name
            if EditFile(GoName)                    // Load The File
                    GotoLine(GoLine)               // And Go to the Line
                    ScrollToCenter()               // Center Screen
                    CurrId = GetBufferId()
            endif
        endif
        if FTEList <> 0
            AbandonFile(FTEList)                   // free FTEList
        endif
        if FTEClip <> 0
            AbandonFile(FTEClip)
        endif
        GotoBufferId(CurrId)
    else
        Message("Use V.bat to Create FTE.GRP First")
    endif  // End Of FTE Found
    GotoBufferId(CurrId)
end CreateFTEList

integer proc PopWin(string title, integer width, integer height)
    integer x
    integer y = WhereY()

    x = (Query(ScreenCols) - width) / 2
    // try to put on line above
    if y > height + 1
        y = y - height - 1
    else
        y = y + 1
    endif
    if y + height > Query(ScreenRows)
        y = Query(WindowRows) - height
    endif
    if PopWinOpen(x,y,x + width+1,y + height - 1,1,title,Query(MenuBorderAttr))
        return (TRUE)
    endif
    return (FALSE)
end PopWin

proc DisplayPromptInfo(integer x, integer y, string prompt, string s)
#ifndef WIN32
    integer attr
#endif

    VGotoXY(x,y)
    PutHelpLine(prompt)
#ifdef WIN32
    PutStrXY(x + 9,y,s,Query(MenuTextAttr))
#else
    VGotoXY(x + 9, y)
    attr = Set(Attr, Query(MenuTextAttr))
    PutStr(s)
    Set(Attr, attr)
#endif
end

KeyDef GrepKeys
    <Shift Tab> EndProcess(pPREV_FIELD)
    <Tab>       EndProcess(pNEXT_FIELD)
    <Enter>     EndProcess(pACCEPT)
    <Escape>    EndProcess(pABORT)
    <F1>        mPopupHelp(1)
    <Alt S>     next_state = sSEARCH     EndProcess(pSET_STATE)
    <Alt F>     next_state = sFILES      EndProcess(pSET_STATE)
    <Alt O>     next_state = sOPTIONS    EndProcess(pSET_STATE)
    <Alt D>     next_state = sDIR        EndProcess(pSET_STATE)
end

proc EnableTheseKeys()
    if not Enable(GrepKeys)
        EndProcess(pABORT)
    endif
    BreakHookChain()
end

string proc CutLastSlash(string opts)
	integer i
        string opts2[127]

        i = NumTokens(opts,"\")
        if i > 0
          opts2=GetToken(opts,"\",i)
          i = pos(opts2,opts) - 2
          return(SubStr(opts,1,i))
        endif
        return (opts)
end

proc VGREP()
   integer n, exec
   string bMask[127]
   string workDIR[127]
    exec = FALSE
    search = GetWord(TRUE)              // get current word Token


    files = GetHistoryStr(98,1)         // Get files history
    directorys = GetHistoryStr(99,1)    // Get Directorys history
    if (files == "")                    // default Setting for first times
        directorys = GetEnvStr("bhome")
        if (directorys == "")
          directorys = GetEnvStr("TagFile")
          if (directorys=="")
            directorys=CurrDir()
          endif
        else
          directorys = CutLastSlash(directorys)
        endif
        bMask = GetEnvStr("BMASK")          // BiosMASK
        if (bMask <> "")
            files = bMask
        endif
    endif

    Set(Attr, Query(MenuTextAttr))
    if PopWin("VGrep ["+CurrDir()+"]", 78, 6)
        ClrScr()
        WindowFooter("{Enter}-Execute  {Escape}-Abort  {Tab}-Next field   {Power by Lechee.Lai} 2oo2")
        DisplayPromptInfo(1,1,"{S}earch:" ,search)
        DisplayPromptInfo(1,2,"{F}iles:"  ,files)
        DisplayPromptInfo(1,3,"{O}ptions:",options)
        DisplayPromptInfo(1,4,"{D}ir:",directorys)
        state = sSEARCH
        if Hook(_PROMPT_STARTUP_, EnableTheseKeys)
            loop
                VGotoXY(10,1 + state)
                case state
                    when sSEARCH
                        n = Read(search,_FIND_HISTORY_)
                    when sFILES
                        n = Read(files,98)
                    when sOPTIONS
                        n = Read(options)
                    when sDIR
                        n = Read(directorys,99)
                endcase
                VGotoXY(8,1 + state)
                PutAttr(Query(MenuTextAttr),Query(PopWinCols) - 7)
                case n
                    when pPREV_FIELD
                        state = ((state - 1) + nSTATES) mod nSTATES
                    when pNEXT_FIELD
                        state = (state + 1) mod nSTATES
                    when pABORT
                        break
                    when pACCEPT
                        Exec = TRUE
                        break
                    when pSET_STATE
                        state = next_state
                endcase
            endloop
            UnHook(EnableTheseKeys)
        endif
        PopWinClose()
        if (exec)
                workDIR=currDir()
                if (chDir(directorys))
                        Dos("grep "+options+" "+search+" "+files+">c:\fte.grp",_DONT_PROMPT_)
                        Message("VGrep Completed Active in <Alt-F8>")
                else
                        Message("Invalid Directory")
                endif

                chDir(workDIR)
        endif
    endif
end

proc WhereIS()
    integer i,j=0,CurrId
    string  StrLine[255]
    string  StrIdx[20]
    CurrId = GetBufferId()
    if not GotoBufferId(FTEList)
        FTEList = CreateTempBuffer()
    else
        EmptyBuffer(FTEList)
    endif
    if FileExists("C:\FTE.DIR")         // Check FTE file exist
        PushPosition()
        FTEClip=EditFile("C:\FTE.DIR")
        BufferType(_HIDDEN_)

        if FTEClip                         // Add context to hidden buffer lists
            BegFile()
            for i = 1 to NumLines()
                GotoLine(i)
                j = j + 1
                AddLine(Str(j)+") "+GetText(1,CurrLineLen()),FTEList)
            endfor
        endif
        PopPosition()
        GotoBufferId(FTEList)
        Hook(_LIST_STARTUP_, ListStartup)  // Hooks the StatusLine
        GoName = ""                                // Initialize Blank Name
        if List("Go WhereIS v1.00",Query(ScreenCols))
            StrLine = GetText(1,128)
            StrIdx = GetToken(StrLine,")",1)
            j = Val(StrIdx) - 1                   // Convert Correct Index
            FTEWhere(j)                           // Return the Valid FileName
            GotoBufferId(CurrId)
        else
            Message("WhereIS Canceled.")
        endif // End of List
        if Length(GoName)                          // NoZero File Name
            if EditFile(GoName)                    // Load The File
                    ScrollToCenter()               // Center Screen
                    CurrId = GetBufferId()
            endif
        endif
        if FTEList <> 0
            AbandonFile(FTEList)                   // free FTEList
        endif
        if FTEClip <> 0
            AbandonFile(FTEClip)
        endif
        GotoBufferId(CurrId)
    else
        Message("Use W.bat to Create FTE.DiR First")
    endif  // End Of FTE Found
    GotoBufferId(CurrId)
end WhereIS

proc vAtags()
    search = GetWord(TRUE)              // get current word Token
    Dos("vgrep --atags "+search,_DONT_PROMPT_)
    Dos("vgrep --sidx "+CurrFilename()+" "+Str(CurrLine()),_DONT_PROMPT_)
end vAtags

<F11>        vAtags()
<Ctrl F8>    VGREP()
<Alt  F8>    CreateFTEList()
<Alt  F7>    WhereIS()
