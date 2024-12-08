

############################
# routines
############################

variables() {
  NSAPP=$(echo ${APP,,} | tr -d ' ') # This function sets the NSAPP variable by converting the value of the APP variable to lowercase and removing any spaces.
  var_install="${NSAPP}-install"     # sets the var_install variable by appending "-install" to the value of NSAPP.
  INTEGER='^[0-9]+([.][0-9]+)?$'     # it defines the INTEGER regular expression pattern.
}

# This function sets various color variables using ANSI escape codes for formatting text in the terminal.
color() {
  YW=$(echo "\033[33m")
  YWB=$(echo "\033[93m")
  BL=$(echo "\033[36m")
  RD=$(echo "\033[01;31m")
  BGN=$(echo "\033[4;92m")
  GN=$(echo "\033[1;92m")
  DGN=$(echo "\033[32m")
  CL=$(echo "\033[m")

  RETRY_NUM=10
  RETRY_EVERY=3

  CM="${GN}✓${CL}"
  CROSS="${RD}✗${CL}"
  BFR="\\r\\033[K"
  HOLD=" "
}


# This function enables error handling in the script by setting options and defining a trap for the ERR signal.
catch_errors() {
  set -Eeuo pipefail
  trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
}

# This function is called when an error occurs. It receives the exit code, line number, and command that caused the error, and displays an error message.
error_handler() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  local error_message="${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}"
  echo -e "\n$error_message\n"
}

# This function displays a spinner.
spinner() {
    local chars="/-\|"
    local spin_i=0
    printf "\e[?25l"
    while true; do
        printf "\r \e[36m%s\e[0m" "${chars:spin_i++%${#chars}:1}"
        sleep 0.1
    done
}

# This function displays an informational message with a yellow color.
msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}   "
  spinner &
  SPINNER_PID=$!
}

# This function displays a success message with a green color.
msg_ok() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

# This function displays a error message with a red color.
msg_error() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local msg="$1"
  echo -e "${BFR} ${CROSS} ${RD}${msg}${CL}"
}

# Check if the shell is using bash
shell_check() {
  if [[ "$(basename "$SHELL")" != "bash" ]]; then
    clear
    msg_error "Your default shell is currently not set to Bash. To use these scripts, please switch to the Bash shell."
    echo -e "\nExiting..."
    sleep 2
    exit
  fi
}

# Run as root only
root_check() {
  if [[ "$(id -u)" -ne 0 || $(ps -o comm= -p $PPID) == "sudo" ]]; then
    clear
    msg_error "Please run this script as root."
    echo -e "\nExiting..."
    sleep 2
    exit
  fi
}

# This function checks the version of Proxmox Virtual Environment (PVE) and exits if the version is not supported.
pve_check() {
  if ! pveversion | grep -Eq "pve-manager/7.[1-9]"; then
    msg_error "This version of Proxmox Virtual Environment is not supported"
    echo -e "Requires Proxmox Virtual Environment Version 7.1 or later."
    echo -e "Exiting..."
    sleep 2
    exit
fi
}

# This function checks the system architecture and exits if it's not "amd64".
arch_check() {
  if [ "$(dpkg --print-architecture)" != "amd64" ]; then
    echo -e "\n ${CROSS} This script will not work with PiMox! \n"
    echo -e "\n Visit https://github.com/asylumexp/Proxmox for ARM64 support. \n"
    echo -e "Exiting..."
    sleep 2
    exit
  fi
}

# This function checks if the script is running through SSH and prompts the user to confirm if they want to proceed or exit.
ssh_check() {
  if command -v pveversion >/dev/null 2>&1 && [ -n "${SSH_CLIENT:+x}" ]; then
    if whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "SSH DETECTED" --yesno "It's advisable to utilize the Proxmox shell rather than SSH, as there may be potential complications with variable retrieval. Proceed using SSH?" 10 72; then
      whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Proceed using SSH" "You've chosen to proceed using SSH. If any issues arise, please run the script in the Proxmox shell before creating a repository issue." 10 72
    else
      clear
      echo "Exiting due to SSH usage. Please consider using the Proxmox shell."
      exit
    fi
  fi
}

