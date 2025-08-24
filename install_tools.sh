#!/bin/bash

# DeepRecon - Tools Installation Script
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
    echo -e "${CYAN}DeepRecon - Tools Installation Script${NC}"
    echo -e "${WHITE}Author: r0tbin | Version: 1.0${NC}"
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

# Detect operating system
detect_os() {
    log_info "Detecting operating system..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$NAME
            VER=$VERSION_ID
        else
            log_error "Could not detect Linux distribution"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    log_success "Detected: $OS"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install system dependencies
install_system_deps() {
    log_info "Installing system dependencies..."
    
    case $OS in
        "Ubuntu"|"Debian GNU/Linux")
            log_info "Using apt package manager..."
            sudo apt update
            sudo apt install -y curl jq git wget
            ;;
        "Arch Linux"|"Manjaro Linux")
            log_info "Using pacman package manager..."
            sudo pacman -Sy --noconfirm curl jq git wget
            ;;
        "macOS")
            log_info "Using Homebrew package manager..."
            if ! command_exists brew; then
                log_info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install curl jq git wget
            ;;
        *)
            log_error "Unsupported distribution: $OS"
            exit 1
            ;;
    esac
    
    log_success "System dependencies installed"
}

# Install Go
install_go() {
    if command_exists go; then
        log_success "Go is already installed: $(go version)"
        return 0
    fi
    
    log_info "Installing Go..."
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) GOARCH="amd64" ;;
        aarch64|arm64) GOARCH="arm64" ;;
        *) log_error "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    
    # Download and install Go
    GO_VERSION="1.21.0"
    GO_URL="https://go.dev/dl/go${GO_VERSION}.linux-${GOARCH}.tar.gz"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        GO_URL="https://go.dev/dl/go${GO_VERSION}.darwin-${GOARCH}.tar.gz"
    fi
    
    log_info "Downloading Go ${GO_VERSION}..."
    wget -q "$GO_URL" -O /tmp/go.tar.gz
    
    if [ $? -ne 0 ]; then
        log_error "Failed to download Go"
        exit 1
    fi
    
    log_info "Installing Go..."
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    
    # Add Go to PATH
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
    export PATH=$PATH:/usr/local/go/bin
    
    rm /tmp/go.tar.gz
    
    log_success "Go installed: $(go version)"
}

# Install npm if not present
install_npm() {
    if command_exists npm; then
        log_success "npm is already installed: $(npm --version)"
        return 0
    fi
    
    log_info "Installing Node.js and npm..."
    
    case $OS in
        "Ubuntu"|"Debian GNU/Linux")
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        "Arch Linux"|"Manjaro Linux")
            sudo pacman -S --noconfirm nodejs npm
            ;;
        "macOS")
            brew install node
            ;;
    esac
    
    log_success "npm installed: $(npm --version)"
}

# Install Go tools
install_go_tools() {
    log_info "Installing Go tools..."
    
    # Ensure Go is in PATH
    export PATH=$PATH:/usr/local/go/bin
    
    # Go tools to install
    declare -A go_tools=(
        ["subfinder"]="github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        ["amass"]="github.com/owasp-amass/amass/v4/...@master"
        ["httpx"]="github.com/projectdiscovery/httpx/cmd/httpx@latest"
        ["ffuf"]="github.com/ffuf/ffuf/v2@latest"
        ["katana"]="github.com/projectdiscovery/katana/cmd/katana@latest"
    )
    
    for tool in "${!go_tools[@]}"; do
        if command_exists "$tool"; then
            log_success "$tool is already installed"
        else
            log_info "Installing $tool..."
            go install -v "${go_tools[$tool]}"
            if [ $? -eq 0 ]; then
                log_success "$tool installed successfully"
            else
                log_error "Failed to install $tool"
            fi
        fi
    done
    
    # Install assetfinder (special case)
    if ! command_exists assetfinder; then
        log_info "Installing assetfinder..."
        if command_exists git; then
            log_info "Cloning assetfinder repository..."
            git clone https://github.com/tomnomnom/assetfinder.git /tmp/assetfinder
            if [ $? -eq 0 ]; then
                cd /tmp/assetfinder
                go mod init assetfinder
                go build .
                if [ $? -eq 0 ]; then
                    sudo mv assetfinder /usr/local/bin/
                    cd - > /dev/null
                    rm -rf /tmp/assetfinder
                    log_success "assetfinder installed successfully"
                else
                    cd - > /dev/null
                    rm -rf /tmp/assetfinder
                    log_error "Failed to build assetfinder"
                fi
            else
                log_error "Failed to clone assetfinder repository"
            fi
        else
            log_error "Failed to install assetfinder - git not found"
        fi
    else
        log_success "assetfinder is already installed"
    fi
    
    # Install findomain (special case)
    if ! command_exists findomain; then
        log_info "Installing findomain..."
        if command_exists curl; then
            log_info "Downloading findomain binary..."
            curl -LO https://github.com/findomain/findomain/releases/latest/download/findomain-linux-i386.zip
            if [ $? -eq 0 ]; then
                unzip -q findomain-linux-i386.zip
                chmod +x findomain
                sudo mv findomain /usr/bin/findomain
                rm findomain-linux-i386.zip
                log_success "findomain installed successfully"
            else
                log_error "Failed to download findomain"
            fi
        else
            log_error "Failed to install findomain - curl not found"
        fi
    else
        log_success "findomain is already installed"
    fi
}

# Install jsleak
install_jsleak() {
    log_info "Installing jsleak..."
    
    if command_exists jsleak; then
        log_success "jsleak is already installed"
        return 0
    fi
    
    npm install -g jsleak
    
    if [ $? -eq 0 ]; then
        log_success "jsleak installed successfully"
    else
        log_error "Failed to install jsleak"
    fi
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    # Check if deeprecon.sh exists
    if [ ! -f "./deeprecon.sh" ]; then
        log_error "deeprecon.sh not found in current directory"
        return 1
    fi
    
    # Make it executable
    chmod +x ./deeprecon.sh
    
    # Run tool check
    log_info "Running DeepRecon tool verification..."
    ./deeprecon.sh --check-tools
    
    if [ $? -eq 0 ]; then
        log_success "All tools installed successfully!"
        echo ""
        echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
        echo -e "${CYAN}You can now use DeepRecon with: ./deeprecon.sh --help${NC}"
    else
        log_warning "Some tools may not be installed correctly"
        echo -e "${YELLOW}Please check the output above and install missing tools manually${NC}"
    fi
}

# Main installation function
main() {
    show_banner
    
    log_info "Starting DeepRecon tools installation..."
    echo ""
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        log_error "Please do not run this script as root"
        exit 1
    fi
    
    # Detect OS
    detect_os
    
    # Install system dependencies
    install_system_deps
    
    # Install Go
    install_go
    
    # Install npm
    install_npm
    
    # Install Go tools
    install_go_tools
    
    # Install jsleak
    install_jsleak
    
    # Verify installation
    verify_installation
    
    echo ""
    log_info "Installation process completed!"
}

# Run main function
main "$@"
