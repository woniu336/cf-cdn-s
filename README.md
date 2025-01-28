## 基础配置结构



主域名配置文件： `111.com.conf`

共享配置文件： `proxy_common.conf`

upstream: `111_com_backend` 唯一标识符，不能和其他配置文件同名

主域名： `111.com`  # 用户访问的域名，托管在cf，cname指向线路域名222.com，不要开小云朵

线路域名： `222.com` # 具有分运营商解析功能，托管在DNSPod, 华为云DNS，阿里云DNS等等

后端域名： `333.com`  # 即源站域名，托管在cf, 开启小云朵



## 申请证书

安装certbot

```
apt update
apt install -y python3-pip certbot
```



首先是申请`线路域名`证书，申请通配符是因为在配置多站点时，可以反复利用，不需要重复申请。


```
certbot certonly -d "*.222.com" --manual --preferred-challenges dns-01  --server https://acme-v02.api.letsencrypt.org/directory
```

示例：

![Image](https://img.meituan.net/video/f8860d86b0c9cda77e54917771861d4d38045.png)



cf添加txt解析：`_acme-challenge`

值填入第二个红框内容，先不要急着回车，等个十秒钟，回车即可申请成功。



拷贝证书到`/etc/nginx/certs`目录,例如你要使用 `xx.222.com` 作为线路域名，只需要修改前面的 xx 即可，这就是通配符方便的地方


```
sudo cp /etc/letsencrypt/live/222.com/fullchain.pem /etc/nginx/certs/xx.222.com_cert.pem
sudo cp /etc/letsencrypt/live/222.com/privkey.pem /etc/nginx/certs/xx.222.com_key.pem
```


权限设置

```
sudo chown -R root:root /etc/nginx/certs/
sudo chmod 600 /etc/nginx/certs/*.pem
```

接下来是申请主域名证书，方法同上。



## 安装nginx

为了避免版本不同，配置时出现问题，务必使用以下脚本安装

```
curl -sS -O https://raw.githubusercontent.com/woniu336/cf-cdn/main/install_nginx.sh && chmod +x install_nginx.sh && ./install_nginx.sh
```



## 添加站点

1. 把`111.com.conf`重命名改成其他名称，不能和现有重名，然后修改

- 111.com 改成 主域名

- 222.com 改成 线路域名

- 333.com 改成 源站域名


2. 把`proxy_common.conf` 里面的`333.com`改成源站域名

注意：下次添加新的站点时，记得修改111.com.conf里面的`include /etc/nginx/conf.d/proxy_common.conf;  `名称

然后重启nginx，没有报错则成功启动

```
sudo rm -rf /usr/local/nginx/cache/proxy/*
sudo systemctl restart nginx && nginx -t
```




卸载certbot

```
apt remove -y certbot python3-certbot-apache python3-certbot-nginx
apt autoremove -y
```

