# ansible-practice

## Elasticsearch

hosts
```ini
[ubuntu_2204]
192.168.1.130

[all:children]
ubuntu_2204

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

0-initial.yml

```yaml
{% raw %}
---
- name: Initial servers
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

    - name: Create user {{ new_user }}
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

    - name: Check sudoers file exists /etc/sudoers.d/{{ new_user }}
      ansible.builtin.stat:
        path: "/etc/sudoers.d/{{ new_user }}"
      register: create_user_data

    # - name: Validate the sudoers file before saving
    #   ansible.builtin.lineinfile:
    #     path: "/etc/sudoers.d/{{ new_user }}"
    #     state: present
    #     regexp: "^{{ new_user }}   ALL=(ALL)     NOPASSWD: ALL"
    #     line: "{{ new_user }}   ALL=(ALL)     NOPASSWD: ALL"
    #     validate: /usr/sbin/visudo -cf %s

    - name: Create sudoers file for {{ new_user }}
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
    install_tool: "elasticsearch"
    es_dir: "/opt/elasticsearch"
    es_setup_dir: "{{ es_dir }}/setup"
    es_data_dir: "{{ es_dir }}/data"
    es_data_node_dir: "{{ es_data_dir }}/node"
    es_log_dir: "{{ es_dir }}/log"
    es_backup_dir: "{{ es_dir }}/backup"
    es_user: "elasticsearch"
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
        - "{{ es_data_node_dir }}"
        - "{{ es_setup_dir }}"
        - "{{ es_data_dir }}"
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
      when: not item.stat.exists

    - name: Check directory exists {{ es_setup_dir }}
      ansible.builtin.stat:
        path: "{{ es_setup_dir }}"
      register: es_setup_dir_data

    - name: Check ES setup file exists
      ansible.builtin.stat:
        path: "{{ es_setup_dir }}/elasticsearch-{{ es_ver }}-amd64.deb"
      register: es_setup_file_data

    - name: Download .deb file if it not exists
      ansible.builtin.get_url:
        url: "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-{{ es_ver }}-amd64.deb"
        dest: "{{ es_setup_dir }}/elasticsearch-{{ es_ver }}-amd64.deb"
        checksum: "sha512:https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-{{ es_ver }}-amd64.deb.sha512"
        mode: "0755"
        validate_certs: false
      when: es_setup_dir_data.stat.exists and not es_setup_file_data.stat.exists

    - name: Check ES installed or not
      ansible.builtin.shell:
      args:
        executable: /bin/bash
        cmd: |
          set -o pipefail
          dpkg-query -f '${binary:Package}\n' -W | grep {{ install_tool }}
      register: es_installed
      # ignore_errors: true
      # failed_when: es_installed.rc != 1 and es_installed.rc != 0
      failed_when: es_installed.rc not in [0, 1]
      changed_when: es_installed.rc not in [0, 1]

    # - name: Print 1
    #   ansible.builtin.debug:
    #     var: es_installed

    # - name: Check ES installed
    #   vars:
    #     filter_json: "{{ packages | community.general.json_query(\"stdout_lines[?contains(@, 'elasticsearch')]\") }}"
    #   ansible.builtin.set_fact:
    #     es_installed: "{{ true if filter_json | length > 0 else false }}"

    # - name: Result of checking ES installed
    #   ansible.builtin.debug:
    #     var: es_installed

    - name: Install ES with .deb package {{ es_ver }}
      ansible.builtin.shell: |
        dpkg -i {{ es_setup_dir }}/elasticsearch-{{ es_ver }}-amd64.deb
      when: es_installed.msg != install_tool
      register: es_deb
      changed_when: es_deb.rc != 0

    - name: Grant privileges ES directories for {{ es_user }}
      ansible.builtin.file:
        path: "{{ item }}"
        state: directory
        owner: "{{ es_user }}"
        group: "{{ es_user }}"
        mode: "0770"
      with_items:
        - "{{ es_dir }}"
        - "{{ es_data_node_dir }}"
        - "{{ es_setup_dir }}"
        - "{{ es_data_dir }}"
        - "{{ es_log_dir }}"
        - "{{ es_backup_dir }}"

