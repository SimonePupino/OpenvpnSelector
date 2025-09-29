#!/bin/bash

CONFIG_DIR="$(dirname "$0")/config"
PIDFILE="/tmp/openvpn.pid"

while true; do
    clear

    # Get current public IP
    if command -v curl >/dev/null 2>&1; then
        CURR_IP=$(curl -s ifconfig.me)
    elif command -v wget >/dev/null 2>&1; then
        CURR_IP=$(wget -qO- ifconfig.me)
    else
        CURR_IP="N/A (install curl or wget)"
    fi

    # Check VPN status
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            STATUS="RUNNING (PID $PID)"
        else
            STATUS="DISABLED"
            rm -f "$PIDFILE"
        fi
    else
        STATUS="DISABLED"
    fi

    # Banner
    echo "=============================="
    echo " Welcome to OpenVPN Selector"
    echo " Current IP: $CURR_IP"
    echo " VPN status: $STATUS"
    echo "=============================="
    echo
    echo "[0] List config"
    echo "[1] Kill connection"
    echo "[2] Exit"
    echo "[3] Check public IP"
    echo
    read -p "Select an option: " opt

    case $opt in
        0)
            files=("$CONFIG_DIR"/*.ovpn)
            if [ ${#files[@]} -eq 0 ]; then
                echo "No .ovpn files found in $CONFIG_DIR"
                read -p "Press Enter to continue..."
                continue
            fi

            echo "Available configs:"
            i=1
            for f in "${files[@]}"; do
                echo "[$i] $(basename "$f")"
                i=$((i+1))
            done
            echo "[0] Back"
            read -p "Select config: " cfgchoice

            if [ "$cfgchoice" -gt 0 ] 2>/dev/null; then
                sel="${files[$((cfgchoice-1))]}"
                if [ -f "$sel" ]; then
                    echo "[!] Launching OpenVPN with $sel..."
                    sudo openvpn --config "$sel"
                    read -p "[!] Press Enter to continue..."
                fi
            fi
            ;;
        1)
            if [ -f "$PIDFILE" ]; then
                PID=$(cat "$PIDFILE")
                if ps -p $PID > /dev/null 2>&1; then
                    echo "Killing OpenVPN process $PID..."
                    sudo kill $PID
                else
                    echo "No active OpenVPN process."
                fi
                rm -f "$PIDFILE"
            else
                echo "No VPN connection found."
            fi
            read -p "Press Enter to continue..."
            ;;
        2)
            echo "Exiting..."
            exit 0
            ;;
        3)
            echo "Fetching current public IP..."
            if command -v curl >/dev/null 2>&1; then
                curl -s ifconfig.me
                echo
            elif command -v wget >/dev/null 2>&1; then
                wget -qO- ifconfig.me
                echo
            else
                echo "Neither curl nor wget is installed!"
            fi
            read -p "Press Enter to continue..."
            ;;
        *)
            echo "Invalid option"
            read -p "Press Enter to continue..."
            ;;
    esac
done