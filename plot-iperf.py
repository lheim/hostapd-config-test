#!/usr/bin/env python3
import json, sys, glob, os
import matplotlib.pyplot as plt
import numpy as np

def iperf_plot(log_name, logs_iperf):
    fig, ax = [[0 for _ in logs_iperf] for _ in range(2)]

    for index, log in enumerate(logs_iperf):
        json_object = json.load(open(log))
        data_rates = []
        times = []
        rtts = []

        if json_object['start']['test_start']['protocol'] == 'TCP':
            protocol = 'TCP'
        elif json_object['start']['test_start']['protocol'] == 'UDP':
            protocol = 'UDP'
        else:
            protocol = 'unknown'

        if json_object['start']['test_start']['reverse'] == 1:
            reverse = 1
        else:
            reverse = 0


        for interval in json_object['intervals']:
            data_rates.append(interval['sum']['bits_per_second']/(1000*1000))
            times.append(interval['sum']['start'])


        if protocol == 'TCP':
            avg_latency_jitter = json_object['end']['streams'][-1]['sender']['mean_rtt']/1000
            avg_latency_jitter = (avg_latency_jitter, -99.99)[avg_latency_jitter == 0]
            total_packet_errors = json_object['end']['sum_sent']['retransmits']
            data_rates_mean = json_object['end']['sum_sent']['bits_per_second']/(1000*1000)

            measurement_information = \
            "Mean:          %.2f Mbit/s" \
            %(data_rates_mean)
            if reverse == 0:
                measurement_information += \
                "\nRetransmits:   %.0f\n" \
                "Latency:       %.2f ms" \
                %(total_packet_errors, avg_latency_jitter)

        elif protocol == 'UDP':
            avg_latency_jitter = json_object['end']['sum']['jitter_ms']
            total_packet_errors = json_object['end']['sum']['lost_packets']
            data_rates_mean = json_object['end']['sum']['bits_per_second']/(1000*1000)

            measurement_information = \
            "Mean:      %.2f Mbit/s\n" \
            "Losses:    %.0f\n" \
            "Jitter:    %.2f ms" \
            %(data_rates_mean, total_packet_errors, avg_latency_jitter)

        else:
            total_packet_errors = -1
            avg_latency_jitter = -1
            data_rates_mean = -1
            measurement_information = "unkown protocol"

        data_rates_mean = [data_rates_mean]*len(times)

        fig[index], (ax[index]) = plt.subplots(1, 1, sharex=True)
        fig[index].suptitle('iperf3 Throughput', fontsize=12, fontweight='bold')

        ypos = 95 if data_rates_mean[0] < 50 else 25
        ax[index].text(0, ypos, measurement_information, fontname = 'monospace',
                       horizontalalignment='left', verticalalignment='top',
                       bbox={'facecolor':'grey', 'alpha':0.3, 'pad':10})


        ax[index].set_ylim(0, 120)
        title = log_name + ' ' + protocol
        if reverse ==1:
            title += ' reverse (Client -> AP)'
        else:
            title += ' (AP -> Client)'
        ax[index].set_title(title)
        ax[index].grid(True)
        ax[index].plot(times, data_rates, label='Throughput', marker='o', markersize=2)
        ax[index].plot(times, data_rates_mean, label='Throughput Mean', linestyle='--')
        ax[index].legend(loc='upper right')
        ax[index].set_ylabel('Throughput in Mbit/s')


        filename = "%s/plots/%s_plot.pdf" %(log[:log.find('/iperf3')], log[log.find('/iperf3')+1:log.find('.json')])
        fig[index].savefig(filename)



def main():
    pwd = str(sys.argv[1])
    logs_iperf = glob.glob(pwd + '/iperf3*.json')
    if not os.path.exists(pwd+'/plots/'):
        print("📈 Directory for plots does not exist yet. Creating it ...")
        os.makedirs(pwd+'/plots/')

    print("📈 We got a total of %d iperf.json's. Creating plots ..." %len(logs_iperf))

    log_name = pwd[pwd.find('logs/')+5:]
    iperf_plot(log_name, logs_iperf)

    print("📈 Plotting finished. See %s." %(pwd+'/plots/'))


if __name__ == "__main__":
    main()
