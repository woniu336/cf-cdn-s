#!/bin/bash

# 颜色定义
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
NC="\033[0m"

# 定义证书存储目录
certs_directory="/etc/letsencrypt/live/"

# 遍历所有证书文件
for cert_dir in $certs_directory*; do
    # 获取域名
    yuming=$(basename "$cert_dir")
    
    # 忽略 README 目录
    if [ "$yuming" = "README" ]; then
        continue
    fi
    
    # 先尝试使用域名特定的凭证文件，如果不存在则使用默认凭证
    cf_credentials="/root/.secrets/${yuming}.ini"
    if [ ! -f "$cf_credentials" ]; then
        cf_credentials="/root/.secrets/cloudflare.ini"
        if [ ! -f "$cf_credentials" ]; then
            echo -e "${RED}错误: 未找到 ${yuming} 的专用凭证文件或默认凭证文件${NC}"
            continue
        fi
        echo -e "${YELLOW}使用默认凭证文件: ${cf_credentials}${NC}"
    else
        echo -e "${YELLOW}使用域名专用凭证文件: ${cf_credentials}${NC}"
    fi

    echo -e "${YELLOW}检查证书过期日期： ${yuming}${NC}"
    echo -e "使用凭证文件: ${cf_credentials}"

    # 获取证书文件路径
    cert_file="${cert_dir}/fullchain.pem"

    # 获取证书过期日期
    expiration_date=$(openssl x509 -enddate -noout -in "${cert_file}" | cut -d "=" -f 2-)
    echo "过期日期： ${expiration_date}"

    # 将日期转换为时间戳
    expiration_timestamp=$(date -d "${expiration_date}" +%s)
    current_timestamp=$(date +%s)

    # 计算距离过期还有几天
    days_before_expiry=10
    days_until_expiry=$(( ($expiration_timestamp - $current_timestamp) / 86400 ))

    # 检查是否需要续签
    if [ $days_until_expiry -le $days_before_expiry ]; then
        echo -e "${YELLOW}证书将在${days_before_expiry}天内过期，正在进行自动续签。${NC}"

        # 获取所有相关域名
        domains=$(openssl x509 -in "$cert_file" -text -noout | grep "DNS:" | sed 's/DNS://g' | tr -d ' ' | tr ',' ' ')
        
        # 构建域名参数
        domains_param=""
        for domain in $domains; do
            domains_param+=" -d $domain"
        done

        # 使用对应域名的凭证文件续签证书
        certbot certonly \
            --dns-cloudflare \
            --dns-cloudflare-credentials "$cf_credentials" \
            $domains_param \
            --preferred-challenges dns-01 \
            --agree-tos \
            --email "1@123.com" \
            --non-interactive \
            --key-type ecdsa \
            --force-renewal \
            --dns-cloudflare-propagation-seconds 60

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}证书续签成功${NC}"
            
            # 复制证书到 Nginx 目录
            mkdir -p /etc/nginx/certs
            cp "${cert_dir}/fullchain.pem" "/etc/nginx/certs/${yuming}_cert.pem"
            cp "${cert_dir}/privkey.pem" "/etc/nginx/certs/${yuming}_key.pem"
            chmod 644 "/etc/nginx/certs/${yuming}_cert.pem"
            chmod 600 "/etc/nginx/certs/${yuming}_key.pem"

            # 更新会话票据密钥
            openssl rand -out /etc/nginx/certs/ticket12.key 48
            openssl rand -out /etc/nginx/certs/ticket13.key 80

            # 重启 Nginx
            systemctl restart nginx
            
            echo -e "${GREEN}证书和配置文件已更新${NC}"
        else
            echo -e "${RED}证书续签失败${NC}"
        fi
    else
        echo -e "${GREEN}证书仍然有效，距离过期还有 ${days_until_expiry} 天。${NC}"
    fi

    echo "--------------------------"
done 