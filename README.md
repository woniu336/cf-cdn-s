## 一键脚本

在反代服务器上操作

```
curl -sS -O https://raw.githubusercontent.com/woniu336/cf-cdn-s/main/cf-cdn-s.sh && chmod +x cf-cdn-s.sh && ./cf-cdn-s.sh
```




## 证书申请细节

在反代服务器上操作


> 如果你全部的域名只托管在一个cloudflare账号中，使用以下命令


手动创建默认凭证文件

```
mkdir -p /root/.secrets && nano /root/.secrets/cloudflare.ini
```

输入默认的 API Token：

```
dns_cloudflare_api_token = 你的默认cloudflare_api_token
```


设置正确的权限：

```
chmod 600 /root/.secrets/*.ini
```


> 如果你需要用到两个cloudflare账号的情况下，使用以下命令


为特定域名创建配置，以域名为名称，例如 `example.com.ini`

```
mkdir -p /root/.secrets && nano /root/.secrets/example.com.ini
```

输入第二个账号API Token：

```
dns_cloudflare_api_token = cloudflare_api_token
```

设置正确的权限：

```
chmod 600 /root/.secrets/*.ini
```

## haproxy安装


在转发服务器上操作


一键脚本


```
curl -sS -O https://raw.githubusercontent.com/woniu336/cf-cdn-s/main/setup_haproxy.sh && chmod +x setup_haproxy.sh && ./setup_haproxy.sh
```



> 以下是手动配置
> 端口转发，使用haproxy

```
sudo apt update
sudo apt install haproxy -y
```

备份，避免出错

```
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
```


编辑配置文件，修改成自己的ip

```
sudo curl -sS -o /etc/haproxy/haproxy.cfg https://raw.githubusercontent.com/woniu336/cf-cdn-s/main/haproxy.cfg
```

替换1.1.1.1成自己ip

```
sudo sed -i 's/8\.8\.8\.8/1.1.1.1/g' /etc/haproxy/haproxy.cfg
```

检测

```
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

Configuration file is valid 有效


重启 HAProxy 服务以使更改生效

```
sudo systemctl restart haproxy
```


## 获取客户端ip


一键脚本


```
curl -sS -O https://raw.githubusercontent.com/woniu336/cf-cdn-s/main/update_nginx.sh && chmod +x update_nginx.sh && ./update_nginx.sh
```


查看nginx配置

```
cat /etc/nginx/nginx.conf
```

移除转发ip，例如 2.2.2.2

```
sudo sed -i "/set_real_ip_from 2.2.2.2;/d" /etc/nginx/nginx.conf
```

重启

```
sudo nginx -t
sudo systemctl restart nginx
```


> 以下是手动配置


编辑站点配置文件

```
nano /etc/nginx/nginx.conf
```

在末尾添加以下内容：

```
    # proxy_protocol 全局配置
    set_real_ip_from 转发ip;
    #set_real_ip_from 转发ip2;
    real_ip_header proxy_protocol;
    
    # 为所有 HTTPS 端口配置 proxy_protocol
    server {
        listen 443 ssl proxy_protocol;
        return 444;
    }

    include /etc/nginx/conf.d/*.conf;
```

重启nginx

```
nginx -t
systemctl restart nginx
```

