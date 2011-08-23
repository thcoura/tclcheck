
if exists("b:did_tclCheck_plugin")
    finish
else
    let b:did_tclCheck_plugin = 1
endif

if !has('tcl')
    echoe "Tclcheck requires Vim built with Tcl support"
    finish
endif

if !exists("g:tclcheck_showtime")
    let g:tclcheck_showtime = 0
endif

if !exists('g:tclcheck_only_current_proc')
    let g:tclcheck_only_current_proc = 0
endif

if !exists('g:tclcheck_use_threading')
    let g:tclcheck_use_threading = 1
endif


let s:this_path = escape(expand('<sfile>:p:h'), '\ \')
silent exec 'tcl set this_path ' . s:this_path 


if g:tclcheck_use_threading
    tcl namespace eval ::tclCheck { set use_threading true }
else
    tcl namespace eval ::tclCheck { set use_threading false }
endif


tcl << EOF

namespace eval ::tclCheck {

    if {$use_threading} {
        catch {
            package require Thread
        } version

        # FIXME a better way of checking this?
        if {![string is integer -strict [string map {. {}} $version]]} {
            set use_threading false
        } else {
            set thread_id [::thread::create]
            ::thread::send $thread_id [ list set ::this_path $this_path ]
        }
    }

    if {$use_threading} {
        ::thread::send $thread_id {
            source $this_path/nagelfar.tcl
            source $this_path/preferences.tcl
            source $this_path/startup.tcl
        } r
    } else {
        source $this_path/nagelfar.tcl
        source $this_path/preferences.tcl
        source $this_path/startup.tcl
    }

}