# This function displays the default values for various settings.
echo_default() {
  echo -e "${DGN}Using Distribution: ${BGN}$var_os${CL}"
  echo -e "${DGN}Using $var_os Version: ${BGN}$var_version${CL}"
  echo -e "${DGN}Using Container Type: ${BGN}$CT_TYPE${CL}"
  echo -e "${DGN}Using Root Password: ${BGN}Automatic Login${CL}"
  echo -e "${DGN}Using Container ID: ${BGN}$NEXTID${CL}"
  echo -e "${DGN}Using Hostname: ${BGN}$NSAPP${CL}"
  echo -e "${DGN}Using Disk Size: ${BGN}$var_disk${CL}${DGN}GB${CL}"
  echo -e "${DGN}Allocated Cores ${BGN}$var_cpu${CL}"
  echo -e "${DGN}Allocated Ram ${BGN}$var_ram${CL}"
  echo -e "${DGN}Using Bridge: ${BGN}vmbr0${CL}"
  echo -e "${DGN}Using Static IP Address: ${BGN}dhcp${CL}"
  echo -e "${DGN}Using Gateway IP Address: ${BGN}Default${CL}"
  echo -e "${DGN}Using Apt-Cacher IP Address: ${BGN}Default${CL}"
  echo -e "${DGN}Disable IPv6: ${BGN}No${CL}"
  echo -e "${DGN}Using Interface MTU Size: ${BGN}Default${CL}"
  echo -e "${DGN}Using DNS Search Domain: ${BGN}Host${CL}"
  echo -e "${DGN}Using DNS Server Address: ${BGN}Host${CL}"
  echo -e "${DGN}Using MAC Address: ${BGN}Default${CL}"
  echo -e "${DGN}Using VLAN Tag: ${BGN}Default${CL}"
  echo -e "${DGN}Enable Root SSH Access: ${BGN}No${CL}"
  echo -e "${DGN}Enable Verbose Mode: ${BGN}No${CL}"
  echo -e "${BL}Creating a ${APP} LXC using the above default settings${CL}"
}

# This function is called when the user decides to exit the script. It clears the screen and displays an exit message.
exit-script() {
  clear
  echo -e "⚠  User exited script \n"
  exit
}

