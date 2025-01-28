
### 证书申请细节

1. 如果你全部的域名只托管在一个cloudflare账号中，使用以下命令


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


2. 如果你需要用到两个cloudflare账号的情况下，使用以下命令


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

