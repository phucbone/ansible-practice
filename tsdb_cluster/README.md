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

Kiểm tra trạng thái dịch vụ TimescaleDB
```bash
systemctl status timescaledb
```

Cấu hình trên Access Node
```sql
-- Tạo extension TimescaleDB
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Thêm Data Nodes
SELECT add_data_node('cl-mspstg-ts-02', host => '70.222.9.196');
SELECT add_data_node('cl-mspstg-ts-03', host => '70.222.9.197');
SELECT add_data_node('cl-mspstg-ts-04', host => '70.222.9.198');
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