# This function allows the user to configure advanced settings for the script.
advanced_settings() {
  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Here is an instructional tip:" "To make a selection, use the Spacebar." 8 58
  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Default distribution for $APP" "${var_os} ${var_version} \n \nIf the default Linux distribution is not adhered to, script support will be discontinued. \n" 10 58
  if [ "$var_os" != "alpine" ]; then
    var_os=""
    while [ -z "$var_os" ]; do
      if var_os=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "DISTRIBUTION" --radiolist "Choose Distribution:" 10 58 2 \
        "debian" "" OFF \
        "ubuntu" "" OFF \
        3>&1 1>&2 2>&3); then
        if [ -n "$var_os" ]; then
          echo -e "${DGN}Using Distribution: ${BGN}$var_os${CL}"
        fi
      else
        exit-script
      fi
    done
  fi

  if [ "$var_os" == "debian" ]; then

   # apt-get install whiptail?

    var_version=""
    while [ -z "$var_version" ]; do
      if var_version=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "DEBIAN VERSION" --radiolist "Choose Version" 10 58 2 \
        "11" "Bullseye" OFF \
        "12" "Bookworm" OFF \
        3>&1 1>&2 2>&3); then
        if [ -n "$var_version" ]; then
          echo -e "${DGN}Using $var_os Version: ${BGN}$var_version${CL}"
        fi
      else
        exit-script
      fi
    done
  fi

  if [ "$var_os" == "ubuntu" ]; then
    var_version=""
    while [ -z "$var_version" ]; do
      if var_version=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "UBUNTU VERSION" --radiolist "Choose Version" 10 58 3 \
        "20.04" "Focal" OFF \
        "22.04" "Jammy" OFF \
        "24.04" "Noble" OFF \
        3>&1 1>&2 2>&3); then
        if [ -n "$var_version" ]; then
          echo -e "${DGN}Using $var_os Version: ${BGN}$var_version${CL}"
        fi
      else
        exit-script
      fi
    done
  fi

  CT_TYPE=""
  while [ -z "$CT_TYPE" ]; do
    if CT_TYPE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "CONTAINER TYPE" --radiolist "Choose Type" 10 58 2 \
      "1" "Unprivileged" OFF \
      "0" "Privileged" OFF \
      3>&1 1>&2 2>&3); then
      if [ -n "$CT_TYPE" ]; then
        echo -e "${DGN}Using Container Type: ${BGN}$CT_TYPE${CL}"
      fi
    else
      exit-script
    fi
  done

  while true; do
    if PW1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --passwordbox "\nSet Root Password (needed for root ssh access)" 9 58 --title "PASSWORD (leave blank for automatic login)" 3>&1 1>&2 2>&3); then
      if [[ ! -z "$PW1" ]]; then
        if [[ "$PW1" == *" "* ]]; then
          whiptail --msgbox "Password cannot contain spaces. Please try again." 8 58
        elif [ ${#PW1} -lt 5 ]; then
          whiptail --msgbox "Password must be at least 5 characters long. Please try again." 8 58
        else
          if PW2=$(whiptail --backtitle "Proxmox VE Helper Scripts" --passwordbox "\nVerify Root Password" 9 58 --title "PASSWORD VERIFICATION" 3>&1 1>&2 2>&3); then
            if [[ "$PW1" == "$PW2" ]]; then
              PW="-password $PW1"
              echo -e "${DGN}Using Root Password: ${BGN}********${CL}"
              break
            else
              whiptail --msgbox "Passwords do not match. Please try again." 8 58
            fi
          else
            exit-script
          fi
        fi
      else
        PW1="Automatic Login"
        PW=""
        echo -e "${DGN}Using Root Password: ${BGN}$PW1${CL}"
        break
      fi
    else
      exit-script
    fi
  done


  if CT_ID=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Container ID" 8 58 $NEXTID --title "CONTAINER ID" 3>&1 1>&2 2>&3); then
    if [ -z "$CT_ID" ]; then
      CT_ID="$NEXTID"
      echo -e "${DGN}Using Container ID: ${BGN}$CT_ID${CL}"
    else
      echo -e "${DGN}Container ID: ${BGN}$CT_ID${CL}"
    fi
  else
    exit
  fi

  if CT_NAME=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Hostname" 8 58 $NSAPP --title "HOSTNAME" 3>&1 1>&2 2>&3); then
    if [ -z "$CT_NAME" ]; then
      HN="$NSAPP"
    else
      HN=$(echo ${CT_NAME,,} | tr -d ' ')
    fi
    echo -e "${DGN}Using Hostname: ${BGN}$HN${CL}"
  else
    exit-script
  fi

  if DISK_SIZE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Disk Size in GB" 8 58 $var_disk --title "DISK SIZE" 3>&1 1>&2 2>&3); then
    if [ -z "$DISK_SIZE" ]; then
      DISK_SIZE="$var_disk"
      echo -e "${DGN}Using Disk Size: ${BGN}$DISK_SIZE${CL}"
    else
      if ! [[ $DISK_SIZE =~ $INTEGER ]]; then
        echo -e "${RD}⚠ DISK SIZE MUST BE AN INTEGER NUMBER!${CL}"
        advanced_settings
      fi
      echo -e "${DGN}Using Disk Size: ${BGN}$DISK_SIZE${CL}"
    fi
  else
    exit-script
  fi

  if CORE_COUNT=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate CPU Cores" 8 58 $var_cpu --title "CORE COUNT" 3>&1 1>&2 2>&3); then
    if [ -z "$CORE_COUNT" ]; then
      CORE_COUNT="$var_cpu"
      echo -e "${DGN}Allocated Cores: ${BGN}$CORE_COUNT${CL}"
    else
      echo -e "${DGN}Allocated Cores: ${BGN}$CORE_COUNT${CL}"
    fi
  else
    exit-script
  fi

  if RAM_SIZE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate RAM in MiB" 8 58 $var_ram --title "RAM" 3>&1 1>&2 2>&3); then
    if [ -z "$RAM_SIZE" ]; then
      RAM_SIZE="$var_ram"
      echo -e "${DGN}Allocated RAM: ${BGN}$RAM_SIZE${CL}"
    else
      echo -e "${DGN}Allocated RAM: ${BGN}$RAM_SIZE${CL}"
    fi
  else
    exit-script
  fi

  if BRG=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a Bridge" 8 58 vmbr0 --title "BRIDGE" 3>&1 1>&2 2>&3); then
    if [ -z "$BRG" ]; then
      BRG="vmbr0"
      echo -e "${DGN}Using Bridge: ${BGN}$BRG${CL}"
    else
      echo -e "${DGN}Using Bridge: ${BGN}$BRG${CL}"
    fi
  else
    exit-script
  fi

  while true; do
    NET=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a Static IPv4 CIDR Address (/24)" 8 58 dhcp --title "IP ADDRESS" 3>&1 1>&2 2>&3)
    exit_status=$?
    if [ $exit_status -eq 0 ]; then
      if [ "$NET" = "dhcp" ]; then
        echo -e "${DGN}Using IP Address: ${BGN}$NET${CL}"
        break
      else
        if [[ "$NET" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$ ]]; then
          echo -e "${DGN}Using IP Address: ${BGN}$NET${CL}"
          break
        else
          whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox "$NET is an invalid IPv4 CIDR address. Please enter a valid IPv4 CIDR address or 'dhcp'" 8 58
        fi
      fi
    else
      exit-script
    fi
  done

  if [ "$NET" != "dhcp" ]; then
    while true; do
      GATE1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Enter gateway IP address" 8 58 --title "Gateway IP" 3>&1 1>&2 2>&3)
      if [ -z "$GATE1" ]; then
        whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox "Gateway IP address cannot be empty" 8 58
      elif [[ ! "$GATE1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox "Invalid IP address format" 8 58
      else
        GATE=",gw=$GATE1"
        echo -e "${DGN}Using Gateway IP Address: ${BGN}$GATE1${CL}"
        break
      fi
    done
  else
    GATE=""
    echo -e "${DGN}Using Gateway IP Address: ${BGN}Default${CL}"
  fi

  if [ "$var_os" == "alpine" ]; then
    APT_CACHER=""
    APT_CACHER_IP=""
  else
    if APT_CACHER_IP=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set APT-Cacher IP (leave blank for default)" 8 58 --title "APT-Cacher IP" 3>&1 1>&2 2>&3); then
      APT_CACHER="${APT_CACHER_IP:+yes}"
      echo -e "${DGN}Using APT-Cacher IP Address: ${BGN}${APT_CACHER_IP:-Default}${CL}"
    else
      exit-script
    fi
  fi

  if (whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "IPv6" --yesno "Disable IPv6?" 10 58); then
    DISABLEIP6="yes"
  else
    DISABLEIP6="no"
  fi
  echo -e "${DGN}Disable IPv6: ${BGN}$DISABLEIP6${CL}"

  if MTU1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Interface MTU Size (leave blank for default)" 8 58 --title "MTU SIZE" 3>&1 1>&2 2>&3); then
    if [ -z $MTU1 ]; then
      MTU1="Default"
      MTU=""
    else
      MTU=",mtu=$MTU1"
    fi
    echo -e "${DGN}Using Interface MTU Size: ${BGN}$MTU1${CL}"
  else
    exit-script
  fi

  if SD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a DNS Search Domain (leave blank for HOST)" 8 58 --title "DNS Search Domain" 3>&1 1>&2 2>&3); then
    if [ -z $SD ]; then
      SX=Host
      SD=""
    else
      SX=$SD
      SD="-searchdomain=$SD"
    fi
    echo -e "${DGN}Using DNS Search Domain: ${BGN}$SX${CL}"
  else
    exit-script
  fi

  if NX=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a DNS Server IP (leave blank for HOST)" 8 58 --title "DNS SERVER IP" 3>&1 1>&2 2>&3); then
    if [ -z $NX ]; then
      NX=Host
      NS=""
    else
      NS="-nameserver=$NX"
    fi
    echo -e "${DGN}Using DNS Server IP Address: ${BGN}$NX${CL}"
  else
    exit-script
  fi

  if MAC1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a MAC Address(leave blank for default)" 8 58 --title "MAC ADDRESS" 3>&1 1>&2 2>&3); then
    if [ -z $MAC1 ]; then
      MAC1="Default"
      MAC=""
    else
      MAC=",hwaddr=$MAC1"
      echo -e "${DGN}Using MAC Address: ${BGN}$MAC1${CL}"
    fi
  else
    exit-script
  fi

  if VLAN1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a Vlan(leave blank for default)" 8 58 --title "VLAN" 3>&1 1>&2 2>&3); then
    if [ -z $VLAN1 ]; then
      VLAN1="Default"
      VLAN=""
    else
      VLAN=",tag=$VLAN1"
    fi
    echo -e "${DGN}Using Vlan: ${BGN}$VLAN1${CL}"
  else
    exit-script
  fi

  if [[ "$PW" == -password* ]]; then
    if (whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "SSH ACCESS" --yesno "Enable Root SSH Access?" 10 58); then
      SSH="yes"
    else
      SSH="no"
    fi
    echo -e "${DGN}Enable Root SSH Access: ${BGN}$SSH${CL}"
  else
    SSH="no"
    echo -e "${DGN}Enable Root SSH Access: ${BGN}$SSH${CL}"
  fi

  if (whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "VERBOSE MODE" --yesno "Enable Verbose Mode?" 10 58); then
    VERB="yes"
  else
    VERB="no"
  fi
  echo -e "${DGN}Enable Verbose Mode: ${BGN}$VERB${CL}"

  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "ADVANCED SETTINGS COMPLETE" --yesno "Ready to create ${APP} LXC?" 10 58); then
    echo -e "${RD}Creating a ${APP} LXC using the above advanced settings${CL}"
  else
    clear
    header_info
    echo -e "${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}


check_container_resources() {
  # Check actual RAM & Cores
  current_ram=$(free -m | awk '/^Mem:/{print $2}')
  current_cpu=$(nproc) 

  # Check whether the current RAM is less than the required RAM or the CPU cores are less than required
  if [[ "$current_ram" -lt "$var_ram" ]] || [[ "$current_cpu" -lt "$var_cpu" ]]; then
    echo -e "\n⚠️${HOLD} ${GN}Required: ${var_cpu} CPU, ${var_ram}MB RAM ${CL}| ${RD}Current: ${current_cpu} CPU, ${current_ram}MB RAM${CL}"
    echo -e "${YWB}Please ensure that the ${APP} LXC is configured with at least ${var_cpu} vCPU and ${var_ram} MB RAM for the build process.${CL}\n"
    exit 1  
  else
    echo -e ""
  fi
}

check_container_storage() {
  # Check if the /boot partition is more than 80% full
  total_size=$(df /boot --output=size | tail -n 1)
  local used_size=$(df /boot --output=used | tail -n 1)
  usage=$(( 100 * used_size / total_size ))
  if (( usage > 80 )); then
    # Prompt the user for confirmation to continue
    echo -e "⚠️${HOLD} ${YWB}Warning: Storage is dangerously low (${usage}%).${CL}"
    read -r -p "Continue anyway? <y/N>  " prompt  
    # Check if the input is 'y' or 'yes', otherwise exit with status 1
    if [[ ! ${prompt,,} =~ ^(y|yes)$ ]]; then
      echo -e "❌${HOLD} ${YWB}Exiting based on user input.${CL}"
      exit 1
    fi
  fi
}


# This function collects user settings and integrates all the collected information.
build_container() {
#  if [ "$VERB" == "yes" ]; then set -x; fi

  if [ "$CT_TYPE" == "1" ]; then
    FEATURES="keyctl=1,nesting=1"
  else
    FEATURES="nesting=1"
  fi


  TEMP_DIR=$(mktemp -d)
  pushd $TEMP_DIR >/dev/null
  if [ "$var_os" == "alpine" ]; then
    export FUNCTIONS_FILE_PATH=""
    #export FUNCTIONS_FILE_PATH="$(curl -s https://raw.githubusercontent.com/minlearnminlearn/ProxmoxVE_fixed/main/misc/alpine-install.func.sh)"
  else
    export FUNCTIONS_FILE_PATH=""
    #export FUNCTIONS_FILE_PATH="$(curl -s https://raw.githubusercontent.com/minlearnminlearn/ProxmoxVE_fixed/main/misc/install.func.sh)"
  fi
  export CACHER="$APT_CACHER"
  export CACHER_IP="$APT_CACHER_IP"
  export tz="$timezone"
  export DISABLEIPV6="$DISABLEIP6"
  export APPLICATION="$APP"
  export app="$NSAPP"
  export PASSWORD="$PW"
  export VERBOSE="$VERB"
  export SSH_ROOT="${SSH}"
  export CTID="$CT_ID"
  export CTTYPE="$CT_TYPE"
  export PCT_OSTYPE="$var_os"
  export PCT_OSVERSION="$var_version"
  export PCT_DISK_SIZE="$DISK_SIZE"
  export PCT_OPTIONS="
    -features $FEATURES
    -hostname $HN
    -tags proxmox-helper-scripts
    $SD
    $NS
    -net0 name=eth0,bridge=$BRG$MAC,ip=$NET$GATE$VLAN$MTU
    -onboot 1
    -cores $CORE_COUNT
    -memory $RAM_SIZE
    -unprivileged $CT_TYPE
    $PW
  "
  # This executes create_lxc.sh and creates the container and .conf file
  # bash -c "$(wget -qLO - https://raw.githubusercontent.com/minlearnminlearn/ProxmoxVE_fixed/main/misc/create_lxc.sh)" || exit


  ########################################################

# create_lxc.sh
# This checks for the presence of valid Container Storage and Template Storage locations
msg_info "Validating Storage"
VALIDCT=$(pvesm status -content rootdir | awk 'NR>1')
if [ -z "$VALIDCT" ]; then
  msg_error "Unable to detect a valid Container Storage location."
  exit 1
fi
VALIDTMP=$(pvesm status -content vztmpl | awk 'NR>1')
if [ -z "$VALIDTMP" ]; then
  msg_error "Unable to detect a valid Template Storage location."
  exit 1
fi

# This function is used to select the storage class and determine the corresponding storage content type and label.
function select_storage() {
  local CLASS=$1
  local CONTENT
  local CONTENT_LABEL
  case $CLASS in
  container)
    CONTENT='rootdir'
    CONTENT_LABEL='Container'
    ;;
  template)
    CONTENT='vztmpl'
    CONTENT_LABEL='Container template'
    ;;
  *) false || exit "Invalid storage class." ;;
  esac
  
  # This Queries all storage locations
  local -a MENU
  while read -r line; do
    local TAG=$(echo $line | awk '{print $1}')
    local TYPE=$(echo $line | awk '{printf "%-10s", $2}')
    local FREE=$(echo $line | numfmt --field 4-6 --from-unit=K --to=iec --format %.2f | awk '{printf( "%9sB", $6)}')
    local ITEM="  Type: $TYPE Free: $FREE "
    local OFFSET=2
    if [[ $((${#ITEM} + $OFFSET)) -gt ${MSG_MAX_LENGTH:-} ]]; then
      local MSG_MAX_LENGTH=$((${#ITEM} + $OFFSET))
    fi
    MENU+=("$TAG" "$ITEM" "OFF")
  done < <(pvesm status -content $CONTENT | awk 'NR>1')
  
  # Select storage location
  if [ $((${#MENU[@]}/3)) -eq 1 ]; then
    printf ${MENU[0]}
  else
    local STORAGE
    while [ -z "${STORAGE:+x}" ]; do
      STORAGE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Storage Pools" --radiolist \
      "Which storage pool you would like to use for the ${CONTENT_LABEL,,}?\nTo make a selection, use the Spacebar.\n" \
      16 $(($MSG_MAX_LENGTH + 23)) 6 \
      "${MENU[@]}" 3>&1 1>&2 2>&3) || exit "Menu aborted."
    done
    printf $STORAGE
  fi
}

# Test if required variables are set
[[ "${CTID:-}" ]] || exit "You need to set 'CTID' variable."
[[ "${PCT_OSTYPE:-}" ]] || exit "You need to set 'PCT_OSTYPE' variable."

# Test if ID is valid
[ "$CTID" -ge "100" ] || exit "ID cannot be less than 100."

# Test if ID is in use
if pct status $CTID &>/dev/null; then
  echo -e "ID '$CTID' is already in use."
  unset CTID
  exit "Cannot use ID that is already in use."
fi

# Get template storage
TEMPLATE_STORAGE=$(select_storage template) || exit
msg_ok "Using ${BL}$TEMPLATE_STORAGE${CL} ${GN}for Template Storage."

# Get container storage
CONTAINER_STORAGE=$(select_storage container) || exit
msg_ok "Using ${BL}$CONTAINER_STORAGE${CL} ${GN}for Container Storage."

<<'BLOCK'

# Update LXC template list
msg_info "Updating LXC Template List"
pveam update >/dev/null
msg_ok "Updated LXC Template List"

# Get LXC template string
TEMPLATE_SEARCH=${PCT_OSTYPE}-${PCT_OSVERSION:-}
mapfile -t TEMPLATES < <(pveam available -section system | sed -n "s/.*\($TEMPLATE_SEARCH.*\)/\1/p" | sort -t - -k 2 -V)
[ ${#TEMPLATES[@]} -gt 0 ] || exit "Unable to find a template when searching for '$TEMPLATE_SEARCH'."
TEMPLATE="${TEMPLATES[-1]}"

# Download LXC template if needed
if ! pveam list $TEMPLATE_STORAGE | grep -q $TEMPLATE; then
  msg_info "Downloading LXC Template"
  pveam download $TEMPLATE_STORAGE $TEMPLATE >/dev/null ||
    exit "A problem occured while downloading the LXC template."
  msg_ok "Downloaded LXC Template"
fi

BLOCK

TEMPLATE="lxcdebtpl.tar.xz"

# Combine all options
DEFAULT_PCT_OPTIONS=(
  -arch $(dpkg --print-architecture))

PCT_OPTIONS=(${PCT_OPTIONS[@]:-${DEFAULT_PCT_OPTIONS[@]}})
[[ " ${PCT_OPTIONS[@]} " =~ " -rootfs " ]] || PCT_OPTIONS+=(-rootfs $CONTAINER_STORAGE:${PCT_DISK_SIZE:-8})

# Create container
msg_info "Creating LXC Container"
pct create $CTID ${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE} ${PCT_OPTIONS[@]} >/dev/null ||
  exit "A problem occured while trying to create container."
msg_ok "LXC Container ${BL}$CTID${CL} ${GN}was successfully created."

########################################################


  LXC_CONFIG=/etc/pve/lxc/${CTID}.conf
  if [ "$CT_TYPE" == "0" ]; then
    cat <<EOF >>$LXC_CONFIG
# USB passthrough
lxc.cgroup2.devices.allow: a
lxc.cap.drop:
lxc.cgroup2.devices.allow: c 188:* rwm
lxc.cgroup2.devices.allow: c 189:* rwm
lxc.mount.entry: /dev/serial/by-id  dev/serial/by-id  none bind,optional,create=dir
lxc.mount.entry: /dev/ttyUSB0       dev/ttyUSB0       none bind,optional,create=file
lxc.mount.entry: /dev/ttyUSB1       dev/ttyUSB1       none bind,optional,create=file
lxc.mount.entry: /dev/ttyACM0       dev/ttyACM0       none bind,optional,create=file
lxc.mount.entry: /dev/ttyACM1       dev/ttyACM1       none bind,optional,create=file
EOF
  fi

  if [ "$CT_TYPE" == "0" ]; then
    if [[ "$APP" == "Channels" || "$APP" == "Emby" || "$APP" == "ErsatzTV" || "$APP" == "Frigate" || "$APP" == "Jellyfin" || "$APP" == "Plex" || "$APP" == "Scrypted" || "$APP" == "Tdarr" || "$APP" == "Unmanic" || "$APP" == "Ollama" ]]; then
      cat <<EOF >>$LXC_CONFIG
# VAAPI hardware transcoding
lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
lxc.cgroup2.devices.allow: c 29:0 rwm
lxc.mount.entry: /dev/fb0 dev/fb0 none bind,optional,create=file
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file
EOF
    fi
  else
    if [[ "$APP" == "Channels" || "$APP" == "Emby" || "$APP" == "ErsatzTV" || "$APP" == "Frigate" || "$APP" == "Jellyfin" || "$APP" == "Plex" || "$APP" == "Scrypted" || "$APP" == "Tdarr" || "$APP" == "Unmanic" || "$APP" == "Ollama" ]]; then
      if [[ -e "/dev/dri/renderD128" ]]; then
        if [[ -e "/dev/dri/card0" ]]; then
          cat <<EOF >>$LXC_CONFIG
# VAAPI hardware transcoding
dev0: /dev/dri/card0,gid=44
dev1: /dev/dri/renderD128,gid=104
EOF
        else
          cat <<EOF >>$LXC_CONFIG
# VAAPI hardware transcoding
dev0: /dev/dri/card1,gid=44
dev1: /dev/dri/renderD128,gid=104
EOF
        fi
      fi
    fi
  fi

  echo $CTID

}


########################

# install.func.sh

# This function enables IPv6 if it's not disabled and sets verbose mode if the global variable is set to "yes"
verb_ip6() {
  if [ "$VERBOSE" = "yes" ]; then
    STD=""
  else STD="silent"; fi
  silent() { "$@" >/dev/null 2>&1; }
  if [ "$DISABLEIPV6" == "yes" ]; then
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >>/etc/sysctl.conf
    $STD sysctl -p
  fi
}

# This function sets up the Container OS by generating the locale, setting the timezone, and checking the network connection
setting_up_container() {
  msg_info "Setting up Container OS"
  sed -i "/$LANG/ s/\(^# \)//" /etc/locale.gen
  locale_line=$(grep -v '^#' /etc/locale.gen | grep -E '^[a-zA-Z]' | awk '{print $1}' | head -n 1)
  echo "LANG=${locale_line}" >/etc/default/locale
  locale-gen >/dev/null
  export LANG=${locale_line}
  echo $tz >/etc/timezone
  ln -sf /usr/share/zoneinfo/$tz /etc/localtime
  for ((i = RETRY_NUM; i > 0; i--)); do
    if [ "$(hostname -I)" != "" ]; then
      break
    fi
    echo 1>&2 -en "${CROSS}${RD} No Network! "
    sleep $RETRY_EVERY
  done
  if [ "$(hostname -I)" = "" ]; then
    echo 1>&2 -e "\n${CROSS}${RD} No Network After $RETRY_NUM Tries${CL}"
    echo -e " 🖧  Check Network Settings"
    exit 1
  fi
  rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
  systemctl disable -q --now systemd-networkd-wait-online.service
  msg_ok "Set up Container OS"
  msg_ok "Network Connected: ${BL}$(hostname -I)"
}

# This function checks the network connection by pinging a known IP address and prompts the user to continue if the internet is not connected
network_check() {
  set +e
  trap - ERR
  ipv4_connected=false
  ipv6_connected=false
  sleep 1
# Check IPv4 connectivity
  if ping -c 1 -W 1 1.1.1.1 &>/dev/null; then 
    msg_ok "IPv4 Internet Connected";
    ipv4_connected=true
  else
    msg_error "IPv4 Internet Not Connected";
  fi

# Check IPv6 connectivity
  if ping6 -c 1 -W 1 2606:4700:4700::1111 &>/dev/null; then
    msg_ok "IPv6 Internet Connected";
    ipv6_connected=true
  else
    msg_error "IPv6 Internet Not Connected";
  fi

# If both IPv4 and IPv6 checks fail, prompt the user
  if [[ $ipv4_connected == false && $ipv6_connected == false ]]; then
    read -r -p "No Internet detected,would you like to continue anyway? <y/N> " prompt
    if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
      echo -e " ⚠️  ${RD}Expect Issues Without Internet${CL}"
    else
      echo -e " 🖧  Check Network Settings"
      exit 1
    fi
  fi

  RESOLVEDIP=$(getent hosts github.com | awk '{ print $1 }')
  if [[ -z "$RESOLVEDIP" ]]; then msg_error "DNS Lookup Failure"; else msg_ok "DNS Resolved github.com to ${BL}$RESOLVEDIP${CL}"; fi
  set -e
  trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
}

# This function updates the Container OS by running apt-get update and upgrade
update_os() {
  msg_info "Updating Container OS"
  if [[ "$CACHER" == "yes" ]]; then
    echo "Acquire::http::Proxy-Auto-Detect \"/usr/local/bin/apt-proxy-detect.sh\";" >/etc/apt/apt.conf.d/00aptproxy
    cat <<EOF >/usr/local/bin/apt-proxy-detect.sh
#!/bin/bash
if nc -w1 -z "${CACHER_IP}" 3142; then
  echo -n "http://${CACHER_IP}:3142"
else
  echo -n "DIRECT"
fi
EOF
  chmod +x /usr/local/bin/apt-proxy-detect.sh
  fi
  $STD apt-get update
  $STD apt-get -o Dpkg::Options::="--force-confold" -y dist-upgrade
  rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
  msg_ok "Updated Container OS"
}

# This function modifies the message of the day (motd) and SSH settings
motd_ssh() {
  echo "export TERM='xterm-256color'" >>/root/.bashrc
  echo -e "$APPLICATION LXC provided by https://helper-scripts.com/\n" >/etc/motd
  chmod -x /etc/update-motd.d/*
  if [[ "${SSH_ROOT}" == "yes" ]]; then
    sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
    systemctl restart sshd
  fi
}

# This function customizes the container by modifying the getty service and enabling auto-login for the root user
customize() {
  if [[ "$PASSWORD" == "" ]]; then
    msg_info "Customizing Container"
    GETTY_OVERRIDE="/etc/systemd/system/container-getty@1.service.d/override.conf"
    mkdir -p $(dirname $GETTY_OVERRIDE)
    cat <<EOF >$GETTY_OVERRIDE
  [Service]
  ExecStart=
  ExecStart=-/sbin/agetty --autologin root --noclear --keep-baud tty%I 115200,38400,9600 \$TERM
EOF
    systemctl daemon-reload
    systemctl restart $(basename $(dirname $GETTY_OVERRIDE) | sed 's/\.d//')
    msg_ok "Customized Container"
  fi
  echo "bash -c \"\$(wget -qLO - https://github.com/minlearnminlearn/ProxmoxVE_fixed/raw/main/${app}.sh)\"" >/usr/bin/update
  chmod +x /usr/bin/update
}

########################




# This function sets the description of the container.
description() {
  IP=$(pct exec "$CTID" ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)

  # Generate LXC Description
  DESCRIPTION=$(cat <<EOF
<div align='center'>
  <a href='https://Helper-Scripts.com' target='_blank' rel='noopener noreferrer'>
    <img src='https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/images/logo-81x112.png' alt='Logo' style='width:81px;height:112px;'/>
  </a>

  <h2 style='font-size: 24px; margin: 20px 0;'>${APP} LXC</h2>

  <p style='margin: 16px 0;'>
    <a href='https://ko-fi.com/community_scripts' target='_blank' rel='noopener noreferrer'>
      <img src='https://img.shields.io/badge/&#x2615;-Buy us a coffee-blue' alt='spend Coffee' />
    </a>
  </p>
  
  <span style='margin: 0 10px;'>
    <i class="fa fa-github fa-fw" style="color: #f5f5f5;"></i>
    <a href='https://github.com/community-scripts/ProxmoxVE' target='_blank' rel='noopener noreferrer' style='text-decoration: none; color: #00617f;'>GitHub</a>
  </span>
  <span style='margin: 0 10px;'>
    <i class="fa fa-comments fa-fw" style="color: #f5f5f5;"></i>
    <a href='https://github.com/community-scripts/ProxmoxVE/discussions' target='_blank' rel='noopener noreferrer' style='text-decoration: none; color: #00617f;'>Discussions</a>
  </span>
  <span style='margin: 0 10px;'>
    <i class="fa fa-exclamation-circle fa-fw" style="color: #f5f5f5;"></i>
    <a href='https://github.com/community-scripts/ProxmoxVE/issues' target='_blank' rel='noopener noreferrer' style='text-decoration: none; color: #00617f;'>Issues</a>
  </span>
</div>
EOF
)

  # Set Description in LXC
  pct set "$CTID" -description "$DESCRIPTION"

  if [[ -f /etc/systemd/system/ping-instances.service ]]; then
    systemctl start ping-instances.service
  fi
}


######################
# main
######################


function header_info {
clear
cat <<"EOF"
   ______ _  __
  / ____/(_)/ /____  ____ _
 / / __// // __/ _ \/ __  /
/ /_/ // // /_/  __/ /_/ /
\____//_/ \__/\___/\__,_/

EOF
}
header_info
echo -e "Loading..."
APP="$1"
var_disk="8"
var_cpu="1"
var_ram="1024"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr1"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}


install_script() {
  pve_check
  shell_check
  root_check
  arch_check
  ssh_check

  if systemctl is-active -q ping-instances.service; then
    systemctl -q stop ping-instances.service
  fi
  NEXTID=$(pvesh get /cluster/nextid)
  timezone=$(cat /etc/timezone)
  header_info
  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "SETTINGS" --yesno "Use Default Settings?" --no-button Advanced 10 58); then
    header_info
    echo -e "${BL}Using Default Settings${CL}"
    default_settings
  else
    header_info
    echo -e "${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

function update_script() {
header_info
check_container_storage
check_container_resources

bash -c "$(wget -qLO - https://raw.githubusercontent.com/minlearnminlearn/ProxmoxVE_fixed/main/${APP}/${APP}_update.sh)" || exit

exit
}


start() {
  if command -v pveversion >/dev/null 2>&1; then
    if ! (whiptail --backtitle "Proxmox VE Helper Scripts" --title "${APP} LXC" --yesno "This will create a New ${APP} LXC. Proceed?" 10 58); then
      clear
      echo -e "⚠  User exited script \n"
      exit
    fi
    SPINNER_PID=""
    install_script
  fi

  if ! command -v pveversion >/dev/null 2>&1; then
    if ! (whiptail --backtitle "Proxmox VE Helper Scripts" --title "${APP} LXC UPDATE" --yesno "Support/Update functions for ${APP} LXC.  Proceed?" 10 58); then
      clear
      echo -e "⚠  User exited script \n"
      exit
    fi
    SPINNER_PID=""
    update_script
  fi
}

start


build_container

[[ ! -z "$CTID" ]] && {
  # This starts the container and executes <app>-install.sh
  msg_info "Starting LXC Container"
  pct start "$CTID"
  msg_ok "Started LXC Container"
  if [ "$var_os" == "alpine" ]; then
    sleep 3
        pct exec "$CTID" -- /bin/sh -c 'cat <<EOF >/etc/apk/repositories
http://dl-cdn.alpinelinux.org/alpine/latest-stable/main
http://dl-cdn.alpinelinux.org/alpine/latest-stable/community
#http://dl-cdn.alpinelinux.org/alpine/v3.19/main
#http://dl-cdn.alpinelinux.org/alpine/v3.19/community
EOF'
    pct exec "$CTID" -- ash -c "apk add bash >/dev/null"
  fi

  verb_ip6
  setting_up_container
  network_check
  update_os
  lxc-attach -n "$CTID" -- bash -c "$(wget -qLO - https://raw.githubusercontent.com/minlearnminlearn/ProxmoxVE_fixed/main/${APP}/${APP}_install.sh)" || exit
  motd_ssh
  customize
}


description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:3000${CL} \n"