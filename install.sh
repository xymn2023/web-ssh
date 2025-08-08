#!/bin/bash

# WebSSH Python 版本兼容性修复脚本
# 解决 cffi 和 pynacl 的版本冲突问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查可用的 Python 版本
check_python_versions() {
    log_info "检查系统中可用的 Python 版本..."
    
    # 检查 Python 3.8
    if command -v python3.8 &> /dev/null; then
        PYTHON_VERSION="3.8"
        PYTHON_CMD="python3.8"
        log_success "找到 Python 3.8"
        return 0
    fi
    
    # 检查 Python 3.9
    if command -v python3.9 &> /dev/null; then
        PYTHON_VERSION="3.9"
        PYTHON_CMD="python3.9"
        log_success "找到 Python 3.9"
        return 0
    fi
    
    # 检查 Python 3.10
    if command -v python3.10 &> /dev/null; then
        PYTHON_VERSION="3.10"
        PYTHON_CMD="python3.10"
        log_success "找到 Python 3.10"
        return 0
    fi
    
    # 检查 Python 3.11
    if command -v python3.11 &> /dev/null; then
        PYTHON_VERSION="3.11"
        PYTHON_CMD="python3.11"
        log_success "找到 Python 3.11"
        return 0
    fi
    
    # 检查默认 Python 3
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
        PYTHON_CMD="python3"
        log_success "找到 Python $PYTHON_VERSION"
        return 0
    fi
    
    log_error "未找到合适的 Python 版本"
    return 1
}

# 安装特定版本的 Python
install_python_version() {
    local version=$1
    log_info "安装 Python $version..."
    
    if [[ -f /etc/debian_version ]]; then
        # Debian/Ubuntu 系统
        sudo apt-get update
        sudo apt-get install -y software-properties-common
        sudo add-apt-repository -y ppa:deadsnakes/ppa
        sudo apt-get update
        sudo apt-get install -y python$version python$version-dev python$version-pip
        PYTHON_CMD="python$version"
        PYTHON_VERSION="$version"
    elif [[ -f /etc/redhat-release ]]; then
        # CentOS/RHEL 系统
        sudo yum update -y
        sudo yum install -y python$version python$version-devel python$version-pip
        PYTHON_CMD="python$version"
        PYTHON_VERSION="$version"
    else
        log_error "不支持的系统类型"
        return 1
    fi
    
    log_success "Python $version 安装完成"
}

# 创建虚拟环境
create_venv() {
    log_info "创建 Python 虚拟环境..."
    
    # 检查虚拟环境是否已存在
    if [[ -d "webssh_venv" ]]; then
        log_warning "虚拟环境已存在"
        read -p "是否删除现有虚拟环境并重新创建? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf webssh_venv
        else
            log_info "使用现有虚拟环境"
            return 0
        fi
    fi
    
    # 创建虚拟环境
    $PYTHON_CMD -m venv webssh_venv
    
    if [[ $? -eq 0 ]]; then
        log_success "虚拟环境创建完成"
    else
        log_error "虚拟环境创建失败"
        return 1
    fi
}

# 激活虚拟环境并安装依赖
install_in_venv() {
    log_info "激活虚拟环境并安装依赖..."
    
    # 激活虚拟环境
    source webssh_venv/bin/activate
    
    # 升级 pip
    pip install --upgrade pip setuptools wheel
    
    # 安装关键依赖
    log_info "安装关键依赖..."
    pip install cffi==1.15.1 pynacl==1.5.0 cryptography==41.0.7
    
    # 安装 webssh
    log_info "安装 WebSSH..."
    cd webssh
    pip install -e .
    
    if [[ $? -eq 0 ]]; then
        log_success "WebSSH 安装完成"
    else
        log_error "WebSSH 安装失败"
        return 1
    fi
    
    cd ..
}

