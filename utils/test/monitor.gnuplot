set datafile separator comma
set terminal png
set output outputfile

set title "CPU & Memory usage"

set xdata time
set timefmt "%Y-%m-%dT%H:%M:%S"
#set timefmt "%H:%M:%S"

set key autotitle columnhead # use the first line as title
set ylabel "%" # label for the Y axis
set xlabel "Time" # label for the X axis
set xtics rotate by -45
set format x '%H:%M'

plot filename using 1:2 with lines, '' using 1:3 with lines
