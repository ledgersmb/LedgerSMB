#!/bin/bash

#
# location utils/devel/make_help_icon.sh
#
# This script generates a circular help icon containing the letter "i" with a gradient background
#

gitDirName=`git rev-parse --show-toplevel 2>/dev/null`

OutDir='$gitDirName/UI/js-src/lsmb/theme/claro'
OutFile="$OutDir/help_128.svg"
StartColor='#bcd8f4'
Font='DejaVu Serif'
FontColor='#000000'
FontSize='120px'
Text='i'

Help() {
    cat <<-EOF
	${0##*/} [--bg color|--fg color|--font font|--fs size|--target dir/file.svg|-h|--help] [text]
	    defaults
	        bg      $StartColor
	        fg      $FontColor
	        font    $Font
	        fs      $FontSize
	        target  $OutFile
	        text    $Text
	EOF
    exit 9
}

while (( $# >0 )); do
    case $1 in
        '--bg'    ) shift; StartColor="$1";;
        '--fg'    ) shift; FontColor="$1";;
        '--font'  ) shift; Font="$1";;
        '--fs'    ) shift; FontSize="$1";;
        '--target') shift; OutFile="$1";;
        '-h'      ) shift; Help;;
        '--help'  ) shift; Help;;
    esac
    if (( $# == 1 )); then Text="$1"; fi
    shift
done

Init() {
    local D
    D="${OutFile%/*}" # strip the filename to get a directory
    if ! [[ "$D" == "$OutFile" ]]; then # only make the dir if we stripped a filename off
        mkdir -p "$D"
    fi
}

WriteSVG() {
cat <<-EOF
	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
	<svg
	   xmlns="http://www.w3.org/2000/svg"
	   xmlns:xlink="http://www.w3.org/1999/xlink"
	   id="SVGRoot"
	   version="1.1"
	   viewBox="0 0 128 128"
	   height="128px"
	   width="128px">
	  <defs
	     id="defs815">
	    <linearGradient
	       id="linearGradient1399">
	      <stop
	         id="stop1395"
	         offset="0"
	         style="stop-color:$StartColor;stop-opacity:1;" />
	      <stop
	         id="stop1397"
	         offset="1"
	         style="stop-color:#ffffff;stop-opacity:0.98841697" />
	    </linearGradient>
	    <linearGradient
	       gradientTransform="matrix(1.3574203,0,0,1.3574203,-45.852125,-167.55408)"
	       gradientUnits="userSpaceOnUse"
	       y2="50.153347"
	       x2="106.49409"
	       y1="77.752495"
	       x1="21.794813"
	       id="linearGradient1401"
	       xlink:href="#linearGradient1399" />
	  </defs>
	  <g
	    id="layer1">
	    <circle
	       transform="rotate(108.04813)"
	       r="60.04726"
	       cy="-80.679192"
	       cx="41.022778"
	       id="path1374"
	       style="opacity:1;
	                fill:url(#linearGradient1401);
	                fill-opacity:1;
	                stroke:$StartColor;
	                stroke-width:1;
	                stroke-miterlimit:4;
	                stroke-dasharray:none;
	                stroke-opacity:1" />
	    <text
	        id="text832"
	        y="109.58594"
	        x="40.650391"
	        style=" font-style:normal;
	                font-variant:normal;
	                font-weight:bold;
	                font-stretch:normal;
	                font-family:'$Font';
	                font-variant-ligatures:normal;
	                font-variant-caps:normal;
	                font-variant-numeric:normal;
	                font-feature-settings:normal;
	                font-size:$FontSize;
	                letter-spacing:0px;
	                word-spacing:0px;
	                fill:$FontColor;
	                fill-opacity:1;
	                stroke:none;
	                stroke-width:1
	                text-align:start;
	                writing-mode:lr-tb;
	                text-anchor:start;
	        "
	        >
	        <tspan id="tspan830" style="font-size:$FontSize;">
	        $Text
	        </tspan>
	    </text>
	  </g>
	</svg>
	EOF
}

Init
echo "Generating \"$OutFile\" with content $Text sized @ $FontSize"
WriteSVG > "$OutFile"


