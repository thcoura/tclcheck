
if exists("b:did_tclCheck_plugin")
    finish
else
    let b:did_tclCheck_plugin = 1
endif

if !exists("g:tclcheck_showtime")
    let g:tclcheck_showtime = 1
endif

let s:this_path = escape(expand('<sfile>:p:h'), '\ \')
silent exec 'tcl set this_path ' . s:this_path 

tcl << EOF

namespace eval ::tclCheck {
    source $this_path/nagelfar.tcl
    source $this_path/preferences.tcl
    source $this_path/startup.tcl
}

