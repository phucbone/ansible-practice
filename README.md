# ansible-practice

## Elasticsearch

0-initial.yml
```yaml
---
- name: Download and install the Elasticsearch
  hosts: all
  become: true
  vars:
    es_dir: "/opt/elasticsearch"
    es_work_dir: "\{{ es_dir }\}/running"
    es_setup_dir: "\{{ es_dir }\}/setup"
    es_log_dir: "\{{ es_dir }\}/log"
    es_backup_dir: "\{{ es_dir }\}/backup"
    es_ver: "7.10.1"
  tasks:
    - name: Install dependencies packages
      ansible.builtin.shell: |
        apt update
        apt install -y apt-transport-https net-tools jq tree wget python3
      register: install_dependencies_data
      changed_when: install_dependencies_data.rc != 0

    - name: Check ES directories exists
      ansible.builtin.stat:
        path: "\{{ item }\}"
      register: es_dirs_data
      loop:
        - "\{{ es_dir }\}"
        - "\{{ es_work_dir }\}"
        - "\{{ es_setup_dir }\}"
        - "\{{ es_log_dir }\}"
        - "\{{ es_backup_dir }\}"

    - name: Create ES directories if it not exists
      ansible.builtin.file:
        path: "\{{ item.item }\}"
        state: directory
        owner: root
        group: root
        mode: "0775"
      loop: "\{{ es_dirs_data.results }\}"
```
