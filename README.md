# Ansible Role: PWA Demo

Installs a shell script on RHEL / CentOS for installing PWA (Venia theme).

The role sets up a config file for a specific domain/directory/user and saves the config files and scripts in the user's home directory ~/username/pwa-demo/.

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
        pwa_demo_hostname: "pwa-{{ app_domain }}"
        pwa_demo_env_root: /var/www/data-pwa
        pwa_demo_app_dir: /var/www/data-pwa/venia-concept
        pwa_demo_user: www-data-pwa
        pwa_demo_group: www-data-pwa
        pwa_demo_scripts_dir: "/home/{{ pwa_demo_user }}/pwa-demo"
        pwa_demo_config_name: "site"

        pwa_demo_config_overrides:
          CONFIG_NAME: "site"
          SITE_HOSTNAME: "pwa-{{ app_domain }}"
          PWA_APP_DIR: "/var/www/data-pwa/venia-concept"
          SITE_ROOT_DIR: "current"
          PWA_STUDIO_REPO: "https://github.com/magento/pwa-studio/archive/refs/tags/"
          PWA_STUDIO_VER: "11.0.0"
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

## License

This work is licensed under the MIT license. See LICENSE file for details.