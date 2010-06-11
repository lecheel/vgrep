" File: vgrep.vim
" Author: Lechee.Lai 
" Version: 1.3
" 
" Goal:
"   Easy look for complex directory search without long filename fill 
" context line
" 
" Another grep output in wide format like semware grep / oakgrep / TurboGrep
" and GNU grep 2.0d with patch http://www.interlog.com/~tcharron/grep.html
" it also ork for Win32 only I think it's easy port from current GNU grep
"
" ============ "Wide Output Format" =================
" File: C:\vim\vim62\plugin\vgrep.vim             
"     1: File: vgrep.vim                          
"    17: let loaded_vgrep = 1                     
" File: C:\vim\vim62\plugin\testtttt1\testtttt2\testtttt3\whereis.vim           
"     1: File: whereis.vim                        
" =================================================
"
" Wide vs Unix
" 
" ============ "Unix Output" ========================
" plugin\vgrep.vim:1: file...
" plugin\vgrep.vim:17: let....
" plugin\testtttt1\testtttt2\testtttt3\whereis.vim:1: file ...
" =================================================
" 
" Change Vgrep_Path locate for grep.exe
" Change Vgrep_Output locate for grep result store
" Make sure your are using semware grep or GNU grep 2.0f
" only this two grep are support now default in GNU grep 2.0f
"
"
"
" Command: :Vgrep for grep under cursor
"          :Vlist for lister and select by ENTER
"
" Operator:
"          <Enter>		EditFile
"          o	   		EditFile
"          <2LeftMouse>	EditFile
"          <Esc>		Quit/Close
" Require:
"		+viminfo feature must enable
"         
"
" History:
"    1.0 Initial Revision
"        Only GnuGrep 2.0f and semware Support
"
"    1.1 Add Start Directory for search
"        Add Turbo Grep 5.5 Support 
"        Add OakGrep 5.1+ Support
"        Add Error handle for unknow format prevent 100% CPU Usage
"        Add grp.vim for syntax color
"    1.2 
"        Add LeftMouse Double Click / o for Open
"        Add search_dirs memory last location
"        Add file_mask memory last use
"        Bugfix Error Handle
"        Default is regexp enable
"    1.3 
"	 Add unix grep support    
"        Add g2w.pl for wide convertion
"    1.4 
"	 Add native vgrep support
"        same as g2w.pl but in c code
"

if exists("loaded_vgrep") || &cp
    finish
endif
let loaded_vgrep = 1

" "=== S e l e c t   Y o u r  G r e p   F i r s t  ==="
" ======= "? Which grep you have ?" ======= 
let TurboGrep = 0
let semwareGrep = 0
let GnuGrep = 0
let OakGrep = 0
let UnixGrep = 0
let vgrep = 1
" =========================================

" ====== Enable your grep as "regexp" enable ======
let regexp = 1

if TurboGrep == 1 
    let semwareGrep = 0     
    let GnuGrep = 0
    let OakGrep = 0
elseif semwareGrep == 1
    let TurboGrep = 0
    let GnuGrep = 0
    let OakGrep = 0    
elseif GnuGrep == 1
    let TurboGrep = 0
    let semwareGrep = 0
    let OakGrep = 0
elseif OakGrep == 1
	let semwareGrep = 0
	let GnuGrep = 0
	let TurboGrep = 0
endif

" Location of the grep utility
if !exists("Vgrep_Path")
  if semwareGrep == 1
    let Vgrep_Path = 'c:\usr32\grep.exe'
  elseif GnuGrep == 1
    let Vgrep_Path = 'c:\usr32\gnugrep.exe'
  elseif TurboGrep == 1
    let Vgrep_Path = 'c:\usr32\tgrep.exe'
  elseif OakGrep == 1
	let Vgrep_Path = 'c:\usr32\grep32.exe'  
  elseif UnixGrep == 1
	let Vgrep_Path = 'grep'      
  elseif vgrep == 1
  	let Vgrep_Path = 'vgrep'
  endif  
  
endif

" Location of perl unix grep2wide convert 
  let g2w = '/usr/local/bin/g2w.pl'