{% endraw %}
```

2-config-es1.yml

```yaml
{% raw %}
---
- name: Configure ES Cluster
  hosts: all
  become: true
  vars:
    es_user: "elasticsearch"
    es_cluster_name: "mspplus-es"
    es_node_name: "cl-mspplus-es01"
    es_cluster_initial_master_nodes: "['cl-mspplus-es01']"
    es_network_hosts: "70.222.5.21"
    es_http_port: "9200"
    es_transport_hosts: "0.0.0.0"
    es_data_path: "/opt/elasticsearch/data/"
    es_log_path: "/opt/elasticsearch/log/"
    es_discovery_seed_hosts: "['70.222.5.21', '70.222.5.22', '70.222.5.23']"
    es_config_file: "/etc/elasticsearch/elasticsearch.yml"
    es_http_host: "0.0.0.0"
  tasks:
    - name: Backup & Modify {{ es_config_file }}
      ansible.builtin.lineinfile:
        backup: true
        path: "{{ es_config_file }}"
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
        owner: "{{ es_user }}"
        group: "{{ es_user }}"
        mode: "0770"
      loop:
        - { regexp: "^#cluster.name:|^cluster.name:", line: "cluster.name: {{ es_cluster_name }}" }
        - { regexp: "^#node.name:|^node.name:", line: "node.name: {{ es_node_name }}" }
        - { regexp: "^#network.host:|^network.host:", line: "network.host: {{ es_network_hosts }}" }
        - { regexp: "^#http.port:|^http.port:", line: "http.port: {{ es_http_port }}" }
        - { regexp: "^#transport.host:|^transport.host:", line: "transport.host: {{ es_transport_hosts }}" }
        - { regexp: "^#path.data:|^path.data:", line: "path.data: {{ es_data_path }}" }
        - { regexp: "^#path.logs:|^path.logs:", line: "path.logs: {{ es_log_path }}" }
        - { regexp: "^#discovery.seed_hosts:|^discovery.seed_hosts:", line: "discovery.seed_hosts: {{ es_discovery_seed_hosts }}" }
        - { regexp: "^#http.host:|^http.host:", line: "http.host: {{ es_http_host }}" }
        - regexp: "^#cluster.initial_master_nodes:|^cluster.initial_master_nodes:"
          line: "cluster.initial_master_nodes: {{ es_cluster_initial_master_nodes }}"
        - regexp: "^#action.auto_create_index:|^action.auto_create_index:"
          line: "action.auto_create_index: .monitoring*,.watches,.triggered_watches,.watcher-history*,.ml*"

    - name: Enable Security features
      ansible.builtin.lineinfile:
        backup: true
        path: "{{ es_config_file }}"
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
        owner: "{{ es_user }}"
        group: "{{ es_user }}"
        mode: "0770"
      loop:
        - regexp: "^# Enable Security features|^#Enable Security features"
          line: "# Enable Security features"
        - regexp: "^#xpack.security.enabled:|^xpack.security.enabled:"
          line: "xpack.security.enabled: true"

    - name: Restart ES service for Security features
      ansible.builtin.systemd_service:
        name: elasticsearch
        state: restarted
        enabled: true

    - name: Enable TLS features
      ansible.builtin.lineinfile:
        backup: true
        path: "{{ es_config_file }}"
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
        owner: "{{ es_user }}"
        group: "{{ es_user }}"
        mode: "0770"
      loop:
        - regexp: "^# Enable TLS|^#Enable TLS"
          line: "# Enable TLS features"
        - regexp: "^#xpack.security.transport.ssl.enabled:|^xpack.security.transport.ssl.enabled:"
          line: "xpack.security.transport.ssl.enabled: true"
        - regexp: "^#xpack.security.transport.ssl.client_authentication:|^xpack.security.transport.ssl.client_authentication:"
          line: "xpack.security.transport.ssl.client_authentication: required"
        - regexp: "^#xpack.security.transport.ssl.verification_mode:|^xpack.security.transport.ssl.verification_mode:"
          line: "xpack.security.transport.ssl.verification_mode: certificate"
        - regexp: "^#xpack.security.transport.ssl.keystore.type:|^xpack.security.transport.ssl.keystore.type:"
          line: "xpack.security.transport.ssl.keystore.type: PKCS12"
        - regexp: "^#xpack.security.transport.ssl.keystore.path:|^xpack.security.transport.ssl.keystore.path:"
          line: "xpack.security.transport.ssl.keystore.path: elastic-certificates.p12"
        - regexp: "^#xpack.security.transport.ssl.truststore.type:|^xpack.security.transport.ssl.truststore.type:"
          line: "xpack.security.transport.ssl.truststore.type: PKCS12"
        - regexp: "^#xpack.security.transport.ssl.truststore.path:|^xpack.security.transport.ssl.truststore.path:"
          line: "xpack.security.transport.ssl.truststore.path: elastic-certificates.p12"
        # - regexp: "^#xpack.security.transport.ssl.keystore.password:|^xpack.security.transport.ssl.keystore.password:"
        #   line: "xpack.security.transport.ssl.keystore.password: mspplus"

    - name: Restart ES service for TLS features
      ansible.builtin.systemd_service:
        name: elasticsearch
        state: restarted

    # - name: Enable SSL features
    #   ansible.builtin.lineinfile:
    #     backup: true
    #     path: "{{ es_config_file }}"
    #     regexp: "{{ item.regexp }}"
    #     line: "{{ item.line }}"
    #     owner: "{{ es_user }}"
    #     group: "{{ es_user }}"
    #     mode: "0770"
    #   loop:
    #     - regexp: "^# Enable HTTPS|^#Enable HTTPS"
    #       line: "# Enable HTTPS features"
    #     - regexp: "^#xpack.security.http.ssl.enabled:|^xpack.security.http.ssl.enabled:"
    #       line: "xpack.security.http.ssl.enabled: true"
    #     - regexp: "^#xpack.security.http.ssl.keystore.type:|^xpack.security.http.ssl.keystore.type:"
    #       line: "xpack.security.http.ssl.keystore.type: PKCS12"
    #     - regexp: "^#xpack.security.http.ssl.keystore.path:|^xpack.security.http.ssl.keystore.path:"
    #       line: "xpack.security.http.ssl.keystore.path: elastic-certificates.p12"
    #     - regexp: "^#xpack.security.http.ssl.keystore.password:|^xpack.security.http.ssl.keystore.password:"
    #       line: "xpack.security.http.ssl.keystore.password: mspplus"
    #     - regexp: "^#xpack.security.http.ssl.client_authentication:|^xpack.security.http.ssl.client_authentication:"
    #       line: "xpack.security.http.ssl.client_authentication: required"

    # - name: Restart ES service for SSL features
    #   ansible.builtin.systemd_service:
    #     name: elasticsearch
    #     state: restarted

    # - name: Check ES user exists
    #   ansible.builtin.shell:
    #   args:
    #     executable: /bin/bash
    #     chdir: "/usr/share/elasticsearch/bin"
    #     cmd: |
    #       set -o pipefail
    #       ./elasticsearch-users list | grep {{ item }} | awk '{print $1}'
    #   with_items:
    #     - "msp"
    #     - "sreplusop"
    #     - "mspplus"
    #   register: es_new_user_data
    #   changed_when: es_new_user_data.changed

    # - name: Print
    #   ansible.builtin.debug:
    #     var: es_new_user_data

{% endraw %}
```
