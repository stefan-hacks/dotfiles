#!/usr/bin/env bash

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'
UNDERLINE='\033[4m'

# Check dependencies
check_dependencies() {
    local dependencies=("whois" "jq" "curl" "dig" "grep" "awk" "sed")
    local missing=()
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Missing dependencies:${NC}"
        for dep in "${missing[@]}"; do
            echo "  - $dep"
        done
        echo "Install with: sudo apt-get install whois jq curl dnsutils"
        exit 1
    fi
    
    # Check for grc (optional)
    if command -v grc &> /dev/null; then
        GRC_CMD="grc"
    else
        echo -e "${YELLOW}Note: Install 'grc' for enhanced colorization: sudo apt-get install grc${NC}"
        GRC_CMD=""
    fi
}

# Show help information
show_help() {
    echo -e "${BOLD}${UNDERLINE}NetIntel - Network Intelligence Tool${NC}"
    echo -e "${GREEN}Version: 2.0 | Author: NetSec Team${NC}\n"
    echo "Usage: $0 [OPTIONS] <TARGET>"
    echo -e "\n${BOLD}Target Types:${NC}"
    echo "  IP Address (e.g., 8.8.8.8)"
    echo "  URL/Domain (e.g., google.com)"
    echo "  Country Name/Code (e.g., 'United States' or 'US')"
    echo "  City Name (e.g., 'London')"
    
    echo -e "\n${BOLD}Options:${NC}"
    echo "  -h, --help          Show this help message"
    echo "  -v, --verbose       Enable verbose output"
    echo "  -c, --city <CITY>   Search for city information"
    echo "  -C, --country <CC>  Search for country information"
    echo "  -i, --ip <IP>       Specify IP address directly"
    echo "  -d, --dns           Show detailed DNS information"
    echo "  -w, --whois         Show full WHOIS information"
    echo "  -r, --range         Show all IP ranges for country"
    echo "  -s, --summary       Show summary information only"
    
    echo -e "\n${BOLD}Examples:${NC}"
    echo "  $0 8.8.8.8"
    echo "  $0 google.com -d"
    echo "  $0 -c 'New York'"
    echo "  $0 -C FR -r"
    echo "  $0 -i 1.1.1.1 -w"
    
    exit 0
}

# Resolve domain to IP
resolve_domain() {
    local domain=$1
    dig +short "$domain" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1
}

# Get WHOIS information
get_whois() {
    local ip=$1
    echo -e "\n${BOLD}${BLUE}====[ WHOIS INFORMATION ]====${NC}"
    if [ -n "$GRC_CMD" ] && [ "$FULL_WHOIS" != "true" ]; then
        $GRC_CMD -e whois "$ip" | grep -vE '^#|^%' | awk 'NF' | head -n 25
    else
        whois "$ip" | grep -vE '^#|^%' | awk 'NF' | head -n 25
    fi
    echo -e "\n${BOLD}Full WHOIS: whois $ip${NC}"
}

# Get IP geolocation
get_geolocation() {
    local ip=$1
    echo -e "\n${BOLD}${BLUE}====[ GEOLOCATION ]====${NC}"
    
    # Get data from ip-api.com
    local api_data=$(curl -s "http://ip-api.com/json/$ip?fields=status,message,continent,continentCode,country,countryCode,region,regionName,city,district,zip,lat,lon,timezone,offset,currency,isp,org,as,asname,reverse,proxy,hosting,query")
    
    if echo "$api_data" | jq -e '.status == "success"' &> /dev/null; then
        echo -e "${GREEN}Country:          $(echo "$api_data" | jq -r '.country // empty')${NC}"
        echo -e "${GREEN}Country Code:     $(echo "$api_data" | jq -r '.countryCode // empty')${NC}"
        echo -e "${GREEN}Region:           $(echo "$api_data" | jq -r '.regionName // empty')${NC}"
        echo -e "${GREEN}City:             $(echo "$api_data" | jq -r '.city // empty')${NC}"
        echo -e "${GREEN}ZIP Code:         $(echo "$api_data" | jq -r '.zip // empty')${NC}"
        echo -e "${GREEN}Coordinates:      $(echo "$api_data" | jq -r '.lat // empty'), $(echo "$api_data" | jq -r '.lon // empty')${NC}"
        echo -e "${GREEN}Timezone:         $(echo "$api_data" | jq -r '.timezone // empty')${NC}"
        echo -e "${GREEN}ISP:              $(echo "$api_data" | jq -r '.isp // empty')${NC}"
        echo -e "${GREEN}Organization:     $(echo "$api_data" | jq -r '.org // empty')${NC}"
        echo -e "${GREEN}AS Number:        $(echo "$api_data" | jq -r '.as // empty')${NC}"
        echo -e "${GREEN}AS Name:          $(echo "$api_data" | jq -r '.asname // empty')${NC}"
        echo -e "${GREEN}Reverse DNS:      $(echo "$api_data" | jq -r '.reverse // empty')${NC}"
        
        local proxy_status=$(echo "$api_data" | jq -r 'if .proxy == true then "Likely" else "Unlikely" end')
        if [ "$proxy_status" == "Likely" ]; then
            echo -e "${RED}VPN/Proxy:        $proxy_status${NC}"
        else
            echo -e "${GREEN}VPN/Proxy:        $proxy_status${NC}"
        fi
        
        local hosting_status=$(echo "$api_data" | jq -r 'if .hosting == true then "Yes" else "No" end')
        if [ "$hosting_status" == "Yes" ]; then
            echo -e "${RED}Hosting/Datacenter: $hosting_status${NC}"
        else
            echo -e "${GREEN}Hosting/Datacenter: $hosting_status${NC}"
        fi
        
        # Get map link
        local lat=$(echo "$api_data" | jq -r '.lat')
        local lon=$(echo "$api_data" | jq -r '.lon')
        if [[ $lat != "null" && $lon != "null" ]]; then
            echo -e "${CYAN}Map Link:         https://www.openstreetmap.org/?mlat=$lat&mlon=$lon&zoom=12${NC}"
        fi
    else
        echo -e "${RED}API Error: $(echo "$api_data" | jq -r '.message // "Unknown error"')${NC}"
    fi
}

