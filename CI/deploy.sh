#!/bin/bash
# deploy
openssl aes-256-cbc -K $encrypted_2da8cfd5de4c_key -iv $encrypted_2da8cfd5de4c_iv -in CI/id_rsa.enc -out ~/.ssh/id_rsa -d
chmod 600 ~/.ssh/id_rsa
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

# ssh -i ~/.ssh/deploy_rsa root@39.104.123.222
# pwd
# ls
