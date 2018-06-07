#!/bin/sh

.  /usr/lib/tuned/functions

stop_services() {
    systemctl stop cpupower
    systemctl stop cpuspeed
    systemctl stop cpufreqd
    systemctl stop powerd
    systemctl stop irqbalance
    systemctl stop firewalld
}

flush_iptables() {
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X
    iptables -S > /tmp/iptables_check.txt
}

disable_spectre_meltdown() {
    echo 0 > /sys/kernel/debug/x86/ibrs_enabled
    echo 0 > /sys/kernel/debug/x86/pti_enabled
    grep . /sys/kernel/debug/x86/*nabled > /tmp/spec_melt_check.txt # Check
}

remove_modules() {
    modprobe --remove kvm_intel kvm irqbypass
    modprobe -r ipt_SYNPROXY nf_synproxy_core xt_CT \
             nf_conntrack_ftp nf_conntrack_tftp nf_conntrack_irc \
             nf_nat_tftp ipt_MASQUERADE iptable_nat nf_nat_ipv4 \
             nf_nat nf_conntrack_ipv4 nf_nat nf_conntrack_ipv6 \
             xt_state xt_conntrack iptable_raw nf_conntrack \
             iptable_filter iptable_raw iptable_mangle ipt_REJECT \
             xt_CHECKSUM ip_tables nf_defrag_ipv4 ip6table_filter \
             ip6_tables nf_defrag_ipv6 ip6t_REJECT xt_LOG \
             xt_multiport nf_conntrack ebtable_nat ebtables \
             iptable_mangle iptable_nat nf_conntrack_ipv4 \
             nf_defrag_ipv4 nf_nat_ipv4 nf_nat nf_conntrack \
             iptable_filter ip_tables iTCO_wdt iTCO_vendor_support
}

start() {
    # Turn off adaptive moderation and set interrupt moderation to a high value
    # (microseconds) to avoid flooding the system with interrupts.
    /sbin/ethtool -C {{ tuned_test_interface }} rx-usecs-irq 0 adaptive-rx off
    # When loading, the Onload module will create a variety of common data structures.
    # To ensure that these are created on the NUMA node nearest to the Solarflare
    # adapter, onload_tool reload should be affinitized to a core on the correct NUMA
    # node.
    /usr/bin/numactl --physcpubind={{ tuned_local_housekeeping_core_0 }} onload_tool reload

    echo 400 > /sys/devices/system/node/node{{ tuned_local_numa_node  }}/hugepages/hugepages-2048kB/nr_hugepages

    ifup {{ tuned_test_interface }}
    ip link set {{ tuned_test_interface }} mtu 1700

    sfcirqaffinity {{ tuned_test_interface }} {{ tuned_local_housekeeping_core_0 }}
    #sfcirqaffinity p258p2 8

    taskset -pc {{ tuned_local_housekeeping_core_1 }}  `ps -eo pid,comm | grep onload_cp | awk '{ print $1 }'`
    
    auditctl -e 0

    disable_spectre_meltdown()
    stop_services()
    flush_iptables()
    remove_modules()
}
stop() {
    echo "stop"
}
verify() {
    echo "stop"
}

process $@
