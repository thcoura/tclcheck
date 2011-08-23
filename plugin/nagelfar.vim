" ============================================================================
" File:        ftplugin/nagelfar.vim
" Description: TclCheck, a Vim plugin for on-the-fly Tcl syntax checking and linting.
" Author:      Kearn Holliday <thekearnman@gmail.com>
" Licence:     GPL version 2
" Website:     TBD
" Version:     0.1
" Note:        The Tcl syntax checking in this plugin is powered by Nagelfar
"              (https://developer.berlios.de/git/?group_id=6731) by Peter
"              Spjuth. Many thanks to him.
"
" Copyright (C) 2011  K. Holliday
"
" This program is free software; you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation; either version 2 of the License, or
" (at your option) any later version.

" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.

" You should have received a copy of the GNU General Public License
" along with this program; if not, write to the Free Software
" Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
" ============================================================================

if exists("b:did_tclCheck_plugin")
    finish
else
    let b:did_tclCheck_plugin = 1
endif

if !has('tcl')
    echoe "Tclcheck requires Vim built with Tcl support"
    finish
endif

" Useful only for debugging while I work on this plugin.
if !exists("g:tclcheck_showtime")
    let g:tclcheck_showtime = 0
endif

" In insert mode, only send the current proc to to Nagelfar for linting. This
" means error highlighting outside the current proc will disappear. Robustness
" for proc extraction may not be so good. Currently uses a regex to find the
" start of the proc and then matches a closing brace, so if braces don't match
" etc. this may not work. Supports oo methods as well.
if !exists('g:tclcheck_only_current_proc')
    let g:tclcheck_only_current_proc = 0
endif

" Process file in a background thread (error highlighting may not be immediate).
" This is currently not finished/working, so I recommend not using it for now.
if !exists('g:tclcheck_use_threading')
    let g:tclcheck_use_threading = 0
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

