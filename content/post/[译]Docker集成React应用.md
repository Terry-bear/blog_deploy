---
title: "[译]Docker集成React应用"
date: 2019-06-22T17:27:39+08:00
lastmod: 2019-06-22T17:27:39+08:00
draft: false
keywords: ["javascript", "容器化"]
description: ""
tags: ["javascript", "容器化"]
categories: ["code", "Ops"]
author: "Terryzh"

postMetaInFooter: false

---

<!--more-->
> 本文翻译自 Michael Herman 的 Dockerizing a React App

`Docker`是一种容器化工具，可以帮助开发者加快开发和部署过程。如果你正在使用微服务，`Docker`可以更轻松地将小型独立服务链接在一起。

它还可以消除你在不同环境下遇到的部署问题，你可以直接复制你的当前环境用于生产。

下面将演示如何使用`Create React App`脚手架配合`Dockerize React`。

我们在开发中特别关注的点:

1. 使用代码热重新设置开发环境
2. 使用多级构建配置生产就绪映像

本文使用到的版本

1. Docker v18.09.2
2. Create React App v3.0.1
3. NodeJS v12.2.0

## 如何设置

全局安装Create React App:

```bash
npm install -g create-react-app@3.0.1
```

生成一个新的React项目

```bash
create-react-app sample
cd sample
```

## Docker

将Dockerfile添加到项目根目录:

```docker
# base image
FROM node:12.2.0-alpine

# set working directory
WORKDIR /app

# add `/app/node_modules/.bin` to $PATH
ENV PATH /app/node_modules/.bin:$PATH

# install and cache app dependencies
COPY package.json /app/package.json
RUN npm install --silent
RUN npm install react-scripts@3.0.1 -g --silent

# start app
CMD ["npm", "start"]
```

> 通过 `-silent` 来进行 npm install 可以忽略错误信息,加快安装速度,但同时也无法进行错误的排除。

添加忽略文件 `.dockerignore`:

```bash
node_module
```

这将加速`Docker`构建过程,因为我们的本地依赖项将不会发送到`Docker`守护程序。

构建并标记`Docker`镜像:

```bash
docker build -t sample:dev .
```

>**注意这里dev后面的-->点**

然后,在构建完成后旋转容器:

```bash
docker run -v ${PWD}:/app -v /app/node_modules -p 3001:3000 --rm sample:dev
```

>如果遇到了"ENOENT: no such file or directory, open '/app/package.json"的错误，可能需要添加额外的卷：-v /app/package.json。

我们来看看上述的命令发生了什么:

1. `docker run`命令从我们刚刚创建的image里面创建一个新的容器实例，并运行。
2. -v ${PWD}:/app 将代码安装到“/ app”的容器中。>>>`{PWD}可能无法在Windows上运行。有关详细信息，请参阅此 Stack Overflow问题。`
3. 由于我们要使用`node_modules`文件夹的容器版本，因此我们配置了另一个卷：`-v /app/node_modules`。现在能够删除本地`node_modules`。
4. `-p 3001:3000` 将端口`3000`暴露给同一网络上的其他`Docker`容器（用于容器间通信），将端口`3001`暴露给主机。
5. 最后，在容器退出后 `--rm` 删除容器和卷。

将浏览器打开到`http://localhost:3001/`就可以访问正常的React构建的网页了。尝试`App`在代码编辑器中更改组件。你应该看到应用程序热重载。

>添加后会发生什么`-it`？

```bash
docker run -it -v ${PWD}:/app -v /app/node_modules -p 3001:3000 --rm sample:dev
```

如何使用`Docker Compose`？将`docker-compose.yml`文件添加到项目根目录：

```yml
version: '3.7'

services:

  sample:
    container_name: sample
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - '.:/app'
      - '/app/node_modules'
    ports:
      - '3001:3000'
    environment:
      - NODE_ENV=development
```

注意音量。如果没有**匿名**卷（`'/app/node_modules'`），则`node_modules`目录将在运行时通过挂载主机目录来覆盖。换句话说，这会发生：

* 构建 - node_modules在图像中创建目录。
* 运行 - 将当前目录装入容器，覆盖node_modules构建期间安装的目录。

构建映像并启动容器：

```bash
docker-compose up -d --build
```

确保应用程序在浏览器中运行并再次测试热重新加载。在继续之前放下容器：

```bash
docker-compose stop
```

>`Windows`用户：在使卷正常工作时遇到问题？查看以下资源：
>
>1. `Windows`安装主机目录上的Docker
>2. 为`Windows`共享驱动器配置Docker
>
>您还可能需要添加`COMPOSE_CONVERT_WINDOWS_PATHS=1`到`Docker Compose`文件的环境部分。查看文件指南中的`Declare`默认环境变量以获取更多信息。

