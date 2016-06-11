# moon
Monitoring tools (at node/app level)

A.- Node monitoring
 
 1) ./node-mon-nc.sh &
 2) firefox view-gc-timeline.html &
 3) click on the 'start' button
 
B.- Application monitoring
 
 1) ./app-mon-nc.sh <pid> &
 2) firefox view-gc-timeline.html &
 3) click on the 'start' button 
 
 <pid> has to be a valid process identification (pid).
 
C.- Strace monitoring
 
 1) ./strace-mon-nc.sh &
 2) firefox view-gc-timeline-strace.html &
 3) click on the 'start' button
 
 1) ./strace-mon-nc.sh &
 2) firefox view-viz-timegroup-strace.html &
 3) click on the 'start' button

 Both options are valid (Google Chart or Viz.js)
 
