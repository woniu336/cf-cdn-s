## 一键脚本

```
curl -sS -O https://raw.githubusercontent.com/woniu336/cf-cdn-s/main/cf-cdn-s.sh && chmod +x cf-cdn-s.sh && ./cf-cdn-s.sh
```




## 证书申请细节

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

> 端口转发，使用haproxy

```
sudo apt update
sudo apt install haproxy -y
```

编辑配置文件

```
curl -sS -o /etc/haproxy/haproxy.cfg https://raw.githubusercontent.com/woniu336/cf-cdn-s/main/haproxy.cfg
```

粘贴以下内容，修改成自己的ip

```
nano /etc/haproxy/haproxy.cfg
```
