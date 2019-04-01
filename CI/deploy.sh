#!/bin/bash
# deploy
openssl aes-256-cbc -K $encrypted_e206ebe4192c_key -iv $encrypted_e206ebe4192c_iv -in CI/deploy_rsa.enc -out ~/.ssh/deploy_rsa -d
chmod 600 ~/.ssh/deploy_rsa
eval $(ssh-agent)
ssh-add ~/.ssh/deploy_rsa
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
