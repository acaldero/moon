#!/usr/bin/python -u

#
# Application Monitoring (version 1.5)
# Alejandro Calderon @ ARCOS.INF.UC3M.ES
# GPL 3.0
#

import math
import time
import psutil
import threading
import multiprocessing
import subprocess
import os
import sys
import getopt
import json


def print_record ( format, data ):
        try:
            if (format == 'json'):
                print(json.dumps(data))

            if (format == 'csv'):
                for item in data:
                    if item != 'type':
                       sys.stdout.write('"' + str(data[item]) + '";')
                print '"' + data['type'] + '"'

            sys.stdout.flush()

        except IOError, e:
            sys.exit()


def mon ():
        global format, rrate, delta, p_id, p_obj
        global last_info_m_time, last_info_m_usage
        global last_info_c_time, last_info_c_usage
        global last_info_n_time, last_info_n_usage
        global last_info_d_time, last_info_d_usage

	info_time = time.time() 

        # 1.- Check Memory
        info_m_usage = p_obj.memory_percent(memtype="vms")

        info_delta = math.fabs(info_m_usage - last_info_m_usage) 
        if info_delta >= delta:
            data = { "type":          "memory", 
                     "timestamp":     info_time,
                     "timedelta":     info_time - last_info_m_time,
                     "usagepercent":  last_info_m_usage,
                     "usageabsolute": p_obj.memory_info()[1] } ; 
            print_record(format, data)

            last_info_m_time  = info_time
            last_info_m_usage = info_m_usage

        # 2.- Check CPU 
        info_c_usage = p_obj.cpu_percent()

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

            # CPU freq * time * CPU usage * # cores
            data = { "type":          "compute", 
                     "timestamp":     info_time,
                     "cpufreq":       info_cpufreq,
                     "timedelta":     info_time - last_info_c_time,
                     "usagepercent":  last_info_c_usage,
                     "usageabsolute": info_cpufreq * (info_time - last_info_c_time) * last_info_c_usage * info_ncores,
                     "ncores":        info_ncores } ; 
            print_record(format, data)

            last_info_c_time  = info_time
            last_info_c_usage = info_c_usage

        # 3.- Check Network
        netinfo = p_obj.connections()
        info_n_usage = len(netinfo)

        info_delta = math.fabs(info_n_usage - last_info_n_usage)
        if info_delta > 0:
            # connections
            data = { "type":          "network", 
                     "timestamp":     info_time,
                     "timedelta":     info_time - last_info_n_time,
                     "usageabsolute": last_info_n_usage } ; 
            print_record(format, data)

            last_info_n_time  = info_time
            last_info_n_usage = info_n_usage

        # 3.- Set next checking...
	threading.Timer(rrate, mon).start()


def main(argv):
        global format, rrate, delta, p_id, p_obj
        global last_info_m_usage, last_info_c_usage, last_info_n_usage, last_info_d_usage

        # get parameters
        try:
           opts, args = getopt.getopt(argv,"h:f:r:d:p:",["format=","rate=","delta=","pid="])
        except getopt.GetoptError:
           print 'app-mon.py -f <format> -r <rate> -d <delta> -p <pid>'
           sys.exit(2)

        for opt, arg in opts:
            if opt == '-h':
               print 'app-mon.py -f <format> -r <rate> -d <delta> -p <pid>'
               sys.exit()
            elif opt in ("-f", "--format"):
               format  = str(arg)
            elif opt in ("-p", "--pid"):
               p_id  = int(arg)
            elif opt in ("-r", "--rate"):
               rrate = float(arg)
            elif opt in ("-d", "--delta"):
               delta = float(arg)

        # get proccess object from pid
        p_obj = psutil.Process(p_id)

        # get initial information
	last_info_m_usage = p_obj.memory_percent()
	last_info_c_usage = p_obj.cpu_percent()
	last_info_n_usage = len(p_obj.connections())

	# start simulation
	threading.Timer(rrate, mon).start()


# initial values
start_time = time.time()

last_info_m_time = start_time
last_info_c_time = start_time
last_info_n_time = start_time

format = 'csv'
rrate  = 1.0 
delta  = 0.5
p_id   = os.getpid()

if __name__ == "__main__":
   try:
       main(sys.argv[1:])
   except psutil.NoSuchProcess:
       print "app-mon: the execution of process with pid '" + str(p_id) + "' has ended."

