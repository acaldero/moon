#!/usr/bin/python

#
# strace2csv (version 2.2)
# Alejandro Calderon @ ARCOS.INF.UC3M.ES
# GPL 3.0
#

# 
# Import packages
# 

import os 
import re 
import sys
import math
import time
import getopt


def print_records ( format, data ):
        if (format == 'json'):
            for y in data:
 	        print y

        if (format == 'csv'):
            for y in data:
                for item in y:
                    if item != 'type':
                       sys.stdout.write('"' + str(y[item]) + '";')
                print '"' + y['type'] + '"'


def strace2info():
        global format

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

                data = { "type":      "disk", 
                         "date":      l_date,
                         "x_2":       x[len(x)-2],
                         "op":        l_op,
                         "x1":        x[1] } ; 

		ak[key] = 'disk'
		an[key] = x[1] 
		ao[key] = [ data ]


	    if l_op == 'openat':
		try:
		   key = int(x[5])
		except ValueError:
		   continue

                data = { "type":      "disk", 
                         "date":      l_date,
                         "x_2":       x[len(x)-2],
                         "op":        l_op,
                         "x2":        x[2] } ; 

		ak[key] = 'disk'
		an[key] = x[2] 
		ao[key] = [ data ]


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
                            "key":       str(an[key]),
                            "dest":      l_dest } ; 
		except ValueError:
		   continue

		ao[key] += [ data ]


	    if l_op == 'sendmmsg':
		try:
		   key = int(x[1])
		   if key not in ao:
		      continue

                   data = { "type":      "network", 
                            "date":      l_date,
                            "duration":  x[-2],
                            "op":        l_op,
                            "an_key":    str(an[key]) } ; 
		except ValueError:
		   continue

		ao[key] += [ data ]


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
                         "an_key":    str(an[key]),
                         "amount":    x[len(x)-3] } ; 
		ao[key] += [ data ]


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
                         "an_key":    str(an[key]),
                         "amount":    x[len(x)-3] } ; 
		ao[key] += [ data ]


	    #
	    # Stop
	    #

	    if l_op == 'close':
		try:
		   key = int(x[1])
		   if key not in ao:
		      continue

		   l_name = str(an[key])
		   l_name = l_name.replace("\"","")

                   data = { "type":      ak[key], 
                            "date":      l_date,
                            "duration":  x[-2],
                            "op":        l_op,
                            "name":      l_name } ; 
		except ValueError:
		   continue
		except KeyError:
		   continue

		ao[key] += [ data ]

                print_records(format, ao[key])

		ak[key] = ''
		an[key] = ''
		ao[key] = [] 

	# print "\n"

	for key in ao:
	    if an[key] != '':
               print_records(format, ao[key])


def main(argv):
        global format

        # get parameters
        try:
           opts, args = getopt.getopt(argv,"hf",["format="])
        except getopt.GetoptError:
           print 'strace2csv.sh -f <format>'
           sys.exit(2)

        for opt, arg in opts:
            if opt == '-h':
               print 'app2csv.sh -f <format>'
               sys.exit()
            elif opt in ("-f", "--format"):
               format  = str(arg)

	# start transformation
	strace2info()


# initial values
format = 'csv'

if __name__ == "__main__":
   main(sys.argv[1:])

