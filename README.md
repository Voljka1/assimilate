# LibreNMS Device Assimilator

A bash script designed to inject custom device definitions, MIBs, and icons into a **LibreNMS (v.26.3.1)** Docker deployment. It automates the transfer, permission handling, and cache clearing required to make new hardware "part of the collective".

## 🚀 Overview

The `assimilate.sh` script automates the process of copying files into running Docker containers and setting the correct ownership (`librenms:librenms`). It targets two specific containers:
* **librenms_main**: The primary web/poller container.
* **librenms_dispatcher**: The dispatcher/worker container.

## 📂 Directory Structure

For the script to function, place it in a folder alongside your device files using the following naming conventions:

```text
.
├── _pikard_.txt           # Vendor Marker (Mandatory: _VendorName_.txt)
├── assimilate.sh          # This script
├── mibs/                  # Folder containing all .mib files
├── icon_myos.svg          # OS Icon (prefix: icon_)
├── logo_myvendor.png      # Vendor Logo (prefix: logo_)
├── os_detection_myos.yaml # OS Detection logic (prefix: os_detection_)
├── os_discovery_myos.yaml # OS Discovery logic (prefix: os_discovery_)
└── os_logic_MyOS.php      # Custom PHP logic (prefix: os_logic_)
```

## 🛠️ Usage

### 1. Prerequisites
* A running Docker environment with containers named `librenms_main` and `librenms_dispatcher`.
* Linux or Windows **WSL2** shell.
* Execution permissions on the script.

### 2. Preparation
Ensure you have a vendor marker file in the directory. The script uses this to create the MIB subdirectory.
* Example: `touch _Cisco_.txt` will result in MIBs being placed in `/opt/librenms/mibs/Cisco/`.

### 3. Execution
Run the script from within the folder containing your files:

```bash
chmod +x assimilate.sh
./assimilate.sh
```

## 🤖 What the Script Does

1.  **Vendor Detection:** Parses the `_*_.txt` file to determine the vendor name.
2.  **MIB Injection:** Creates the vendor directory in both containers and moves all files from the local `mibs/` folder, setting permissions to `644`.
3.  **Component Mapping:**
    * `icon_*` ➡️ `/opt/librenms/html/images/os/`
    * `logo_*` ➡️ `/opt/librenms/html/images/logos/`
    * `os_detection_*` ➡️ `/opt/librenms/resources/definitions/os_detection/`
    * `os_discovery_*` ➡️ `/opt/librenms/resources/definitions/os_discovery/`
    * `os_logic_*` ➡️ `/opt/librenms/LibreNMS/OS/`
4.  **Permission Correction:** Executes `chown librenms:librenms` on all injected files via root access.
5.  **Cache Clearing:** Runs `lnms cache:clear` inside the container to apply changes immediately.

## ✍️ Authors

* **Primary Author:** [Voljka 1of1]
* **Co-Author:** Gemini (AI Collaborator)

## ⚠️ Important Notes
* **Version Compatibility:** Optimized for LibreNMS v.26.3.1.
* **Strict Mode:** Uses `set -e` to ensure the script stops if any copy command fails.

---
*"Resistance is futile. Your hardware will be integrated."*
