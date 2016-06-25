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
   PORT=9200
fi

echo "$0 running on port $PORT..."

while [ 1 ]; do

	./node-mon.py -f json -d 0.5 | awk -v port="$PORT" '{
                                                 print "curl -XPOST http://localhost:"port"/moon/nodemon/?pretty=true -d \x27"$0"\x27\n";
						 fflush();
					    }' | sh

done

