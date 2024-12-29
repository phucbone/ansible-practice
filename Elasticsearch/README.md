ansible-elasticsearch/
├── inventory                # File inventory liệt kê các node Elasticsearch
├── site.yml                 # Playbook chính
├── group_vars/
│   └── elasticsearch.yml    # Biến chung cho nhóm Elasticsearch
├── roles/
│   └── elasticsearch/
│       ├── tasks/
│       │   └── main.yml     # Tác vụ chính để cài đặt Elasticsearch
│       ├── templates/
│       │   ├── elasticsearch.yml.j2  # Template cấu hình Elasticsearch
│       │   └── elasticsearch.service.j2  # Template file systemd service
│       ├── files/
│       │   ├── elasticsearch-7.9.1-linux-x86_64.tar.gz  # File Elasticsearch
│       │   ├── jdk-11.0.16_linux-x64_bin.tar.gz        # File JDK nếu cần