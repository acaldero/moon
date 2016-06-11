#!/usr/bin/python -u

#
# Strace Monitoring (version 2.5)
# Alejandro Calderon @ ARCOS.INF.UC3M.ES
# GPL 3.0
#

import os 
import re 
import sys
import math
import time
import getopt
import json


def print_records ( format, data, okeys ):
        if (format == 'json'):
            print(json.dumps(data))

        if (format == 'csv'):
            u = 0
            while u < len(data):
                o = []
                for item in okeys[u]:
                     o.append('"' + str(data[u][item]) + '"')
                print ';'.join(o)
                u = u + 1


def strace2info():
        global format

	# 
	# Names (an), Types (ak), Operations (ao), and Keys (ok)
	# 

	an = {} 
	an[0] = 'stdin'
	an[1] = 'stdout'
	an[2] = 'stderr'

	ak = {} 
	ak[0] = ak[1] = ak[2] = 'disk'

	ao = {}
	ao[0] = ao[1] = ao[2] = []

	ok = {}
	ok[0] = ok[1] = ok[2] = []


	#
	# strace -> csv/json
	#

	while True:
	    line = sys.stdin.readline()
	    if not line: break # EOF

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

		l_name = x[1].replace("\"","")
                data = { "type":      "disk", 
                         "date":      l_date,
                         "duration":  x[len(x)-2],
                         "op":        l_op,
                         "name":      l_name } ; 

		ak[key] = 'disk'
		an[key] = l_name
		ao[key] = [ data ]
		ok[key] = [ ("type","date","duration","op","name") ]


	    if l_op == 'openat':
		try:
		   key = int(x[5])
		except ValueError:
		   continue

		l_name = x[2].replace("\"","")
                data = { "type":      "disk", 
                         "date":      l_date,
                         "duration":  x[len(x)-2],
                         "op":        l_op,
                         "name":      l_name } ; 

		ak[key] = 'disk'
		an[key] = l_name
		ao[key] = [ data ]
		ok[key] = [ ("type","date","duration","op","name") ]


	    #
	    # Start: network
	    #

	    if l_op == 'socket':
		try:
		   key  = int(x[5])
                   data = { "type":      "network", 
                            "date":      l_date,
                            "duration":  x[-2],
                            "op":        l_op,
                            "key":       str(key) } ; 
		except ValueError:
		   continue

		ak[key] = 'network'
		an[key] = key 
		ao[key] = [ data ]
		ok[key] = [ ("type","date","duration","op","key") ]


	    if l_op == 'connect':
		try:
		   key = int(x[1])
		   l_dest = ''
		   l_notation = x[4]

		   if l_notation == 'sun_path':
		      l_dest = x[5]
   		   if l_notation == 'sin_port':
		      l_dest = x[10] + ':' + x[6]
		   l_dest = l_dest.replace("\"","")
		   l_dest = l_dest.replace("}","")

                   data = { "type":      "network", 
                            "date":      l_date,
                            "duration":  x[-2],
                            "op":        l_op,
                            "key":       str(key),
                            "dest":      l_dest } ; 
		except ValueError:
		   continue

		ao[key] += [ data ]
		ok[key] += [ ("type","date","duration","op","key","dest") ]


	    #
	    # Send/Receive data
	    #

	    if l_op == 'recvfrom':
		try:
		   key = int(x[1])
		   if key not in ao:
		      continue

		   l_dest = 'NULL'
		   if x[5] != 'NULL':
		      l_dest = x[13] + ':' + x[9]
		      l_dest = l_dest.replace("\"","")

                   data = { "type":      "network", 
                            "date":      l_date,
                            "duration":  x[-2],
                            "op":        l_op,
                            "name":      an[key],
                            "dest":      l_dest } ; 
		except ValueError:
		   continue

		ao[key] += [ data ]
		ok[key] += [ ("type","date","duration","op","name","dest") ]


	    if l_op == 'sendmmsg':
		try:
		   key = int(x[1])
		   if key not in ao:
		      continue

                   data = { "type":      "network", 
                            "date":      l_date,
                            "duration":  x[-2],
                            "op":        l_op,
                            "name":      an[key] } ; 
		except ValueError:
		   continue

		ao[key] += [ data ]
		ok[key] += [ ("type","date","duration","op","name") ]


	    if l_op == 'read':
		try:
		   key = int(x[1])
		   if key not in ao:
		      continue
		except ValueError:
		   continue

		if x[len(x)-5] == '-1 EISDIR':
		   continue

                data = { "type":      ak[key], 
                         "date":      l_date,
                         "duration":  x[-2],
                         "op":        l_op,
                         "name":      an[key],
                         "amount":    x[len(x)-3] } ; 

		ao[key] += [ data ]
		ok[key] += [ ("type","date","duration","op","name","amount") ]


	    if l_op == 'write':
		try:
		   key = int(x[1])
		   if key not in ao:
		      continue
		except ValueError:
		   continue

		if x[len(x)-5] == '-1 EISDIR':
		   continue

                data = { "type":      ak[key], 
                         "date":      l_date,
                         "duration":  x[-2],
                         "op":        l_op,
                         "name":      an[key],
                         "amount":    x[len(x)-3] } ; 

		ao[key] += [ data ]
		ok[key] += [ ("type","date","duration","op","name","amount") ]


	    #
	    # Stop
	    #

	    if l_op == 'close':
		try:
		   key = int(x[1])
		   if key not in ao:
		      continue

                   data = { "type":      ak[key], 
                            "date":      l_date,
                            "duration":  x[-2],
                            "op":        l_op,
                            "name":      an[key] } ; 
		except ValueError:
		   continue
		except KeyError:
		   continue

		ao[key] += [ data ]
		ok[key] += [ ("type","date","duration","op","name") ]

                print_records(format, ao[key], ok[key])

		ak[key] = ''
		an[key] = ''
		ao[key] = [] 
		ok[key] = [] 


	    if l_op == 'dup2':
		try:
		   key1 = int(x[1])
		   key2 = int(x[2])
		   if key1 not in ao:
		      continue

                   data = { "type":      ak[key1],
                            "date":      l_date,
                            "duration":  x[-2],
                            "op":        l_op,
                            "name":      an[key1] } ; 
		except ValueError:
		   continue
		except KeyError:
		   continue

		ao[key1] += [ data ]
		ok[key1] += [ ("type","date","duration","op","name") ]

                print_records(format, ao[key1], ok[key1])

		ak[key2] = ak[key1]
		an[key2] = an[key1]
		ao[key2] = ao[key1]
		ok[key2] = ok[key1] 

	# print "\n"

	for key in ao:
	    if an[key] != '':
               print_records(format, ao[key], ok[key])


def main(argv):
        global format

        # get parameters
        try:
           opts, args = getopt.getopt(argv,"h:f:",["format="])
        except getopt.GetoptError:
           print 'strace2csv.sh -f <format>'
           sys.exit(2)

        for opt, arg in opts:
            if opt == '-h':
               print 'strace2csv.sh -f <format>'
               sys.exit()
            elif opt in ("-f", "--format"):
               format  = str(arg)

	# start transformation
	strace2info()


# initial values
format = 'csv'

if __name__ == "__main__":
   main(sys.argv[1:])

