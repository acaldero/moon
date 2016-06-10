#!/usr/bin/python -u

import os 
import re 
import sys
import csv
import datetime

ao = {} 
ao[0] = []
ao[1] = []
ao[2] = []

# 0 -> date (uniq)
counter_states = 0
# 0 -> date (uniq)
#counter_clusters = 0

while True:
    line = sys.stdin.readline()
    if not line: break # EOF

    x1 = csv.reader(line)
    x2 = list(x1)

    # "disk";"15:58:21.764842";"0.000009";"open";"/lib/x86_64-linux-gnu/libpthread.so.0"

    l_subsys   = x2[0][0]
    l_date     = x2[2][0]
    l_duration = x2[4][0]
    l_op       = x2[6][0]
    l_file     = x2[8][0]
    try:
       l_size  = x2[10][0]
    except:
       l_size  = 0

    if l_op == 'open':
        ao[l_file]  = ['"' + l_date + '";"' + l_op + '";"' + l_duration + '";'] 
        counter_clusters = datetime.datetime.strptime(l_date, "%H:%M:%S.%f").strftime("%H%M%S%f")

    if l_op == 'openat':
        ao[l_file]  = ['"' + l_date + '";"' + l_op + '";"' + l_duration + '";'] 

    if l_op == 'read':
        if l_file not in ao:
           continue
        ao[l_file] += ['"' + l_date + '";"' + l_op + '";"' + l_duration + '";"' + l_size + '"'] 

    if l_op == 'write':
        if l_file not in ao:
           continue
        ao[l_file] += ['"' + l_date + '";"' + l_op + '";"' + l_duration + '";"' + l_size + '"'] 

    if l_op == 'close':
        if l_file not in ao:
           continue
        ao[l_file] += ['"' + l_date + '";"' + l_op + '";"' + l_duration + '";'] 

        print "subgraph cluster{0} {{".format(counter_clusters)
        print " label=\"{0}\";".format(l_file)
        for y in ao[l_file]:
            print " {0} -> {1} [label=\"{2}\"];".format(counter_states, counter_states+1, y.replace('"','\''))
            counter_states = counter_states + 1
        print "}"
        counter_states   = counter_states + 1

        # delete ao[l_file]
        ao[l_file] = [] 

