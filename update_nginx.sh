#!/bin/bash

# 下载 nginx.conf 文件
echo "正在下载 nginx.conf 文件..."
sudo curl -sS -o /etc/nginx/nginx.conf https://raw.githubusercontent.com/woniu336/cf-cdn-s/main/nginx.conf

if [ $? -ne 0 ]; then
    echo "错误：下载 nginx.conf 文件失败，请检查网络连接或 URL 是否正确。"
    exit 1
fi
echo "nginx.conf 文件下载完成！"

# 移除默认的 set_real_ip_from 1.1.1.1
echo "正在移除默认的 IP 配置..."
sudo sed -i '/set_real_ip_from 1.1.1.1;/d' /etc/nginx/nginx.conf

# 提示用户输入转发 IP 地址
while true; do
    read -p "请输入要添加的转发 IP 地址: " ip_address

    # 验证 IP 地址格式是否合法
    if [[ ! $ip_address =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "错误：IP 地址格式不正确，请重新输入。"
        continue
    fi

    # 在配置文件中查找并添加 set_real_ip_from 行
    # 修改这部分逻辑，确保在最后一个 set_real_ip_from 之后添加新的 IP
    if grep -q "set_real_ip_from $ip_address;" /etc/nginx/nginx.conf; then
        echo "提示：IP 地址 $ip_address 已存在于配置文件中，无需重复添加。"
    else
        # 找到最后一个 set_real_ip_from 行并在其后添加新的 IP
        sudo sed -i "/real_ip_header proxy_protocol;/i \    set_real_ip_from $ip_address;" /etc/nginx/nginx.conf
        if [ $? -ne 0 ]; then
            echo "错误：添加 IP 地址到配置文件失败。"
            exit 1
        fi
        echo "IP 地址 $ip_address 已成功添加到配置文件中。"
    fi

    # 询问用户是否继续添加 IP 地址
    read -p "是否继续添加 IP 地址？(y/n): " continue_add
    if [[ "$continue_add" != "y" ]]; then
        break
    fi
done

# 测试 Nginx 配置
echo "正在测试 Nginx 配置..."
nginx -t

if [ $? -eq 0 ]; then
    echo "Nginx 配置测试成功！"
else
    echo "错误：Nginx 配置测试失败，请检查配置文件。"
    exit 1
fi

# 重启 Nginx
echo "正在重启 Nginx 服务..."
sudo systemctl restart nginx

if [ $? -eq 0 ]; then
    echo "Nginx 服务重启成功！"
else
    echo "错误：Nginx 服务重启失败，请检查日志以获取更多信息。"
    exit 1
fi