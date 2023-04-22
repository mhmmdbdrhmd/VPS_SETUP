#!/bin/bash

#example napsternet_config.sh --port 54321 --name MOHAMMAD --id "ff87f555-1b4c-4346-efc7-60f5620c1184"


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

config_path="/usr/local/etc/v2ray/config.json"
vpn_configs_path="$HOME/VPN_CONFIGS"

if [ ! -d "$vpn_configs_path" ]; then
    mkdir "$vpn_configs_path"
fi

new_port=$(jq -r --arg port "$port" '.inbounds[] | select(.settings.port == ($port|tonumber)) | .port' "$config_path")

if [ -z "$new_port" ]; then
    echo "Error: Port $port is not found in $config_path"
    exit 1
fi

irvps_ip=$(hostname -I | awk '{print $1}')


output_file="$vpn_configs_path/${name}_${port}.txt"
echo "{\"routing\":{\"domainStrategy\":\"Asls\"},\"inbounds\":[{\"sniffing\":{\"enabled\":false},\"listen\":\"127.0.0.1\",\"protocol\":\"socks\",\"settings\":{\"udp\":true,\"auth\":\"noauth\",\"userLevel\":8},\"tag\":\"socks\",\"port\":10808}],\"outbounds\":[{\"mux\":{\"enabled\":false},\"streamSettings\":{\"network\":\"tcp\",\"security\":\"none\"},\"protocol\":\"vmess\",\"settings\":{\"vnext\":[{\"address\":\"$irvps_ip\",\"users\":[{\"id\":\"$id\",\"alterId\":0,\"security\":\"auto\",\"level\":8}],\"port\":$new_port}]}}],\"log\":{\"loglevel\":\"none\"},\"dns\":{\"servers\":[\"8.8.8.8\",\"8.8.4.4\"]}}" > "$output_file"

echo "Generated config file: $output_file"
echo ""
cat $output_file
