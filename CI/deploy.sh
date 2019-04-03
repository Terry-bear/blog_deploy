#!/bin/bash
# deploy
openssl aes-256-cbc -K $encrypted_e206ebe4192c_key -iv $encrypted_e206ebe4192c_iv -in CI/secrets.tar.enc -out ~/.ssh/secrets.tar -d
tar xvf ~/.ssh/secrets.tar -C ~/.ssh
chmod 600 ~/.ssh/server.pub
chmod 600 ~/.ssh/id_rsa
pwd
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa
git config --global user.name "terryzh"
git config --global user.email "496971418@qq.com"
git clone git@github.com:t496971418/my_blog.git
cd my_blog
cp -R ../public/* .
git add .
git commit -m "[Ops]Travis built blog"
git push origin master

# upload master server

cat ~/.ssh/server.pub > ~/.ssh/authorized_keys
cd ..
ls -lrt ~/.ssh
chmod 777 my_blog
sshpass -p $SPW ssh -o StrictHostKeyChecking=no -p root@39.104.123.222
ls -lrt
cd /var/www/html
git pull
exit 0
