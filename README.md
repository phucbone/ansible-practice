# ansible-practice

## Elasticsearch

0-initial.yml

```yaml
{% raw %}
---
- name: Initial server
  hosts: all
  become: true
  vars:
    new_user: "devops"
  tasks:

    - name: Add serveral lines to /etc/hosts
      ansible.builtin.lineinfile:
        path: /etc/hosts
        line: "{{ item }}"
        create: true
        mode: "0600"
      with_items:
        - "192.168.1.130 es-prd-01"
        - "192.168.1.140 es-prd-02"
        - "192.168.1.150 es-prd-03"
        - "192.168.1.160 es-prd-04"

    - name: Create new user
      ansible.builtin.user:
        name: "{{ new_user }}"
        groups: "{{ new_user }},root,sudo"
        append: true
        create_home: true
        shell: /bin/bash
        expires: -1

    # - name: Check .ssh directory exists
    #   ansible.builtin.stat:
    #     path: "/home/{{ new_user }}/.ssh/"
    #   register: ssh_dir_data

    # - name: Create .ssh directory if it not exists
    #   ansible.builtin.file:
    #     path: "/home/{{ new_user }}/.ssh/"
    #     state: directory
    #     mode: "0700"
    #   when: not ssh_dir_data.stat.exists

    - name: Check sudoers file exists
      ansible.builtin.stat:
        path: "/etc/sudoers.d/{{ new_user }}"
      register: create_user_data

    - name: Create sudoers for new user
      ansible.builtin.copy:
        dest: "/etc/sudoers.d/{{ new_user }}"
        mode: "0400"
        content: "{{ new_user }}   ALL=(ALL)     NOPASSWD: ALL"
      when: not create_user_data.stat.exists
{% endraw %}
```

1-install-es.yml

```yaml
{% raw %}
---
- name: Download and install the Elasticsearch
  hosts: all
  become: true
  vars:
    es_dir: "/opt/elasticsearch"
    es_work_dir: "{{ es_dir }}/running"
    es_setup_dir: "{{ es_dir }}/setup"
    es_log_dir: "{{ es_dir }}/log"
    es_backup_dir: "{{ es_dir }}/backup"
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
        path: "{{ item }}"
      register: es_dirs_data
      loop:
        - "{{ es_dir }}"
        - "{{ es_work_dir }}"
        - "{{ es_setup_dir }}"
        - "{{ es_log_dir }}"
        - "{{ es_backup_dir }}"

    - name: Create ES directories if it not exists
      ansible.builtin.file:
        path: "{{ item.item }}"
        state: directory
        owner: root
        group: root
        mode: "0775"
      loop: "{{ es_dirs_data.results }}"
{% endraw %}
```