" you can use "CTRL-V" for mapping real key in Quote
if !exists("Vlist_Key")
	if has("gui_running")
		let Vlist_Key = "<M-'>"
	else	
		let Vlist_Key = "[23~" 
	endif
endif

" you can use "CTRL-V" for mapping real key in Quote
if !exists("Vgrep_Key")
	if has("gui_running")
		let Vgrep_Key = '§'
	else	
		let Vgrep_Key = "'"   " Alt-'
	endif
endif

let g:Vgrep_Shell_Quote_Char = '"'


"============ different grep option =========================
" make default grep -option- as "ignore case / Subdirectory / line number"

" semware grep 2.0
if semwareGrep == 1
	let g:Vgrep_Default_Options = '-isn'
        
	if regexp == 1
		let g:Vgrep_Default_Options = g:Vgrep_Default_Options . 'x'
	endif
endif

" GNU grep 2.0f option z for wide output
if GnuGrep == 1
    	let g:Vgrep_Default_Options = '-iSzn'
    	if regexp == 1
    		let g:Vgrep_Default_Options = g:Vgrep_Default_Options . 'E'
	endif
endif

" Turbo Grep 5.5 from Borloand C++ 5.5 free compiler kit
if TurboGrep == 1
    if regexp == 1
    	let g:Vgrep_Default_Options = '-idn'
    else
    	let g:Vgrep_Default_Options = '-idnr'
    endif
endif

if OakGrep == 1
	let g:Vgrep_Default_Options = '-isnQ'
endif

if UnixGrep == 1
	let g:Vgrep_Default_Options = '-irn'
endif 

if vgrep == 1
	let g:Vgrep_Default_Options = 'i'
endif

"============================================================

if !exists("VGREP_MASK")
     if $bmask == ""   
         let g:VGREP_MASK = '*'
     else 
	     let g:VGREP_MASK = $bmask
     endif
endif	
	
let Vgrep_Output = 'c:\fte.grp'
if (UnixGrep == 1 || vgrep ==1 )
	let Vgrep_Output = $HOME . '/fte.grp'
    let Vgrep_Output1 = $HOME . '/fte.g__'
endif

if !exists("VGREP_DIRS")
    if $bhome == ""    
       let g:VGREP_DIRS=getcwd()
    else
       let g:VGREP_DIRS=$bhome     
    endif
endif

if !exists("Vgrep_Null_Device")
    if has("win32") || has("win16") || has("win95")
        let Vgrep_Null_Device = 'NUL'
    else
        let Vgrep_Null_Device = '/dev/null'
    endif
endif
 

" Map a key to invoke grep on a word under cursor.
exe "nnoremap <unique> <silent> " . Vgrep_Key . " :call <SID>RunVgrep()<CR>"
exe "inoremap <unique> <silent> " . Vgrep_Key . " <C-O>:call <SID>RunVgrep()<CR>"
exe "nnoremap <unique> <silent> " . Vlist_Key . " :call <SID>RunVlist()<CR>"
exe "inoremap <unique> <silent> " . Vlist_Key . " <C-O>:call <SID>RunVlist()<CR>"

" DelVgrepClrDat()
"
function! s:RunVgrepClrDat()
    let tmpfile = g:Vgrep_Output
    let tmpfile1 = g:Vgrep_Output1
    if filereadable(tmpfile)
        let del_str = 'del ' . tmpfile
        if (g:UnixGrep == 1 || g:vgrep == 1)
            let del_str = 'rm -f ' . tmpfile 
        endif  
"        let cmd_del = system(del_str)
"        exe "redir! > " . g:Vgrep_Null_Device
"        silent echon cmd_del
"        redir END
	call delete(tmpfile1)
        call delete(tmpfile)
    endif

    
endfunction

" RunVgrepWidePatch()
" Convert Unix2Wide format 
function! s:RunVgrepWidePatch()
	let cmd = "perl " . g:g2w
	let cmd_output = system(cmd)
	silent echon cmd_output
endfunction

