# DeepRecon 🔍

**Advanced Reconnaissance Tool by r0tbin**

DeepRecon is a comprehensive bash-based reconnaissance tool designed for security researchers and penetration testers. It automates the process of subdomain enumeration, alive checks, directory fuzzing, JavaScript extraction, and sensitive data discovery.

![Version](https://img.shields.io/badge/version-1.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Shell](https://img.shields.io/badge/shell-bash-yellow.svg)

## 🎯 Features

- **Subdomain Enumeration**: Multiple tools integration for comprehensive subdomain discovery
- **Alive Check**: HTTP status verification for discovered subdomains
- **Directory Fuzzing**: Automated directory and file discovery
- **JavaScript Extraction**: Crawl and extract JavaScript files from alive targets
- **Sensitive Data Detection**: Analyze JavaScript files for sensitive information
- **Tool Verification**: Automatic check for required dependencies
- **Colored Output**: Beautiful terminal output with color coding
- **Modular Design**: Easy to extend with new reconnaissance modules

## 🛠️ Required Tools

Before using DeepRecon, ensure the following tools are installed:

### Core Tools
- **subfinder** - Fast subdomain discovery tool
- **amass** - In-depth attack surface mapping
- **assetfinder** - Find domains and subdomains
- **findomain** - Cross-platform subdomain enumerator
- **httpx** - Fast and multi-purpose HTTP toolkit
- **ffuf** - Fast web fuzzer
- **katana** - Next-generation crawling and spidering framework
- **jsleak** - JavaScript secrets finder

### System Tools
- **jq** - JSON processor
- **curl** - Command line tool for transferring data

## 📦 Installation

### Quick Installation Script

```bash
# Clone the repository
git clone https://github.com/yourusername/deeprecon.git
cd deeprecon

# Make the script executable
chmod +x deeprecon.sh

# Check if all tools are installed
./deeprecon.sh --check-tools
```

### Manual Tool Installation

#### Ubuntu/Debian
```bash
# Install system dependencies
sudo apt update
sudo apt install curl jq git

# Install Go tools
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/owasp-amass/amass/v4/...@master
go install -v github.com/tomnomnom/assetfinder@latest
go install -v github.com/findomain/findomain@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/ffuf/ffuf/v2@latest
go install -v github.com/projectdiscovery/katana/cmd/katana@latest

# Install jsleak
npm install -g jsleak
```

#### Arch Linux
```bash
# Install from AUR
yay -S subfinder amass assetfinder findomain httpx ffuf katana

# Install jsleak
npm install -g jsleak
```

#### macOS
```bash
# Using Homebrew
brew install jq curl
brew install subfinder amass assetfinder findomain httpx ffuf katana

# Install jsleak
npm install -g jsleak
```

## 🚀 Usage

### Basic Syntax
```bash
./deeprecon.sh [OPTIONS] [FLAGS]
```

### Available Commands

#### 1. Subdomain Enumeration
Discover subdomains using multiple tools and sources.

```bash
./deeprecon.sh -u example.com --subdomains
```

**What it does:**
- Uses subfinder with recursive enumeration
- Runs amass passive enumeration
- Executes assetfinder for subdomain discovery
- Queries findomain database
- Searches crt.sh certificate transparency logs
- Consolidates all results into a unified list

**Output:** Creates `recon_example.com/subdomains.txt`

#### 2. Alive Check
Verify which discovered subdomains are actually alive and responsive.

```bash
./deeprecon.sh --alive
```

**Prerequisites:** Must have `subdomains.txt` file (from subdomain enumeration)

**What it does:**
- Checks HTTP status codes for all subdomains
- Extracts page titles
- Filters only responsive targets

**Output:** Creates `alive_subdomains.txt`

#### 3. Directory/File Fuzzing
Discover hidden directories and files on target domains.

```bash
./deeprecon.sh -u example.com --fuzzing
```

**What it does:**
- Uses ffuf with recursive fuzzing
- Searches for common directories and files
- Uses built-in wordlist or custom `wordlist.txt`

**Note:** If `wordlist.txt` doesn't exist, a basic wordlist will be created automatically.

#### 4. JavaScript Extraction
Crawl alive subdomains and extract JavaScript files.

```bash
./deeprecon.sh --extract-js
```

**Prerequisites:** Must have `alive_subdomains.txt` file

**What it does:**
- Uses katana to crawl up to 5 levels deep
- Extracts JavaScript files
- Verifies JS files are accessible (HTTP 200)

**Output:** Creates `alive_js.txt`

#### 5. Sensitive Data Detection
Analyze JavaScript files for sensitive information.

```bash
./deeprecon.sh --sensible-data
```

**Prerequisites:** Must have `alive_js.txt` file

**What it does:**
- Scans JavaScript files for API keys
- Looks for sensitive strings and patterns
- Identifies potential security leaks

#### 6. Tool Verification
Check if all required tools are properly installed.

```bash
./deeprecon.sh --check-tools
```

**What it does:**
- Verifies each required tool is in PATH
- Reports missing dependencies
- Provides installation guidance

### 🔄 Complete Workflow Example

Here's a complete reconnaissance workflow:

```bash
# Step 1: Verify all tools are installed
./deeprecon.sh --check-tools

# Step 2: Enumerate subdomains
./deeprecon.sh -u target.com --subdomains

# Step 3: Check which subdomains are alive
./deeprecon.sh --alive

# Step 4: Perform directory fuzzing
./deeprecon.sh -u target.com --fuzzing

# Step 5: Extract JavaScript files
./deeprecon.sh --extract-js

# Step 6: Search for sensitive data
./deeprecon.sh --sensible-data
```

## 📁 Output Structure

After running the complete workflow, you'll have the following files:

```
DeepRecon/
├── deeprecon.sh
├── recon_target.com/
│   ├── subfinder.txt
│   ├── amass_passive.txt
│   ├── assetfinder.txt
│   ├── findomain.txt
│   ├── crth.txt
│   ├── crt_fallback.txt
│   └── subdomains.txt          # Consolidated subdomains
├── alive_subdomains.txt         # Live subdomains with status
├── alive_js.txt                 # Accessible JavaScript files
└── wordlist.txt                 # Fuzzing wordlist
```

## 🎨 Output Colors

DeepRecon uses color-coded output for better readability:

- 🟢 **Green**: Success messages and completed tasks
- 🔵 **Blue**: Informational messages
- 🟡 **Yellow**: Warnings and usage information
- 🔴 **Red**: Error messages
- 🟣 **Purple**: Banner and branding
- 🔷 **Cyan**: Examples and highlights

## ⚙️ Customization

### Custom Wordlists

Replace the default `wordlist.txt` with your preferred wordlist:

```bash
# Download a comprehensive wordlist
wget https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt -O wordlist.txt

# Or use your custom wordlist
cp /path/to/your/wordlist.txt ./wordlist.txt
```

### Adding New Modules

DeepRecon is designed to be easily extensible. To add a new module:

1. Create a new function in the script
2. Add the command-line option parsing
3. Add the new option to the usage function
4. Test your module

Example:
```bash
# Add to the case statement in main()
"--your-module")
    action="your-module"
    shift
    ;;

# Add new function
your_module() {
    log_info "Running your custom module..."
    # Your code here
    log_success "Your module completed!"
}
```

## 🐛 Troubleshooting

### Common Issues

**1. "Tool not found" errors**
```bash
# Check if tool is in PATH
which subfinder
echo $PATH

# Ensure Go tools are in PATH
export PATH=$PATH:~/go/bin
```

**2. "Permission denied" errors**
```bash
# Make script executable
chmod +x deeprecon.sh

# Check file permissions
ls -la deeprecon.sh
```

**3. "No such file or directory" for input files**
- Ensure you run modules in the correct order
- Check if prerequisite files exist before running dependent modules

**4. Network connectivity issues**
```bash
# Test internet connectivity
curl -I https://google.com

# Check DNS resolution
nslookup example.com
```

### Debug Mode

For verbose output, you can modify the script to include debug information:

```bash
# Add to the beginning of any function
set -x  # Enable debug mode
# Your code here
set +x  # Disable debug mode
```

## 🔒 Security Considerations

- **Rate Limiting**: Some modules may trigger rate limiting. Use responsibly.
- **Legal**: Only use on domains you own or have explicit permission to test.
- **Data Handling**: Be careful with sensitive data found in JavaScript files.
- **Network Traffic**: The tool generates significant network traffic during scans.

## 📝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Development Guidelines

- Follow bash best practices
- Add proper error handling
- Include logging for all operations
- Update documentation for new features
- Test on multiple systems

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **ProjectDiscovery** - For amazing security tools (subfinder, httpx, katana)
- **OWASP Amass** - For comprehensive attack surface mapping
- **Tom Hudson** - For assetfinder
- **Eduard Tolosa** - For findomain
- **Joona Hoikkala** - For ffuf
- **jsleak contributors** - For JavaScript security analysis

## 📞 Contact

- **Author**: r0tbin
- **Version**: 1.0
- **Repository**: [GitHub Repository URL]

---

**⚠️ Disclaimer**: This tool is for educational and authorized security testing purposes only. Users are responsible for complying with applicable laws and regulations. The author is not responsible for any misuse of this tool.

**🎯 Happy Hunting!** 🔍