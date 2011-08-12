
if exists("b:did_tclCheck_ftplugin")
    finish " only load once
else
    let b:did_tclCheck_ftplugin = 1
endif


if !exists('s:enabled')
    let s:enabled = 1
endif

"sign define TclCheckWarn text=W
"sign define TclCheckNote text=N
"sign define TclCheckErr linehl=TclCheckErr

if !exists("*s:RunTclCheck")
    function! s:RunTclCheck()
        if &background == "dark"
            "hi TclCheckErr guibg=#660015
            hi TclCheckErr gui=undercurl guisp=#ff0000
            "hi TclCheckWarn guibg=#662900
            "hi TclCheckNote guibg=#662900
            hi TclCheckWarn gui=undercurl guisp=#ffaa00
            hi TclCheckNote gui=undercurl guisp=#ffaa00
        else
            "hi TclCheckErr guibg=#E08888
            hi TclCheckErr gui=undercurl guisp=#ff0000
            "hi TclCheckWarn guibg=#FF944D
            "hi TclCheckNote guibg=#FF944D
            hi TclCheckWarn gui=undercurl guisp=#ffaa00
            hi TclCheckNote gui=undercurl guisp=#ffaa00
        endif
        if !s:enabled
            return
        endif
        call clearmatches()
        let s:qflist = []
        call setqflist([])
        let buf_no = winbufnr('.')
        silent exec "tcl set buf_no " . buf_no
        "sign unplace *
        " Map options to tcl space
        exec 'tcl set showtime ' . g:tclcheck_showtime
tcl << end_tcl
if {$showtime} {
    set start [clock milliseconds]
}
set buf [::vim::buffer $buf_no]
set messages {}
# FIXME 
set out [synCheck [join [$buf get 1 end] \n] "${this_path}\\syntaxdb.tcl"]
#set sign_no 1
set err_lines {}
foreach ln $out {
    if {![string match "*Unknown command*" $ln]} {
        if {[string match "*Line*" $ln]} {
            regexp {(?:Line\s+)(\d+)(?::)} $ln -> line_no
            regexp {(?::\s)(.*$)} $ln -> msg
            ::vim::command -quiet "let s:qflist += \[{'bufnr': winbufnr('.'), 'lnum': $line_no, 'col': 1, 'text': '$msg'}\]" 

            set match_expr "\\%${line_no}l\\S.*$"

            if { [string match -nocase "E unknown variable \"*" $msg] \
              || [string match -nocase "W found constant \"*" $msg]
               } {
                regexp {(?:.*?")(.*?)(")} $msg -> var
                set match_expr "\\%${line_no}l\\<$var\\>"
            }                    

            if {[string match "W *" $msg]} {
                #::vim::command "sign place $sign_no line=$line_no name=TclCheckWarn buffer=$buf_no"
                ::vim::command "let s:mID = matchadd('TclCheckWarn', '${match_expr}')"
            } elseif {[string match "N *" $msg]} {
                #::vim::command "sign place $sign_no line=$line_no name=TclCheckNote buffer=$buf_no"
                ::vim::command "let s:mID = matchadd('TclCheckNote', '${match_expr}')"
            } elseif {[string match "E *" $msg]} {
                #::vim::command "sign place $sign_no line=$line_no name=TclCheckErr buffer=$buf_no"
                ::vim::command "let s:mID = matchadd('TclCheckErr', '${match_expr}')"
                lappend err_lines $line_no
            }
            #incr sign_no

            if {[string match "W *" $msg] || [string match "N *" $msg]} {
                if {$line_no in $err_lines} {
                    continue
                }
            }

            set _msg [split $msg \n]
            set msg {}
            foreach m $_msg { lappend msg [string trimright [string trimleft $m]] }
            set msg [join $msg " | "]
            dict set messages $line_no $msg
        }
    }
}
if {$showtime} {
    puts [expr [clock milliseconds] - $start]
}
end_tcl
        call setqflist(s:qflist)
    endfunction
endif

if !exists("*s:TclCheckUpdate")
    function! s:TclCheckUpdate()
        call s:RunTclCheck()
        "call s:GetTclCheckMessage()
    endfunction
endif

if !exists("*s:GetTclCheckMessages")
    function! s:GetTclCheckMessages()
tcl << EOF
if {[info exists messages]} {
    set line_no [::vim::expr "line('.')"]
    if {[dict exists $messages $line_no]} {
        puts [dict get $messages $line_no]
    } else {
        puts {}
    }
}
EOF
    endfunction
endif

if !exists("*s:ClearTclCheck")
    function! s:ClearTclCheck()
        let s:qflist = []
        call clearmatches()
        sign unplace *
    endfunction
endif

" Enable / Disable {{{

function! s:Enable()
    let s:enabled = 1
    silent call s:RunTclCheck()
endfunction

function! s:Disable()
    let s:enabled = 0
    silent call s:ClearTclCheck()
endfunction

if !exists(":EnableTclCheck")
    command EnableTclCheck :call s:Enable()
endif

if !exists(":DisableTclCheck")
    command DisableTclCheck :call s:Disable()
endif

if !exists(":ClearTclCheck")
    command ClearTclCheck :call s:ClearTclCheck()
endif

if !exists(":TclCheckGetMessage")
    command TclCheckGetMessage :call s:GetTclCheckMessages()
endif

" }}}


" Call this function in your .vimrc to update PyFlakes
if !exists(":TclCheckUpdate")
  command TclCheckUpdate :call s:TclCheckUpdate()
endif

" Hook common text manipulation commands
"   TODO: is there a more general "text op" autocommand we could register
"   for here?
noremap <buffer><silent> dd dd:TclCheckUpdate<CR>
noremap <buffer><silent> dw dw:TclCheckUpdate<CR>
noremap <buffer><silent> x x:TclCheckUpdate<CR>
noremap <buffer><silent> u u:TclCheckUpdate<CR>
noremap <buffer><silent> <C-R> <C-R>:TclCheckUpdate<CR>

au BufEnter <buffer> TclCheckUpdate
au InsertLeave <buffer> TclCheckUpdate
au InsertEnter <buffer> TclCheckUpdate
au BufWritePost <buffer> TclCheckUpdate
au BufLeave <buffer> ClearTclCheck

" screen update not great when using signs, also TclCheckUpdate needs to be
" faster before using these
"au CursorHold <buffer> TclCheckUpdate
"au CursorHoldI <buffer> TclCheckUpdate
au CursorMovedI <buffer> TclCheckUpdate

au CursorHold <buffer> TclCheckGetMessage
au CursorMoved <buffer> TclCheckGetMessage
