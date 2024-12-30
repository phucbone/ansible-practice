Nếu bạn muốn tải các gói APT từ một phiên bản khác của Ubuntu, bạn có thể làm theo các bước sau. Tuy nhiên, cần lưu ý rằng việc sử dụng các gói từ phiên bản khác có thể gây ra các vấn đề không tương thích hoặc phá vỡ hệ thống của bạn. Hãy thực hiện cẩn thận và sao lưu dữ liệu trước khi bắt đầu.

## Sử dụng apt-get download
Cách này tải gói từ kho lưu trữ mà không cần cài đặt:

Thêm nguồn từ phiên bản Ubuntu khác vào tệp /etc/apt/sources.list. Ví dụ, nếu bạn đang sử dụng Ubuntu 22.04 (Jammy) và muốn tải gói từ Ubuntu 20.04 (Focal), làm như sau dòng sau:
```bash
# Thêm dòng sau vào /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu focal main restricted universe multiverse

# Cập nhật danh sách gói (nhưng không nâng cấp hệ thống):
sudo apt-get update

# Tải gói từ phiên bản cũ:
sudo apt-get -t focal download <tên_gói>
```

## Cài đặt Ansible (Offline)

Trên máy có Internet
```bash
# Cập nhật danh sách gói
sudo apt update

# Tải các gói cần thiết
mkdir -p ~/ansible-offline
cd ~/ansible-offline
sudo apt install apt-rdepends
sudo apt-rdepends ansible | grep -v "^ " | xargs -I{} sudo apt-get download {}

# Tạo file nén
tar czvf ansible-offline.tar.gz ~/ansible-offline
```

Chuyển file sang máy không có Internet và Cài đặt Ansible
```bash
# Giải nén file
tar xzvf ansible-offline.tar.gz
cd ansible-offline

# Cài đặt các gói
sudo dpkg -i *.deb

# Nếu gặp lỗi phụ thuộc, chạy lệnh sau để sửa:
sudo apt --fix-broken install
# Lệnh trên sẽ tự động cài đặt các phụ thuộc đã được tải xuống.

# Kiểm tra cài đặt
ansible --version
```
