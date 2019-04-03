#!/bin/bash
# deploy
openssl aes-256-cbc -K $encrypted_e206ebe4192c_key -iv $encrypted_e206ebe4192c_iv -in CI/secrets.tar.enc -out ~/.ssh/secrets.tar -d
tar xvf ~/.ssh/secrets.tar -C ~/.ssh
chmod 600 ~/.ssh/server
chmod 600 ~/.ssh/id_rsa
pwd
cat <<EOF > /home/travis/.ssh/config  
Host github.com
User 496971418@qq.com
PreferredAuthentications publickey
IdentityFile ~/.ssh/id_rsa

Host $IP
User terryzh
PreferredAuthentications publickey
IdentityFile ~/.ssh/server
EOF
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
cat ~/.ssh/config
ssh-add ~/.ssh/server
cd ..
ls -lrt
chmod 777 my_blog
# scp -o StrictHostKeyChecking=no -r my_blog/*  root@$IP:/var/www/html
exit 0
