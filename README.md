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

    - hosts: all
      vars:
        pwa_demo_config_overrides:
          pwa_demo_magento_base_url: example.lan
          pwa_demo_env_root: /var/www/data-pwa
          pwa_demo_magento_root: /var/www/data-pwa/pwa
          pwa_demo_user: www-data-pwa
          pwa_demo_group: www-data-pwa
      roles:
        - { role: classyllama.pwa-demo, tags: pwa-demo, when: use_classyllama_pwa_demo | default(false) }

## Script Usage

    # Once the scripts are on the server
    ~/pwa-demo/install-pwa.sh config_site.json
    ~/pwa-demo/uninstall-pwa.sh config_site.json

## License

This work is licensed under the MIT license. See LICENSE file for details.
