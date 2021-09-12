# SPS Performance Review

This repository contains toolset to effortlessly spin-up Grafana+Inlfux stack to analyze performance of Akamai SPS platform.

Pre-requiremets:
* Docker
* Docker-compose

How to run:
1. Take backup of InlfuxDB database from Akamai SPS platform(also previously known as Nominum N2)<br>
   If version of SPS platform predates 19.X, influxdb backup can be taken with following command:<br>
   <i>influxd backup -database n2 -since 2021-09-01T00:00:00Z /tmp/influx-backup</i><br>
   In case of SPS 19.X:<br>
   <i>influxd backup -portable -db n2 -since 2021-09-01T00:00:00Z /tmp/influx-backup</i><br>
2. Pack influxdb backup directory to tar-ball:<br>
   <i>tar -czf /tmp/influx.tar.gz /tmp/influx-backup</i><br>
3. Transfer tar-ball to the host where you plan to run this toolset and create Grafana stack with following command:<br>
   <i>$ bash setup.sh --start \<path to tar-ball\></i> # for SPS 19.X<br>
   <i>$ bash setup.sh --start \<path to tar-ball\> --legacy </i> # for SPS pre-19.X<br>
4. After setup script will finish, you can access grafana web-interface on port 8080 with default credentials admin/admin<br>

When done, environment can be deleted with command:<br>
<i>$ bash setup.sh --stop</i><br>
