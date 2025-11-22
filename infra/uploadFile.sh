#!/bin/bash
sudo apt update -y
sudo snap install aws-cli --classic
sudo apt install -y nginx curl unzip

sudo systemctl enable nginx
sudo systemctl start nginx

sudo rm -rf /var/www/html/*
sudo aws s3 sync s3://web-bucket-sidilian-01 /var/www/html --delete

sudo systemctl restart nginx
