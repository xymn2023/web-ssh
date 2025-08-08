#!/bin/bash

# WebSSH 一键安装脚本
# 从 GitHub 下载并执行安装脚本

echo "=========================================="
echo "        WebSSH 一键安装脚本"
echo "=========================================="
echo

# 下载安装脚本
echo "正在下载安装脚本..."
curl -fsSL https://raw.githubusercontent.com/xymn2023/web-ssh/main/install.sh -o install.sh

if [[ $? -eq 0 ]]; then
    echo "下载成功！"
    
    # 添加执行权限
    chmod +x install.sh
    
    # 执行安装脚本
    echo "开始执行安装脚本..."
    ./install.sh
else
    echo "下载失败，请检查网络连接或 GitHub 地址"
    exit 1
fi 