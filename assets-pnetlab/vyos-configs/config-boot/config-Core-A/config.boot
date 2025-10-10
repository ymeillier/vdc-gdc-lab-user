interfaces {
    ethernet eth0 {
        address 10.10.15.102/24
        hw-id 50:89:91:00:3b:00
        mtu 8896
        vrf oob
    }
    ethernet eth1 {
        address 1.0.1.2/30
        address fd:0:0:101::2222/64
        hw-id 50:89:91:00:3b:01
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth2 {
        address 2.0.1.2/30
        address fd:0:0:201::2222/64
        disable
        hw-id 50:89:91:00:3b:02
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth3 {
        address 3.0.1.1/30
        address fd:0:0:301::1111/64
        hw-id 50:89:91:00:3b:03
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth4 {
        address 3.0.2.1/30
        address fd:0:0:302::1111/64
        disable
        hw-id 50:89:91:00:3b:04
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth5 {
        address 3.0.3.1/30
        address fd:0:0:303::1111/64
        hw-id 50:89:91:00:3b:05
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth6 {
        address 3.0.4.1/30
        address fd:0:0:304::1111/64
        disable
        hw-id 50:89:91:00:3b:06
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    loopback lo {
        address 10.0.3.1/32
        address fd:0:0:3::1111/64
    }
}
policy {
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
        peer 1.0.1.1 {
        }
        peer 2.0.1.1 {
        }
        peer 3.0.1.2 {
        }
        peer 3.0.2.2 {
        }
        peer 3.0.3.2 {
        }
        peer 3.0.4.2 {
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
        neighbor 1.0.1.1 {
            address-family {
                ipv4-unicast {
                }
            }
            bfd {
            }
            remote-as 65001
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 1.0.1.2
        }
        neighbor 2.0.1.1 {
            address-family {
                ipv4-unicast {
                }
            }
            bfd {
            }
            remote-as 65001
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 2.0.1.2
        }
        neighbor 3.0.1.2 {
            address-family {
                ipv4-unicast {
                }
            }
            bfd {
            }
            remote-as 65004
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 3.0.1.1
        }
        neighbor 3.0.2.2 {
            address-family {
                ipv4-unicast {
                }
            }
            bfd {
            }
            remote-as 65004
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 3.0.2.1
        }
        neighbor 3.0.3.2 {
            address-family {
                ipv4-unicast {
                }
            }
            bfd {
            }
            remote-as 65010
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 3.0.3.1
        }
        neighbor 3.0.4.2 {
            address-family {
                ipv4-unicast {
                }
            }
            bfd {
            }
            remote-as 65010
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 3.0.4.1
        }
        neighbor fd:0:0:101::1111 {
            address-family {
                ipv6-unicast {
                }
            }
            ebgp-multihop 2
            remote-as 65001
            timers {
                holdtime 9
                keepalive 3
            }
            update-source fd:0:0:101::2222
        }
        neighbor fd:0:0:201::1111 {
            address-family {
                ipv6-unicast {
                }
            }
            ebgp-multihop 2
            remote-as 65001
            timers {
                holdtime 9
                keepalive 3
            }
            update-source fd:0:0:201::2222
        }
        neighbor fd:0:0:301::2222 {
            address-family {
                ipv6-unicast {
                }
            }
            ebgp-multihop 2
            remote-as 65004
            timers {
                holdtime 9
                keepalive 3
            }
            update-source fd:0:0:301::1111
        }
        neighbor fd:0:0:302::2222 {
            address-family {
                ipv6-unicast {
                }
            }
            ebgp-multihop 2
            remote-as 65004
            timers {
                holdtime 9
                keepalive 3
            }
            update-source fd:0:0:302::1111
        }
        neighbor fd:0:0:303::2222 {
            address-family {
                ipv6-unicast {
                }
            }
            ebgp-multihop 2
            remote-as 65010
            timers {
                holdtime 9
                keepalive 3
            }
            update-source fd:0:0:303::1111
        }
        neighbor fd:0:0:403::2222 {
            address-family {
                ipv6-unicast {
                }
            }
            ebgp-multihop 2
            remote-as 65010
            timers {
                holdtime 9
                keepalive 3
            }
            update-source fd:0:0:403::1111
        }
        parameters {
            bestpath {
                as-path {
                    multipath-relax
                }
            }
            router-id 10.0.3.1
        }
        system-as 65002
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
    host-name Core-A
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
        server time1.vyos.net {
        }
        server time2.vyos.net {
        }
        server time3.vyos.net {
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
