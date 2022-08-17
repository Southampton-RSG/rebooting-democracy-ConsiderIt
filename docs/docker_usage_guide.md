# Docker Usage Guide

## Disclaimer

This is currently a very barebones 'naive' implementation following the process in the 
[developer installation guide](developer_installation_guide.md). 
It is not suitable for 'real' deployment, as the database data is stored in the container,
and so if the code is updated and the image is rebuilt, all the data will be thrown away.

A 'proper' implementation using `docker-compose` would:

* Split the code into 2 containers
  * A vanilla MySQL one run as the server 
  * A dockerfile-based one containing the website, build off an existing Ruby or Rails image
* Add a volume that holds the database, and is mounted as the MySQL data directory in the MySQL container

In addition, the Docker setup isn't currently structured to allow for Google auth - 
presumably I need to map and open ports for SSH.

## Usage

To spin up an instance of the server, make sure you have 
[Docker and Docker Compose installed](https://docs.docker.com/compose/install/).

Then, enter the root directory of this project and run

```shell
docker-compose up
```

You should then be able to access a copy of the server at `localhost:3001`, 
and `docker container ls` should list it running with the name `considerit`. 
Create a user account, then whilst the container is up jump into it using:

```shell
docker run -it considerit /bin/sh
```
and make yourself admin following the developer guide instructions:
```shell
rails C
```
```
u=User.find_by_email('my_test@email.address')
u.super_admin=true
u.save
```
And then exit out of Rails and the shell (or remain in it to bugfix).