# ============================================================================
# File:        ftplugin/startup.tcl
# Description: TclCheck, a Vim plugin for on-the-fly Tcl syntax checking and linting.
# Author:      Kearn Holliday <thekearnman@gmail.com>
# Licence:     GPL version 2
# Website:     TBD
# Version:     0.1
# Note:        The Tcl syntax checking in this plugin is powered by Nagelfar
#              (https://developer.berlios.de/git/?group_id=6731) by Peter
#              Spjuth. Many thanks to him.
#
# Copyright (C) 2011  K. Holliday
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
# ============================================================================

# Initialise global variables with defaults.
proc StartUp {} {
    set ::Nagelfar(db) {}
    set ::Nagelfar(files) {}
    set ::Nagelfar(quiet) 0
    set ::Nagelfar(filter) {}
    set ::Nagelfar(2pass) 1
    set ::Nagelfar(encoding) system
    set ::Nagelfar(dbpicky) 0
    set ::Nagelfar(withCtext) 0
    set ::Nagelfar(instrument) 0
    set ::Nagelfar(header) ""
    set ::Nagelfar(tabReg) { {0,7}\t| {8,8}}
    set ::Nagelfar(tabSub) [string repeat " " 8]
    set ::Nagelfar(tabMap) [list \t $::Nagelfar(tabSub)]
    set ::Nagelfar(procs) {}
    set ::Nagelfar(stop) 0
    if {![info exists ::Nagelfar(embedded)]} {
        set ::Nagelfar(embedded) 0
    }
    getOptions
}

# Procedure to perform a check when embedded.
proc synCheck {script dbPath} {
    #StartUp
    set ::Nagelfar(allDb) {}
    set ::Nagelfar(allDbView) {}
    set ::Nagelfar(allDb) [list $dbPath]
    set ::Nagelfar(allDbView) [list [file tail $dbPath] "(app)"]
    set ::Nagelfar(db) [list $dbPath]
    set ::Nagelfar(embedded) 1
    set ::Nagelfar(chkResult) ""
    set ::Nagelfar(header) {}
    set ::Nagelfar(stop) 0
    set ::Nagelfar(checkEdit) $script
    doCheck
    return $::Nagelfar(chkResult)
}

# only load once, not every call
if {1} {
  set dbPath "$::this_path\\syntaxdb.tcl"
  StartUp
  set ::Nagelfar(allDb) {}
  set ::Nagelfar(allDbView) {}
  set ::Nagelfar(allDb) [list $dbPath]
  set ::Nagelfar(allDbView) [list [file tail $dbPath] "(app)"]
  set ::Nagelfar(db) [list $dbPath]
  set ::Nagelfar(embedded) 1
  set ::Nagelfar(chkResult) ""
  set ::Nagelfar(header) {}
  set ::Nagelfar(stop) 0
  loadDatabases
}

