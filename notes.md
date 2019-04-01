# 802.11ac on the Raspberry Pi 3B+ - Notes

## Hardware related points

- Wireless circuity:
	https://blog.pimoroni.com/a-deep-dive-into-the-raspberry-pi-3-b-hardware/
- There’s no MIMO. Single Antenna.
- Wireless Ship Datasheet (Cypress43455 or bcm43455c0)
  - [Datasheet](https://www.cypress.com/file/358916/download)
  - Key Features
    - Supports 20, 40, and 80 MHz channels with optional SGI (256 QAM modulation).
    - IEEE 802.11h 5 GHz Extensions
    - IEEE 802.11e QoS Enhancements 
- For best usage aim for a 2.4A capable power supply
  - [more Information](https://www.raspberrypi.org/documentation/hardware/raspberrypi/power/README.md)

- Capabilities according to `iw phy`
```
>> iw phy
Capabilities: 0x1062
			HT20/HT40
			Static SM Power Save
			RX HT20 SGI
			RX HT40 SGI
			No RX STBC
			Max AMSDU length: 3839 bytes
			DSSS/CCK HT40
		Maximum RX AMPDU length 65535 bytes (exponent: 0x003)
		Minimum RX AMPDU time spacing: 16 usec (0x07)
		HT TX/RX MCS rate indexes supported: 0-7
		VHT Capabilities (0x00001020):
			Max MPDU length: 3895
			Supported Channel Width: neither 160 nor 80+80
			short GI (80 MHz)
			SU Beamformee
		VHT RX MCS set:
			1 streams: MCS 0-9
			2 streams: not supported
			3 streams: not supported
			4 streams: not supported
			5 streams: not supported
			6 streams: not supported
			7 streams: not supported
			8 streams: not supported
		VHT RX highest supported: 0 Mbps
		VHT TX MCS set:
			1 streams: MCS 0-9
			2 streams: not supported
			3 streams: not supported
			4 streams: not supported
			5 streams: not supported
			6 streams: not supported
			7 streams: not supported
			8 streams: not supported
		VHT TX highest supported: 0 Mbps
		Bitrates (non-HT):
			* 6.0 Mbps
			* 9.0 Mbps
			* 12.0 Mbps
			* 18.0 Mbps
			* 24.0 Mbps
			* 36.0 Mbps
			* 48.0 Mbps
			* 54.0 Mbps
		Frequencies:

		    [...]

```

- Turn off power saving mode
  - `iw dev wlan0 set power_save off`

- Driver
  - `DRIVER=brcmfmac`

- Monitoring mode is by default not possible
  - can be enabled by firmware Patching
    - [seemoo-lab/bcm-rpi3](https://github.com/seemoo-lab/bcm-rpi3)
    - [seemoo-lab/nexmon](https://github.com/seemoo-lab/nexmon)


## Hostapd configuration

Hostapd is the software which enables the access point.
- https://wiki.gentoo.org/wiki/Hostapd


Example hostapd with explanations in the comments
- [1] https://w1.fi/cgit/hostap/plain/hostapd/hostapd.conf


**For details of the possible settings please refer to [[1]](https://w1.fi/cgit/hostap/plain/hostapd/hostapd.conf) or the `hostapd-all-settings.conf` in this repository.**
- Always make sure so set the channel manually as the Automatic Channel Selection (ACS) is currently not working in the 5 GHz band.
- wmm (QoS) enabled is recommended for ht and vht
```
wmm_enabled=1
```

#### enable HT 802.11n
```
channel=36
ieee80211n=1
ht_capab=[HT40+]
```

where `HT40+` or `HT40-` indicate the primary channel.


#### enable HT 802.11ac
```
channel=36
ieee80211n=1
ht_capab=[HT40+]
```

#### enable VHT 802.11ac
```
channel=36
ieee80211ac=1
ht_capab=[HT40+]
vht_capab=[SHORT-GI-80]
vht_oper_chwidth=1
vht_oper_centr_freq_seg0_idx=42
```
possible `vht_capab`:`[MAX-MPDU-3895][SHORT-GI-80][SU-BEAMFORMEE]`


**For more possible options please refer to the output of `iw phy` or the logs from the `logs.tar.gz`. The hostapd documentation ([[1]](https://w1.fi/cgit/hostap/plain/hostapd/hostapd.conf)) gives an overview of theoretical options with a brief explanation.**


## Miscellaneous

- Current issues with 5 GHz on RPi3B+
  - https://github.com/raspberrypi/linux/issues/2619
- Driver Wiki
  - https://wireless.wiki.kernel.org/en/users/drivers/ath10k/configuration
- Explanations on OpenWRT:
  - https://openwrt.org/docs/guide-user/network/wifi/basic
- To enable an AP & DHCP Server, follow this guide - skip bridging:
  - https://www.raspberrypi.org/documentation/configuration/wireless/access-point.md
- iperf measurements:
  - https://www.phoronix.com/scan.php?page=article&item=raspberry-pi3bplus-wifi&num=2
  - https://raspberrypi.stackexchange.com/questions/83873/how-to-improve-wireless-throughput-on-rpi-3-b-in-ap-mode
