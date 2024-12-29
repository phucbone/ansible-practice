# ansible-practice

## Elasticsearch Cluster v7.9.1

Cấu trúc dự án
```plaintext
ansible-es-cluster/
├── inventory                             # File inventory liệt kê các node Elasticsearch
├── playbook.yml                          # Playbook chính
├── group_vars/
│   └── elasticsearch.yml                 # Biến chung cho nhóm Elasticsearch
├── roles/
│   └── elasticsearch/
│       ├── tasks/
│       │   └── main.yml                  # Tác vụ chính để cài đặt Elasticsearch
│       ├── templates/
│       │   ├── elasticsearch.yml.j2      # Template cấu hình Elasticsearch
│       │   └── elasticsearch.service.j2  # Template file systemd service
│       ├── files/
│       │   ├── elasticsearch-7.9.1-linux-x86_64.tar.gz   # File Elasticsearch
│       │   ├── jdk-11.0.16_linux-x64_bin.tar.gz          # File JDK nếu cần
```
Nội dung các file

playbook.yml
```yaml
{% raw %}
---
- hosts: elasticsearch
  roles:
    - elasticsearch
{% endraw %}
```

inventory
```ini
[elasticsearch]
node1 ansible_host=192.168.1.101 ansible_user=root
node2 ansible_host=192.168.1.102 ansible_user=root
node3 ansible_host=192.168.1.103 ansible_user=root
```

group_vars/elasticsearch.yml
```yaml
{% raw %}
elasticsearch_version: 7.9.1

elasticsearch_tarball: elasticsearch-7.9.1-linux-x86_64.tar.gz

java_package: openjdk-11-jdk

cluster_name: es_cluster

node_name_prefix: es_node

network_host: 0.0.0.0

discovery_seed_hosts:
  - 192.168.1.101
  - 192.168.1.102
  - 192.168.1.103

cluster_initial_master_nodes:
  - 192.168.1.101
  # - 192.168.1.102
  # - 192.168.1.103

path_data: /opt/elasticsearch/data

path_logs: /opt/elasticsearch/logs
{% endraw %}
```

roles/elasticsearch/tasks/main.yml

```yaml
{% raw %}
---
- name: Install required dependencies
  apt:
    name: "{{ item }}"
    state: present
  with_items:
    - libcurl4
    - apt-transport-https
    - wget

- name: Install JDK
  unarchive:
    src: "{{ role_path }}/files/{{ jdk_tarball }}"
    dest: /usr/local/
    remote_src: yes

- name: Add ES Nodes to /etc/hosts
  lineinfile:
    path: /etc/hosts
    line: "{{ item }}"  # Sử dụng biến item để lặp qua các dòng
    create: yes         # Tạo file nếu nó không tồn tại
    state: present      # Đảm bảo dòng này tồn tại trong file
  with_items:
    - "192.168.1.101  es-1"
    - "192.168.1.102  es-2"
    - "192.168.1.103  es-3"

- name: Create elasticsearch group
  group:
    name: elasticsearch
    state: present

- name: Create elasticsearch user
  user:
    name: elasticsearch
    group: elasticsearch
    home: /home/elasticsearch
    shell: /bin/bash
    create_home: yes
    state: present

- name: Add elasticsearch user to sudo group
  user:
    name: elasticsearch
    groups: sudo
    append: yes

# - name: Allow elasticsearch user to run sudo without password
#   lineinfile:
#     path: /etc/sudoers
#     regexp: "^elasticsearch"
#     line: "elasticsearch ALL=(ALL) NOPASSWD:ALL"
#     state: present
#     validate: "visudo -cf %s"

- name: Create sudoers file for elasticsearch user
  copy:
    dest: /etc/sudoers.d/elasticsearch
    content: "elasticsearch ALL=(ALL) NOPASSWD:ALL\n"
    owner: root
    group: root
    mode: '0440'
  validate: "visudo -cf %s"

- name: Set permissions for Elasticsearch directories
  file:
    path: "{{ item }}"
    state: directory
    owner: elasticsearch
    group: elasticsearch
    mode: '0755'
  with_items:
    - /opt/elasticsearch
    - "{{ path_data }}"
    - "{{ path_logs }}"

- name: Set Java environment variables
  lineinfile:
    path: /etc/environment
    line: "{{ item }}"
    create: yes
  with_items:
    - "JAVA_HOME=/usr/local/jdk-11.0.16"
    - "PATH=$PATH:/usr/local/jdk-11.0.16/bin"
  notify: Reload environment

- name: Extract Elasticsearch tarball
  unarchive:
    src: "{{ role_path }}/files/{{ elasticsearch_tarball }}"
    dest: /opt
    remote_src: yes

- name: Create data and log directories
  file:
    path: "{{ item }}"
    state: directory
    owner: elasticsearch
    group: elasticsearch
    mode: '0755'
  with_items:
    - "{{ path_data }}"
    - "{{ path_logs }}"

- name: Configure Elasticsearch
  template:
    src: elasticsearch.yml.j2
    dest: /opt/elasticsearch-{{ elasticsearch_version }}/config/elasticsearch.yml
    owner: elasticsearch
    group: elasticsearch
    mode: '0644'

- name: Configure systemd service
  template:
    src: elasticsearch.service.j2
    dest: /etc/systemd/system/elasticsearch.service
    mode: '0644'

- name: Enable and start Elasticsearch service
  systemd:
    name: elasticsearch
    enabled: yes
    state: started
{% endraw %}
```

