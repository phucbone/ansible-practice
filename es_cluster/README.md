Cấu trúc thư mục

```plaintext
es_cluster/
├── inventory/
│   └── hosts
├── playbooks/
│   ├── install_es-for-data.yml
│   └── install_es-for-logs.yml
├── roles/
│   └── elasticsearch/
│       ├── tasks/
│       │   ├── main.yml
│       │   ├── setup.yml
│       │   ├── install.yml
│       │   └── configure.yml
│       ├── files/
│       │   ├── elasticsearch-7.10.1-linux-x86_64.tar.gz
│       └── templates/
│           ├── elasticsearch.yml.j2
│           └── jvm.options.j2
├── group_vars/
│   └── all.yml
```

Chạy Playbook
```bash
ansible-playbook -i inventory/hosts playbooks/install_es-for-data.yml --log-file=es-for-data_cluster-2.11.2.log
ansible-playbook -i inventory/hosts playbooks/install_es-for-logs.yml --log-file=es-for-logs_cluster-2.11.2.log
```