## Docker Machine

为了获得热重载与`Docker Machine`和`VirtualBox`的你需要能够通过轮询机制`chokidar`（它包装`fs.watch`，`fs.watchFile`和`fsevents`）。

创建一个新机器：

```bash
docker-machine create -d virtualbox sample
docker-machine env sample
eval $(docker-machine env sample)
```

抓住IP地址：

```bash
docker-machine ip sample
```

然后，构建图像并运行容器：

```bash
docker build -t sample:dev .
docker run -v ${PWD}:/app -v /app/node_modules -p 3001:3000 --rm sample:dev
```

在浏览器中再次测试应用程序：`http://DOCKER_MACHINE_IP:3001/`（确保替换`DOCKER_MACHINE_IP`为`Docker Machine`的实际`IP`地址）。同时，确认热重装是不工作的。您也可以尝试使用Docker Compose，但结果将是相同的。

要使热重载工作，我们需要添加一个环境变量：`CHOKIDAR_USEPOLLING=true`。

```bash
docker run -v ${PWD}:/app -v /app/node_modules -p 3001:3000 -e CHOKIDAR_USEPOLLING=true --rm sample:dev
```

再试一次。确保热重新加载再次起作用。

更新了*docker-compose.yml*文件：

```yml
version: '3.7'

services:

  sample:
    container_name: sample
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - '.:/app'
      - '/app/node_modules'
    ports:
      - '3001:3000'
    environment:
      - NODE_ENV=development
      - CHOKIDAR_USEPOLLING=true
```

## 生产

让我们创建一个单独的`Dockerfile`，用于名为`Dockerfile-prod`的生产：

```docker
# build environment
FROM node:12.2.0-alpine as build
WORKDIR /app
ENV PATH /app/node_modules/.bin:$PATH
COPY package.json /app/package.json
RUN npm install --silent
RUN npm install react-scripts@3.0.1 -g --silent
COPY . /app
RUN npm run build

# production environment
FROM nginx:1.16.0-alpine
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

在这里，我们利用**多阶段构建**模式来创建用于构建工件的临时映像 - 生产就绪的React静态文件 - 然后将其复制到生产映像。临时构建映像与原始文件和与映像关联的文件夹一起被丢弃。这样可以生成精简的生产就绪图像。

>有关多阶段构建的更多信息，请查看`Docker`博客文章中的`Builder`模式与多阶段构建。

使用生产Dockerfile，构建并标记Docker镜像：

```bash
docker build -f Dockerfile-prod -t sample:prod .
```

旋转容器：

```bash
docker run -it -p 80:80 --rm sample:prod
```

假设您仍在使用相同的Docker Machine，请在浏览器中导航到`http://DOCKER_MACHINE_IP`。

使用新的`Docker Compose`文件进行测试，也称为`docker-compose-prod.yml`：

```yml
version: '3.7'

services:

  sample-prod:
    container_name: sample-prod
    build:
      context: .
      dockerfile: Dockerfile-prod
    ports:
      - '80:80'
```

启动容器：

```bash
docker-compose -f docker-compose-prod.yml up -d --build
```

在浏览器中再次测试它。然后，如果你已经完成，继续销毁机器：

```bash
eval $(docker-machine env -u)
docker-machine rm sample
```

## 反应路由器和Nginx

如果您使用的是`React Router`，那么您需要在构建时更改默认的`Nginx`配置：

```docker
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx/nginx.conf /etc/nginx/conf.d
```

将更改添加到*Dockerfile-prod*：

```docker
# build environment
FROM node:12.2.0-alpine as build
WORKDIR /app
ENV PATH /app/node_modules/.bin:$PATH
COPY package.json /app/package.json
RUN npm install --silent
RUN npm install react-scripts@3.0.1 -g --silent
COPY . /app
RUN npm run build

# production environment
FROM nginx:1.16.0-alpine
COPY --from=build /app/build /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx/nginx.conf /etc/nginx/conf.d
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

创建以下文件夹以及`nginx.conf`文件：

```txt
└── nginx
    └── nginx.conf
```

*nginx.conf：*

```conf
server {

  listen 80;

  location / {
    root   /usr/share/nginx/html;
    index  index.html index.htm;
    try_files $uri $uri/ /index.html;
  }

  error_page   500 502 503 504  /50x.html;

  location = /50x.html {
    root   /usr/share/nginx/html;
  }

}
```
