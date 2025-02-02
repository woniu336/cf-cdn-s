# CF-CDN 部署指南

本指南帮助你设置和配置 Cloudflare CDN 服务。

## 目录
- [CF-CDN 部署指南](#cf-cdn-部署指南)
  - [目录](#目录)
  - [快速部署](#快速部署)
  - [证书配置](#证书配置)
    - [单账号配置](#单账号配置)
    - [多账号配置](#多账号配置)
    - [设置权限](#设置权限)
  - [HAProxy 配置](#haproxy-配置)
    - [快速安装](#快速安装)
    - [手动配置](#手动配置)
  - [Nginx 配置](#nginx-配置)
    - [快速配置](#快速配置)
    - [管理转发 IP](#管理转发-ip)
  - [备份和还原](#备份和还原)
    - [备份](#备份)
    - [还原步骤](#还原步骤)

## 快速部署

在反代服务器上执行：

```bash
curl -sS -O https://raw.githubusercontent.com/woniu336/cf-cdn-s/main/cf-cdn-s.sh && chmod +x cf-cdn-s.sh && ./cf-cdn-s.sh
```

## 证书配置

### 单账号配置
如果所有域名都在同一个 Cloudflare 账号下：

1. 创建凭证文件：
```bash
mkdir -p /root/.secrets && nano /root/.secrets/cloudflare.ini
```

2. 添加 API Token：
```ini
dns_cloudflare_api_token = 你的cloudflare_api_token
```

### 多账号配置
如果使用多个 Cloudflare 账号：

1. 为特定域名创建配置文件：
```bash
mkdir -p /root/.secrets && nano /root/.secrets/example.com.ini
```

2. 添加对应账号的 API Token：
```ini
dns_cloudflare_api_token = cloudflare_api_token
```

### 设置权限
对所有配置文件应用安全权限：
```bash
chmod 600 /root/.secrets/*.ini
```

## 获取真实IP

### 快速配置
在反代服务器上执行：
```bash
curl -sS -O https://raw.githubusercontent.com/woniu336/cf-cdn-s/main/update_nginx.sh && chmod +x update_nginx.sh && ./update_nginx.sh
```

### 管理转发 IP
```bash
# 查看配置
cat /etc/nginx/nginx.conf

# 移除特定转发 IP
sudo sed -i "/set_real_ip_from 具体IP;/d" /etc/nginx/nginx.conf

# 重启 Nginx
sudo nginx -t && sudo systemctl restart nginx
```



## HAProxy 配置

### 快速安装
在转发服务器上执行：
```bash
curl -sS -O https://raw.githubusercontent.com/woniu336/cf-cdn-s/main/setup_haproxy.sh && chmod +x setup_haproxy.sh && ./setup_haproxy.sh
```

### 手动配置
1. 安装 HAProxy：
```bash
sudo apt update && sudo apt install haproxy -y
```

2. 备份原配置：
```bash
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
```

3. 下载并修改配置：
```bash
sudo curl -sS -o /etc/haproxy/haproxy.cfg https://raw.githubusercontent.com/woniu336/cf-cdn-s/main/haproxy.cfg
sudo sed -i 's/8\.8\.8\.8/你的IP/g' /etc/haproxy/haproxy.cfg
```

4. 验证并重启：
```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl restart haproxy
```

## 备份和还原

### 备份
在反代服务器上执行：
```bash
curl -sS -O https://raw.githubusercontent.com/woniu336/cf-cdn-s/main/backup-nginx-ssl.sh && chmod +x backup-nginx-ssl.sh && ./backup-nginx-ssl.sh
```

### 还原步骤
1. 将备份文件复制到目标服务器
2. 解压备份：
```bash
tar -xzf backup文件名.tar.gz -C /tmp/restore/
```

3. 还原文件：
```bash
sudo cp -r /tmp/restore/letsencrypt/* /etc/letsencrypt/
sudo cp -r /tmp/restore/nginx/conf.d/* /etc/nginx/conf.d/
sudo cp -r /tmp/restore/nginx/certs/* /etc/nginx/certs/
sudo cp -r /tmp/restore/nginx/templates/* /etc/nginx/templates/
sudo cp /tmp/restore/nginx/nginx.conf /etc/nginx/
```

4. 设置权限：
```bash
sudo chown -R root:root /etc/letsencrypt
sudo chmod -R 600 /etc/nginx/certs/*
sudo chmod 644 /etc/nginx/nginx.conf
sudo chmod -R 644 /etc/nginx/conf.d/*
```

5. 重启 Nginx：
```bash
sudo systemctl restart nginx
```

> 注意：还原前请确保已安装 Nginx 并备份原有配置。
