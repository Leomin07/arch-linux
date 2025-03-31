#!/bin/bash

# Clone repository từ GitHub
git clone https://github.com/SolDoesTech/HyprV2.git

# Di chuyển vào thư mục HyprV2
cd HyprV2

# Cấp quyền thực thi cho script set-hypr
chmod +x set-hypr

# Chạy script set-hypr
./set-hypr