roles/elasticsearch/templates/elasticsearch.yml.j2

```yaml
{% raw %}
cluster.name: {{ cluster_name }}
node.name: "{{ node_name_prefix }}-{{ inventory_hostname }}"
path.data: {{ path_data }}
path.logs: {{ path_logs }}
network.host: {{ network_host }}
discovery.seed_hosts: {{ discovery_seed_hosts }}
cluster.initial_master_nodes: {{ cluster_initial_master_nodes }}
{% endraw %}
```

roles/elasticsearch/templates/elasticsearch.service.j2

```ini
[Unit]
Description=Elasticsearch
After=network.target

[Service]
Type=simple
User=elasticsearch
Group=elasticsearch
ExecStart=/opt/elasticsearch-{{ elasticsearch_version }}/bin/elasticsearch
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

Chạy playbook:

```bash
ansible-playbook -i inventory es_cluster.yml --log-file=es_cluster-7.9.1.log
```

Kiểm tra trạng thái dịch vụ Elasticsearch:
```bash
systemctl status elasticsearch
```

Xác nhận cluster hoạt động:

```bash
curl -X GET "http://192.168.1.101:9200/_cluster/health?pretty"
```

>Lưu ý quan trọng
>
>**Java JDK:**
>+ Elasticsearch yêu cầu Java, vì vậy bạn cần chắc chắn JDK đã được cài đặt.
>+ Sử dụng jdk-11 là phiên bản tương thích với Elasticsearch 7.9.1.
>
>**Quyền thư mục:** Thư mục /opt/elasticsearch/data và /opt/elasticsearch/logs cần được tạo với quyền sở hữu là elasticsearch.
>
>**Cổng mạng:** Mở cổng 9200 và 9300 trên cả 3 node để đảm bảo cluster giao tiếp được.
>
>**Tài nguyên hệ thống:** Đảm bảo các node có đủ tài nguyên (CPU, RAM, Disk) để Elasticsearch hoạt động ổn định.

## TimescaleDB Cluster v2.11.2 (PostgreSQL 14.9)

Cấu trúc thư mục Ansible:
```plaintext
ansible-tsdb-cluster/
├── inventory                             # File inventory liệt kê các node TSDB
├── playbook.yml                          # Playbook chính
├── roles/
│   ├── setup-timescaledb/
│   │   ├── tasks/
│   │   │   └── main.yml                  # Tác vụ chính để cài đặt TSDB
│   │   ├── templates/
│   │   │   └── postgresql.conf.j2        # Template cấu hình TSDB
│   │   ├── files/
│   │   │   ├── timescaledb-2.11.2-postgresql-14_2.11.2~ubuntu20.04_amd64.deb   # File TSDB
│   │   │   ├── postgresql-14_14.9-1.pgdg20.04+1_amd64.deb                      # File PostgreSQL
```

Nội dung các file

inventory
```ini
[access_node]
access-node ansible_host=192.168.1.10 ansible_user=your_user

