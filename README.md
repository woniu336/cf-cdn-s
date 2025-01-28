1. 手动创建凭证文件

```
mkdir -p /root/.secrets && nano /root/.secrets/cloudflare.ini
```

输入默认的 API Token：

```
dns_cloudflare_api_token = 你的默认cloudflare_api_token
```

为特定域名创建配置（如果是两个以上cloudflare账号）：

```
nano /root/.secrets/example.com.ini
```

输入该域名专用的 API Token：

```
dns_cloudflare_api_token = 该域名的cloudflare_api_token
```

设置正确的权限：

```
chmod 600 /root/.secrets/*.ini
```

