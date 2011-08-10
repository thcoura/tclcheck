
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
  set dbPath "$this_path\\syntaxdb.tcl"
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

