
python << EOF
import subprocess
import os
import re
messages = {}
EOF

"if !exists("*s:FrinkGetMessages")
"endif

"if !exists("*s:RunFrink")
    function! s:RunFrink()
        highlight link Frink SpellBad
        call clearmatches()
python << EOF
messages = {}
fname = vim.eval('tempname()')
with open(fname, 'w') as f:
    f.write('\n'.join(vim.current.buffer))
f.close()
out = subprocess.check_output(['frink', '-GHJ', fname], stderr=subprocess.STDOUT, shell=True)
subprocess.call(['rm', fname], shell=True)
for ln in out.split('\n'):
    line_no_match = re.search('\(\d*\)', ln)
    msg_match = re.search(': .*$', ln)

    if line_no_match is None:
        # try find "line xx"
        line_no_match = re.search('line \d*', ln)
        if line_no_match is not None:
            start, end = line_no_match.start()+5, line_no_match.end()
    else:
        start, end = line_no_match.start()+1, line_no_match.end()-1

    if line_no_match is not None:                         
        line_no = ln[start:end]
        vim.command(r"let s:mID = matchadd('Frink', '\%" + line_no + r"l\n\@!')")
        if msg_match is not None:
            messages[line_no] = ln[msg_match.start()+2:msg_match.end()]
EOF
    endfunction
"endif

"if !exists("*s:FrinkUpdate")
    function! s:FrinkUpdate()
        silent call s:RunFrink()
        "call s:GetFrinkMessage()
    endfunction
"endif

"if !exists("*s:GetFrinkMessages")
    function! s:GetFrinkMessages()
python << EOF
if messages:
    line_no = vim.eval('line(".")')
    print messages.get(line_no, '')
EOF
    endfunction
"endif

" Hook common text manipulation commands
"   TODO: is there a more general "text op" autocommand we could register
"   for here?
noremap <buffer><silent> dd dd:FrinkUpdate<CR>
noremap <buffer><silent> dw dw:FrinkUpdate<CR>
noremap <buffer><silent> u u:FrinkUpdate<CR>
noremap <buffer><silent> <C-R> <C-R>:FrinkUpdate<CR>

if exists("b:did_frink_plugin")
    finish " only load once
else
    let b:did_frink_plugin = 1
endif

augroup FrinkUpdate
    autocmd!
    au BufEnter <buffer> call s:RunFrink()
    au InsertLeave <buffer> call s:RunFrink()
    au InsertEnter <buffer> call s:RunFrink()
    au BufWritePost <buffer> call s:RunFrink()
augroup END

augroup FrinkMessages
    autocmd!
    au CursorHold <buffer> call s:GetFrinkMessages()
    au CursorMoved <buffer> call s:GetFrinkMessages()
augroup END
