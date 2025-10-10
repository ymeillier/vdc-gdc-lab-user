firewall {
    send-redirects disable
}
high-availability {
    vrrp {
        group gw-4 {
            address 10.100.4.1/24 {
            }
            advertise-interval 1
            disable
            interface br100
            no-preempt
            priority 100
            vrid 4
        }
        group gw-5 {
            address 10.100.5.1/24 {
            }
            advertise-interval 1
            disable
            interface br100
            no-preempt
            priority 100
            vrid 5
        }
        group gw-100 {
            address 10.100.100.1/24 {
            }
            advertise-interval 1
            disable
            interface br100
            no-preempt
            priority 100
            vrid 100
        }
        group gw-101 {
            address 10.100.101.1/24 {
            }
            advertise-interval 1
            interface br100
            no-preempt
            priority 100
            vrid 101
        }
        group gw-102 {
            address 10.100.102.1/24 {
            }
            advertise-interval 1
            interface br100
            no-preempt
            priority 100
            vrid 102
        }
        group gw-103 {
            address 10.100.103.1/24 {
            }
            advertise-interval 1
            interface br100
            vrid 103
        }
        group gw-104 {
            address 10.100.104.1/24 {
            }
            advertise-interval 1
            interface br100
            vrid 104
        }
        group gw-105 {
            address 10.100.105.1/24 {
            }
            advertise-interval 1
            interface br100
            no-preempt
            priority 100
            vrid 105
        }
        group gw-106 {
            address 10.100.106.1/24 {
            }
            advertise-interval 1
            interface br100
            no-preempt
            priority 100
            vrid 106
        }
        group gw-107 {
            address 10.100.107.1/24 {
            }
            advertise-interval 1
            interface br100
            no-preempt
            priority 100
            vrid 107
        }
        group gw-199101 {
            address 10.199.101.1/24 {
            }
            advertise-interval 1
            disable
            interface br100
            no-preempt
            priority 100
            vrid 199
        }
        group gw-105-v6 {
            address fd:0:100:105::1111/64 {
            }
            advertise-interval 1
            interface br100
            no-preempt
            priority 100
            vrid 056
        }
        group gw-106-v6 {
            address fd:0:100:106::1111/64 {
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
        address 10.100.100.2/24
        member {
            interface eth1 {
            }
            interface eth6 {
            }
        }
        mtu 8846
    }
    ethernet eth0 {
        address 10.10.15.106/24
        hw-id 50:91:6e:00:05:00
        ipv6 {
            address {
            }
        }
        mtu 8896
        vrf oob
    }
    ethernet eth1 {
        hw-id 50:91:6e:00:05:01
        mtu 8896
    }
    ethernet eth2 {
        address 3.0.3.2/30
        address fd:0:0:303::2222/64
        hw-id 50:91:6e:00:05:02
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth3 {
        address 4.0.3.2/30
        address fd:0:0:403::2222/64
        disable
        hw-id 50:91:6e:00:05:03
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth4 {
        address 5.0.1.2/30
        address fd:0:0:501::2222/64
        hw-id 50:91:6e:00:05:04
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth5 {
        address 6.0.1.2/30
        address fd:0:0:601::2222/64
        hw-id 50:91:6e:00:05:05
        ipv6 {
            address {
            }
        }
        mtu 8846
    }
    ethernet eth6 {
        hw-id 50:91:6e:00:05:06
        mtu 8846
    }
    ethernet eth7 {
        disable
        hw-id 50:91:6e:00:05:07
        ipv6 {
            address {
            }
        }
    }
    loopback lo {
        address 10.0.0.1/32
        address 127.0.0.1/8
        address fd:0:0:0::1111/64
    }
}
policy {
    prefix-list spine-in {
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
        rule 10 {
            action deny
            prefix 10.15.0.0/16
        }
        rule 11 {
            action deny
            ge 24
            prefix 5.0.1.0/24
        }
        rule 12 {
            action permit
            ge 24
            prefix 5.0.2.0/24
        }
        rule 13 {
            action permit
            ge 24
            prefix 5.0.3.0/24
        }
        rule 14 {
            action permit
            ge 24
            prefix 5.0.4.0/24
        }
        rule 15 {
            action permit
            ge 24
            prefix 5.0.5.0/24
        }
        rule 16 {
            action permit
            ge 24
            prefix 5.0.6.0/24
        }
        rule 17 {
            action permit
            ge 24
            prefix 5.0.7.0/24
        }
        rule 18 {
            action permit
            ge 24
            prefix 5.0.8.0/24
        }
        rule 21 {
            action deny
            ge 24
            prefix 6.0.1.0/24
        }
        rule 22 {
            action permit
            ge 24
            prefix 6.0.2.0/24
        }
        rule 23 {
            action permit
            ge 24
            prefix 6.0.3.0/24
        }
        rule 24 {
            action permit
            ge 24
            prefix 6.0.4.0/24
        }
        rule 25 {
            action permit
            ge 24
            prefix 6.0.5.0/24
        }
        rule 26 {
            action permit
            ge 24
            prefix 6.0.6.0/24
        }
        rule 27 {
            action permit
            ge 24
            prefix 6.0.7.0/24
        }
        rule 28 {
            action permit
            ge 24
            prefix 6.0.8.0/24
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
            action permit
            ge 16
            prefix 10.110.0.0/16
        }
        rule 120 {
            action permit
            ge 16
            prefix 10.120.0.0/16
        }
        rule 130 {
            action permit
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
            action deny
            prefix 0.0.0.0/0
        }
        rule 300 {
            action deny
            ge 16
            prefix 10.210.0.0/16
        }
        rule 301 {
            action permit
            ge 16
            prefix 10.211.0.0/16
        }
        rule 302 {
            action permit
            ge 16
            prefix 10.212.0.0/16
        }
        rule 303 {
            action permit
            ge 16
            prefix 10.213.0.0/16
        }
        rule 304 {
            action permit
            ge 16
            prefix 10.214.0.0/16
        }
        rule 305 {
            action permit
            ge 16
            prefix 10.215.0.0/16
        }
        rule 306 {
            action permit
            ge 16
            prefix 10.216.0.0/16
        }
        rule 307 {
            action permit
            ge 16
            prefix 10.217.0.0/16
        }
        rule 308 {
            action permit
            ge 16
            prefix 10.218.0.0/16
        }
        rule 309 {
            action permit
            ge 16
            prefix 10.219.0.0/16
        }
        rule 310 {
            action permit
            ge 16
            prefix 10.0.0.0/16
        }
    }
    prefix-list to-spine {
        rule 1 {
            action deny
            description "border def originates spine"
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
        rule 10 {
            action deny
            prefix 10.15.0.0/16
        }
        rule 11 {
            action deny
            description "routes owned by spine"
            ge 24
            prefix 5.0.1.0/24
        }
        rule 12 {
            action deny
            ge 24
            prefix 5.0.2.0/24
        }
        rule 13 {
            action deny
            ge 24
            prefix 5.0.3.0/24
        }
        rule 14 {
            action deny
            ge 24
            prefix 5.0.4.0/24
        }
        rule 15 {
            action deny
            ge 24
            prefix 5.0.5.0/24
        }
        rule 16 {
            action deny
            ge 24
            prefix 5.0.6.0/24
        }
        rule 17 {
            action deny
            ge 24
            prefix 5.0.7.0/24
        }
        rule 18 {
            action deny
            ge 24
            prefix 5.0.8.0/24
        }
        rule 21 {
            action deny
            description "routes owned by spine"
            ge 24
            prefix 6.0.1.0/24
        }
        rule 22 {
            action deny
            ge 24
            prefix 6.0.2.0/24
        }
        rule 23 {
            action deny
            ge 24
            prefix 6.0.3.0/24
        }
        rule 24 {
            action deny
            ge 24
            prefix 6.0.4.0/24
        }
        rule 25 {
            action deny
            ge 24
            prefix 6.0.5.0/24
        }
        rule 26 {
            action deny
            ge 24
            prefix 6.0.6.0/24
        }
        rule 27 {
            action deny
            ge 24
            prefix 6.0.7.0/24
        }
        rule 28 {
            action deny
            ge 24
            prefix 6.0.8.0/24
        }
        rule 99 {
            action deny
            description "border default originates spine"
            ge 16
            prefix 10.99.0.0/16
        }
        rule 100 {
            action permit
            description "border default originates spine"
            ge 16
            prefix 10.100.0.0/16
        }
        rule 110 {
            action deny
            description "route learned from spine"
            ge 16
            prefix 10.110.0.0/16
        }
        rule 120 {
            action deny
            description "route learned from spine"
            ge 16
            prefix 10.120.0.0/16
        }
        rule 130 {
            action deny
            description "route learned from spine"
            ge 16
            prefix 10.130.0.0/16
        }
        rule 200 {
            action permit
            description "border default originates spine"
            prefix 0.0.0.0/0
        }
        rule 300 {
            action permit
            description "R0 flating ips"
            ge 16
            prefix 10.210.0.0/16
        }
        rule 301 {
            action deny
            ge 16
            prefix 10.211.0.0/16
        }
        rule 302 {
            action permit
            ge 16
            prefix 10.212.0.0/16
        }
        rule 303 {
            action deny
            ge 16
            prefix 10.213.0.0/16
        }
        rule 304 {
            action deny
            ge 16
            prefix 10.214.0.0/16
        }
        rule 305 {
            action deny
            ge 16
            prefix 10.215.0.0/16
        }
        rule 306 {
            action deny
            ge 16
            prefix 10.216.0.0/16
        }
        rule 307 {
            action deny
            ge 16
            prefix 10.217.0.0/16
        }
        rule 308 {
            action deny
            ge 16
            prefix 10.218.0.0/16
        }
        rule 309 {
            action deny
            ge 16
            prefix 10.219.0.0/16
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
        peer 3.0.3.1 {
        }
        peer 4.0.3.1 {
        }
        peer 6.0.1.1 {
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
        neighbor 3.0.3.1 {
            address-family {
                ipv4-unicast {
                }
            }
            bfd {
            }
            remote-as 65002
            solo
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 3.0.3.2
        }
        neighbor 4.0.3.1 {
            address-family {
                ipv4-unicast {
                }
            }
            bfd {
            }
            remote-as 65002
            solo
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 4.0.3.2
        }
        neighbor 5.0.1.1 {
            address-family {
                ipv4-unicast {
                    default-originate {
                    }
                    prefix-list {
                        export to-spine
                        import spine-in
                    }
                }
            }
            remote-as 65003
            solo
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 5.0.1.2
        }
        neighbor 6.0.1.1 {
            address-family {
                ipv4-unicast {
                    default-originate {
                    }
                    prefix-list {
                        export to-spine
                        import spine-in
                    }
                }
            }
            bfd {
            }
            remote-as 65003
            solo
            timers {
                holdtime 9
                keepalive 3
            }
            update-source 6.0.1.2
        }
        neighbor 10.100.101.31 {
            address-family {
                ipv4-unicast {
                }
            }
            description "ABM k8s2 CP peer"
            passive
            remote-as 64600
            update-source 10.0.0.1
        }
        neighbor 10.100.103.31 {
            address-family {
                ipv4-unicast {
                }
            }
            description "ABM k8s-adm2 CP peer"
            passive
            remote-as 64603
            update-source 10.0.0.1
        }
        neighbor fd:0:0:303::1111 {
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
            update-source fd:0:0:303::2222
        }
        neighbor fd:0:0:403::1111 {
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
            update-source fd:0:0:403::2222
        }
        neighbor fd:0:0:501::1111 {
            address-family {
                ipv6-unicast {
                }
            }
            ebgp-multihop 2
            remote-as 65003
            timers {
                holdtime 9
                keepalive 3
            }
            update-source fd:0:0:501::2222
        }
        neighbor fd:0:0:601::1111 {
            address-family {
                ipv6-unicast {
                }
            }
            ebgp-multihop 2
            remote-as 65003
            timers {
                holdtime 9
                keepalive 3
            }
            update-source fd:0:0:601::2222
        }
        parameters {
            bestpath {
                as-path {
                    multipath-relax
                }
            }
            router-id 10.0.0.1
        }
        peer-group dyn-peers-r0 {
            address-family {
                ipv4-unicast {
                }
            }
            ebgp-multihop 3
            passive
            remote-as 64600
            update-source 10.0.0.1
        }
        peer-group dyn-peers-r1 {
            address-family {
                ipv4-unicast {
                }
            }
            ebgp-multihop 3
            passive
            remote-as 64600
            update-source 10.0.0.1
        }
        peer-group dyn-peers-r2 {
            address-family {
                ipv4-unicast {
                }
            }
            ebgp-multihop 3
            passive
            remote-as 64600
            update-source 10.0.0.1
        }
        peer-group dyn-peers-r3 {
            address-family {
                ipv4-unicast {
                }
            }
            ebgp-multihop 3
            passive
            remote-as 64600
            update-source 10.0.0.1
        }
        system-as 65010
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
    host-name Border-A
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
