# moon: Monitoring Tools
Quick Start

A.- Node monitoring

    Local monitoring:
       1) ./node-mon.py
       
    Remote monitoring:
       1) ./node-mon-nc.sh &
       2) firefox view-gc-timeline.html &
       3) Fill the IP address and the port (default 9999)
       4) click on the 'start' button
 
B.- Application monitoring

    Local monitoring:
       1) ./app-mon.py
       
    Remote monitoring:
       1) ./app-mon-nc.sh <pid> &
       2) firefox view-gc-timeline.html &
       3) Fill the IP address and the port (default 9999)
       4) click on the 'start' button 
 
    <pid> has to be a valid process identification (pid).
 
C.- Strace monitoring

    Local monitoring:
       1) ./strace.sh <application and parameters> &
       2) tail -c +0 -f strace.txt | ./strace-mon.py 
       
    Remote monitoring (a):
       1) ./strace.sh <application and parameters> &
       2) ./strace-mon-nc.sh &
       3) firefox view-gc-timeline-strace.html &
       4) Fill the IP address and the port (default 9999)
       5) click on the 'start' button

    Remote monitoring (b):
       1) ./strace.sh <application and parameters> &
       2) ./strace-mon-nc.sh &
       3) firefox view-viz-timegroup-strace.html &
       4) Fill the IP address and the port (default 9999)
       5) click on the 'start' button

    Both options are valid (Google Chart or Viz.js)
 
