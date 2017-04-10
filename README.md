![](http://i.imgur.com/GpOR4F5.png)

Simple CLI to Generate and Run a Rails environment with Docker!   
---
(using Docker, Docker-Compose and Docker-Sync behind the scenes)

### About

Many of us have been struggling to setup a **usable** and **efficient** docker development environment for Rails App

This Gem include a CLI that generate your docker environment then provide a simple command to run it.

Web/Job containers **sync code base from your Rails App in realtime**, letting you code on you Mac and run in the same time everything from the container

Bundler Gems, DB and Redis data are **persisted across restart** and you can use **ByeBug or Pry out of the box** easily.

Currently the CLI offers a Docker environment with the option of:
- PGSQL or MYSQL Database
- Redis Database
- Web and Job (Sidekiq) container

You can expand this scope very easily by modifying the output docker files generated.

### Install

```gem install dockrails```

### Requirements

- [Docker Toolbox](https://www.docker.com/products/docker-toolbox)
- ```brew install unison```

### Commands

Dockerize your app:
- ```dockrails init```

*Answer the different questions to build your docker environment and then you are ready to run it!*

Start the containers:
- ```dockrails start```

Stop/Remove the containers:
- ```dockrails clear```

Run a command inside a container:
- ```dockrails run CONTAINER COMMAND``` (ex: dockrails run web bundle install)

Attach TTY to a container (ex: for debugging with ByeBug or Pry):
- ```dockrails attach CONTAINER```
:warning: DO NOT use ```CTRL+C``` here or it will exit the container but instead use ```CTRL+Q+P```
