#!/bin/bash

# 颜色定义
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
NC="\033[0m"

# 创建临时目录
TEMP_DIR="/tmp/nginx_ssl_backup"
# 获取当前时间戳
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
# 定义备份文件名
BACKUP_FILE="nginx_ssl_backup_${TIMESTAMP}.tar.gz"
# 定义备份存储目录
BACKUP_DIR="/root/backups"

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 清理函数
cleanup() {
    echo -e "${YELLOW}清理临时文件...${NC}"
    rm -rf "$TEMP_DIR"
}

# 错误处理
handle_error() {
    echo -e "${RED}错误: $1${NC}"
    cleanup
    exit 1
}

# 开始备份
echo -e "${YELLOW}开始备份 Nginx 和 SSL 证书配置...${NC}"

# 创建临时目录结构
mkdir -p "$TEMP_DIR"/{letsencrypt,nginx/{conf.d,certs,templates}} || handle_error "创建临时目录失败"

# 复制文件
echo -e "${YELLOW}复制文件中...${NC}"

# 复制 letsencrypt 目录
if [ -d "/etc/letsencrypt" ]; then
    cp -rp /etc/letsencrypt/* "$TEMP_DIR/letsencrypt/" || handle_error "复制 letsencrypt 失败"
fi

# 复制 nginx 配置
if [ -d "/etc/nginx/conf.d" ]; then
    cp -rp /etc/nginx/conf.d/* "$TEMP_DIR/nginx/conf.d/" || handle_error "复制 nginx/conf.d 失败"
fi

if [ -d "/etc/nginx/certs" ]; then
    cp -rp /etc/nginx/certs/* "$TEMP_DIR/nginx/certs/" || handle_error "复制 nginx/certs 失败"
fi

if [ -d "/etc/nginx/templates" ]; then
    cp -rp /etc/nginx/templates/* "$TEMP_DIR/nginx/templates/" || handle_error "复制 nginx/templates 失败"
fi

if [ -f "/etc/nginx/nginx.conf" ]; then
    cp -p /etc/nginx/nginx.conf "$TEMP_DIR/nginx/" || handle_error "复制 nginx.conf 失败"
fi

# 创建压缩包
echo -e "${YELLOW}创建压缩包...${NC}"
cd "$TEMP_DIR" || handle_error "无法进入临时目录"
tar -czf "$BACKUP_DIR/$BACKUP_FILE" * || handle_error "创建压缩包失败"

# 清理临时文件
cleanup

# 显示备份信息
echo -e "${GREEN}备份完成！${NC}"
echo -e "备份文件: ${GREEN}$BACKUP_DIR/$BACKUP_FILE${NC}"
echo -e "文件大小: $(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)"

# 创建还原说明文件
cat > "$BACKUP_DIR/restore_instructions.txt" << EOF
还原说明：

1. 将备份文件复制到目标服务器
2. 解压备份文件：
   tar -xzf $BACKUP_FILE -C /tmp/restore/

3. 还原文件：
   sudo cp -r /tmp/restore/letsencrypt/* /etc/letsencrypt/
   sudo cp -r /tmp/restore/nginx/conf.d/* /etc/nginx/conf.d/
   sudo cp -r /tmp/restore/nginx/certs/* /etc/nginx/certs/
   sudo cp -r /tmp/restore/nginx/templates/* /etc/nginx/templates/
   sudo cp /tmp/restore/nginx/nginx.conf /etc/nginx/

4. 设置适当的权限：
   sudo chown -R root:root /etc/letsencrypt
   sudo chmod -R 600 /etc/nginx/certs/*
   sudo chmod 644 /etc/nginx/nginx.conf
   sudo chmod -R 644 /etc/nginx/conf.d/*

5. 重启 Nginx：
   sudo systemctl restart nginx

注意：还原前请确保已安装 nginx 并备份原有配置。
EOF

echo -e "${YELLOW}已创建还原说明文件: $BACKUP_DIR/restore_instructions.txt${NC}" 