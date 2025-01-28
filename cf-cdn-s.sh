#!/bin/bash

# 颜色变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查是否以 root 权限运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}请使用 root 权限运行此脚本${NC}"
        exit 1
    fi
}

# 安装必要的软件
install_requirements() {
    echo -e "${BLUE}正在安装必要的软件...${NC}"
    apt update
    apt install -y python3-pip certbot curl
}

# 安装 Nginx
install_nginx() {
    echo -e "${BLUE}开始安装 Nginx...${NC}"
    curl -sS -O https://raw.githubusercontent.com/woniu336/cf-cdn/main/install_nginx.sh
    chmod +x install_nginx.sh
    ./install_nginx.sh
}

# 下载基础配置文件
download_config_files() {
    echo -e "${BLUE}下载配置文件模板...${NC}"
    
    # 创建模板目录和配置目录
    mkdir -p /etc/nginx/templates/
    mkdir -p /etc/nginx/conf.d/
    
    # 下载配置文件到模板目录
    curl -sS -o /etc/nginx/templates/111.com.conf https://raw.githubusercontent.com/woniu336/cf-cdn-s/main/111.com.conf
    curl -sS -o /etc/nginx/templates/proxy_common.conf https://raw.githubusercontent.com/woniu336/cf-cdn-s/main/proxy_common.conf
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}配置文件下载成功${NC}"
        # 设置适当的权限
        chmod 644 /etc/nginx/templates/*.conf
    else
        echo -e "${RED}配置文件下载失败${NC}"
        exit 1
    fi
}

# 申请证书
apply_cert() {
    local domain=$1
    
    echo -e "${BLUE}开始申请证书...${NC}"
    curl -sS -O https://raw.githubusercontent.com/woniu336/open_shell/main/certbot-ssl-s.sh
    chmod +x certbot-ssl.sh
    ./certbot-ssl.sh "$domain"
}

# 复制证书
copy_certs() {
    local domain=$1
    
    echo -e "${BLUE}复制证书到 Nginx 目录...${NC}"
    
    # 创建证书目录
    mkdir -p /etc/nginx/certs/
    
    # 复制证书
    cp "/etc/letsencrypt/live/$domain/fullchain.pem" "/etc/nginx/certs/${domain}_cert.pem"
    cp "/etc/letsencrypt/live/$domain/privkey.pem" "/etc/nginx/certs/${domain}_key.pem"
    
    # 设置权限
    chown -R root:root /etc/nginx/certs/
    chmod 600 /etc/nginx/certs/*.pem
    
    echo -e "${GREEN}证书已复制并设置权限${NC}"
}

# 检查 Nginx 配置
check_nginx_config() {
    echo -e "${BLUE}检查 Nginx 配置...${NC}"
    nginx -t
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Nginx 配置检查通过${NC}"
        echo -e "${BLUE}重启 Nginx 服务...${NC}"
        systemctl restart nginx
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Nginx 重启成功${NC}"
            return 0
        else
            echo -e "${RED}Nginx 重启失败${NC}"
            return 1
        fi
    else
        echo -e "${RED}Nginx 配置检查失败${NC}"
        return 1
    fi
}

# 配置新站点
configure_site() {
    local domain=$1
    local backend_domain=$2
    
    echo -e "${BLUE}配置新站点...${NC}"
    
    # 检查必要的模板文件是否存在
    if [ ! -f "/etc/nginx/templates/111.com.conf" ] || [ ! -f "/etc/nginx/templates/proxy_common.conf" ]; then
        echo -e "${RED}错误: 配置模板文件不存在${NC}"
        echo -e "${YELLOW}请先执行选项 3 下载配置文件${NC}"
        return 1
    fi
    
    # 创建站点专用目录
    mkdir -p "/etc/nginx/conf.d/sites/${domain}"
    
    # 创建站点专用的 proxy_common 配置
    cp /etc/nginx/templates/proxy_common.conf "/etc/nginx/conf.d/sites/${domain}/proxy_common.conf"
    
    # 修改站点专用的 proxy_common 配置
    sed -i "s/333.com/$backend_domain/g" "/etc/nginx/conf.d/sites/${domain}/proxy_common.conf"
    
    # 复制并修改主配置文件
    cp /etc/nginx/templates/111.com.conf "/etc/nginx/conf.d/${domain}.conf"
    
    # 替换域名
    sed -i "s/111.com/$domain/g" "/etc/nginx/conf.d/${domain}.conf"
    sed -i "s/333.com/$backend_domain/g" "/etc/nginx/conf.d/${domain}.conf"
    
    # 修改 include 语句，使用站点专用目录下的 proxy_common 配置
    sed -i "s|include /etc/nginx/conf.d/proxy_common.conf|include /etc/nginx/conf.d/sites/${domain}/proxy_common.conf|g" "/etc/nginx/conf.d/${domain}.conf"
    
    # 添加配置检查
    if check_nginx_config; then
        echo -e "${GREEN}站点配置完成${NC}"
        echo -e "${BLUE}已创建以下配置文件：${NC}"
        echo -e "1. /etc/nginx/conf.d/${domain}.conf"
        echo -e "2. /etc/nginx/conf.d/sites/${domain}/proxy_common.conf"
    else
        echo -e "${RED}配置有误，请检查配置文件${NC}"
    fi
}

# 重启 Nginx
restart_nginx() {
    echo -e "${BLUE}清理缓存并重启 Nginx...${NC}"
    rm -rf /usr/local/nginx/cache/proxy/*
    systemctl restart nginx
    nginx -t
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Nginx 重启成功${NC}"
    else
        echo -e "${RED}Nginx 重启失败，请检查配置${NC}"
    fi
}

# 主菜单
show_menu() {
    clear
    echo -e "${YELLOW}=== CF-CDN 配置工具 ===${NC}"
    echo -e "${BLUE}1. 安装 certbot${NC}"
    echo -e "${BLUE}2. 安装 Nginx${NC}"
    echo -e "${BLUE}3. 下载配置文件${NC}"
    echo -e "${BLUE}4. 申请证书${NC}"
    echo -e "${BLUE}5. 配置新站点${NC}"
    echo -e "${BLUE}6. 重启 Nginx${NC}"
    echo -e "${BLUE}0. 退出${NC}"
    echo
    read -p "请选择操作 [0-6]: " choice
    
    case $choice in
        1)
            install_requirements
            ;;
        2)
            install_nginx
            ;;
        3)
            download_config_files
            ;;
        4)
            read -p "请输入域名: " domain
            apply_cert "$domain"
            copy_certs "$domain"
            ;;
        5)
            read -p "请输入域名: " domain
            read -p "请输入后端域名: " backend_domain
            configure_site "$domain" "$backend_domain"
            ;;
        6)
            restart_nginx
            ;;
        0)
            echo -e "${GREEN}感谢使用！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            ;;
    esac
    
    echo
    read -p "按回车键返回主菜单..."
    show_menu
}

# 主程序入口
check_root
show_menu 