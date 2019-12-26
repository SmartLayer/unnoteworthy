# ---------
# demo code
# ---------


# where to find the required library packages,
# auto_path usually needs to be modified to fit your specific environment:
#
set dir [file dirname [info script]]
lappend auto_path [file join $dir "."]
lappend auto_path [file join $dir "../../tksqlite-0.5.13-modified.vfs/lib"]


package require Tk
package require TclOO
package require treectrl
package require Img

package require screenshot


set dev_mode 1

if { $dev_mode } {
	catch {
		console show
		console eval {wm protocol . WM_DELETE_WINDOW {exit 0}}
	}
}


# http://wiki.tcl.tk/10504

# DKF: Here's a version (no alpha channel handling) which goes a bit faster.
# It also supports an optional third argument for those times when you want to
# supply a target image.

# -works- but slow!

proc Shrink3 {Image coef {TargetImage {}}} {
	# check coef
	if {$coef > 1.0} {
		error "bad coef \"$coef\": should not be greater than 1.0"
	}
	# get the old image content
	set Width [image width $Image]
	set Height [image height $Image]
	if {$Width == 0 || $Height == 0} {
		error "bad image"
	}
	if {$TargetImage eq ""} {
		# create new image
		set image [image create photo]
	} else {
		set image $TargetImage
	}
	if {abs($coef - 1.0) < 1.e-4} {
		$image copy $Image
		return $image
	}
	set Factor [expr {double($Width)*$Height}]
	# Extract the data from the source - experiment indicates that this is the fastest way
	foreach row [$Image data] {
		set rdata {}
		foreach pixel $row {
			lappend rdata [scan $pixel "#%2x%2x%2x"]
		}
		lappend DATA $rdata
	}
	# compute the new image content
	set width [expr {round($Width * $coef)}]
	set height [expr {round($Height * $coef)}]
	set ey 0
	set Y2 0
	set cy2 $height
	for {set y 0} {$y < $height} {incr y} {
		# Y1 is the top coordinate in the old image
		set Y1 $Y2
		set cy1 [expr {$height - $cy2}]
		incr ey $Height
		set Y2 [expr {$ey / $height}]
		set cy2 [expr {$ey % $height}]
		if {$Y1 == $Y2} {
			set cy1 $cy2
		}
		set ex 0
		set X2 0
		set cx2 $width
		set row {}
		for {set x 0} {$x < $width} {incr x} {
			set X1 $X2
			set cx1 [expr {$width - $cx2}]
			incr ex $Width
			set X2 [expr {$ex / $width}]
			set cx2 [expr {$ex % $width}]
			if {$X1 == $X2} {
				set cx1 $cx2
			}
			# compute pixel
			set r 0.0
			set g 0.0
			set b 0.0
			for {set Y $Y1} {$Y <= $Y2} {incr Y} {
				# compute y coef
				if {$Y == $Y1} {
					if {$cy1 == 0} continue
					set cy [expr {$cy1>$Height ? $Height : $cy1}]
				} elseif {$Y == $Y2} {
					if {$cy2 == 0} continue
					set cy [expr {$cy2>$Height ? $Height : $cy2}]
				} else {
					set cy $height
				}
				for {set X $X1} {$X <= $X2} {incr X} {
					# compute x coef
					if {$X == $X1} {
						if {$cx1 == 0} continue
						set cx [expr {$cx1>$Width ? $Width : $cx1}]
					} elseif {$X == $X2} {
						if {$cx2 == 0} continue
						set cx [expr {$cx2>$Width ? $Width : $cx2}]
					} else {
						set cx $width
					}
					# weight each initial pixel by cx & cy
					set cxy [expr {$cx * $cy / $Factor}]
					set pixel [lindex $DATA $Y $X]
					set r [expr {$r+([lindex $pixel 0] * $cxy)}]
					set g [expr {$g+([lindex $pixel 1] * $cxy)}]
					set b [expr {$b+([lindex $pixel 2] * $cxy)}]
				}
			}
			lappend row [format "#%02x%02x%02x" \
					[expr {$r>255.0 ? 255 : round($r)}] \
					[expr {$g>255.0 ? 255 : round($g)}] \
					[expr {$b>255.0 ? 255 : round($b)}]]
		}
		lappend data $row
	}
	# fill the new image
	$image blank
	$image put $data
	# return the new image
	return $image
}


proc ScaleImage {img1 targetwidth} {

	set w [image width $img1]
	set ratio [expr {$targetwidth / ($w * 1.0)}]
	set img2 [image create photo]

	if {$ratio >= 1} {
		set f [expr int($ratio)]
		$img2 copy $img1 -zoom $f $f

	} else {
		set f [expr round(1.0 / $ratio)]
		
		# a.) Img package (bad quality):
		$img2 copy $img1 -subsample $f $f

		# test as well the following: 
		# $img2 copy $img1 -shrink
		
		# b.) with procedure (slightly better quality, but slow):
		#     http://wiki.tcl.tk/10504
		# set img2 [Shrink3 $img1 $ratio]
	}

	image delete $img1
	return $img2
}


proc SaveScreenShot {wparent capture_img} {

	# finally, write image to file and we are done...
	set filetypes {
		{"All Image Files" {.gif .png .jpg}}
		{"PNG Images" .png}
	}

	set re {\.(gif|png)$}
	set LASTDIR [pwd]
			
	set file [tk_getSaveFile \
		-parent $wparent -title "Save Image to File" \
		-initialdir $LASTDIR -filetypes $filetypes]
			
	if {$file ne ""} {
			
		if {![regexp -nocase $re $file -> ext]} {
			set ext "png"
			append file ".${ext}"
		}
		
		# -test-
		set scaled_img [ScaleImage $capture_img 1200]

		if {[catch {$scaled_img write $file \
					-format [string tolower $ext]} err]} {
						
			tk_messageBox -title "Error Writing File" \
				-parent $wparent -icon error -type ok \
				-message "Error writing to file \"$file\":\n$err"
		}
	}

	# clear some memory:
	image delete $scaled_img
}



wm withdraw .
set t [toplevel .t]

wm geometry $t "+50+50"

screenshot::screenshot $t.scrnshot \
		-background LightYellow -foreground DarkGreen \
		-alpha 0.5 \
		-width 800 -height 600 \
		-screenshotcommand "SaveScreenShot $t"

		
# default values:
# -showgeometry 1
# -grid 1 -showvalues 1
# -measure pixels
# ...

pack $t.scrnshot -expand true -fill both





