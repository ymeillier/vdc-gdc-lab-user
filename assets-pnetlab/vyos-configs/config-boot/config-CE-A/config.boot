interfaces {
    ethernet eth0 {
        address 10.10.15.100/24
        hw-id 50:a5:4c:00:28:00
        ipv6 {
            address {
            }
        }
        mtu 8896
        vrf oob
    }
    ethernet eth1 {
        address 10.10.25.100/24
        hw-id 50:a5:4c:00:28:01
        ipv6 {
            address {
            }
        }
    }
    ethernet eth2 {
        address 10.10.70.210/32
        hw-id 50:a5:4c:00:28:02
        ipv6 {
            address {
            }
        }
        mtu 1460
        vrf vpn
    }
    ethernet eth3 {
        address 1.0.1.1/30
        address fd:0:0:101::1111/64
        hw-id 50:a5:4c:00:28:03
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth4 {
        address 1.0.2.1/30
        address fd:0:0:102::1111/64
        disable
        hw-id 50:a5:4c:00:28:04
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth5 {
        hw-id 50:a5:4c:00:28:05
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    loopback lo {
        address 169.254.22.117/30
        address 10.0.1.1/32
        address fd:0:0:1::1111/64
    }
}
nat {
    source {
        rule 1 {
            description "egress SNAT"
            outbound-interface eth1
            source {
                address !10.10.15.0/24
            }
            translation {
                address masquerade
            }
        }
        rule 2 {
            destination {
                address 10.200.10.0/24
            }
            exclude
            outbound-interface eth2
            source {
                address 10.99.100.0/24
            }
        }
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
        rule 192 {
            action permit
            ge 8
            prefix 192.0.0.0/8
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
        peer 1.0.1.2 {
        }
        peer 1.0.2.2 {
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
        neighbor 1.0.1.2 {
            address-family {
                ipv4-unicast {
                    default-originate {
                    }
                    prefix-list {
                        export route-redist-filtering2
                        import route-redist-filtering2
                    }
                }
            }
            bfd {
            }
            remote-as 65002
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 1.0.1.1
        }
        neighbor 1.0.2.2 {
            address-family {
                ipv4-unicast {
                    default-originate {
                    }
                    prefix-list {
                        export route-redist-filtering2
                        import route-redist-filtering2
                    }
                }
            }
            bfd {
            }
            remote-as 65002
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 1.0.2.1
        }
        neighbor fd:0:0:101::2222 {
            address-family {
                ipv6-unicast {
                    default-originate {
                    }
                }
            }
            ebgp-multihop 2
            remote-as 65002
            timers {
                holdtime 9
                keepalive 3
            }
            update-source fd:0:0:101::1111
        }
        neighbor fd:0:0:102::2222 {
            address-family {
                ipv6-unicast {
                    default-originate {
                    }
                }
            }
            ebgp-multihop 2
            remote-as 65002
            timers {
                holdtime 9
                keepalive 3
            }
            update-source fd:0:0:102::1111
        }
        parameters {
            bestpath {
                as-path {
                    multipath-relax
                }
            }
            router-id 10.0.1.1
        }
        system-as 65001
    }
    static {
        route 0.0.0.0/0 {
            next-hop 10.10.25.1 {
                interface eth1
            }
        }
        route 10.10.75.1/32 {
            interface eth2 {
            }
        }
        route 34.172.42.29/32 {
            interface eth2 {
            }
            next-hop 10.10.75.1 {
            }
        }
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
    domain-name acme.local
    domain-search {
        domain acme.local
    }
    host-name CE-A
    login {
        user vyos {
            authentication {
                encrypted-password $6$hL5MbeXxuSMY4hYP$EQDOB3g3xTQhZEt0zzqHXYwjR4y38KDXazGXjgZQhR3FBB6ZhwUQbDRXNNhGxEFSsAPZVzr0bwMCsZTw1d96B1
                plaintext-password ""
            }
        }
    }
    name-server 192.168.1.10
    ntp {
        allow-clients {
        }
        listen-address 10.10.25.101
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
vpn {
    ipsec {
        esp-group aes256-sha256 {
            lifetime 28800
            mode tunnel
            pfs dh-group19
            proposal 1 {
                encryption aes256
                hash sha256
            }
        }
        ike-group aes256-sha256 {
            dead-peer-detection {
                action restart
                interval 30
                timeout 120
            }
            key-exchange ikev2
            lifetime 3600
            proposal 1 {
                dh-group 19
                encryption aes256
                hash sha256
            }
        }
        interface eth2
        site-to-site {
            peer cloud-vpn-1-classic {
                authentication {
                    mode pre-shared-secret
                    pre-shared-secret Cw0xGAqJZxxDAHI0iZZF3d7yUnF/3GeK
                }
                ike-group aes256-sha256
                local-address 10.10.70.210
                remote-address 34.172.42.29
                tunnel 0 {
                    esp-group aes256-sha256
                    local {
                        prefix 10.99.100.0/24
                        prefix 10.100.100.0/24
                        prefix 10.110.100.0/24
                        prefix 10.120.100.0/24
                        prefix 10.130.100.0/24
                    }
                    remote {
                        prefix 10.200.10.0/24
                        prefix 10.210.10.0/24
                    }
                }
            }
        }
    }
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
    name vpn {
        protocols {
            static {
                route 0.0.0.0/0 {
                    next-hop 10.10.75.1 {
                        interface eth2
                    }
                }
                route 10.10.75.1/32 {
                    interface eth2 {
                    }
                }
            }
        }
        table 800
    }
}

// Warning: Do not remove the following line.
// vyos-config-version: "bgp@4:broadcast-relay@1:cluster@1:config-management@1:conntrack@3:conntrack-sync@2:container@1:dhcp-relay@2:dhcp-server@6:dhcpv6-server@1:dns-dynamic@1:dns-forwarding@4:firewall@10:flow-accounting@1:https@4:ids@1:interfaces@29:ipoe-server@1:ipsec@12:isis@3:l2tp@4:lldp@1:mdns@1:monitoring@1:nat@5:nat66@1:ntp@2:openconnect@2:ospf@2:policy@5:pppoe-server@6:pptp@2:qos@2:quagga@11:rip@1:rpki@1:salt@1:snmp@3:ssh@2:sstp@4:system@26:vrf@3:vrrp@3:vyos-accel-ppp@2:wanloadbalance@3:webproxy@2"
// Release version: 1.4-rolling-202306290317
