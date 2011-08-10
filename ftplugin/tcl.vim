
if exists("b:did_tclCheck_ftplugin")
    finish " only load once
else
    let b:did_tclCheck_ftplugin = 1
endif


if !exists('s:enabled')
    let s:enabled = 1
endif

sign define TclCheckWarn text=W
sign define TclCheckN text=N

sign define TclCheckErr linehl=TclCheckErr

if !exists("*s:RunTclCheck")
    function! s:RunTclCheck()
        if &background == "dark"
            hi TclCheckErr guibg=#440010
        else
            hi TclCheckErr guibg=#E08888
        endif
        if !s:enabled
            return
        endif
        "highlight link TclCheck ToDo
        "hi TclCheck guibg=#888888
        call clearmatches()
        let s:qflist = []
        call setqflist([])
        let buf_no = winbufnr('.')
        silent exec "tcl set buf_no " . buf_no
        sign unplace *
tcl << end_tcl
set buf [::vim::buffer $buf_no]
set messages {}
# FIXME 
set out [synCheck [join [$buf get 1 end] \n] "${this_path}\\syntaxdb.tcl"]
set sign_no 1
set err_lines {}
foreach ln $out {
  if {![string match "*Unknown command*" $ln]} {
    if {[string match "*Line*" $ln]} {
      regexp {(?:Line\s+)(\d+)(?::)} $ln -> line_no
      regexp {(?::\s)(.*$)} $ln -> msg
      set match_expr "\\%${line_no}l\\S.*$" 
      #::vim::command "let s:mID = matchadd('TclCheck', '${match_expr}')"
      ::vim::command -quiet "let s:qflist += \[{'bufnr': winbufnr('.'), 'lnum': $line_no, 'col': 1, 'text': '$msg'}\]" 
      if {[string match "W *" $msg]} {
        ::vim::command "sign place $sign_no line=$line_no name=TclCheckWarn buffer=$buf_no"
      } elseif {[string match "N *" $msg]} {
        ::vim::command "sign place $sign_no line=$line_no name=TclCheckN buffer=$buf_no"
      } elseif {[string match "E *" $msg]} {
        ::vim::command "sign place $sign_no line=$line_no name=TclCheckErr buffer=$buf_no"
        lappend err_lines $line_no
      }
      incr sign_no

      if {[string match "W *" $msg] || [string match "W *" $msg]} {
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
end_tcl
        call setqflist(s:qflist)
    endfunction
endif

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
