# Ansible Role: PWA Demo

Installs a shell script on RHEL / CentOS for installing PWA (upward-js and upward-php implementations).

It supports two types of PWA installation - upward-js, which allows to use separate document root for PWA storefront (requires nodejs and PM2 services) and upward-php (using Magento_UpwardConnector module).
To switch the type of installation `pwa_demo_type_upward_js` variable can be used (upward-js is a default type).
When upward-js is enabled the second virtualhost must be created for PWA storefront, upward-php installation doesn't require a separate virtualhost but it requires additional Nginx reconfiguration:

    fastcgi_param MAGENTO_BACKEND_URL "https://{{ app_domain }}/";
    fastcgi_param NODE_ENV "production";

The role sets up a config file for a specific domain/directory/user and saves the config files and scripts in the user's home directory ~/username/pwa-demo/.
When upward-php is choosed it also places custom_script_site.sh configuration file into /home/www-data/magento-demo/ folder to run the Magento_UpwardConnector module installation and configuration.

Please note, PWA Studio Version must be compatible with the installed Magento version, please check the requested PWA Studio version using [PWA Studio compability matrix](https://magento.github.io/pwa-studio/technologies/magento-compatibility/).

## Requirements

None.

## Role Variables

See `defaults/main.yml` for details.

## Dependencies

None.

## Example Playbook

    - hosts: web
      vars:
        use_classyllama_pwa_demo: true
        pwa_demo_config_name: "site"
        pwa_demo_hostname: "pwa-{{ app_domain }}"
        pwa_demo_env_root: /var/www/data-pwa
        pwa_demo_user: www-data-pwa
        pwa_demo_group: www-data-pwa
        pwa_demo_scripts_dir: "/home/{{ pwa_demo_user }}/pwa-demo"
        pwa_demo_type_upward_js: true                              # when it set to 'false' upward-php implmentation will be installed, using Magento_UpwardConnector module via magento-demo/custom_script_site.sh
        pwa_demo_config_overrides:
          CONFIG_NAME: "site"
          SITE_HOSTNAME: "pwa-{{ app_domain }}"
          PWA_SITE_ROOT_DIR: "current"
          PWA_STUDIO_REPO: "https://github.com/magento/pwa-studio/archive/refs/tags/"
          PWA_STUDIO_VER: "12.1.0"
          PWA_STUDIO_ROOT_DIR: "/var/www/data-pwa/pwa-studio"
          MAGENTO_URL: "https://{{ app_domain }}"
          MAGENTO_REL_VER: "2.4.3"
          MAGENTO_LICENSE: "EE"
      roles:
        - { role: classyllama.pwa-demo, tags: pwa-demo, when: use_classyllama_pwa_demo | default(false) }

## Script Usage

    # Once the scripts are on the server
    ~/pwa-demo/install-pwa.sh config_site.json
    ~/pwa-demo/uninstall-pwa.sh config_site.json
    # For upward-php implementation: 
    /home/www-data/magento-demo/custom_script_site.sh 

## License

This work is licensed under the MIT license. See LICENSE file for details.
