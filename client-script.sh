#!/usr/bin/env bash
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games
export PATH

DIR=$1
mkdir $DIR

iwconfig wlan0 > $DIR/iwconfig.log
iw dev wlan0 link > $DIR/iwlink.log
iw dev wlan0 station dump > $DIR/iwstationdump.log

iperf3 -s -D -I $DIR/iperf.pid
