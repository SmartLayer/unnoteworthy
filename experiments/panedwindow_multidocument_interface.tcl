#!/usr/bin/wish

# experiment using panedwindow to emulate a tiling multi-document
# interface.  the missing features are iconifying (or collapsing) a
# document and moving a document through drag-and-drop. These are to
# be amended programtically.

ttk::panedwindow .p -orient vertical

proc note {w } {
    ttk::frame $w
    ttk::button $w.openclose -text ◀
    ttk::label  $w.dndhandle -text ☰
    text $w.txt
    $w.txt insert 1.0 $w
    pack $w.txt -side bottom
    pack $w.openclose -side right
    pack $w.dndhandle
}

note .p.f1 
note .p.f2
note .p.f3
.p add .p.f1
.p add .p.f2
pack .p
ttk::button .button -command {
    .p insert 0 .p.f3}

pack .button
