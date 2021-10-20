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

# Checking Magento and PWA Studio version compability
# removing patch releases
MAGENTO_MAIN_VER=$(echo ${MAGENTO_REL_VER} | sed 's/-p.$//')

if [[ ${MAGENTO_MAIN_VER} == "2.4.3" ]]; then
   PWA_COMPAT_VER=("11.0.0" "12.0.0")
elif [[ ${MAGENTO_MAIN_VER} == "2.4.2" ]]; then
   PWA_COMPAT_VER=("9.0.0" "9.0.1" "10.0.0")
elif [[ ${MAGENTO_MAIN_VER} == "2.4.1" ]]; then
   PWA_COMPAT_VER=("8.0.0")
elif [[ ${MAGENTO_MAIN_VER} == "2.4.0" ]]; then
   PWA_COMPAT_VER=("8.0.0")
elif [[ ${MAGENTO_MAIN_VER} == "2.3.5" ]]; then
   PWA_COMPAT_VER=("6.0.0" "6.0.1" "7.0.0")
elif [[ ${MAGENTO_MAIN_VER} == "2.3.4" ]]; then
   PWA_COMPAT_VER=("5.0.0" "6.0.0" "6.0.1")
elif [[ ${MAGENTO_MAIN_VER} == "2.3.3" ]]; then
   PWA_COMPAT_VER=("4.0.0" "5.0.0" "5.0.1")
elif [[ ${MAGENTO_MAIN_VER} == "2.3.2" ]]; then
   PWA_COMPAT_VER=("4.0.0")
elif [[ ${MAGENTO_MAIN_VER} == "2.3.1" ]]; then
   PWA_COMPAT_VER=("2.1.0" "3.0.0")
elif [[ ${MAGENTO_MAIN_VER} == "2.3.0" ]]; then
   PWA_COMPAT_VER=("2.0.0")
else
   PWA_COMPAT_VER=("12.0.0")
fi

if [[ ! "${PWA_COMPAT_VER[*]}" =~ "${PWA_STUDIO_VER}" ]]; then
  echo "Please check Magento and PWA Studio version compability:

        Magento version: ${MAGENTO_REL_VER}
        PWA Studio: ${PWA_STUDIO_VER}

Compability matrix: https://magento.github.io/pwa-studio/technologies/magento-compatibility/"
  exit 1;
fi

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

curl ${PWA_STUDIO_REPO}/v${PWA_STUDIO_VER}.tar.gz -o ${PWA_STUDIO_REPO}/v${PWA_STUDIO_VER}.tar.gz
tar xf v${PWA_STUDIO_VER}.tar.gz --strip-components 1 && rm v${PWA_STUDIO_VER}.tar.gz

# Generate Braintree Token
declare BTOKEN=sandbox_$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-z0-9' | fold -w 8 | head -n1)_$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-z0-9' | fold -w 16 | head -n1)
 
echo "----: Run buildpack"
echo y | npx @magento/pwa-buildpack create-project $(basename ${PWA_APP_DIR}) --name \"${SITE_HOSTNAME}\" --author \"PWA Demo\" --template \"@magento/venia-concept\" --backend-url \"${MAGENTO_URL}\" --braintree-token \"${BTOKEN}\" --npm-client \"yarn\"

mv $(basename ${PWA_APP_DIR}) ${PWA_APP_DIR} 

echo "----: Checking Magento license"
if [ ${MAGENTO_LICENSE} == "EE" ]; then
  sed -i 's/MAGENTO_BACKEND_EDITION=CE/MAGENTO_BACKEND_EDITION=EE/' ${PWA_APP_DIR}/.env
fi

echo "----: Yarn build"
cd ${PWA_APP_DIR}
yarn build

# Save admin credentials as indicator that script completed successfully
echo "----: Saving PWA Data"
PWA_DATA=$(cat <<CONTENTS_HEREDOC
{
  "SITE_HOSTNAME": "${SITE_HOSTNAME}",
  "PWA_APP_DIR": "${PWA_APP_DIR}",
  "PWA_STUDIO_VER": "${PWA_STUDIO_VER}",
  "MAGENTO_URL": "${MAGENTO_URL}",
  "MAGENTO_REL_VER": "${MAGENTO_REL_VER}",
  "MAGENTO_LICENSE": "${MAGENTO_LICENSE}"
}
CONTENTS_HEREDOC
)
echo ${PWA_DATA} > $(dirname ${PWA_STUDIO_ROOT_DIR})/pwa_instance_data.json
echo "----: PWA Install Finished"
