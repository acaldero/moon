#!/bin/sh
#set -x

#
# Application Monitoring NetCat (version 1.0)
# Alejandro Calderon @ ARCOS.INF.UC3M.ES
# GPL 3.0
#

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

	./app-mon.py -f json -d 0.3 -p $PID | awk -v port="$PORT" '{
                                                 print "curl -XPOST http://localhost:"port"/moon/appmon/?pretty=true -d \x27"$0"\x27\n";
						 fflush();
					    }' | sh

done

