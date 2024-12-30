Sơ đồ files

```css
tsdb_cluster/
├── inventory
├── playbook.yml
├── group_vars/
│   └── all.yml
├── roles/
│   ├── common/
│   │   ├── tasks/
│   │   │   ├── install.yml
│   │   │   ├── main.yml
│   │   │   └── setup.yml
│   │   ├── files/
│   │   │   ├── postgresql-14_14.9-1.pgdg20.04+1_amd64.deb
│   │   │   └── timescaledb-2.11.2-postgresql-14_2.11.2~ubuntu20.04_amd64.deb
│   │   └── templates/
│   ├── access_node/
│   │   ├── tasks/
│   │   │   ├── configure.yml
│   │   │   └── main.yml
│   └── data_node/
│       └── tasks/
│       │   ├── configure.yml
│       │   └── main.yml
```

Chạy Playbook
```bash
ansible-playbook -i inventory playbook.yml --log-file=tsdb_cluster-2.11.2.log
```
  - ""
  - ""
