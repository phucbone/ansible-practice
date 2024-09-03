# ansible-practice


add-host.yml
```yaml
---
- name: Add hosts
  hosts: all
  become: true
  tasks:

    - name: Add serveral lines to /etc/hosts
      ansible.builtin.lineinfile:
        path: /etc/hosts
        line: "{{ item }}"
        create: true
        mode: "0600"
      with_items:
        - "192.168.1.130 ts-prd-01"
        - "192.168.1.140 ts-prd-02"
        - "192.168.1.150 ts-prd-03"
        - "192.168.1.160 ts-prd-04"
```


add-user.yml
```yaml
---
- name: Add new devops user
  hosts: all
  become: true
  tasks:

    - name: Create devops user
      ansible.builtin.user:
        name: devops
        groups: root,sudo,devops
        append: true
        create_home: true
        shell: /bin/bash
        expires: -1
        generate_ssh_key: true
        ssh_key_type: ed25519
        ssh_key_bits: 2048
        ssh_key_file: .ssh/id_rsa
        ssh_key_comment: devops

    # - name: Add ssh key for devops user
    #   ansible.builtin.authorized_key:
    #     user: devops
    #     key: ""

    - name: Add sudoers file for devops user
      ansible.builtin.copy:
        src: /etc/ansible/files/sudoers_devops
        dest: /etc/sudoers.d/devops
        owner: root
        group: root
        mode: "0440"
```

install-tsdb.yml
```yaml
---
- name: Install and configure TimescaleDB on PostgreSQL
  hosts: all
  become: true
  vars:
    tsdb_dir: "/opt/tsdb"
    tsdb_ver: "2.16.1"
    tsdb_user: "postgres"
    tsdb_pass: "postgres"
    tsdb_dbname: "postgres"

  tasks:

    - name: Install dependencies packages
      ansible.builtin.apt:
        pkg:
          - debian-archive-keyring
          - gnupg
          - postgresql-common
          - lsb-release
          - apt-transport-https
          - wget
          - postgresql-server-dev-16
          - net-tools
          - jq
          - tree
          - python3
          - psycopg2
        update_cache: true

    - name: Create timescaledb directory
      ansible.builtin.file:
        path: "{{ tsdb_dir }}/{{ item }}"
        state: directory
        owner: root
        group: root
        mode: "0775"
      with_items:
        - "setup"
        - "backup"
        - "log"
        - "running"

    # Option: 1
    - name: Download and Run the TimescaleDB package setup script
      block:
        - name: Download TimesacleDB script repository
          ansible.builtin.get_url:
            url: "https://packagecloud.io/install/repositories/timescale/timescaledb/script.deb.sh"
            dest: "{{ tsdb_dir }}/setup/install-timescaledb-repository.sh"
            mode: "0755"

        - name: Run TimesacleDB script repository
          ansible.builtin.command:
            cmd: "{{ tsdb_dir }}/setup/install-timescaledb-repository.sh"
          register: script_tsdb
          changed_when: script_tsdb.rc != 0

    - name: Install GPG key and add package of TimescaleDB
      block:
        - name: Install the TimescaleDB GPG key
          ansible.builtin.get_url:
            url: "https://packagecloud.io/timescale/timescaledb/gpgkey"
            dest: /etc/apt/trusted.gpg.d/timescaledb.gpg
            mode: "0440"

        - name: Add the TimescaleDB package
          ansible.builtin.apt_repository:
            repo: "deb https://packagecloud.io/timescale/timescaledb/debian/ {{ ansible_distribution_release }} main"
            filename: timescaledb.list
            state: present

    - name: Update local repository list & Install TimescaleDB specific version
      ansible.builtin.apt:
        pkg:
          - "timescaledb-2-postgresql-14={{ tsdb_ver }}"
          - "timescaledb-2-loader-postgresql-14={{ tsdb_ver }}"
        update_cache: true

    # Option: 2
    - name: Download and run .deb with version {{ tsdb_ver }}
      block:
        - name: Download .deb with version {{ tsdb_ver }}
          ansible.builtin.get_url:
            url: "https://packagecloud.io/timescale/timescaledb/packages/ubuntu/{{ ansible_distribution_release }}/timescaledb-2-postgresql-14_{{ tsdb_ver }}~ubuntu22.04_amd64.deb"
            dest: "{{ tsdb_dir }}/setup"
            mode: "0755"

        - name: Install a .deb package
          ansible.builtin.apt:
            deb: "{{ tsdb_dir }}/setup/timescaledb-2-postgresql-14_{{ tsdb_ver }}~ubuntu22.04_amd64.deb"

    - name: Tune PostgreSQL instances for TimescaleDB
      ansible.builtin.command:
        cmd: timescaledb-tune
      register: timescaledb_tune
      changed_when: timescaledb_tune.rc != 0

    - name: Print Tuned PostgreSQL
      ansible.builtin.debug:
        var: timescaledb_tune

    - name: Restart PostgreSQL
      ansible.builtin.systemd_service:
        name: postgresql
        state: restarted
        enable: true

    - name: Utility present
      ansible.builtin.package:
        name: python3-psycopg2
        state: present

    - name: Run SQL query
      community.postgresql.postgresql_query:
        db: "{{ tsdb_dbname }}"
        query: "SELCT version()"
        become: true
        become_user: "{{ tsdb_user }}"
        register: tsdb_query_data

    - name: Print result of query
      ansible.builtin.debug:
        var: tsdb_query_data

    - name: Login to PostgreSQL as postgres and Set the password for serveral users
      community.postgresql.postgresql_user:
        name: "{{ item.name }}"
        password: "{{ item.password }}"
        expires: "infinity"
        become: true
        become_user: "{{ tsdb_user }}"
      loop:
        - { name: "admin", password: "msplus2024!" }
        - { name: "devportal", password: "sre2024!" }
        - { name: "sreplus", password: "dnsdud2024!" }
```

tsdb-add-users.yml

```yaml
---
- name: Add db, users and grant privileges permission
  hosts: all
  become: true
  vars:
    tsdb_user: "postgres"
    tsdb_pass: "postgres"
    tsdb_dbname: "sop"

  tasks:
    - name: Utility present
      ansible.builtin.package:
        name: python3-psycopg2
        state: present

    - name: Add users
      community.postgresql.postgresql_user:
        login_user: "{{ tsdb_user }}"
        name: "{{ item.name }}"
        password: "{{ item.password }}"
        expires: "infinity"
        become: true
        become_user: "{{ tsdb_user }}"
      loop:
        - { name: "admin", password: "msplus2024!" }
        - { name: "devportal", password: "sre2024!" }
        - { name: "sreplus", password: "dnsdud2024!" }

    - name: Run SQL query
      community.postgresql.postgresql_query:
        db: "{{ tsdb_dbname }}"
        query: "SELCT version()"
        become: true
        become_user: "{{ tsdb_user }}"
        register: tsdb_query_data

    - name: Print result of query
      ansible.builtin.debug:
        var: tsdb_query_data
```
