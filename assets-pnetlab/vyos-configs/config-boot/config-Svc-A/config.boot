high-availability {
    vrrp {
        group gw-100 {
            address 10.99.100.1/24 {
            }
            advertise-interval 1
            interface br100
            no-preempt
            priority 100
            vrid 100
        }
        group gw-101 {
            address 10.99.101.1/24 {
            }
            advertise-interval 1
            interface br100
            no-preempt
            priority 100
            vrid 101
        }
        group gw-102 {
            address 10.99.102.1/24 {
            }
            advertise-interval 1
            interface br100
            no-preempt
            priority 100
            vrid 102
        }
        group gw-103 {
            address 10.99.103.1/24 {
            }
            advertise-interval 1
            interface br100
            no-preempt
            priority 100
            vrid 103
        }
        group gw-104 {
            address 10.99.104.1/24 {
            }
            advertise-interval 1
            interface br100
            no-preempt
            priority 100
            vrid 104
        }
        group gw-105 {
            address 10.99.105.1/24 {
            }
            advertise-interval 1
            interface br100
            no-preempt
            priority 100
            vrid 105
        }
        group gw-106 {
            address 10.99.106.1/24 {
            }
            advertise-interval 1
            interface br100
            no-preempt
            priority 100
            vrid 106
        }
        group gw-107 {
            address 10.99.107.1/24 {
            }
            advertise-interval 1
            interface br100
            no-preempt
            priority 100
            vrid 107
        }
        group gw-105-v6 {
            address fd:0:99:105::1111/64 {
            }
            advertise-interval 1
            interface br100
            no-preempt
            priority 100
            vrid 056
        }
        group gw-106-v6 {
            address fd:0:99:106::1111/64 {
            }
            advertise-interval 1
            interface br100
            no-preempt
            priority 100
            vrid 066
        }
    }
}
interfaces {
    bridge br100 {
        address 10.99.100.2/24
        member {
            interface eth1 {
            }
            interface eth4 {
            }
            interface eth5 {
            }
        }
        mtu 8846
    }
    ethernet eth0 {
        address 10.10.15.104/24
        hw-id 50:a5:08:00:0b:00
        ipv6 {
            address {
            }
        }
        mtu 8896
        vrf oob
    }
    ethernet eth1 {
        hw-id 50:a5:08:00:0b:01
        mtu 8896
    }
    ethernet eth2 {
        address 3.0.1.2/30
        address fd:0:0:301::2222/64
        hw-id 50:a5:08:00:0b:02
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth3 {
        address 4.0.1.2/30
        address fd:0:0:401::2222/64
        disable
        hw-id 50:a5:08:00:0b:03
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth4 {
        hw-id 50:a5:08:00:0b:04
        mtu 8846
    }
    ethernet eth5 {
        disable
        hw-id 50:a5:08:00:0b:05
        mtu 8846
    }
    loopback lo {
        address 10.0.99.1/32
        address fd:0:0:99::1111/64
    }
}
policy {
    prefix-list route-filter {
        rule 10 {
            action deny
            prefix 10.15.0.0/16
        }
        rule 11 {
            action deny
            prefix 1.0.0.0/8
        }
        rule 12 {
            action deny
            prefix 2.0.0.0/8
        }
        rule 13 {
            action deny
            prefix 3.0.0.0/8
        }
        rule 14 {
            action deny
            prefix 4.0.0.0/8
        }
        rule 15 {
            action deny
            prefix 5.0.0.0/8
        }
        rule 16 {
            action deny
            prefix 6.0.0.0/8
        }
        rule 98 {
            action permit
            prefix 192.168.99.0/24
        }
        rule 99 {
            action permit
            prefix 172.16.0.0/16
        }
        rule 100 {
            action permit
            prefix 192.168.0.0/16
        }
        rule 101 {
            action permit
            prefix 0.0.0.0/0
        }
    }
    prefix-list route-redist-filtering {
        description "Preventdistribution of local point-2-point links and mgmt interface"
        rule 10 {
            action deny
            prefix 10.15.0.0/16
        }
        rule 100 {
            action permit
            description "allow any CIDR of size /29 or less. i.e. block exchange of ptp local links"
            le 29
            prefix 0.0.0.0/0
        }
    }
    prefix-list route-redist-filtering2 {
        rule 10 {
            action deny
            prefix 10.15.0.0/16
        }
        rule 100 {
            action permit
            ge 16
            prefix 192.168.0.0/16
        }
        rule 101 {
            action permit
            ge 16
            prefix 172.16.0.0/16
        }
        rule 110 {
            action permit
            ge 8
            prefix 10.0.0.0/8
        }
        rule 120 {
            action permit
            ge 16
            prefix 1.0.0.0/16
        }
        rule 121 {
            action permit
            ge 16
            prefix 2.0.0.0/16
        }
        rule 122 {
            action permit
            ge 16
            prefix 3.0.0.0/16
        }
        rule 123 {
            action permit
            ge 16
            prefix 4.0.0.0/16
        }
        rule 124 {
            action permit
            ge 16
            prefix 5.0.0.0/16
        }
        rule 125 {
            action permit
            ge 16
            prefix 6.0.0.0/16
        }
        rule 200 {
            action permit
            prefix 0.0.0.0/0
        }
    }
    prefix-list6 route-redist-filtering6 {
        rule 620 {
            action permit
            ge 48
            prefix fd::/48
        }
    }
}
protocols {
    bfd {
        peer 3.0.1.1 {
        }
        peer 4.0.1.1 {
        }
    }
    bgp {
        address-family {
            ipv4-unicast {
                redistribute {
                    connected {
                    }
                    static {
                    }
                }
            }
            ipv6-unicast {
                network fd:0::/32 {
                }
                redistribute {
                    connected {
                    }
                    static {
                    }
                }
            }
        }
        listen {
            range 10.99.105.0/24 {
                peer-group dyn-peers-rs-105
            }
        }
        neighbor 3.0.1.1 {
            address-family {
                ipv4-unicast {
                }
            }
            bfd {
            }
            remote-as 65002
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 3.0.1.2
        }
        neighbor 4.0.1.1 {
            address-family {
                ipv4-unicast {
                }
            }
            bfd {
            }
            remote-as 65002
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 4.0.1.2
        }
        neighbor fd:0:0:301::1111 {
            address-family {
                ipv6-unicast {
                }
            }
            ebgp-multihop 2
            remote-as 65002
            timers {
                holdtime 9
                keepalive 3
            }
            update-source fd:0:0:301::2222
        }
        neighbor fd:0:0:401::1111 {
            address-family {
                ipv6-unicast {
                }
            }
            ebgp-multihop 2
            remote-as 65002
            timers {
                holdtime 9
                keepalive 3
            }
            update-source fd:0:0:401::2222
        }
        parameters {
            bestpath {
                as-path {
                    multipath-relax
                }
            }
            router-id 10.0.99.1
        }
        peer-group dyn-peers-rs-105 {
            address-family {
                ipv4-unicast {
                }
            }
            ebgp-multihop 2
            passive
            remote-as 64600
            update-source 10.0.99.1
        }
        system-as 65004
    }
}
service {
    ssh {
        port 22
    }
}
system {
    conntrack {
        modules {
            ftp
            h323
            nfs
            pptp
            sip
            sqlnet
            tftp
        }
    }
    console {
        device ttyS0 {
            speed 115200
        }
    }
    host-name Svc-A
    login {
        user vyos {
            authentication {
                encrypted-password $6$hL5MbeXxuSMY4hYP$EQDOB3g3xTQhZEt0zzqHXYwjR4y38KDXazGXjgZQhR3FBB6ZhwUQbDRXNNhGxEFSsAPZVzr0bwMCsZTw1d96B1
                plaintext-password ""
            }
        }
    }
    ntp {
        server 0.pool.ntp.org {
        }
        server 1.pool.ntp.org {
        }
        server 2.pool.ntp.org {
        }
    }
    syslog {
        global {
            facility all {
                level info
            }
            facility protocols {
                level debug
            }
        }
    }
    time-zone America/Denver
}
vrf {
    bind-to-all
    name oob {
        protocols {
            static {
                route 0.0.0.0/0 {
                    next-hop 10.10.15.1 {
                        interface eth0
                    }
                }
            }
        }
        table 100
    }
}

// Warning: Do not remove the following line.
// vyos-config-version: "bgp@4:broadcast-relay@1:cluster@1:config-management@1:conntrack@3:conntrack-sync@2:container@1:dhcp-relay@2:dhcp-server@6:dhcpv6-server@1:dns-dynamic@1:dns-forwarding@4:firewall@10:flow-accounting@1:https@4:ids@1:interfaces@29:ipoe-server@1:ipsec@12:isis@3:l2tp@4:lldp@1:mdns@1:monitoring@1:nat@5:nat66@1:ntp@2:openconnect@2:ospf@2:policy@5:pppoe-server@6:pptp@2:qos@2:quagga@11:rip@1:rpki@1:salt@1:snmp@3:ssh@2:sstp@4:system@26:vrf@3:vrrp@3:vyos-accel-ppp@2:wanloadbalance@3:webproxy@2"
// Release version: 1.4-rolling-202306290317
