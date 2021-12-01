<!--
 * @Author: zym
 * @Date: 2021-12-01 20:09:27
 * @LastEditors: zym
 * @LastEditTime: 2021-12-01 22:07:39
 * @Description: 
 * @FilePath: \mymtproxy\README.md
-->
# Whitelist MTProxy
可以在openvz vps上工作的白名单MTProxy镜像

# 介绍
该镜像集成了nginx、mtproxy+tls 实现对流量的伪装，并采用白名单模式来应对防火墙的检测。

因为官方的[MTProxy](https://github.com/TelegramMessenger/MTProxy)无法在openvz vps上正常工作。

所以这里借鉴了[ellermister/mtproxy](https://github.com/ellermister/mtproxy)中nginx的白名单工作方式，结合了[TrafeX/docker-php-nginx](https://github.com/TrafeX/docker-php-nginx)的nginx + php镜像实现了nginx白名单功能。

MTProxy则完全使用了[alexbers/mtprotoproxy](https://github.com/alexbers/mtprotoproxy)实现。

# 构建
    git clone https://github.com/PineappleBeer/whitelist-mtproxy 
    cd whitelist-mtproxy
    docker build -t mtproxy:v1 --rm .

# 运行
    docker run -d --name mtproxy -p 80:8080 -p 7443:6443 mtproxy:v1

# 使用
在与运行镜像后通过命令查看MTproxy链接

    docker logs mtproxy

在连接MTProxy前，需要客户端请求80端口的add.php。

例如宿主机ip为`1.1.1.1`，则需要先在浏览器打开`http://1.1.1.1/add.php`以便于将客户端ip地址添加到白名单里。

然后连接MTProxy即可正常使用，否则无法连接，用这种方式来应对防火墙检测。

# 配置
## 更改MTProxy端口
首先在`Dockerfile`文件里将这一句的7443修改为想要的端口

    sed -i 's/443/7443/' config.py && \

然后再去`config/nginx.conf`里修改

    map $ssl_preread_server_name $name {
      default 127.0.0.1:7443;
    }

将这里的7443修改为同样的端口，然后再构建镜像。
在运行时则建议也修改为同样的端口(好处是可以直接复制链接不用修改链接端口避免自己混淆)。

例如上面两处修改为5443：

    docker run -d --name mtproxy -p 80:8080 -p 5443:6443 mtproxy:v1

## 更改MTProxy secret
在`Dockerfile`里修改这一句

    sed -i 's/"tg":\s*".*"/"tg": "si3catbra4ps85p6jpi8nnjg98u6ihr6"/' config.py && \

## 更改MTProxy TLS_DOMAIN
在`Dockerfile`里修改这一句

    sed -i 's/#\s*TLS_DOMAIN\s*=\s*"www\.google\.com"/TLS_DOMAIN = "www.cloudflare.com"/' config.py 

## 更改nginx端口
这里默认nginx端口为8080，因为没有使用root权限启动nginx（nginx监听80和443端口都需要使用root权限）。

如果需要修改端口，则打开`config/nginx.conf`修改两个地方，将这两处8080修改即可。

    server {
        listen [::]:8080 default_server;
        listen 8080 default_server;
        server_name _;

        sendfile off;

以及

    upstream def {
      server "127.0.0.1:8080";
    }
  
然后在构建镜像后，运行时端口映射也要修改，例如改为了3080：

    docker run -d --name mtproxy -p 80:3080 -p 7443:6443 mtproxy:v1

## 更多高级配置
可以参考[alexbers/mtprotoproxy](https://github.com/alexbers/mtprotoproxy)进入容器再慢慢修改:

    docker exec -it mtproxy /bin/bash

mtprotoproxy文件目录在`/usr/local/mtprotoproxy`