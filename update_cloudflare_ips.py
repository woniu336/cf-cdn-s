#!/usr/bin/env python3

import requests
import os
import sys

# 配置文件路径
CF_CONF = "/etc/nginx/conf.d/cloudflare-ips.conf"

def get_cloudflare_ips():
    # 使用主站 URL 作为主要源
    ipv4_urls = [
        "https://www.cloudflare.com/ips-v4",
        "https://www.cloudflare-cn.com/ips-v4/"
    ]
    ipv6_urls = [
        "https://www.cloudflare.com/ips-v6",
        "https://www.cloudflare-cn.com/ips-v6/"
    ]
    
    def try_urls(urls):
        for url in urls:
            try:
                response = requests.get(url, timeout=10)
                response.raise_for_status()
                return response.text.strip().split('\n')
            except requests.RequestException as e:
                print(f"警告：从 {url} 获取数据失败: {e}")
                continue
        return []

    ipv4_list = try_urls(ipv4_urls)
    ipv6_list = try_urls(ipv6_urls)
    
    if not ipv4_list and not ipv6_list:
        raise Exception("无法从任何源获取 Cloudflare IP 列表")
        
    return ipv4_list, ipv6_list

def update_cf_conf(ipv4_list, ipv6_list):
    if not ipv4_list and not ipv6_list:
        print("错误：没有找到 IP 地址。不进行更新。")
        return
    
    # 确保目录存在
    os.makedirs(os.path.dirname(CF_CONF), exist_ok=True)
    
    # 如果文件存在，创建备份
    if os.path.exists(CF_CONF):
        backup_path = CF_CONF + '.bak'
        try:
            os.rename(CF_CONF, backup_path)
            print(f"已备份原始文件到 {backup_path}")
        except OSError as e:
            print(f"警告：创建备份文件失败: {e}")
    
    try:
        with open(CF_CONF, 'w') as f:
            f.write("# Cloudflare IP Ranges Configuration\n")
            f.write("# Auto-generated file - DO NOT EDIT\n\n")
            
            f.write("# IPv4 Ranges\n")
            for ip in ipv4_list:
                f.write(f"set_real_ip_from {ip};\n")
            
            f.write("\n# IPv6 Ranges\n")
            for ip in ipv6_list:
                f.write(f"set_real_ip_from {ip};\n")
            
            f.write("\n# Real IP Header Configuration\n")
            f.write("real_ip_header CF-Connecting-IP;\n")
        
        print(f"Cloudflare IP 地址已更新到 {CF_CONF}")
        
        # 验证文件权限
        os.chmod(CF_CONF, 0o644)
        
    except IOError as e:
        print(f"错误：写入配置文件失败: {e}")
        # 如果写入失败，尝试恢复备份
        if os.path.exists(backup_path):
            try:
                os.rename(backup_path, CF_CONF)
                print("已恢复原始配置文件")
            except OSError:
                print("警告：恢复原始配置文件失败")

def test_nginx_config():
    """测试 Nginx 配置"""
    test_result = os.system('nginx -t')
    if test_result == 0:
        print("Nginx 配置测试通过")
        # 重新加载 Nginx
        reload_result = os.system('nginx -s reload')
        if reload_result == 0:
            print("Nginx 已成功重新加载")
        else:
            print("错误：Nginx 重新加载失败")
    else:
        print("错误：Nginx 配置测试失败")
        # 如果测试失败，尝试恢复备份
        backup_path = CF_CONF + '.bak'
        if os.path.exists(backup_path):
            try:
                os.rename(backup_path, CF_CONF)
                print("已恢复原始配置文件")
            except OSError:
                print("警告：恢复原始配置文件失败")

def main():
    try:
        print("开始更新 Cloudflare IP 列表...")
        ipv4_list, ipv6_list = get_cloudflare_ips()
        update_cf_conf(ipv4_list, ipv6_list)
        
        print(f"\n更新统计:")
        print(f"IPv4 地址数量: {len(ipv4_list)}")
        print(f"IPv6 地址数量: {len(ipv6_list)}")
        
        if os.path.exists(CF_CONF):
            print(f"配置文件总行数: {sum(1 for line in open(CF_CONF))}")
            
            # 测试并重载 Nginx
            test_nginx_config()
        else:
            print("警告：配置文件不存在")
            
    except Exception as e:
        print(f"错误：更新过程中发生异常: {e}")
        print("错误详情:", sys.exc_info())
        sys.exit(1)

if __name__ == "__main__":
    main()