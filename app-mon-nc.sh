#!/bin/sh

if [ $# -gt 2 ]; then
   echo "Usage: $0 <pid> <port>"
   exit
fi
if [ $# -eq 0 ]; then
   echo "Usage: $0 <pid> <port>"
   exit
fi

if [ $# -eq 2 ]; then
   PID=$1
   PORT=$2
else
   PID=$1
   PORT=9999
fi

echo "$0 running on port $PORT for pid $PID..."

while [ 1 ]; do

	./app-mon.py -f json -d 0.3 -p $PID | awk 'BEGIN { 
						    print "HTTP/1.1 200 OK"; 
						    print "Access-Control-Allow-Origin: *"; 
						    print "Content-Type: text/event-stream"; 
						    print "Cache-Control: no-cache"; 
						    print ""; 
						  } 
						  { 
						    print "data: " $0 "\n";
						    fflush(); 
						  }' | ( nc -l -p $PORT ; killall awk )

done

