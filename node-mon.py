#!/usr/bin/python -u

#
# Node Monitoring (version 1.5)
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


def mon():
        global last_info_m_time, last_info_m_usage
        global last_info_c_time, last_info_c_usage
        global last_info_n_time, last_info_n_usage
        global last_info_d_time, last_info_d_usage
        global format

	info_time = time.time() 

        # 1.- Check Memory
	meminfo = psutil.virtual_memory()
        info_m_usage = meminfo[2]

        info_delta = math.fabs(info_m_usage - last_info_m_usage) 
        if info_delta >= delta:
            data = { "type":          "memory", 
                     "timestamp":     info_time,
                     "timedelta":     info_time - last_info_m_time,
                     "usagepercent":  last_info_m_usage,
                     "usageabsolute": meminfo[0] - meminfo[1] } ; 
            print_record(format, data)

            last_info_m_time  = info_time
            last_info_m_usage = info_m_usage

        # 2.- Check CPU 
	cpuinfo = psutil.cpu_percent()
        info_c_usage = cpuinfo 

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
        netinfo = psutil.net_io_counters()
        info_n_usage = (netinfo.bytes_sent + netinfo.bytes_recv) / (1024*1024)

        info_delta = 100 * math.fabs(info_n_usage - last_info_n_usage) / (last_info_n_usage + 1)
        if info_delta >= delta:
            data = { "type":           "network", 
                     "timestamp":      info_time,
                     "timedelta":      info_time - last_info_n_time,
                     "usageabsolute":  last_info_n_usage } ; 
            print_record(format, data)

            last_info_n_time  = info_time
            last_info_n_usage = info_n_usage

        # 4.- Check Disk
        diskinfo = psutil.disk_io_counters()
        info_d_usage = (diskinfo.read_bytes + diskinfo.write_bytes) / (1024*1024)

        info_delta = 100 * math.fabs(info_d_usage - last_info_d_usage) / (last_info_d_usage + 1)
        if info_delta >= delta:
            data = { "type":           "disk", 
                     "timestamp":      info_time,
                     "timedelta":      info_time - last_info_d_time,
                     "usageabsolute":  last_info_d_usage } ; 
            print_record(format, data)

            last_info_d_time  = info_time
            last_info_d_usage = info_d_usage

        # 5.- Set next checking...
	threading.Timer(rrate, mon).start()


def main(argv):
        global format, rrate, delta 

        # get parameters
        try:
           opts, args = getopt.getopt(argv,"h:f:r:d:",["format=","rate=","delta="])
        except getopt.GetoptError:
           print 'node-mon.py -f <format> -r <rate> -d <delta>'
           sys.exit(2)

        for opt, arg in opts:
            if opt == '-h':
               print 'node-mon.py -f <format> -r <rate> -d <delta>'
               sys.exit()
            elif opt in ("-f", "--format"):
               format  = str(arg)
            elif opt in ("-r", "--rate"):
               rrate = float(arg)
            elif opt in ("-d", "--delta"):
               delta = float(arg)

	# start monitoring
	threading.Timer(rrate, mon).start()


# initial values
start_time = time.time()

last_info_m_time  = start_time
meminfo = psutil.virtual_memory()
last_info_m_usage = meminfo[2]

last_info_c_time  = start_time
cpuinfo = psutil.cpu_percent()
last_info_c_usage = cpuinfo 

last_info_n_time  = start_time
netinfo = psutil.net_io_counters()
last_info_n_usage = (netinfo.bytes_sent + netinfo.bytes_recv) / (1024*1024*1024)

last_info_d_time  = start_time
diskinfo = psutil.disk_io_counters()
last_info_d_usage = (diskinfo.read_bytes + diskinfo.write_bytes) / (1024*1024)

format = 'csv'
rrate  = 1.0 
delta  = 0.5

if __name__ == "__main__":
   main(sys.argv[1:])

