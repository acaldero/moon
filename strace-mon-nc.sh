#!/bin/sh
#set -x

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

 tail -c +0 -f strace.txt | ./strace-mon.py | ./io-csv2predot.py | awk 'BEGIN {
						    print "HTTP/1.1 200 OK";
						    print "Access-Control-Allow-Origin: *";
						    print "Content-Type: text/event-stream";
						    print "Cache-Control: no-cache";
						    print "";
						  }
						  {
                                                    if ($1 == "}") {
						        print "data: }\n" ;
						        fflush();
                                                    } else {
						        print "data: " $0 ;
						        fflush();
                                                    }
						  }
                                                  END {
						    print "\n";
						    fflush();
                                                  }' | ( nc -l -p $PORT )

done

