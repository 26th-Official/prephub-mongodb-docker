## Removal instruction for old docker data

`docker-compose stop`

`docker-compose rm -v`

--- 

## Get the docker-compose file to local pc

`pwd` - to check current path

exit the ssh

`scp root@123.45.67.89:/root/prephub-mongodb-docker/docker-compose.yml ~/Desktop/old-docker.yml`

---

## Delte the old github folder

`rm -r prephub-mongodb-docker`

---

## Git clone the repo

`https://github.com/26th-Official/prephub-mongodb-docker.git`

`cd prephub-mongodb-docker`

exit the ssh

`scp root@123.45.67.89:/root/prephub-mongodb-docker/docker-compose.yml ~/Desktop/`

edit the new docker-compose with the credentials from the `old-docker.yml` to `docker-compose.yml`

`scp ~/Desktop/docker-compose.yml root@123.45.67.89:/root/prephub-mongodb-docker/`

``

---

## 

## New docker setup

`docker-compose up -d --build`

---

## Check the backup system

`docker-compose exec mongo-backup bash -c "source /backup/cron_env.sh && /usr/local/bin/backup.sh"`

---
