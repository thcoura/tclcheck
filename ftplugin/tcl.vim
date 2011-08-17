
if exists("b:did_tclCheck_ftplugin")
    finish " only load once
else
    let b:did_tclCheck_ftplugin = 1
endif

echo "tclcheck loaded"


if !exists('s:enabled')
    let s:enabled = 1
endif


" FIXME can't this be done by naglefar, if it's given a line number?
if !exists('*s:GetProc')
    function! s:GetProc()
        let old_m = @m
        norm mm
        let curr_line = line('.')
        let proc_line = search('^\(\s\|\t\)*\(proc\|oo::def*\)', 'bcn')
        if proc_line == 0
            norm `m
            let @m = old_m
            return [-2, 0]
        endif
        let to_end = getline(proc_line, '$')
        " FIXME Rewrite in tcl, otherwise vim with python is also required
        python << end_py
ret = list()
to_end = vim.eval('to_end')
ret.append(to_end[0])
braces = 1
for ln in to_end[1:]:
    ret.append(ln)
    braces += ln.count('{')
    braces -= ln.count('}')
    if braces <= 0:
        break

vim.command('let end_line = %d' % (int(vim.eval('proc_line')) + len(ret) - 1))
ret_ = '\n'.join(ret)
# FIXME
if "'" in ret_:
    #print 'Warning: unable to extract proc, "\'" found'
    vim.command("let ret = -1") 
else:
    vim.command("let ret = '%s'" % ret_) 
end_py
        norm `m
        let @m = old_m
        if curr_line > end_line
            return [-2, 0]
        endif
        return [ret, proc_line-1]
    endfunction
endif


if !exists("*s:RunTclCheck")
    function! s:RunTclCheck(force_all)
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

        " Map options to tcl space
        exec 'tcl set showtime ' . g:tclcheck_showtime

        exec 'tcl set start_ln 0'
        if g:tclcheck_only_current_proc == 1 && a:force_all == 0
            let code_n = s:GetProc()
            let code = code_n[0]
            exec 'tcl set start_ln ' . code_n[1]
            if code != -2 && code != -1
                exec 'tcl set code {' . code . '}'
            endif
        endif

        tcl << end_tcl

if {$showtime} {
    set start [clock milliseconds]
}

if {![info exists code]} {
    set code [join [[::vim::buffer $buf_no] get 1 end] \n]
}
set messages {}

set out [::tclCheck::synCheck $code "${this_path}\\syntaxdb.tcl"]
unset -nocomplain code

set err_lines {}
foreach ln $out {
    if {![string match "*Unknown command*" $ln]} {
        if {[string match "*Line*" $ln]} {

            regexp {(?:Line\s+)(\d+)(?::)} $ln -> line_no
            incr line_no $start_ln

            regexp {(?::\s)(.*$)} $ln -> msg

            ::vim::command -quiet "let s:qflist += \[{'bufnr': winbufnr('.'), 'lnum': $line_no, 'col': 1, 'text': '$msg'}\]" 

            set match_expr "\\%${line_no}l\\S.*$"

            if { [string match -nocase {E unknown variable *} $msg] \
              || [string match -nocase {W found constant *} $msg] \
              || [string match -nocase {N suspicious variable name *} $msg] \
              || [string match -nocase {E unknown subcommand *} $msg] \
              || [string match -nocase {W suspicious command *} $msg] \
              || [string match -nocase {E strange command *} $msg] \
              || [string match -nocase {E bad expression: invalid bareword *} $msg] \
              } {
                regexp {(?:.*?")(.*?)(")} $msg -> var
                set match_expr "\\%${line_no}l$var\\>"
            } elseif {[string match -nocase "E bad option -*" $msg]} {
                regexp {(?:.*?\s)(-.*?)(\s)} $msg -> opt
                set match_expr "\\%${line_no}l$opt\\>"
            }                   

            if {[string match "W *" $msg]} {
                ::vim::command "let s:mID = matchadd('TclCheckWarn', '${match_expr}')"
            } elseif {[string match "N *" $msg]} {
                ::vim::command "let s:mID = matchadd('TclCheckNote', '${match_expr}')"
            } elseif {[string match "E *" $msg]} {
                ::vim::command "let s:mID = matchadd('TclCheckErr', '${match_expr}')"
                lappend err_lines $line_no
            }

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
    function! s:TclCheckUpdate(force_all)
        call s:RunTclCheck(a:force_all)
    endfunction
endif

if !exists("*s:GetTclCheckMessages")
    function! s:GetTclCheckMessages()
        tcl << end_tcl

if {[info exists messages]} {
    set line_no [::vim::expr "line('.')"]
    if {[dict exists $messages $line_no]} {
        puts [dict get $messages $line_no]
    } else {
        puts {}
    }
}

end_tcl

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
    silent call s:RunTclCheck(1)
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


if !exists(":TclCheckUpdate")
  command TclCheckUpdate :call s:TclCheckUpdate(0)
endif

if !exists(":TclCheckUpdateForceAll")
  command TclCheckUpdateForceAll :call s:TclCheckUpdate(1)
endif


" Hook common text manipulation commands
"   TODO: is there a more general "text op" autocommand we could register
"   for here?
noremap <buffer><silent> dd dd:TclCheckUpdate<CR>
noremap <buffer><silent> dw dw:TclCheckUpdate<CR>
noremap <buffer><silent> x x:TclCheckUpdate<CR>
noremap <buffer><silent> u u:TclCheckUpdate<CR>
noremap <buffer><silent> <C-R> <C-R>:TclCheckUpdate<CR>

au! * <buffer>
au BufEnter <buffer> TclCheckUpdateForceAll
au InsertLeave <buffer> TclCheckUpdate
au InsertEnter <buffer> TclCheckUpdate
au BufWritePost <buffer> TclCheckUpdateForceAll
au ColorScheme <buffer> TclCheckUpdateForceAll
au BufLeave <buffer> ClearTclCheck

" screen update not great when using signs, also TclCheckUpdate needs to be
" faster before using these
"au CursorHold <buffer> TclCheckUpdate
"au CursorHoldI <buffer> TclCheckUpdate
au CursorMovedI <buffer> TclCheckUpdate

au CursorHold <buffer> TclCheckGetMessage
au CursorMoved <buffer> TclCheckGetMessage
