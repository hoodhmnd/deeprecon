#!/bin/bash

# DeepRecon - Advanced Reconnaissance Tool
# Author: r0tbin
# Version: 1.0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Banner
show_banner() {
    echo -e "${PURPLE}"
    echo "██████╗  ██████╗ ████████╗██████╗ ██╗███╗   ██╗"
    echo "██╔══██╗██╔═████╗╚══██╔══╝██╔══██╗██║████╗  ██║"
    echo "██████╔╝██║██╔██║   ██║   ██████╔╝██║██╔██╗ ██║"
    echo "██╔══██╗████╔╝██║   ██║   ██╔══██╗██║██║╚██╗██║"
    echo "██║  ██║╚██████╔╝   ██║   ██████╔╝██║██║ ╚████║"
    echo "╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═════╝ ╚═╝╚═╝  ╚═══╝"
    echo -e "${NC}"
    echo -e "${CYAN}DeepRecon - Advanced Reconnaissance Tool${NC}"
    echo -e "${WHITE}Author: r0tbin | Version: 1.0${NC}"
    echo ""
}

# Usage function
usage() {
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ${WHITE}$0 -u <domain> --subdomains${NC}     Enumerate subdomains"
    echo -e "  ${WHITE}$0 --alive${NC}                      Check alive subdomains"
    echo -e "  ${WHITE}$0 -u <domain> --fuzzing${NC}        Directory/file fuzzing"
    echo -e "  ${WHITE}$0 --extract-js${NC}                 Extract JavaScript files"
    echo -e "  ${WHITE}$0 --sensible-data${NC}              Find sensitive data in JS files"
    echo -e "  ${WHITE}$0 --check-tools${NC}                Verify required tools installation"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${CYAN}$0 -u example.com --subdomains${NC}"
    echo -e "  ${CYAN}$0 --alive${NC}"
    echo -e "  ${CYAN}$0 -u example.com --fuzzing${NC}"
    echo -e "  ${CYAN}$0 --extract-js${NC}"
    echo -e "  ${CYAN}$0 --sensible-data${NC}"
    echo -e "  ${CYAN}$0 --check-tools${NC}"
    echo ""
}

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if required tools are installed
check_tools() {
    log_info "Checking required tools installation..."
    
    local tools=("subfinder" "amass" "assetfinder" "findomain" "jq" "curl" "httpx" "ffuf" "katana" "jsleaks")
    local missing_tools=()
    local all_installed=true
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_success "$tool is installed"
        else
            log_error "$tool is not installed"
            missing_tools+=("$tool")
            all_installed=false
        fi
    done
    
    if [ "$all_installed" = false ]; then
        echo ""
        log_error "The following tools are missing:"
        for tool in "${missing_tools[@]}"; do
            echo -e "  ${RED}•${NC} $tool"
        done
        echo ""
        log_info "Please install the missing tools before using DeepRecon"
        return 1
    else
        echo ""
        log_success "All required tools are installed!"
        return 0
    fi
}

# Subdomain enumeration
enumerate_subdomains() {
    local domain="$1"
    
    if [ -z "$domain" ]; then
        log_error "Domain is required for subdomain enumeration"
        usage
        exit 1
    fi
    
    log_info "Starting subdomain enumeration for: $domain"
    echo ""
    
    # Create output directory
    mkdir -p "recon_$domain"
    cd "recon_$domain" || exit 1
    
    log_info "Running subfinder..."
    subfinder -d "$domain" -all -recursive -t 10 -o subfinder.txt
    log_success "Subfinder completed"
    
    log_info "Running amass passive enumeration..."
    amass enum -passive -d "$domain" > amass_passive.txt
    log_success "Amass completed"
    
    log_info "Running assetfinder..."
    assetfinder --subs-only "$domain" > assetfinder.txt
    log_success "Assetfinder completed"
    
    log_info "Running findomain..."
    findomain -t "$domain" -u findomain.txt
    log_success "Findomain completed"
    
    log_info "Querying crt.sh..."
    curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | grep -i "$domain" > crth.txt 2>/dev/null
    log_success "crt.sh query completed"
    
    log_info "Running crt.sh fallback method..."
    curl -s "https://crt.sh/?q=%25.$domain&output=json" | grep -o '"name_value":"[^"]*"' | cut -d':' -f2 | tr -d '"' | sort -u > crt_fallback.txt
    log_success "crt.sh fallback completed"
    
    log_info "Consolidating results..."
    cat *.txt | sort -u > subdomains.txt
    
    local count=$(wc -l < subdomains.txt)
    log_success "Subdomain enumeration completed! Found $count unique subdomains"
    log_info "Results saved in: recon_$domain/subdomains.txt"
    
    cd ..
}

