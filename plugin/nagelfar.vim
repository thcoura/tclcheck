
if exists("b:did_tclCheck_plugin")
    finish
else
    let b:did_tclCheck_plugin = 1
endif

let s:this_path = escape(expand('<sfile>:p:h'), '\ \')
silent exec 'tcl set this_path ' . s:this_path 

tcl source $this_path/nagelfar.tcl
tcl source $this_path/preferences.tcl
tcl source $this_path/startup.tcl

