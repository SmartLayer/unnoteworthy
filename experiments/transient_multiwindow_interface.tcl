#!/usr/bin/wish

# This creates a multi-window interface where
# each window is a note with its own tool bar

bind . <Control-q> { exit }
bind . <Control-Q> { exit }

menu .mbar
. configure -menu .mbar

menu .mbar.fl
.mbar add cascade -menu .mbar.fl -label File

.mbar.fl add command -label Exit -command { exit }

wm title . "Unnoteworthy" 

proc rightCenterWindow {root root_width} {
    # centre of the right half of the screen, 5% from top
    set x_offset [expr [lindex [wm maxsize $root] 0] / 2]
    set x_offset [expr $x_offset + ($x_offset - $root_width) / 2]
    set y_offset [expr int([lindex [wm maxsize .] 1] * 0.05)]
    wm geometry $root ${root_width}x0+${x_offset}+${y_offset}
}

proc tileWindow {root previous} {
    update
    set x_offset [expr [lindex [wm maxsize $root] 0] / 2]
    set y_offset [expr [winfo y $previous] + [winfo height $previous] + 20]
    wm geometry $root +$x_offset+$y_offset
    puts +$x_offset+$y_offset
}

proc toplevelNote {w} {
    toplevel $w
    wm transient $w .
    wm attributes $w -type utilty
    bind $w <Control-q> { exit }
    bind $w <Control-Q> { exit }

    text $w.txt
    pack $w.txt -side bottom
    button $w.up -text ▲
    button $w.down -text ▼
    pack  $w.up $w.down -side right
}

toplevelNote .note1
toplevelNote .note2
rightCenterWindow . 200
tileWindow .note1 .
tileWindow .note2 .note1
