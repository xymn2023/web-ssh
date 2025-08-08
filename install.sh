#!/bin/bash

# WebSSH 安装脚本
# 作者: 基于用户需求创建
# 描述: 自动化安装和配置 WebSSH 服务

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
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

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "检测到 root 用户权限，建议使用普通用户运行此脚本"
        read -p "是否继续? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# 检查系统类型
check_system() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/debian_version ]]; then
            SYSTEM_TYPE="debian"
        elif [[ -f /etc/redhat-release ]]; then
            SYSTEM_TYPE="redhat"
        else
            SYSTEM_TYPE="unknown"
        fi
    else
        log_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi
    log_info "检测到系统类型: $SYSTEM_TYPE"
}

# 安装系统依赖
install_system_deps() {
    log_info "安装系统依赖..."
    
    if [[ "$SYSTEM_TYPE" == "debian" ]]; then
        sudo apt-get update
        sudo apt-get install -y build-essential libssl-dev libffi-dev python3-dev python3-pip git curl
    elif [[ "$SYSTEM_TYPE" == "redhat" ]]; then
        sudo yum update -y
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y openssl-devel libffi-devel python3-devel python3-pip git curl
    else
        log_error "不支持的系统类型: $SYSTEM_TYPE"
        exit 1
    fi
    
    log_success "系统依赖安装完成"
    
    # 升级 pip 和 setuptools
    log_info "升级 Python 包管理工具..."
    python3 -m pip install --upgrade pip setuptools wheel
    
    # 预安装关键依赖
    log_info "预安装关键 Python 依赖..."
    python3 -m pip install --upgrade cffi pynacl cryptography
}

# 检查 Python 版本
check_python() {
    log_info "检查 Python 版本..."
    
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
        log_info "检测到 Python 版本: $PYTHON_VERSION"
        
        # 检查版本是否满足要求 (>= 3.7)
        if python3 -c "import sys; exit(0 if sys.version_info >= (3, 7) else 1)"; then
            log_success "Python 版本满足要求"
        else
            log_error "Python 版本过低，需要 Python 3.7 或更高版本"
            exit 1
        fi
    else
        log_error "未找到 Python3，请先安装 Python3"
        exit 1
    fi
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if command -v lsof &> /dev/null; then
        if lsof -i:$port &> /dev/null; then
            log_warning "端口 $port 已被占用"
            lsof -i:$port
            read -p "是否要终止占用端口的进程? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                local pid=$(lsof -ti:$port)
                if [[ -n "$pid" ]]; then
                    sudo kill -9 $pid
                    log_success "已终止占用端口 $port 的进程"
                fi
            else
                log_error "请手动释放端口 $port 后重试"
                exit 1
            fi
        fi
    fi
}

# 下载源码
download_source() {
    log_info "下载 WebSSH 源码..."
    
    # 检查是否已经存在源码目录
    if [[ -d "webssh" ]]; then
        log_warning "检测到已存在的 webssh 目录"
        read -p "是否删除现有目录并重新下载? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf webssh
        else
            log_info "使用现有源码目录"
            return 0
        fi
    fi
    
    # 克隆仓库
    git clone https://github.com/huashengdun/webssh.git
    if [[ $? -eq 0 ]]; then
        log_success "源码下载完成"
    else
        log_error "源码下载失败"
        exit 1
    fi
}

# 进入源码目录并安装
install_webssh() {
    log_info "进入源码目录..."
    cd webssh
    
    log_info "安装 WebSSH Python 包..."
    python3 setup.py install
    
    if [[ $? -eq 0 ]]; then
        log_success "WebSSH 安装完成"
    else
        log_error "WebSSH 安装失败"
        exit 1
    fi
}

# 创建启动脚本
create_startup_script() {
    log_info "创建启动脚本..."
    
    cat > start_webssh.sh << 'EOF'
#!/bin/bash

# WebSSH 启动脚本
echo "启动 WebSSH 服务..."

# 检查端口是否被占用
if command -v lsof &> /dev/null; then
    if lsof -i:8888 &> /dev/null; then
        echo "警告: 端口 8888 已被占用"
        lsof -i:8888
        read -p "是否要终止占用端口的进程? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            pid=$(lsof -ti:8888)
            if [[ -n "$pid" ]]; then
                sudo kill -9 $pid
                echo "已终止占用端口的进程"
            fi
        fi
    fi
fi

# 启动 WebSSH 服务
echo "启动 WebSSH 服务 (允许 HTTP 访问)..."
wssh --fbidhttp=False
EOF

    chmod +x start_webssh.sh
    log_success "启动脚本创建完成: start_webssh.sh"
}

# 创建后台启动脚本
create_background_script() {
    log_info "创建后台启动脚本..."
    
    cat > start_webssh_background.sh << 'EOF'
#!/bin/bash

# WebSSH 后台启动脚本
echo "启动 WebSSH 服务 (后台运行)..."

# 检查端口是否被占用
if command -v lsof &> /dev/null; then
    if lsof -i:8888 &> /dev/null; then
        echo "警告: 端口 8888 已被占用"
        lsof -i:8888
        read -p "是否要终止占用端口的进程? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            pid=$(lsof -ti:8888)
            if [[ -n "$pid" ]]; then
                sudo kill -9 $pid
                echo "已终止占用端口的进程"
            fi
        fi
    fi
fi

# 后台启动 WebSSH 服务
echo "后台启动 WebSSH 服务..."
nohup wssh --fbidhttp=False > webssh.log 2>&1 &

# 获取进程 ID
PID=$!
echo "WebSSH 服务已启动，进程 ID: $PID"
echo "日志文件: webssh.log"
echo "访问地址: http://$(hostname -I | awk '{print $1}'):8888"
echo "停止服务: kill $PID"
EOF

    chmod +x start_webssh_background.sh
    log_success "后台启动脚本创建完成: start_webssh_background.sh"
}

# 显示使用说明
show_usage() {
    log_success "WebSSH 安装完成！"
    echo
    echo "使用说明:"
    echo "1. 前台启动: ./start_webssh.sh"
    echo "2. 后台启动: ./start_webssh_background.sh"
    echo "3. 直接启动: wssh --fbidhttp=False"
    echo "4. 后台启动: nohup wssh --fbidhttp=False &"
    echo
    echo "访问地址: http://$(hostname -I | awk '{print $1}'):8888"
    echo
    echo "注意事项:"
    echo "- 确保 8888 端口未被占用"
    echo "- 如果遇到 403 错误，使用 --fbidhttp=False 参数"
    echo "- 后台运行时，日志保存在 webssh.log 文件中"
}

# 主函数
main() {
    echo "=========================================="
    echo "           WebSSH 安装脚本"
    echo "=========================================="
    echo
    
    check_root
    check_system
    check_python
    install_system_deps
    download_source
    install_webssh
    create_startup_script
    create_background_script
    show_usage
}

# 执行主函数
main "$@" 