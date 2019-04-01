#!/usr/bin/env bash

# IP of the client
CLIENT=10.10.10.16

trap ctrl_c INT

# enable CTRL-C to exit
function ctrl_c() {
  echo "Exiting ..."
  pkill -F hostapd.pid
  rm hostapd.pid
  ssh -i /home/pi/.ssh/id_rsa pi@$CLIENT pkill -F $DIR/iperf.pid
  exit -1
}

# only run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root."
  exit -1
fi


# create a directory with the current date when no argument is given
if [ -z "$1" ]; then DIR=$PWD/logs/$(date +%Y_%m_%d_%H_%M_%S); else DIR=$PWD/logs/$1; fi
mkdir -p $DIR

# save the hostapd.conf which will be used
cp hostapd.conf $DIR/
diff -u hostapd-sample.conf hostapd.conf > $DIR/hostapd-diff.log

echo "Stopping hostapd via systemctl."
systemctl stop hostapd

sleep 2
echo "Starting hostapd daemon."
hostapd -d -t -B -P hostapd.pid -f $DIR/hostapd.log hostapd.conf

if [ ! -f "hostapd.pid" ]; then
    echo "❌ Hostapd daemon failed - check 'hostapd.config' and the log for errors."
    exit -1
fi

echo "Waiting 15 seconds for clients to connect ..."
sleep 15

if ping -c 1 $CLIENT > /dev/null; then
  echo "$CLIENT is reachable."
else
  echo "$CLIENT not reachable yet. Trying in 30 seconds again ..."
  sleep 30
  if ping -c 1 $CLIENT > /dev/null; then
    echo "$CLIENT is reachable."
  else
    echo "$CLIENT not reachable. Exiting ..."
    pkill -F hostapd.pid
    rm hostapd.pid
    exit -1
  fi
fi

# store various wireless information
iwconfig wlan0 > $DIR/iwconfig.log
iw dev wlan0 link > $DIR/iwlink.log
iw dev wlan0 station dump > $DIR/iwstationdump.log

# starting iperf3 server on client: AP -> client transmission
echo "Executing 'client-script.sh' on $CLIENT."
ssh -i /home/pi/.ssh/id_rsa pi@$CLIENT 'bash -s' < client-script.sh $DIR
sleep 2

echo "TCP iperf3 measurement ..."
iperf3 -c $CLIENT -i 0.1 -t 10 -J --logfile $DIR/iperf3-TCP.json
sleep 1
echo "UDP iperf3 measurement ..."
iperf3 -c $CLIENT -u -b 4G -i 0.1 -t 10 -J --logfile $DIR/iperf3-UDP.json
sleep 1

echo "TCP iperf3 reverse measurement ..."
iperf3 -R -c $CLIENT -i 0.1 -t 10 -J --logfile $DIR/iperf3-TCP-R.json
sleep 1

echo "UDP iperf3 reverse measurement ..."
iperf3 -R -c $CLIENT -u -b 4G -i 0.1 -t 10 -J --logfile $DIR/iperf3-UDP-R.json


echo "Finished iperf3 measurement. Stopping iperf server on $CLIENT."
ssh -i /home/pi/.ssh/id_rsa pi@$CLIENT pkill -F $DIR/iperf.pid

echo "Copying logs from $CLIENT to $DIR/client-logs/."
mkdir $DIR/client-logs/
scp -i /home/pi/.ssh/id_rsa pi@$CLIENT:$DIR/*.log $DIR/client-logs/ > /dev/null


echo "Stopping hostapd daemon."
pkill -F hostapd.pid
rm hostapd.pid

sudo chown -R pi:pi $DIR

echo "Plotting iperf3 measurements."
/bin/su -c "python3 ~/hostapd-config-test/plot-iperf.py $DIR" - pi


echo "fin 🌈"
