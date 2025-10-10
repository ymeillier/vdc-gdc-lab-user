firewall {
    send-redirects disable
}
high-availability {
    vrrp {
        group gw-102 {
            address 10.110.102.1/24 {
            }
            advertise-interval 1
            interface br111
            no-preempt
            priority 100
            vrid 102
        }
        group gw-103 {
            address 10.110.103.1/24 {
            }
            advertise-interval 1
            interface br111
            no-preempt
            priority 100
            vrid 103
        }
        group gw-104 {
            address 10.110.104.1/24 {
            }
            advertise-interval 1
            interface br111
            no-preempt
            priority 100
            vrid 104
        }
        group gw-105 {
            address 10.110.105.1/24 {
            }
            advertise-interval 1
            interface br111
            no-preempt
            priority 100
            vrid 105
        }
        group gw-106 {
            address 10.110.106.1/24 {
            }
            advertise-interval 1
            interface br111
            no-preempt
            priority 100
            vrid 106
        }
        group gw-107 {
            address 10.110.107.1/24 {
            }
            advertise-interval 1
            interface br111
            no-preempt
            priority 100
            vrid 107
        }
        group gw4 {
            address 10.110.4.1/24 {
            }
            advertise-interval 1
            disable
            interface br111
            no-preempt
            priority 100
            vrid 4
        }
        group gw100 {
            address 10.110.100.1/24 {
            }
            advertise-interval 1
            disable
            interface br111
            no-preempt
            priority 100
            vrid 100
        }
        group gw101 {
            address 10.110.101.1/24 {
            }
            advertise-interval 1
            interface br111
            no-preempt
            priority 100
            vrid 101
        }
        group gw-105-v6 {
            address fd:0:110:105::1111/64 {
            }
            advertise-interval 1
            interface br111
            no-preempt
            priority 100
            vrid 056
        }
        group gw-106-v6 {
            address fd:0:110:106::1111/64 {
            }
            advertise-interval 1
            interface br111
            no-preempt
            priority 100
            vrid 066
        }
    }
}
interfaces {
    bridge br111 {
        address 10.110.100.2/24
        ipv6 {
            address {
            }
        }
        member {
            interface eth1 {
            }
            interface eth4 {
            }
        }
        mtu 8846
    }
    ethernet eth0 {
        address 10.10.15.108/24
        hw-id 50:39:dc:00:07:00
        ipv6 {
            address {
            }
        }
        mtu 8896
        vrf oob
    }
    ethernet eth1 {
        hw-id 50:39:dc:00:07:01
        mtu 8896
    }
    ethernet eth2 {
        address 5.0.3.2/30
        address fd:0:0:503::2222/64
        hw-id 50:39:dc:00:07:02
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth3 {
        address 6.0.3.2/30
        address fd:0:0:603::2222/64
        hw-id 50:39:dc:00:07:03
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth4 {
        hw-id 50:39:dc:00:07:04
        mtu 8846
    }
    ethernet eth5 {
        disable
        hw-id 50:39:dc:00:07:05
        ipv6 {
            address {
            }
        }
        mtu 8896
    }
    loopback lo {
        address 10.0.10.1/32
        address fd:0:0:10::1111/64
    }
}
policy {
    prefix-list leaf-in {
        rule 1 {
            action deny
            ge 16
            prefix 1.0.0.0/16
        }
        rule 2 {
            action deny
            ge 16
            prefix 2.0.0.0/16
        }
        rule 3 {
            action deny
            ge 16
            prefix 3.0.0.0/16
        }
        rule 4 {
            action deny
            ge 16
            prefix 4.0.0.0/16
        }
        rule 5 {
            action deny
            ge 16
            prefix 5.0.0.0/16
        }
        rule 6 {
            action deny
            ge 16
            prefix 6.0.0.0/16
        }
        rule 10 {
            action deny
            prefix 10.15.0.0/16
        }
        rule 11 {
            action permit
            ge 24
            prefix 10.0.140.0/24
        }
        rule 12 {
            action deny
            ge 16
            prefix 10.0.0.0/16
        }
        rule 99 {
            action deny
            ge 16
            prefix 10.99.0.0/16
        }
        rule 100 {
            action deny
            ge 16
            prefix 10.100.0.0/16
        }
        rule 110 {
            action deny
            ge 16
            prefix 10.110.0.0/16
        }
        rule 120 {
            action deny
            ge 16
            prefix 10.120.0.0/16
        }
        rule 130 {
            action deny
            ge 16
            prefix 10.130.0.0/16
        }
        rule 192 {
            action permit
            description "flat ipv4 with bgp"
            ge 8
            prefix 192.0.0.0/8
        }
        rule 200 {
            action permit
            prefix 0.0.0.0/0
        }
        rule 210 {
            action permit
            description "vips abm cluster"
            ge 16
            prefix 10.210.0.0/16
        }
        rule 211 {
            action permit
            description "vips abm cluster"
            ge 16
            prefix 10.211.0.0/16
        }
        rule 212 {
            action permit
            description "vips abm cluster"
            ge 16
            prefix 10.212.0.0/16
        }
        rule 213 {
            action permit
            description "vips abm cluster"
            ge 16
            prefix 10.213.0.0/16
        }
        rule 214 {
            action permit
            description "vips abm cluster"
            ge 16
            prefix 10.214.0.0/16
        }
        rule 215 {
            action permit
            description "vips abm cluster"
            ge 16
            prefix 10.215.0.0/16
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
            range 10.100.101.0/24 {
                peer-group dyn-peers-r0
            }
            range 10.100.102.0/24 {
                peer-group dyn-peers-r0
            }
            range 10.100.103.0/24 {
                peer-group dyn-peers-r0
            }
            range 10.100.104.0/24 {
                peer-group dyn-peers-r0
            }
            range 10.100.105.0/24 {
                peer-group dyn-peers-r0
            }
            range 10.100.106.0/24 {
                peer-group dyn-peers-r0
            }
            range 10.100.107.0/24 {
                peer-group dyn-peers-r0
            }
            range 10.100.108.0/24 {
                peer-group dyn-peers-r0
            }
            range 10.100.109.0/24 {
                peer-group dyn-peers-r0
            }
            range 10.110.101.0/24 {
                peer-group dyn-peers-r1
            }
            range 10.110.102.0/24 {
                peer-group dyn-peers-r1
            }
            range 10.110.103.0/24 {
                peer-group dyn-peers-r1
            }
            range 10.110.104.0/24 {
                peer-group dyn-peers-r1
            }
            range 10.110.105.0/24 {
                peer-group dyn-peers-r1
            }
            range 10.110.106.0/24 {
                peer-group dyn-peers-r1
            }
            range 10.110.107.0/24 {
                peer-group dyn-peers-r1
            }
            range 10.110.108.0/24 {
                peer-group dyn-peers-r1
            }
            range 10.110.109.0/24 {
                peer-group dyn-peers-r1
            }
            range 10.120.101.0/24 {
                peer-group dyn-peers-r2
            }
            range 10.120.102.0/24 {
                peer-group dyn-peers-r2
            }
            range 10.120.103.0/24 {
                peer-group dyn-peers-r2
            }
            range 10.120.104.0/24 {
                peer-group dyn-peers-r2
            }
            range 10.120.105.0/24 {
                peer-group dyn-peers-r2
            }
            range 10.120.106.0/24 {
                peer-group dyn-peers-r2
            }
            range 10.120.107.0/24 {
                peer-group dyn-peers-r2
            }
            range 10.120.108.0/24 {
                peer-group dyn-peers-r2
            }
            range 10.120.109.0/24 {
                peer-group dyn-peers-r2
            }
            range 10.130.101.0/24 {
                peer-group dyn-peers-r3
            }
            range 10.130.102.0/24 {
                peer-group dyn-peers-r3
            }
            range 10.130.103.0/24 {
                peer-group dyn-peers-r3
            }
            range 10.130.104.0/24 {
                peer-group dyn-peers-r3
            }
            range 10.130.105.0/24 {
                peer-group dyn-peers-r3
            }
            range 10.130.106.0/24 {
                peer-group dyn-peers-r3
            }
            range 10.130.107.0/24 {
                peer-group dyn-peers-r3
            }
            range 10.130.108.0/24 {
                peer-group dyn-peers-r3
            }
            range 10.130.109.0/24 {
                peer-group dyn-peers-r3
            }
        }
        neighbor 5.0.3.1 {
            address-family {
                ipv4-unicast {
                    prefix-list {
                        import leaf-in
                    }
                }
            }
            remote-as 65003
            solo
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 5.0.3.2
        }
        neighbor 6.0.3.1 {
            address-family {
                ipv4-unicast {
                    prefix-list {
                        import leaf-in
                    }
                    soft-reconfiguration {
                    }
                }
            }
            remote-as 65003
            solo
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 6.0.3.2
        }
        parameters {
            bestpath {
                as-path {
                    multipath-relax
                }
            }
            router-id 10.0.10.1
        }
        peer-group dyn-peers-r0 {
            address-family {
                ipv4-unicast {
                }
            }
            ebgp-multihop 3
            passive
            remote-as 64600
            update-source 10.0.10.1
        }
        peer-group dyn-peers-r1 {
            address-family {
                ipv4-unicast {
                }
            }
            ebgp-multihop 3
            passive
            remote-as 64600
            update-source 10.0.10.1
        }
        peer-group dyn-peers-r2 {
            address-family {
                ipv4-unicast {
                }
            }
            ebgp-multihop 3
            passive
            remote-as 64600
            update-source 10.0.10.1
        }
        peer-group dyn-peers-r3 {
            address-family {
                ipv4-unicast {
                }
            }
            ebgp-multihop 3
            passive
            remote-as 64600
            update-source 10.0.10.1
        }
        system-as 65003
    }
}
service {
    ntp {
        allow-client {
            address 0.0.0.0/0
            address ::/0
        }
        server 0.pool.ntp.org {
        }
        server 1.pool.ntp.org {
        }
        server 2.pool.ntp.org {
        }
    }
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
    host-name R1-A
    login {
        user vyos {
            authentication {
                encrypted-password $6$hL5MbeXxuSMY4hYP$EQDOB3g3xTQhZEt0zzqHXYwjR4y38KDXazGXjgZQhR3FBB6ZhwUQbDRXNNhGxEFSsAPZVzr0bwMCsZTw1d96B1
                plaintext-password ""
            }
        }
    }
    syslog {
        global {
            facility all {
                level info
            }
            facility local7 {
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
