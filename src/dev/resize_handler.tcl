# -----------------------------------------------------------------------------
# -- resizeHandle
# -----------------------------------------------------------------------------
# http://wiki.tcl.tk/3350, Thanks to:
# George Peter Staplin: A resize handle is that funky thing usually
# on the bottom right of a window that you can use to resize a window.
# -----------------------------------------------------------------------------

namespace eval resizeHandle {
	
	image create bitmap resizeHandle:image -data {
		#define resizeHandle_width 25
		#define resizeHandle_height 25
		static unsigned char resizeHandle_bits[] = {
			0x40, 0x10, 0x04, 0x01, 0x20, 0x08, 0x82, 0x00, 0x10, 0x04, 0x41, 0x00,
			0x08, 0x82, 0x20, 0x00, 0x04, 0x41, 0x10, 0x00, 0x82, 0x20, 0x08, 0x00,
			0x41, 0x10, 0x04, 0x01, 0x20, 0x08, 0x82, 0x00, 0x10, 0x04, 0x41, 0x00,
			0x08, 0x82, 0x20, 0x00, 0x04, 0x41, 0x10, 0x00, 0x82, 0x20, 0x08, 0x00,
			0x41, 0x10, 0x04, 0x01, 0x20, 0x08, 0x82, 0x00, 0x10, 0x04, 0x41, 0x00,
			0x08, 0x82, 0x20, 0x00, 0x04, 0x41, 0x10, 0x00, 0x82, 0x20, 0x08, 0x00,
			0x41, 0x10, 0x04, 0x01, 0x20, 0x08, 0x82, 0x00, 0x10, 0x04, 0x41, 0x00,
			0x08, 0x82, 0x20, 0x00, 0x04, 0x41, 0x10, 0x00, 0x82, 0x20, 0x08, 0x00,
			0x41, 0x10, 0x04, 0x00};
	}
	
	proc Event_ButtonPress1 {win resizeWin X Y} {
		upvar #0 _resizeHandle$win ar
		set ar(startX) $X
		set ar(startY) $Y
		set ar(minWidth) [image width resizeHandle:image]
		set ar(minHeight) [image height resizeHandle:image]
		set ar(resizeWinX) [winfo x $resizeWin]
		set ar(resizeWinY) [winfo y $resizeWin]
	}
	
	proc Event_B1Motion {win resizeWin internal X Y} {
		upvar #0 _resizeHandle$win ar
		
		set xDiff [expr {$X - $ar(startX)}]
		set yDiff [expr {$Y - $ar(startY)}]
		
		set oldWidth [winfo width $resizeWin]
		set oldHeight [winfo height $resizeWin]
		
		set newWidth [expr {$oldWidth + $xDiff}]
		set newHeight [expr {$oldHeight + $yDiff}]
		
		if {$newWidth < $ar(minWidth) || $newHeight < $ar(minHeight)} {
			return
		}
		
		if {$internal == 0} {
			#if {$ar(resizeWinX) >= 0} {
				set newX "+$ar(resizeWinX)"
			#}
			#if {$ar(resizeWinY) >= 0} {
				set newY "+$ar(resizeWinY)"
			#}
			
			wm geometry $resizeWin ${newWidth}x${newHeight}${newX}${newY}
		} else {
			place $resizeWin -width $newWidth -height $newHeight -x $ar(resizeWinX) -y $ar(resizeWinY)
		}
		
		set ar(startX) $X
		set ar(startY) $Y
	}
	
	proc Event_Destroy {win} {
		upvar #0 _resizeHandle$win ar
		#catch because this may not be set
		catch {array unset ar}
	}
	
	proc resizeHandle {win resizeWin args} {
		eval label [concat $win $args -image resizeHandle:image]
		
		bind $win <ButtonPress-1> "[namespace current]::Event_ButtonPress1 $win $resizeWin %X %Y"
		bind $win <B1-Motion> "[namespace current]::Event_B1Motion $win $resizeWin 0 %X %Y"
		bind $win <Destroy> "[namespace current]::Event_Destroy $win"
		return $win
	}
	
	proc resizeHandle:internal {win resizeWin args} {
		eval label [concat $win $args -image resizeHandle:image]
		
		bind $win <ButtonPress-1> "[namespace current]::Event_ButtonPress1 $win $resizeWin %X %Y"
		bind $win <B1-Motion> "[namespace current]::Event_B1Motion $win $resizeWin 1 %X %Y"
		bind $win <Destroy> "[namespace current]::Event_Destroy $win"
		return $win
	}
}



# Test code
# if {0} {
proc main {argc argv} {
	option add *Frame.background #909090
	option add *background #b0b0b0
	option add *foreground black
	option add *activeBackground #b0a090
	
	wm title . "Internal resizeHandle Demo"
	
	pack [button .exit -text "Press to Exit" -command exit] -side top
	pack [button .b -text Destroy -command {destroy .resizeFrame}] -side top
	#resizeHandle doesn't work with a window managed with -relx or -rely.
	#It also only works with the place manager at the moment.
	place [frame .resizeFrame -bg royalblue -bd 2 -relief raised -width 250 -height 250] -x 40 -y 60
	pack [message .resizeFrame.msg -text "This would normally be a window with a titlebar for movement.\
			If you have a need for such a thing look at the internal movable windows page on the Tcl'ers Wiki."] -side top
	
	pack [::resizeHandle::resizeHandle:internal .resizeFrame.resizeHandle .resizeFrame] -side bottom -anchor e
	
	toplevel .t
	wm transient .t .
	wm title .t "Toplevel resizeHandle Demo"
	
	pack [button .t.exit -text "Press to Exit" -command exit] -anchor c
	pack [frame .t.bottomFrame] -side bottom -anchor e
	pack [::resizeHandle::resizeHandle .t.bottomFrame.resizeHandle .t] -side left
}

main $argc $argv
# }
