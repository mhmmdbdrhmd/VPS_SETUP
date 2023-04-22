#!/bin/bash

#example: ./update_config.sh --port 54321 --name MOHAMMAD --id "ff87f555-1b4c-4346-efc7-60f5620c1184"

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -p|--port)
    port="$2"
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

if [ -z "$port" ]; then
    echo "Error: port is not specified"
    exit 1
fi

if [ -z "$name" ]; then
    name="$port"
fi

if [ -z "$id" ]; then
    echo "Error: id is not specified"
    exit 1
fi

# read the config file
config=$(cat /usr/local/etc/v2ray/config.json)

# extract the EUVPS_IP from the config file
EUVPS_IP=$(echo "$config" | jq -r '.inbounds[-1].settings.address')

# extract the inbounds array from the config file
inbounds=$(echo "$config" | jq '.inbounds')

# count the number of elements in the inbounds array
num_inbounds=$(echo "$inbounds" | jq length)

# increment the last port number to get the new port number
new_port=$(( $(echo "$inbounds" | jq --argjson num_inbounds "$num_inbounds" '.[$num_inbounds-1].port') + 1 ))

# create the new inbound object
new_inbound=$(cat <<EOF
{
  "port": $new_port,
  "listen": "0.0.0.0",
  "protocol": "dokodemo-door",
  "settings": {
    "address": "$EUVPS_IP",
    "port": $port,
    "network": "tcp,udp"
  },
  "tag": "the-new-user-tag",
  "sniffing": {
    "enabled": true,
    "destOverride": [
      "http",
      "tls"
    ]
  }
}
EOF
)

# add the new inbound object to the inbounds array
new_inbounds=$(echo "$inbounds" | jq --argjson new_inbound "$new_inbound" '. + [$new_inbound]')

# update the config file with the new inbounds array
new_config=$(echo "$config" | jq --argjson new_inbounds "$new_inbounds" '.inbounds = $new_inbounds')

# save the updated config file
echo "$new_config" > /usr/local/etc/v2ray/config.json

systemctl restart v2ray.service

./napsternet_config.sh -n $name -p $port -i "$id"
