# hostapd-config-test
Script to test different hostapd configs and their performance.

## `measurement.sh`
Main script which starts a hostapd daemon, waits for a client, runs multiple iperf3 measurements and then plots them.

1. Make sure to generate ssh keys before and exchange them with the client.
```bash
ssh-keygen
ssh-copy-id pi@PI3-5GHz-02
```
2. Modify the Client IP in `measurement.sh`

3. Create a `hostapd.conf` with the settings to test (`cp hostapd-sample.conf hostapd.conf`).

4. Start the script: `sudo ./measurement.sh foldername` - where *foldername* is the name of the folder where the logs get stored.

## Requirements

- hostapd
- iperf3 (*on AP and client*)
- python3
- python3-pip
  - matplotlib
  - numpy


### TL;DR:
```
sudo apt-get install hostapd iperf3 python3 python3-pip
pip3 install -r requirements.txt
sudo ./measurement.sh foldername
```

## File descriptions

### `client-script.sh`
Script which gets executed on the client (which connects to the AP). Please configure the wpa-supplicant on the client before.

### `plot-iperf.py`
Python script to plot the json logfiles of iperf3 (uses matplotlib).


### `hostapd-sample.conf`
Sample hostapd config with the bare minimum settings to create an 802.11ac (5 GHz) AP on RPi3B+.
