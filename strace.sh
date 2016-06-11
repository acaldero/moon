#!/bin/sh
#set -x

#
# Tracer (version 1.0)
# Alejandro Calderon @ ARCOS.INF.UC3M.ES
# GPL 3.0
#

if [ $# -lt 1 ]; then
    echo "Usage:"
    echo "./"$0" <cmd>"
    exit
fi

strace -T -tt -o strace.txt $*

