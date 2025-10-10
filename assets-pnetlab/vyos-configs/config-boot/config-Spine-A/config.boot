firewall {
    send-redirects disable
}
interfaces {
    ethernet eth0 {
        address 10.10.15.114/24
        hw-id 50:19:1b:00:0d:00
        ipv6 {
            address {
                no-default-link-local
            }
        }
        mtu 8896
        vrf oob
    }
    ethernet eth1 {
        address 5.0.1.1/30
        address fd:0:0:501::1111/64
        hw-id 50:19:1b:00:0d:01
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth2 {
        address 5.0.2.1/30
        address fd:0:0:502::1111/64
        disable
        hw-id 50:19:1b:00:0d:02
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth3 {
        address 5.0.3.1/30
        address fd:0:0:503::1111/64
        hw-id 50:19:1b:00:0d:03
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth4 {
        address 5.0.4.1/30
        address fd:0:0:504::1111/64
        disable
        hw-id 50:19:1b:00:0d:04
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth5 {
        address 5.0.5.1/30
        address fd:0:0:505::1111/64
        hw-id 50:19:1b:00:0d:05
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth6 {
        address 5.0.6.1/30
        address fd:0:0:506::1111/64
        disable
        hw-id 50:19:1b:00:0d:06
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth7 {
        address 5.0.7.1/30
        address fd:0:0:507::1111/64
        disable
        hw-id 50:19:1b:00:0d:07
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth8 {
        address 5.0.8.1/30
        address fd:0:0:508::1111/64
        hw-id 50:19:1b:00:0d:08
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    loopback lo {
        address 10.0.140.1/32
        address fd:0:0:140::1111/64
    }
}
policy {
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
        neighbor 5.0.1.2 {
            address-family {
                ipv4-unicast {
                    addpath-tx-all
                }
            }
            remote-as 65010
            solo
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 5.0.1.1
        }
        neighbor 5.0.2.2 {
            address-family {
                ipv4-unicast {
                    addpath-tx-all
                }
            }
            remote-as 65010
            solo
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 5.0.2.1
        }
        neighbor 5.0.3.2 {
            address-family {
                ipv4-unicast {
                    addpath-tx-all
                    attribute-unchanged {
                        next-hop
                    }
                    default-originate {
                    }
                    route-reflector-client
                }
            }
            remote-as 65003
            solo
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 5.0.3.1
        }
        neighbor 5.0.4.2 {
            address-family {
                ipv4-unicast {
                    addpath-tx-all
                    attribute-unchanged {
                        next-hop
                    }
                    default-originate {
                    }
                    route-reflector-client
                }
            }
            remote-as 65003
            solo
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 5.0.4.1
        }
        neighbor 5.0.5.2 {
            address-family {
                ipv4-unicast {
                    addpath-tx-all
                    attribute-unchanged {
                        next-hop
                    }
                    default-originate {
                    }
                    route-reflector-client
                }
            }
            remote-as 65003
            solo
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 5.0.5.1
        }
        neighbor 5.0.6.2 {
            address-family {
                ipv4-unicast {
                    addpath-tx-all
                    attribute-unchanged {
                        next-hop
                    }
                    default-originate {
                    }
                    route-reflector-client
                }
            }
            remote-as 65003
            solo
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 5.0.6.1
        }
        neighbor 5.0.7.2 {
            address-family {
                ipv4-unicast {
                    addpath-tx-all
                    attribute-unchanged {
                        next-hop
                    }
                    default-originate {
                    }
                    route-reflector-client
                }
            }
            remote-as 65003
            solo
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 5.0.7.1
        }
        neighbor 5.0.8.2 {
            address-family {
                ipv4-unicast {
                    addpath-tx-all
                    attribute-unchanged {
                        next-hop
                    }
                    default-originate {
                    }
                    route-reflector-client
                }
            }
            remote-as 65003
            solo
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 5.0.8.1
        }
        parameters {
            router-id 10.0.140.1
        }
        peer-group dyn-peers-r0 {
            address-family {
                ipv4-unicast {
                }
            }
            ebgp-multihop 3
            passive
            remote-as 64600
            update-source 10.0.140.1
        }
        peer-group dyn-peers-r1 {
            address-family {
                ipv4-unicast {
                }
            }
            ebgp-multihop 3
            passive
            remote-as 64600
            update-source 10.0.140.1
        }
        peer-group dyn-peers-r2 {
            address-family {
                ipv4-unicast {
                }
            }
            ebgp-multihop 3
            passive
            remote-as 64600
            update-source 10.0.140.1
        }
        peer-group dyn-peers-r3 {
            address-family {
                ipv4-unicast {
                }
            }
            ebgp-multihop 3
            passive
            remote-as 64600
            update-source 10.0.140.1
        }
        system-as 65003
    }
    static {
        route6 fe80::522c:99ff:fe00:902/128 {
            interface eth5 {
            }
        }
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
    host-name Spine-A
    ip {
        multipath {
            layer4-hashing
        }
    }
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
