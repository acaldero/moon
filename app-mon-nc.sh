#!/bin/sh

if [ $# -ne 1 ]; then
   echo "Usage: $0 <port> <pid>"
   exit
fi

while [ 1 ]; do

	./app-mon.py -f json -d 0.3 -p $2 | awk 'BEGIN { 
						    print "HTTP/1.1 200 OK"; 
						    print "Access-Control-Allow-Origin: *"; 
						    print "Content-Type: text/event-stream"; 
						    print "Cache-Control: no-cache"; 
						    print ""; 
						  } 
						  { 
						    print "data: " $0 "\n";
						    fflush(); 
						  }' | ( nc -l -p $1 ; killall awk )

done