" RunVgrepCmd()
" Run the specified grep command using the supplied pattern
function! s:RunVgrepCmd(cmd, pattern)

    let cmd_output = system(a:cmd)
    if cmd_output == ""
        echohl WarningMsg | 
        \ echomsg "Error: Pattern " . a:pattern . " not found" | 
        \ echohl None
        return
    endif
    let tmpfile = g:Vgrep_Output
    let old_verbose = &verbose
    set verbose&vim

    exe "redir! > " . tmpfile
"    silent echon '[Search results for pattern: ' . a:pattern . "]\n"    
    silent echon cmd_output
    redir END

endfunction

" EditFile()
"
function! s:EditFile()
    let Done = 0    
	let chkerror = 0
    " memory the last location 
    exe 'normal ' . 'mZ'    

	" =============== Semware Grep / GNU Grep / Unix Grep =========== 
    if g:GnuGrep == 1 || g:semwareGrep == 1 || g:UnixGrep == 1 || g:vgrep == 1
    
        let chkline = getline('.')
        let foundln = stridx(chkline,':')
        let chk = strpart(chkline,0,foundln)
        if chk == "File"
    	    let fname = strpart(chkline, foundln+2)
    	    let fline = ""
        else
           let fline = chk
           let fname = ""
           while Done == 0
            	execute "normal " . "k"
    	    	let chkline = getline('.')
    	    	let foundln = stridx(chkline,':')
    	    	let chk = strpart(chkline,0,foundln)
    	    	if chk == "File"
    		 		let fname = strpart(chkline, foundln+2)
    		 		let Done = 1
    	    	endif        
    			let chkerror = line(".")
    			if chkerror == 1 && fname == ""
    				break
    			else	
    				let chkerror = 0
    			endif
           endwhile
        endif   
    endif
    
	" ================ Turbo Grep ================================
    if g:TurboGrep == 1
        let chkline = getline('.')
		let foundln = stridx(chkline, ' ')
		let chk = strpart(chkline,0,foundln)
		if chk == "File"
        	let fname = strpart(chkline, foundln+1)
			let flen = strlen(fname)
			let fname = strpart(fname, 0, flen-1)
			if fname[1] != ':'
				let fname = g:VGREP_DIRS . '\' . fname
			endif
	     	let fline = ""
		else
	     	let fline = chk
			let fname = ""
	     	while Done == 0
				exe "normal " . "k" 	
				let chkline = getline('.')
				let foundln = stridx(chkline, ' ')
				let chk = strpart(chkline,0,foundln)
				if chk == "File"
					let fname = strpart(chkline, foundln+1)
					let flen = strlen(fname)
					let fname = strpart(fname, 0, flen-1)
					if fname[1] != ':'
						let fname = g:VGREP_DIRS . '\' . fname
					endif
					let Done = 1
				endif
    			let chkerror = line(".")
    			if chkerror == 1 && fname == ""
    				break
    			else	
    				let chkerror = 0
    			endif
	     	endwhile
		endif

    endif

	" ============ OakGrep ======================================
	if g:OakGrep == 1
		let chkerror = 0
        let chkline = getline('.')
		if chkline != ""	
 		let foundln = stridx(chkline, ']')
    		if foundln == -1 || foundln > 11
    			let foundln = stridx(chkline, '----------')
    			let chk = strpart(chkline, 0, 10)
    		else
    			let chk = strpart(chkline,1,foundln-1)
    		endif	
    		if chk == "----------"
            	let fname = strpart(chkline, 11)
    			if fname[1] != ':'
    				let fname = g:VGREP_DIRS . '\' . fname
    			endif
    	     	let fline = ""
    		else
    	     	let fline = chk
    			let fname = ""
            	while Done == 0
        			exe "normal " . "k" 	
        			let chkline = getline('.')
        			let foundln = stridx(chkline, ']')
        	        if foundln == -1 || foundln > 11
        				let foundln = stridx(chkline, '----------')
        				let chk = strpart(chkline,0,10)
        			else
        			    let chk = strpart(chkline,1,foundln-1)
        			endif	
        			if chk == "----------"
        				let fname = strpart(chkline, 11)
        				if fname[1] != ':'
        					let fname = g:VGREP_DIRS . '\' . fname
        				endif
        				let Done = 1
        			endif
    				let chkerror = line(".")
    				if chkerror == 1 && fname == ""
    					break
    				else	
    					let chkerror = 0
    				endif
				endwhile
    		endif
    	else
    	  let chkerror = 1	
    	endif   
   		
	endif
    exe 'normal ' . '`Z'

    if chkerror == 1
		echo "Invaild Grep Format / NULL Line " 
 	else	
    	" Make suit for you
    	" silent! bdelete
		echo fline
		let fline = substitute(fline, '\s*', '', "")

		if fline > 0  || fline == ""
    		if filereadable(fname) 
        		exe 'edit ' . fname
        		if strlen(fline)
          			exe 'normal ' . fline . 'gg'
        		endif  
    		else
    			echo "Invaild filename"
    		endif
		else 
		  echo "Line Error"	
		endif
	endif
