#!/bin/sh
#set -x

#
# Node Monitoring NetCat (version 1.0)
# Alejandro Calderon @ ARCOS.INF.UC3M.ES
# GPL 3.0
#

if [ $# -gt 1 ]; then
   echo "Usage: $0 <port>"
   exit
fi

if [ $# -eq 1 ]; then
   PORT=$1
else
   PORT=9999
fi

echo "$0 running on port $PORT..."

while [ 1 ]; do

	./node-mon.py -f json -d 0.5 | awk 'BEGIN {
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

