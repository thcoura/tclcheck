# ============================================================================
# File:        ftplugin/preferences.tcl
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

# original copyright notice:
#
#----------------------------------------------------------------------
#  Nagelfar, a syntax checker for Tcl.
#  Copyright (c) 1999-2010, Peter Spjuth
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; see the file COPYING.  If not, write to
#  the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#  Boston, MA 02111-1307, USA.

# Save default options
proc saveOptions {} {
    if {[catch {set ch [open "~/.nagelfarrc" w]}]} {
        errEcho "Could not create options file."
        return
    }

    foreach i [array names ::Prefs] {
        puts $ch [list set ::Prefs($i) $::Prefs($i)]
    }
    close $ch
}

# Fill in default options and load user's saved file
proc getOptions {} {
    array set ::Prefs {
        warnBraceExpr 2
        warnShortSub 1
        strictAppend 0
        prefixFile 0
        forceElse 1
        noVar 0
        severity N
        editFileBackup 1
        editFileFont {Courier 10}
        resultFont {Courier 10}
        editor internal
        extensions {.tcl .test .adp .tk}
        exitcode 0
        html 0
        htmlprefix ""
    }
}

