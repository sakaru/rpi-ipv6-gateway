# Filename : ipv6tables.rules.sh
# Created by W. Dickson 18.12.12
# First, delete all firewall rules.
ip6tables -F
ip6tables -X
ip6tables -t mangle -F
ip6tables -t mangle -X

# Allow anything on the local link
ip6tables -A INPUT  -i lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT

# Allow anything out onto internet
ip6tables -A OUTPUT -o he-ipv6 -j ACCEPT
# Allow established, related packets back in
ip6tables -A INPUT  -i he-ipv6 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow the localnet to access us:
ip6tables -A INPUT    -i eth0   -j ACCEPT
ip6tables -A FORWARD -i eth0 -o eth0 -j ACCEPT
ip6tables -A OUTPUT   -o eth0   -j ACCEPT

# Filter all packets that have RH0 headers:
ip6tables -A INPUT -m rt --rt-type 0 -j DROP
ip6tables -A FORWARD -m rt --rt-type 0 -j DROP
ip6tables -A OUTPUT -m rt --rt-type 0 -j DROP

# Allow Link-Local addresses
ip6tables -A INPUT -s fe80::/10 -j ACCEPT
ip6tables -A OUTPUT -s fe80::/10 -j ACCEPT

# Allow multicast
ip6tables -A INPUT -d ff00::/8 -j ACCEPT
ip6tables -A OUTPUT -d ff00::/8 -j ACCEPT

# Allow ICMPv6 everywhere
ip6tables -I INPUT  -p icmpv6 -j ACCEPT
ip6tables -I FORWARD -p icmpv6 -j ACCEPT
ip6tables -I OUTPUT -p icmpv6 -j ACCEPT

# Allow forwarding
ip6tables -A FORWARD -m state --state NEW -i eth0 -o he-ipv6 -j ACCEPT
ip6tables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
ip6tables -A FORWARD -m state --state INVALID -j DROP

# Allow &quot;No Next Header&quot; to be forwarded or proto=59
# See http://www.ietf.org/rfc/rfc1883.txt (not sure if the length
# is needed as all IPv6 headers should be that size anyway).
ip6tables -A FORWARD -p ipv6-nonxt -m length --length 40 -j ACCEPT

# Allow all SSH traffic inbound
ip6tables -A FORWARD -i he-ipv6 -p tcp -d 2001:1111:9999:3333::/64 --dport 22 -j ACCEPT
# Allow all SSH traffic to the gateway
ip6tables -A INPUT -i he-ipv6 -p tcp --dport 22 -j ACCEPT

# Allow HTTP to a specific IP address.
# ip6tables -A FORWARD -i he-ipv6 -p tcp -d [Your IPv6 Webserver Address]/128 --dport 80 -j ACCEPT

## LOGGING

ip6tables -A INPUT -m limit --limit 10/m --limit-burst 7 -j LOG --log-prefix '[FW INPUT]: '
ip6tables -A FORWARD -m limit --limit 10/m --limit-burst 7 -j LOG --log-prefix '[FW FORWARD]: '
ip6tables -A OUTPUT -m limit --limit 10/m --limit-burst 7 -j LOG --log-prefix '[FW OUTPUT]: '

# Set the default policy
ip6tables -P INPUT   DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT  DROP
