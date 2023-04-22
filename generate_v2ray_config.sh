#!/bin/bash

#example ./generate_v2ray_config.sh --ip 92.204.160.227 --port 54321 --name MOHAMMAD --id "ff87f555-1b4c-4346-efc7-60f5620c1184"

# Parse command line arguments
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --ip)
    IP="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--port)
    PORT="$2"
    shift # past argument
    shift # past value
    ;;
    -n|--name)
    name="$2"
    shift # past argument
    shift # past value
    ;;
    -i|--id)
    id="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    echo "Unknown option: $1"
    exit 1
    ;;
esac
done

# Generate the config file
cat << EOF > /usr/local/etc/v2ray/config.json
{
  "inbounds": [{
    "port": 23213,
    "listen": "0.0.0.0",
    "protocol": "dokodemo-door",
    "settings": {
      "address": "$IP",
      "port": $PORT,
      "network": "tcp,udp"
    },
    "tag": "",
    "sniffing": {
      "enabled": true,
      "destOverride": [
        "http",
        "tls"
      ]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "blocked"
      }
    ]
  }
}
EOF
systemctl restart v2ray.service

echo "Config file generated at /usr/local/etc/v2ray/config.json"

./napsternet_config.sh -n $name -p $PORT -i "$id"