# 创建启动脚本
create_venv_startup_scripts() {
    log_info "创建虚拟环境启动脚本..."
    
    # 前台启动脚本
    cat > start_webssh_venv.sh << EOF
#!/bin/bash

# WebSSH 虚拟环境启动脚本
echo "激活虚拟环境并启动 WebSSH 服务..."

# 激活虚拟环境
source webssh_venv/bin/activate

# 检查端口是否被占用
if command -v lsof &> /dev/null; then
    if lsof -i:8888 &> /dev/null; then
        echo "警告: 端口 8888 已被占用"
        lsof -i:8888
        read -p "是否要终止占用端口的进程? (y/N): " -n 1 -r
        echo
        if [[ \$REPLY =~ ^[Yy]$ ]]; then
            pid=\$(lsof -ti:8888)
            if [[ -n "\$pid" ]]; then
                sudo kill -9 \$pid
                echo "已终止占用端口的进程"
            fi
        fi
    fi
fi

# 启动 WebSSH 服务
echo "启动 WebSSH 服务 (允许 HTTP 访问)..."
wssh --fbidhttp=False
EOF

    # 后台启动脚本
    cat > start_webssh_venv_background.sh << EOF
#!/bin/bash

# WebSSH 虚拟环境后台启动脚本
echo "激活虚拟环境并后台启动 WebSSH 服务..."

# 激活虚拟环境
source webssh_venv/bin/activate

# 检查端口是否被占用
if command -v lsof &> /dev/null; then
    if lsof -i:8888 &> /dev/null; then
        echo "警告: 端口 8888 已被占用"
        lsof -i:8888
        read -p "是否要终止占用端口的进程? (y/N): " -n 1 -r
        echo
        if [[ \$REPLY =~ ^[Yy]$ ]]; then
            pid=\$(lsof -ti:8888)
            if [[ -n "\$pid" ]]; then
                sudo kill -9 \$pid
                echo "已终止占用端口的进程"
            fi
        fi
    fi
fi

# 后台启动 WebSSH 服务
echo "后台启动 WebSSH 服务..."
nohup wssh --fbidhttp=False > webssh.log 2>&1 &

# 获取进程 ID
PID=\$!
echo "WebSSH 服务已启动，进程 ID: \$PID"
echo "日志文件: webssh.log"
echo "访问地址: http://\$(hostname -I | awk '{print \$1}'):8888"
echo "停止服务: kill \$PID"
EOF

    chmod +x start_webssh_venv.sh start_webssh_venv_background.sh
    log_success "虚拟环境启动脚本创建完成"
}

# 显示使用说明
show_usage() {
    log_success "WebSSH Python 版本兼容性修复完成！"
    echo
    echo "使用说明:"
    echo "1. 激活虚拟环境: source webssh_venv/bin/activate"
    echo "2. 前台启动: ./start_webssh_venv.sh"
    echo "3. 后台启动: ./start_webssh_venv_background.sh"
    echo "4. 直接启动: source webssh_venv/bin/activate && wssh --fbidhttp=False"
    echo
    echo "访问地址: http://$(hostname -I | awk '{print $1}'):8888"
    echo
    echo "注意事项:"
    echo "- 使用虚拟环境避免版本冲突"
    echo "- 确保 8888 端口未被占用"
    echo "- 如果遇到 403 错误，使用 --fbidhttp=False 参数"
}

# 主函数
main() {
    echo "=========================================="
    echo "    WebSSH Python 版本兼容性修复"
    echo "=========================================="
    echo
    
    # 检查 Python 版本
    if ! check_python_versions; then
        log_info "尝试安装 Python 3.8..."
        if install_python_version "3.8"; then
            check_python_versions
        else
            log_error "无法安装合适的 Python 版本"
            exit 1
        fi
    fi
    
    log_info "使用 Python 版本: $PYTHON_VERSION"
    
    # 创建虚拟环境
    create_venv
    
    # 在虚拟环境中安装
    install_in_venv
    
    # 创建启动脚本
    create_venv_startup_scripts
    
    # 显示使用说明
    show_usage
}

# 执行主函数
main "$@" 
