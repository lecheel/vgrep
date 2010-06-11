" Vim syntal file
" Language: vGrep

if version < 600
	syntax clear
elseif exists("b:current_syntax")
	finish
endif

syn match grpLine1 	"\d\+:"
syn match grpLine2	"^[0-9]\+\d"
syn match grpLine3	"^\[\+\s\+\d\+]"
syn match grpLine4	"^File.*"
syn match grpLine5	"^----------\s.*"

if version >= 508 || !exists("did_grp_syntax_inits")
	if version < 508
		let did_grp_syntax_inits = 1
		command -nargs=+ HiLink hi link <args>
	else 
		command -nargs=+ HiLink hi def link <args>
	endif

	HiLink grpLine1	Number
	HiLink grpLine2	Number
	HiLink grpLine3 Number
	HiLink grpLine4 Statement
	HiLink grpLine5 Statement

	delcommand HiLink
endif

let b:current_syntax = "grp"



" vim: ts=4 sw=4
