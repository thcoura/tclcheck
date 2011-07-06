
if exists("b:did_tclCheck_plugin")
    finish " only load once
else
    let b:did_frink_plugin = 1
endif

python << EOF
import subprocess
import os
import re
messages = {}
EOF

if !exists("*s:RunTclCheck")
    function! s:RunTclCheck()
        highlight link TclCheck SpellBad
        "highlight link TclCheck ToDo
        "hi TclCheck guibg=#888888
        call clearmatches()
        let this_dir = getcwd()
        cd c:/nagelfar
        let s:qflist = []
        call setqflist([])
python << EOF
messages = {}
# FIXME using a temp file is slow, maybe use a modified nagelfar.tcl in vim's interpreter?
fname = vim.eval('tempname()')
with open(fname, 'w') as f:
    f.write('\n'.join(vim.current.buffer))
f.close()
out = subprocess.check_output(['c:/user/Tcl/runtime/ptcl-1603/bin/ptclsh86t.exe', 'nagelfar.tcl', fname], stderr=subprocess.STDOUT, shell=True)
subprocess.call(['rm', fname], shell=True)

for ln in out.split('\n'):
    if re.search('Unknown command', ln) is None: # don't do these
        if re.match('Line', ln):
            line_no_match = re.search('\d*:', ln)
            msg_match = re.search(': .*$', ln)

            if line_no_match is not None:                         
                start, end = line_no_match.start(), line_no_match.end()-1
                line_no = ln[start:end]
                vim.command(r"let s:mID = matchadd('TclCheck', '\%" + line_no + r"l\S.*$')")
                if msg_match is not None:
                    msg = ln[msg_match.start()+2:msg_match.end()].rstrip(chr(13))
                    messages[line_no] = msg
                    vim.command("let s:qflist += [{'bufnr': winbufnr('.'), 'lnum': %s, 'col': 1, 'text': '%s'}]" % (line_no, msg))
EOF
        call setqflist(s:qflist)
        exec 'cd ' . this_dir
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
python << EOF
if messages:
    line_no = vim.eval('line(".")')
    print messages.get(line_no, '')
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
