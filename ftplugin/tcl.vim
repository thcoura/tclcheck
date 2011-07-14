
if exists("b:did_tclCheck_plugin")
    finish " only load once
else
    let b:did_frink_plugin = 1
endif

"let s:this_path = escape(expand('<sfile>:p:h'), '\ ')
"silent exec 'tcl set this_path ' . s:this_path 



"if !exists("*s:RunTclCheck")
    function! s:RunTclCheck()
        highlight link TclCheck SpellBad
        "highlight link TclCheck ToDo
        "hi TclCheck guibg=#888888
        call clearmatches()
        let this_dir = getcwd()
        cd c:/nagelfar
        let s:qflist = []
        call setqflist([])
        silent exec 'tcl set buf [::vim::buffer ' . winbufnr('.') . ']'
tcl << end_tcl
set messages {}
# FIXME 
set out [synCheck [join [$buf get 1 end] \n] "${this_path}\\syntaxdb.tcl"]
foreach ln $out {
  if {![string match "*Unknown command*" $ln]} {
    if {[string match "*Line*" $ln]} {
      regexp {(?:Line\s+)(\d+)(?::)} $ln -> line_no
      regexp {(?::\s)(.*$)} $ln -> msg
      set match_expr "\\%${line_no}l\\S.*$" 
      ::vim::command "let s:mID = matchadd('TclCheck', '${match_expr}')"
      ::vim::command -quiet "let s:qflist += \[{'bufnr': winbufnr('.'), 'lnum': $line_no, 'col': 1, 'text': '$msg'}\]" 
      set _msg [split $msg \n]
      set msg {}
      foreach m $_msg { lappend msg [string trimright [string trimleft $m]] }
      set msg [join $msg " | "]
      dict set messages $line_no $msg
    }
  }
}
end_tcl
        call setqflist(s:qflist)
        exec 'cd ' . this_dir
    endfunction
"endif

if !exists("*s:TclCheckUpdate")
    function! s:TclCheckUpdate()
        silent call s:RunTclCheck()
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
    endfunction
endif

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

augroup TclCheckUpdate
    autocmd!
    au BufEnter <buffer> call s:RunTclCheck()
    au InsertLeave <buffer> call s:RunTclCheck()
    au InsertEnter <buffer> call s:RunTclCheck()
    au BufWritePost <buffer> call s:RunTclCheck()
    au BufLeave <buffer> call s:ClearTclCheck()
augroup END

augroup TclCheckMessages
    autocmd!
    au CursorHold <buffer> call s:GetTclCheckMessages()
    au CursorMoved <buffer> call s:GetTclCheckMessages()
augroup END