# Get IP range information
get_ip_range() {
    local ip=$1
    echo -e "\n${BOLD}${BLUE}====[ IP RANGE & NETWORK ]====${NC}"
    
    # Get CIDR from whois
    local cidr=$(whois "$ip" | grep -iE 'CIDR|inetnum' | head -n1 | awk -F': ' '{print $2}')
    echo -e "${CYAN}Network Range:    $cidr${NC}"
    
    # Get organization from whois
    local org=$(whois "$ip" | grep -iE 'OrgName|netname|descr' | head -n1 | awk -F': ' '{print $2}')
    echo -e "${CYAN}Organization:     $org${NC}"
    
    # Get abuse contact
    local abuse_contact=$(whois "$ip" | grep -iE 'abuse-mailbox' | head -n1 | awk -F': ' '{print $2}')
    echo -e "${CYAN}Abuse Contact:    ${abuse_contact:-Not available}${NC}"
    
    # Get BGP ASN information
    echo -e "\n${BOLD}${BLUE}====[ BGP ASN INFORMATION ]====${NC}"
    curl -s "https://api.bgpview.io/ip/$ip" 2>/dev/null | jq -r '.data.prefixes[] | "ASN: \(.asn.asn) | Name: \(.asn.name) | Description: \(.asn.description_) | IP Range: \(.prefix)"' | sort -u
}

# Get detailed DNS information
get_dns_info() {
    local domain=$1
    echo -e "\n${BOLD}${BLUE}====[ DNS INFORMATION ]====${NC}"
    
    echo -e "${YELLOW}A Records:${NC}"
    dig +short A "$domain" | sort | uniq
    
    echo -e "\n${YELLOW}AAAA Records:${NC}"
    dig +short AAAA "$domain" | sort | uniq
    
    echo -e "\n${YELLOW}MX Records:${NC}"
    dig +short MX "$domain" | sort | uniq | awk '{print $2 " (Priority: " $1 ")"}'
    
    echo -e "\n${YELLOW}NS Records:${NC}"
    dig +short NS "$domain" | sort | uniq
    
    echo -e "\n${YELLOW}TXT Records:${NC}"
    dig +short TXT "$domain" | sort | uniq
    
    echo -e "\n${YELLOW}SOA Record:${NC}"
    dig +short SOA "$domain"
    
    echo -e "\n${YELLOW}DNS Sec Status:${NC}"
    dig +short DS "$domain" 2>/dev/null || echo "Not enabled"
}

# Get country information
get_country_info() {
    local country=$1
    echo -e "\n${BOLD}${BLUE}====[ COUNTRY INFORMATION ]====${NC}"
    
    # Get country data from REST Countries API
    local country_data=$(curl -s "https://restcountries.com/v3.1/alpha/$country")
    
    if echo "$country_data" | jq -e '.[0]' &> /dev/null; then
        echo -e "${GREEN}Country:          $(echo "$country_data" | jq -r '.[0].name.common')${NC}"
        echo -e "${GREEN}Official Name:    $(echo "$country_data" | jq -r '.[0].name.official')${NC}"
        echo -e "${GREEN}Capital:          $(echo "$country_data" | jq -r '.[0].capital[0]')${NC}"
        echo -e "${GREEN}Region:           $(echo "$country_data" | jq -r '.[0].region')${NC}"
        echo -e "${GREEN}Subregion:        $(echo "$country_data" | jq -r '.[0].subregion')${NC}"
        echo -e "${GREEN}Population:       $(printf "%'d" $(echo "$country_data" | jq -r '.[0].population'))${NC}"
        echo -e "${GREEN}Area:             $(printf "%'d" $(echo "$country_data" | jq -r '.[0].area')) km²${NC}"
        echo -e "${GREEN}Languages:        $(echo "$country_data" | jq -r '.[0].languages | to_entries | map(.value) | join(", ")')${NC}"
        echo -e "${GREEN}Currencies:       $(echo "$country_data" | jq -r '.[0].currencies | to_entries | map("\(.key) (\(.value.name))") | join(", ")')${NC}"
        echo -e "${GREEN}Timezones:        $(echo "$country_data" | jq -r '.[0].timezones | join(", ")')${NC}"
        echo -e "${GREEN}TLD:              $(echo "$country_data" | jq -r '.[0].tld | join(", ")')${NC}"
        
        # Get IP ranges for country
        echo -e "\n${BOLD}${YELLOW}IP RANGES:${NC}"
        local ranges=$(curl -s "https://stat.ripe.net/data/country-resource-list/data.json?resource=$country" | jq -r '.data.resources.ipv4[]' 2>/dev/null)
        
        if [ -n "$ranges" ]; then
            if [ "$SHOW_ALL_RANGES" == "true" ]; then
                echo "$ranges"
            else
                echo "$ranges" | head -n 20
                echo -e "${CYAN}(Showing first 20 ranges, use -r to show all)${NC}"
                echo "Total Ranges:     $(echo "$ranges" | wc -l)"
            fi
        else
            echo -e "${RED}No IP ranges found for $country${NC}"
        fi
    else
        echo -e "${RED}Country information not found${NC}"
    fi
}