# Check alive subdomains
check_alive() {
    log_info "Checking alive subdomains..."
    
    if [ ! -f "subdomains.txt" ]; then
        # Look for subdomains.txt in recon directories
        local recon_dir=$(find . -name "recon_*" -type d | head -n 1)
        if [ -n "$recon_dir" ] && [ -f "$recon_dir/subdomains.txt" ]; then
            cp "$recon_dir/subdomains.txt" .
        else
            log_error "subdomains.txt not found. Please run subdomain enumeration first."
            exit 1
        fi
    fi
    
    log_info "Running httpx to check alive subdomains..."
    httpx -status-code -title -list subdomains.txt -o alive_subdomains.txt
    
    local count=$(wc -l < alive_subdomains.txt)
    log_success "Alive check completed! Found $count alive subdomains"
    log_info "Results saved in: alive_subdomains.txt"
}

# Directory/file fuzzing
run_fuzzing() {
    local domain="$1"
    
    if [ -z "$domain" ]; then
        log_error "Domain is required for fuzzing"
        usage
        exit 1
    fi
    
    # Check if wordlist exists
    if [ ! -f "wordlist.txt" ]; then
        log_warning "wordlist.txt not found. Creating a basic wordlist..."
        cat > wordlist.txt << 'EOF'
admin
api
app
backup
config
dev
docs
login
panel
test
upload
wp-admin
.git
.env
robots.txt
sitemap.xml
index.php
admin.php
config.php
EOF
        log_info "Basic wordlist created. You can replace it with a more comprehensive one."
    fi
    
    log_info "Starting directory/file fuzzing for: $domain"
    ffuf -w wordlist.txt -u "http://$domain/FUZZ" -recursion -recursion-depth 2
    
    log_success "Fuzzing completed for $domain"
}

# Extract JavaScript files
extract_js() {
    log_info "Extracting JavaScript files..."
    
    if [ ! -f "alive_subdomains.txt" ]; then
        log_error "alive_subdomains.txt not found. Please run alive check first."
        exit 1
    fi
    
    log_info "Running katana to crawl and extract JS files..."
    katana -list alive_subdomains.txt -d 5 -jc | grep '\.js$' | httpx -mc 200 -silent -o alive_js.txt
    
    local count=$(wc -l < alive_js.txt 2>/dev/null || echo "0")
    log_success "JavaScript extraction completed! Found $count JS files"
    log_info "Results saved in: alive_js.txt"
}

# Find sensitive data in JS files
find_sensitive_data() {
    log_info "Searching for sensitive data in JavaScript files..."
    
    if [ ! -f "alive_js.txt" ]; then
        log_error "alive_js.txt not found. Please run JS extraction first."
        exit 1
    fi
    
    log_info "Running jsleaks to find sensitive data..."
    cat alive_js.txt | jsleaks -s -l -k
    
    log_success "Sensitive data analysis completed!"
}

# Main function
main() {
    show_banner
    
    # Parse command line arguments
    local domain=""
    local action=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--url)
                domain="$2"
                shift 2
                ;;
            --subdomains)
                action="subdomains"
                shift
                ;;
            --alive)
                action="alive"
                shift
                ;;
            --fuzzing)
                action="fuzzing"
                shift
                ;;
            --extract-js)
                action="extract-js"
                shift
                ;;
            --sensible-data)
                action="sensible-data"
                shift
                ;;
            --check-tools)
                action="check-tools"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Validate arguments and execute actions
    case $action in
        "subdomains")
            if [ -z "$domain" ]; then
                log_error "Domain (-u) is required for subdomain enumeration"
                usage
                exit 1
            fi
            enumerate_subdomains "$domain"
            ;;
        "alive")
            check_alive
            ;;
        "fuzzing")
            if [ -z "$domain" ]; then
                log_error "Domain (-u) is required for fuzzing"
                usage
                exit 1
            fi
            run_fuzzing "$domain"
            ;;
        "extract-js")
            extract_js
            ;;
        "sensible-data")
            find_sensitive_data
            ;;
        "check-tools")
            check_tools
            ;;
        "")
            log_error "No action specified"
            usage
            exit 1
            ;;
        *)
            log_error "Invalid action: $action"
            usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"