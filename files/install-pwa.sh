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
  echo "Exampe: install-pwa.sh config_site.json"
  exit;
fi

#  "CONFIG_NAME": "example",
#  "SITE_HOSTNAME": "pwa.example.lan",
#  "PWA_APP_DIR": "/var/www/data-pwa/venia-concept",
#  "SITE_ROOT_DIR": "current",
#  "PWA_STUDIO_REPO": "https://github.com/magento/pwa-studio/archive/refs/tags/",
#  "PWA_STUDIO_VER": "11.0.0",
#  "PWA_STUDIO_ROOT_DIR": "/var/www/data-pwa/pwa-studio",
#  "MAGENTO_URL": "https://magento.lan/",
#  "MAGENTO_REL_VER": "2.4.3",
#  "MAGENTO_LICENSE": "CE"

# Config Files
CONFIG_DEFAULT="config_default.json"
CONFIG_OVERRIDE="${CONFIG_FILE}"
[[ "${CONFIG_OVERRIDE}" != "" && -f ${CONFIG_OVERRIDE} ]] || CONFIG_OVERRIDE=""


# Read merged config JSON files
declare CONFIG_NAME=$(cat ${CONFIG_DEFAULT} ${CONFIG_OVERRIDE} | jq -s add | jq -r '.CONFIG_NAME')
declare SITE_HOSTNAME=$(cat ${CONFIG_DEFAULT} ${CONFIG_OVERRIDE} | jq -s add | jq -r '.SITE_HOSTNAME')

declare PWA_APP_DIR=$(cat ${CONFIG_DEFAULT} ${CONFIG_OVERRIDE} | jq -s add | jq -r '.PWA_APP_DIR')
declare SITE_ROOT_DIR=$(cat ${CONFIG_DEFAULT} ${CONFIG_OVERRIDE} | jq -s add | jq -r '.SITE_ROOT_DIR')

declare PWA_STUDIO_REPO=$(cat ${CONFIG_DEFAULT} ${CONFIG_OVERRIDE} | jq -s add | jq -r '.PWA_STUDIO_REPO')
declare PWA_STUDIO_VER=$(cat ${CONFIG_DEFAULT} ${CONFIG_OVERRIDE} | jq -s add | jq -r '.PWA_STUDIO_VER')
declare PWA_STUDIO_ROOT_DIR=$(cat ${CONFIG_DEFAULT} ${CONFIG_OVERRIDE} | jq -s add | jq -r '.PWA_STUDIO_ROOT_DIR')

declare MAGENTO_URL=$(cat ${CONFIG_DEFAULT} ${CONFIG_OVERRIDE} | jq -s add | jq -r '.MAGENTO_URL')
declare MAGENTO_REL_VER=$(cat ${CONFIG_DEFAULT} ${CONFIG_OVERRIDE} | jq -s add | jq -r '.MAGENTO_REL_VER')
declare MAGENTO_LICENSE=$(cat ${CONFIG_DEFAULT} ${CONFIG_OVERRIDE} | jq -s add | jq -r '.MAGENTO_LICENSE')

# Setup Directories
# check if already exists
[ -d "${PWA_STUDIO_ROOT_DIR}" ] && rm -rf ${PWA_STUDIO_ROOT_DIR} 
[ -d "${PWA_APP_DIR}" ] && rm -rf ${PWA_APP_DIR} 

mkdir -p ${PWA_STUDIO_ROOT_DIR}
# Moving to PWA Studio Directory
echo "----: Move to PWA Studio Directory ${PWA_STUDIO_ROOT_DIR}"
cd ${PWA_STUDIO_ROOT_DIR}

# Download and extract PWA Studio
echo "----: Download and extract PWA Studio"

wget ${PWA_STUDIO_REPO}/v${PWA_STUDIO_VER}.tar.gz
tar xf v${PWA_STUDIO_VER}.tar.gz --strip-components 1  && rm v${PWA_STUDIO_VER}.tar.gz

# Generate Braintree Token
declare BTOKEN=sandbox_$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-z0-9' | fold -w 8 | head -n1)_$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-z0-9' | fold -w 16 | head -n1)
 
echo "----: Run buildpack"
npx @magento/pwa-buildpack create-project $(basename ${PWA_APP_DIR}) --name \"${SITE_HOSTNAME}\" --author \"PWA Demo\" --template \"@magento/venia-concept\" --backend-url \"${MAGENTO_URL}\" --braintree-token \"${BTOKEN}\" --npm-client \"yarn\"

mv $(basename ${PWA_APP_DIR}) ${PWA_APP_DIR} 

echo "----: Checking Magento edition"
if [ ${MAGENTO_LICENSE} == "EE" ]; then
  sed -i 's/MAGENTO_BACKEND_EDITION=CE/MAGENTO_BACKEND_EDITION=EE/' ${PWA_APP_DIR}/.env
fi

echo "----: Yarn install && build"
cd ${PWA_APP_DIR}
yarn install
yarn build

echo "----: PWA Install Finished"