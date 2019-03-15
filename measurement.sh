#!/usr/bin/env bash
trap ctrl_c INT

function ctrl_c() {
  echo "Exiting ..."
  pkill -F hostapd.pid
  rm hostapd.pid
  ssh -i /home/pi/.ssh/id_rsa pi@$CLIENT pkill -F $DIR/iperf.pid
  exit -1
}

if [ "$EUID" -ne 0 ]
  then echo "Please run as root."
  exit -1
fi


CLIENT=10.10.10.16

DIR=$PWD/logs/$1
mkdir logs/$1

# save upcoming hostapd.conf
cp hostapd.conf logs/$1/
diff -u hostapd.conf hostapd-sample.conf > $DIR/diff.txt

echo "Stopping hostapd via systemctl."
systemctl stop hostapd

sleep 2
echo "Starting hostapd daemon."
hostapd -d -t -B -P hostapd.pid -f $DIR/hostapd.log hostapd.conf


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
/bin/su -c "python3 ~/measurement-script/plot-iperf.py $DIR" - pi



echo "fin 🌈"
