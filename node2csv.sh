#!/usr/bin/python

#
# node2csv (version 1.2)
# Alejandro Calderon @ ARCOS.INF.UC3M.ES
# GPL 3.0
#

import math
import time
import psutil
import threading
import multiprocessing
import subprocess
import sys
import getopt


def mon():
        global last_info_m_time, last_info_m_usage
        global last_info_c_time, last_info_c_usage
        global last_info_n_time, last_info_n_usage

        # 1.- Get data
	info_time      = time.time() 
	info_timestamp = info_time - start_time

	meminfo = psutil.virtual_memory()
        info_m_usage = meminfo[2]

	cpuinfo = psutil.cpu_percent()
        info_c_usage = cpuinfo 

        netinfo = psutil.net_io_counters()
        info_n_usage = netinfo.bytes_sent + netinfo.bytes_recv

        # 2.- Check delta
        info_delta = math.fabs(info_m_usage - last_info_m_usage) 
        if info_delta >= delta:
	    print '"memory";"' + '{:.9f}'.format(info_timestamp) + '";"' + \
                                 str(info_time - last_info_m_time) + '";"' + \
                                 str(last_info_m_usage) + '"'

            last_info_m_time  = info_time
            last_info_m_usage = info_m_usage

        # CPU freq * time * CPU usage * # cores
        info_delta = math.fabs(info_c_usage - last_info_c_usage)
        if info_delta >= delta:
            info_ncores  = multiprocessing.cpu_count()

            info_cpufreq = 0.0
            proc = subprocess.Popen(["cat","/proc/cpuinfo"],stdout=subprocess.PIPE)
            out, err = proc.communicate()
            for line in out.split("\n"):
                if "cpu MHz" in line:
                    info_cpufreq = info_cpufreq + float(line.split(":")[1])
            info_cpufreq = info_cpufreq / info_ncores

	    print '"compute";"' + '{:.9f}'.format(info_timestamp) + '";"' + \
                                  str(info_cpufreq) + '";"' + \
                                  str(info_time - last_info_c_time) + '";"' + \
                                  str(last_info_c_usage) + '";"' + \
                                  str(info_ncores) + '"'

            last_info_c_time  = info_time
            last_info_c_usage = info_c_usage

        # send + receive
        info_delta = math.fabs(info_n_usage - last_info_n_usage) / (last_info_n_usage + 1)
        if info_delta >= delta:
	    print '"network";"' + '{:.9f}'.format(info_timestamp) + '";"' + \
                                   str(info_time - last_info_n_time) + '";"' + \
                                   str(last_info_n_usage) + '"'

            last_info_n_time  = info_time
            last_info_n_usage = info_n_usage

        # 3.- Set next checking...
	threading.Timer(rrate, mon).start()


def main(argv):
        global rrate, delta 

        # get parameters
        try:
           opts, args = getopt.getopt(argv,"hr:hd:",["rate=","delta="])
        except getopt.GetoptError:
           print 'node2csv.sh -r <rate> -d <delta>'
           sys.exit(2)

        for opt, arg in opts:
            if opt == '-h':
               print 'node2csv.sh -r <rate> -d <delta>'
               sys.exit()
            elif opt in ("-r", "--rate"):
               rrate = arg
            elif opt in ("-d", "--delta"):
               delta = arg
        # print 'rrate "', rrate
        # print 'delta "', delta

	# start simulation
	mon()


# initial values
last_info_m_time  = 0.0
last_info_m_usage = 0.0
last_info_c_time  = 0.0
last_info_c_usage = 0.0
last_info_n_time  = 0.0
last_info_n_usage = 0.0

start_time = time.time()

rrate = 1.0 
delta = 0.5

if __name__ == "__main__":
   main(sys.argv[1:])