[data_nodes]
data-node1 ansible_host=192.168.1.11 ansible_user=your_user
data-node2 ansible_host=192.168.1.12 ansible_user=your_user
data-node3 ansible_host=192.168.1.13 ansible_user=your_user
```

playbook.yml
```yaml
{% raw %}
- name: Setup TimescaleDB Cluster
  hosts: all
  become: yes
  roles:
    - setup-timescaledb
{% endraw %}
```

roles/setup-timescaledb/tasks/main.yml
```yaml
{% raw %}
- name: Install dependencies
  apt:
    name:
      - wget
      - gnupg
    state: present
  when: ansible_os_family == "Debian"

- name: Add TimescaleDB Nodes to /etc/hosts
  lineinfile:
    path: /etc/hosts
    line: "{{ item }}"  # Sử dụng biến item để lặp qua các dòng
    create: yes         # Tạo file nếu nó không tồn tại
    state: present      # Đảm bảo dòng này tồn tại trong file
  with_items:
    - "192.168.1.100   myserver1.local"
    - "192.168.1.101   myserver2.local"
    - "192.168.1.102   myserver3.local"

- name: Copy PostgreSQL and TimescaleDB packages
  copy:
    src: files/
    dest: /tmp/
    remote_src: no

- name: Install PostgreSQL v14.9
  command: dpkg -i /tmp/postgresql-14_14.9-1.pgdg20.04+1_amd64.deb

- name: Install TimescaleDB v2.11.2
  command: dpkg -i /tmp/timescaledb-2.11.2-postgresql-14_2.11.2~ubuntu20.04_amd64.deb

- name: Create directories for TimescaleDB
  file:
    path: "{{ item }}"
    state: directory
    owner: postgres
    group: postgres
    mode: '0755'
  loop:
    - /mnt/timescaledb-data
    - /opt/timescaledb/backup
    - /opt/timescaledb/download
    - /opt/timescaledb/log

- name: Configure PostgreSQL
  template:
    src: postgresql.conf.j2
    dest: /etc/postgresql/14/main/postgresql.conf

# - name: Update PostgreSQL port to 45432
#   lineinfile:
#     path: /etc/postgresql/14/main/postgresql.conf
#     regexp: '^#?port =.*'
#     line: 'port = 45432'
#   notify:
#     - Restart PostgreSQL

# - name: Update PostgreSQL data directory
#   lineinfile:
#     path: /etc/postgresql/14/main/postgresql.conf
#     regexp: '^#?data_directory =.*'
#     line: 'data_directory = "/mnt/timescaledb-data/"'
#   notify:
#     - Restart PostgreSQL

- name: Restart PostgreSQL
  service:
    name: postgresql
    state: restarted
{% endraw %}
```

roles/setup-timescaledb/templates/postgresql.conf.j2
```conf
# PostgreSQL Configuration
listen_addresses = '*'
port = 45432
max_connections = 500
unix_socket_directories = '/tmp'
shared_preload_libraries = 'timescaledb'
```

Cài đặt và cấu hình TimescaleDB
```bash
ansible-playbook -i inventory playbook.yml --log-file=tsdb_cluster-2.11.2.log
```

Kiểm tra trạng thái dịch vụ PostgreSQL
```bash
systemctl status postgresql
```

Cấu hình trên Access Node
```sql
-- Tạo extension TimescaleDB
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Thêm Data Nodes
SELECT add_data_node('data_node1', host => '192.168.1.11');
SELECT add_data_node('data_node2', host => '192.168.1.12');
SELECT add_data_node('data_node3', host => '192.168.1.13');
```

Cấu hình trên Data Nodes
```sql
-- Tạo extension TimescaleDB
CREATE EXTENSION IF NOT EXISTS timescaledb;
```

Testing
```sql
-- Tạo bảng phân tán
CREATE TABLE distributed_table (
    time TIMESTAMPTZ NOT NULL,
    value DOUBLE PRECISION
) USING timescaledb;

-- Thêm dữ liệu thử nghiệm
INSERT INTO distributed_table VALUES (NOW(), 42.0);
```

>**Ghi chú**
>
>+ Đảm bảo rằng cấu hình mạng giữa các Access Node và Data Nodes được thông suốt (các port liên quan PostgreSQL, thường là 5432, phải được mở).
>
>+ Nếu gặp lỗi trong quá trình cài đặt, kiểm tra chi tiết nhật ký Ansible hoặc dịch vụ PostgreSQL.
