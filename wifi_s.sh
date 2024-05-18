#!/bin/bash
# 2024.05.17
# Only Linux

installi(){
    if ! command -v airmon-ng &> /dev/null; then
        echo "Installing aircrack-ng..."
        sudo apt update && sudo apt install -y aircrack-ng
        if [ $? -ne 0 ]; then
            echo "Failed to install aircrack-ng. Exiting."
            exit 1
        fi
    else
        echo "aircrack-ng is already installed."
    fi
    clear
}

function banner(){
    echo " ▄▀▀▄    ▄▀▀▄  ▄▀▀█▀▄    ▄▀▀▀█▄    ▄▀▀█▀▄       ▄▀▀▀▀▄ "
    echo "█   █    ▐  █ █   █  █  █  ▄▀  ▀▄ █   █  █     █ █   ▐ "
    echo "▐  █        █ ▐   █  ▐  ▐ █▄▄▄▄   ▐   █  ▐        ▀▄   "
    echo "  █   ▄    █      █      █    ▐       █        ▀▄   █  "
    echo "   ▀▄▀ ▀▄ ▄▀   ▄▀▀▀▀▀▄   █         ▄▀▀▀▀▀▄      █▀▀▀   "
    echo "         ▀    █       █ █         █       █     ▐      "
    echo "              ▐       ▐ ▐         ▐       ▐            "
    echo "Created By: Crashiz     ver 1.0                        "
}

function connect(){
    SSID="Rego_Wifi"
    PASS="moongive723"
    echo "Bringing wlan0 up..."
    sudo ifconfig wlan0 up
    if [ $? -ne 0 ]; then
        echo "Failed to bring wlan0 up. Exiting."
        exit 1
    fi

    while true; do
        echo "Connecting to WiFi network $SSID..."
        sudo nmcli device wifi connect "$SSID" password "$PASS"
        sleep 4
        if [ $? -eq 0 ]; then
            echo "Successfully connected to $SSID."
            break
        else
            echo "Failed to connect to $SSID. Retrying..."
            sleep 1
        fi
    done

    # Get the MAC address of the connected network
    mac_address=$(sudo nmcli -t -f ACTIVE,BSSID dev wifi | grep '^yes' | cut -d':' -f2- | tr -d '\\')
    echo "Connected MAC Address: $mac_address"

    # Get the channel of the connected network
    channel=$(sudo iwlist wlan0 channel | grep "Current Frequency" | awk '{print $5}' | sed 's/.$//')
    echo "Connected Channel: $channel"
}

function sniff(){
    echo "Stopping interfering processes..."
    sudo airmon-ng check kill
    if [ $? -ne 0 ]; then
        echo "Failed to stop interfering processes. Exiting."
        exit 1
    fi

    echo "Identifying wireless interfaces..."
    interfaces=$(sudo iw dev | awk '$1=="Interface"{print $2}')
    if [ -z "$interfaces" ];then
        echo "No wireless interfaces found. Exiting."
        exit 1
    fi

    for interface in $interfaces; do
        echo "Starting airmon-ng on $interface..."
        sudo airmon-ng start $interface
        if [ $? -ne 0 ];then
            echo "Failed to start airmon-ng on $interface. Exiting."
            exit 1
        fi

        # Get the monitor mode interface name
        mon_interface="${interface}mon"
	echo "sudo airodump-ng --channel $channel --bssid $mac_address --write testt $mon_interface"
        echo "Starting airodump-ng on $mon_interface with channel $channel and BSSID $mac_address"
        sudo airodump-ng --channel $channel --bssid $mac_address --write testt $mon_interface
        if [ $? -ne 0 ];then
            echo "Failed to start airodump-ng on $mon_interface. Exiting."
            exit 1
        fi

        sleep 60

        echo "Stopping airodump-ng on $mon_interface..."
        sudo kill $PID_AIRODUMP

        echo "Stopping airmon-ng on $mon_interface and switching back to managed mode..."
        sudo airmon-ng stop $mon_interface
        if [ $? -ne 0 ];then
            echo "Failed to stop airmon-ng on $mon_interface. Exiting."
            exit 1
        fi
    done
}

#########
installi
banner
connect
sniff
