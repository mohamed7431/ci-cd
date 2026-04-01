clear
sudo apt update
sudo apt install docker.io docker-compose -y
sudo systemctl start docker
sudo usermod -aG docker ubuntu
ping google.com
clear
ping google.com
clear
ls
ping google.com
clear
sudo apt update
sudo apt install docker.io docker-compose -y
sudo systemctl start docker
sudo usermod -aG docker ubuntu
clear
sudo reboot
clear
docker --version
clear
docker run -d   --name jenkins   -p 8080:8080   -p 50000:50000   -v jenkins_home:/var/jenkins_home   -v /var/run/docker.sock:/var/run/docker.sock   jenkins/jenkins:lts
clear
http://10.0.2.114:8000
ls
docker ps
clear
docker ps
docker-compose up -d
docker ps
docker run -d -p 8000:80 nginx
clear
curl -I http://10.0.2.114:8080/login