endfunction	


" RunVgrep()
" Run the specified grep command
function! s:RunVgrep(...)
"    if a:0 == 0 || a:1 == ''
    let vgrep_opt = g:Vgrep_Default_Options
    let vgrep_path = g:Vgrep_Path
    
    " No argument supplied. Get the identifier and file list from user
    let pattern = input("Grep for pattern: ", expand("<cword>"))
    if pattern == ""
	echo "Cancelled."    
        return
    endif
    let pattern = g:Vgrep_Shell_Quote_Char . pattern . g:Vgrep_Shell_Quote_Char

    if g:VGREP_MASK == "*"
        let ff = expand("%:e")
        if ff != ""
            let g:VGREP_MASK = "*.".ff
        endif
    endif

    let filenames = input("Grep in files: ", g:VGREP_MASK)
    if filenames == ""
        echo "Cancelled."    
        return
    endif
    if filenames == "*"
        let ff =expand("%:e")
        if ff != ""
            let filenames = "*.".ff
        endif
    endif

    let g:VGREP_MASK = filenames
    let vgrepdir = input("vgrep dir: ", g:VGREP_DIRS)
    if vgrepdir == ""
	    echo "Cancelled."    
	    return
    endif 
	let g:VGREP_DIRS = vgrepdir
 

    if g:UnixGrep == 1
	let cmd = vgrep_path . " " . "--include=\\" . filenames . " " . vgrep_opt . " " . pattern . " " . g:VGREP_DIRS
    else
 
    	if g:vgrep == 1
                let cmd = vgrep_path . " " . pattern . " \\" . filenames . " " . vgrep_opt
        else 
        	let cmd = vgrep_path . " " . vgrep_opt . " "
        	let cmd = cmd . " " . pattern
        	let cmd = cmd . " \\" . filenames
        endif
    endif
   if g:UnixGrep == 1 
    	call s:RunVgrepClrDat()
        echo cmd
    	call s:RunVgrepCmd(cmd, pattern)
	    call s:RunVgrepWidePatch()
    else 
    	let last_cd = getcwd()
    	exe 'cd ' . vgrepdir
    	call s:RunVgrepClrDat()
    	call s:RunVgrepCmd(cmd, pattern)
    	exe 'cd ' . last_cd
    endif
    if filereadable(g:Vgrep_Output)
       setlocal modifiable 
       exe 'edit ' . g:Vgrep_Output
       setlocal nomodifiable
    endif       

    nnoremap <buffer> <silent> <CR> :call <SID>EditFile()<CR>
    nmap <buffer> <silent> <2-LeftMouse> :call <SID>EditFile()<CR>
    nmap <buffer> <silent> o :call <SID>EditFile()<CR>
	nmap <buffer> <silent> <ESC> :bdelete<CR>
endfunction

function! s:RunVlist()
    setlocal modifiable
    exe 'edit ' . g:Vgrep_Output
    nnoremap <buffer> <silent> <CR> :call <SID>EditFile()<CR>
    nmap <buffer> <silent> <2-LeftMouse> :call <SID>EditFile()<CR>
    nmap <buffer> <silent> o :call <SID>EditFile()<CR>
	nmap <buffer> <silent> <ESC> :bdelete<CR>
    setlocal nomodifiable
endfunction

" Define the set of grep commands
command! -nargs=* Vgrep call s:RunVgrep(<q-args>)
command! Vlist call s:RunVlist()

" vim:tabstop=4:sw=4
