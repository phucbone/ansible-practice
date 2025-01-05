# Ansible Architecture Directory

```ini
elasticsearch-cluster/
├── ansible.cfg                                             # Cấu hình Ansible
├── hosts                                                   # File inventory (danh sách các nodes trong cluster)
├── playbook.yml                                            # Playbook chính để chạy các roles
├── group_vars/                                             # Thư mục chứa các biến dùng chung cho nhóm
│   └── elasticsearch.yml                                   # Các biến chung cho nhóm `elasticsearch`
├── roles/                                                  # Thư mục chứa các roles
│   ├── setup/                                              # Role để thiết lập môi trường
│   │   ├── tasks/                                          # Thư mục chứa các task
│   │   │   └── main.yml                                    # Các task thiết lập user, group, sudoers
│   │   └── files/                                          # Chứa các file tĩnh (nếu cần)
│   │   └── templates/                                      # Chứa các file template (nếu cần)
│   ├── install/                                            # Role để cài đặt Elasticsearch
│   │   ├── tasks/                                          # Thư mục chứa các task
│   │   │   └── main.yml                                    # Các task để cài đặt Elasticsearch
│   │   ├── files/                                          # Thư mục chứa file Elasticsearch tar.gz
│   │   │   └── elasticsearch-7.10.1-linux-x86_64.tar.gz    # File cài đặt Elasticsearch 7.10.1
│   │   └── templates/                                      # Chứa các file template (nếu cần)
│   ├── config/                                             # Role để cấu hình Elasticsearch
│   │   ├── tasks/                                          # Thư mục chứa các task
│   │   │   └── main.yml                                    # Các task để cấu hình Elasticsearch
│   │   ├── templates/                                      # Chứa các file template cho Elasticsearch
│   │   │   ├── elasticsearch.yml.j2                        # Template cho file elasticsearch.yml
│   │   │   └── jvm.options.j2                              # Template cho file jvm.options

```