# Get city information
get_city_info() {
    local city=$1
    echo -e "\n${BOLD}${BLUE}====[ CITY INFORMATION: $city ]====${NC}"
    
    # Use Nominatim API
    echo -e "${GREEN}Searching OpenStreetMap...${NC}"
    local api_data=$(curl -s "https://nominatim.openstreetmap.org/search?q=${city}&format=json")
    
    if [ "$(echo "$api_data" | jq length)" -gt 0 ]; then
        echo "$api_data" | jq -r '.[0] | "Name: \(.display_name)\nType: \(.type)\nCoordinates: \(.lat), \(.lon)\nImportance: \(.importance)"'
        
        # Get weather information
        local lat=$(echo "$api_data" | jq -r '.[0].lat')
        local lon=$(echo "$api_data" | jq -r '.[0].lon')
        if [[ $lat && $lon ]]; then
            echo -e "\n${BOLD}${YELLOW}CURRENT WEATHER:${NC}"
            curl -s "https://wttr.in/${city}?format=%l:+%C+%t+%h+%w+%p" 2>/dev/null || echo "Weather service unavailable"
        fi
    else
        echo -e "${RED}No results found for $city${NC}"
    fi
    
    # Get Wikipedia summary
    echo -e "\n${BOLD}${YELLOW}WIKIPEDIA SUMMARY:${NC}"
    curl -s "https://en.wikipedia.org/api/rest_v1/page/summary/${city}" | jq -r '.extract' 2>/dev/null || echo "Information unavailable"
}

# Main function
main() {
    check_dependencies
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -c|--city)
                CITY="$2"
                shift 2
                ;;
            -C|--country)
                COUNTRY="$2"
                shift 2
                ;;
            -i|--ip)
                IP="$2"
                shift 2
                ;;
            -d|--dns)
                DNS_INFO=true
                shift
                ;;
            -w|--whois)
                FULL_WHOIS=true
                shift
                ;;
            -r|--range)
                SHOW_ALL_RANGES=true
                shift
                ;;
            -s|--summary)
                SUMMARY=true
                shift
                ;;
            *)
                TARGET="$1"
                shift
                ;;
        esac
    done

    # Process target based on type
    if [ -n "$CITY" ]; then
        get_city_info "$CITY"
        exit 0
    fi
    
    if [ -n "$COUNTRY" ]; then
        get_country_info "$COUNTRY"
        exit 0
    fi
    
    if [ -z "$TARGET" ] && [ -z "$IP" ]; then
        echo -e "${RED}Error: No target specified${NC}"
        show_help
        exit 1
    fi

    # Determine target type
    if [ -n "$IP" ]; then
        ip=$IP
    elif [[ "$TARGET" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        ip=$TARGET
    else
        ip=$(resolve_domain "$TARGET")
        if [ -z "$ip" ]; then
            echo -e "${RED}Could not resolve domain: $TARGET${NC}"
            exit 1
        fi
        echo -e "\n${GREEN}Resolved $TARGET to $ip${NC}"
    fi

    # Show investigation header
    echo -e "\n${BOLD}${MAGENTA}====[ NETWORK INVESTIGATION: $ip ]====${NC}"
    
    # Process IP information
    if [ "$SUMMARY" != "true" ]; then
        get_whois "$ip"
        get_geolocation "$ip"
        get_ip_range "$ip"
    fi
    
    if [ "$DNS_INFO" == "true" ] && [ -n "$TARGET" ]; then
        get_dns_info "$TARGET"
    fi
    
    if [ "$FULL_WHOIS" == "true" ]; then
        echo -e "\n${BOLD}${BLUE}====[ FULL WHOIS INFORMATION ]====${NC}"
        if [ -n "$GRC_CMD" ]; then
            $GRC_CMD -e whois "$ip"
        else
            whois "$ip"
        fi
    fi
    
    echo -e "\n${BOLD}${GREEN}Investigation complete.${NC}"
}

# Start main execution
main "$@"
