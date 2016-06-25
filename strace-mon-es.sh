#!/bin/sh
#set -x

#
# Strace Monitoring NetCat (version 1.0)
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

 tail -c +0 -f strace.txt | ./strace-mon.py -f json | awk -v port="$PORT" '{
                                                 print "curl -XPOST http://localhost:"port"/moon/strace/?pretty=true -d \x27"$0"\x27\n";
						 fflush();
					    }' | sh

done

