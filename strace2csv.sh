#!/usr/bin/python

# 
# Import packages
# 

import os 
import re 
import sys


# 
# Names (an), Types (ak), and Operations (ao) 
# 

an = {} 
an[0] = '"stdin"'
an[1] = '"stdout"'
an[2] = '"stderr"'

ak = {} 
ak[0] = ak[1] = ak[2] = 'disk'

ao = {}
ao[0] = ao[1] = ao[2] = []


#
# strace -> csv
#

for line in sys.stdin:

    x = re.split(r'\s*[<>(),=\n]\s*', line)
    l_date = x[0].split()[0]
    l_op   = x[0].split()[1]


    #
    # Start: I/O
    #

    if l_op == 'open':
        try:
           key = int(x[4])
        except ValueError:
           try:
              key = int(x[5])
           except ValueError:
              continue
        except KeyError:
           continue

        ak[key] = 'disk'
        an[key] = x[1] 
        ao[key] = ['"disk";"' + l_date + '";"' + x[len(x)-2] + '";"' + l_op + '";' + x[1]] 


    if l_op == 'openat':
        if x[5] == '-1 EACCES' or x[5] == '-1 ENOENT':
           continue

        try:
           key = int(x[5])
        except ValueError:
           continue

        ak[key] = 'disk'
        an[key] = x[2] 
        ao[key] = ['"disk";"' + l_date + '";"' + x[len(x)-2] + '";"' + l_op + '";' + x[2]] 


    #
    # Start: network
    #

    if l_op == 'socket':
        try:
           key = int(x[5])
           l_duration = x[-2]
        except ValueError:
           continue

        ak[key]  = 'network'
        an[key]  = key 
        ao[key]  = ['"network";"' + l_date + '";"' + l_duration + '";"' + l_op + '";"' + str(key) + '"'] 


    if l_op == 'connect':
        try:
           key = int(x[1])
           l_duration = x[-2]
           l_notation = x[4]
        except ValueError:
           continue

        l_dest = ''
        if l_notation == 'sun_path':
           l_dest = x[5]
        if l_notation == 'sin_port':
           l_dest = x[10] + ':' + x[6]
        l_dest = l_dest.replace("\"","")
        l_dest = l_dest.replace("}","")

        ao[key] += ['"network";"' + l_date + '";"' + l_duration + '";"' + l_op + '";"' + str(key) + '";"' + l_dest + '"'] 


    #
    # Send/Receive data
    #

    if l_op == 'recvfrom':
        try:
           key = int(x[1])
           l_duration = x[-2]
           l_dest = 'NULL'
           if x[5] != 'NULL':
              l_dest = x[13] + ':' + x[9]
              l_dest = l_dest.replace("\"","")
        except ValueError:
           continue

        if key not in ao:
           continue

        ao[key] += ['"network";"' + l_date + '";"' + l_duration + '";"' + l_op + '";"' + str(an[key]) + '";"' + l_dest + '"']


    if l_op == 'sendmmsg':
        try:
           key = int(x[1])
           l_duration = x[-2]
        except ValueError:
           continue

        if key not in ao:
           continue

        ao[key] += ['"network";"' + l_date + '";"' + l_duration + '";"' + l_op + '";"' + str(an[key]) + '";"' + '"'] 


    if l_op == 'read':
        try:
           key = int(x[1])
           l_duration = x[-2]
        except ValueError:
           continue

        if x[len(x)-5] == '-1 EISDIR':
           continue
        if key not in ao:
           continue

        ao[key] += [ '"' + ak[key] + '";"' + l_date + '";"' + x[len(x)-2] + '";"' + l_op + '";' + str(an[key]) + ';"' + x[len(x)-3] + '"'] 


    if l_op == 'write':
        try:
           key = int(x[1])
           l_duration = x[-2]
        except ValueError:
           continue

        if x[len(x)-5] == '-1 EISDIR':
           continue
        if key not in ao:
           continue

        ao[key] += [ '"' + ak[key] + '";"' + l_date + '";"' + l_duration + '";"' + l_op + '";' + str(an[key]) + ';"' + x[len(x)-3] + '"'] 


    #
    # Stop
    #

    if l_op == 'close':
        try:
           key = int(x[1])
           l_duration = x[-2]
           l_name = str(an[key])
           l_name = l_name.replace("\"","")
        except ValueError:
           continue
        except KeyError:
           continue

        if key not in ao:
           continue

        ao[key] += [ '"' + ak[key] + '";"' + l_date + '";"' + l_duration + '";"' + l_op + '";"' + l_name + '"' ]

        for y in ao[key]:
            print "{0}".format(y)

        ak[key] = ''
        an[key] = ''
        ao[key] = [] 

# print "\n"

for key in ao:
    if an[key] != '':
       for y in ao[key]:
           print "{0}".format(y)


