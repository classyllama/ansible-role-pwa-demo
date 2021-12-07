#!/usr/bin/env bash

set -eu

# Move execution to realpath of script
cd $(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

########################################
## Command Line Options
########################################
declare CONFIG_FILE=""
for switch in $@; do
    case $switch in
        *)
            CONFIG_FILE="${switch}"
            if [[ "${CONFIG_FILE}" =~ ^.+$ ]]; then
              if [[ ! -f "${CONFIG_FILE}" ]]; then
                >&2 echo "Error: Invalid config file given"
                exit -1
              fi
            fi
            ;;
    esac
done
if [[ $# < 1 ]]; then
  echo "An argument was not specified:"
  echo " <config_filename>    Specify config file to use to override default configs."
  echo ""
  echo "Exampe: uninstall-pwa.sh config_site.json"
  exit;
fi


# Config Files
CONFIG_DEFAULT="config_default.json"
CONFIG_OVERRIDE="${CONFIG_FILE}"
[[ "${CONFIG_OVERRIDE}" != "" && -f ${CONFIG_OVERRIDE} ]] || CONFIG_OVERRIDE=""

# Read merged config JSON files
declare CONFIG_NAME=$(cat ${CONFIG_DEFAULT} ${CONFIG_OVERRIDE} | jq -s add | jq -r '.CONFIG_NAME')
declare PWA_STUDIO_ROOT_DIR=$(cat ${CONFIG_DEFAULT} ${CONFIG_OVERRIDE} | jq -s add | jq -r '.PWA_STUDIO_ROOT_DIR')
declare PWA_SITE_ROOT_DIR=$(cat ${CONFIG_DEFAULT} ${CONFIG_OVERRIDE} | jq -s add | jq -r '.PWA_SITE_ROOT_DIR')
declare PWA_UPWARD_JS=$(cat ${CONFIG_DEFAULT} ${CONFIG_OVERRIDE} | jq -s add | jq -r '.PWA_UPWARD_JS')

if [[ "${PWA_UPWARD_JS}" == "true" ]]; then
  # UPWARD-JS installation
  echo "----: Stopping PM2 service"
  cd ${PWA_STUDIO_ROOT_DIR}/pwa
  IS_RUNNING=$(pm2 ls |grep online |wc -l)
  if [[ "${IS_RUNNING}" ]]; then
    echo "----: Found ${IS_RUNNING} running PM2 processes"
    pm2 stop pwa
  fi

  echo "----: Removing symlink $(dirname ${PWA_STUDIO_ROOT_DIR})/${PWA_SITE_ROOT_DIR} if exists..."
  [ -L "$(dirname ${PWA_STUDIO_ROOT_DIR})/${PWA_SITE_ROOT_DIR}" ] && unlink $(dirname ${PWA_STUDIO_ROOT_DIR})/${PWA_SITE_ROOT_DIR}

else
  # UPWARD-PHP installation
  echo "----: Removing symlink /var/www/data/magento/pwa if exists..."
  [ -L "/var/www/data/magento/pwa" ] && unlink /var/www/data/magento/pwa
fi

echo "----: Removing ${PWA_STUDIO_ROOT_DIR} if exists..."
[ -d "${PWA_STUDIO_ROOT_DIR}" ] && rm -rf ${PWA_STUDIO_ROOT_DIR}
echo "----: Uninstall finished"
