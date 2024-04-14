# DockerOpenDevin

OpenDevin the scaly way.

## About this repository

This project's goal is a catch-all solution to running this project along with its dependencies in [docker](https://www.docker.com/products/docker-desktop/).

> This code is highly experimental.  Please use at your own risk.

## Why?

I decided to release it public at this time because the code is being worked on over at the [OpenDevin/OpenDevin](https://github.com/OpenDevin/OpenDevin) repository in [this issue](https://github.com/OpenDevin/OpenDevin/pull/1023)

Some of this command line utility code, including the docker entrypoint script and multistage builder / bash swarm / stack API may be useful to the contributors currently working on the project.

## Getting Started

### 1.  Verify dependencies

#### Docker Engine

You'll need [docker](https://www.docker.com/products/docker-desktop/) on your favorite flavor of Linux.  Please verify your docker installation is completed by running the ``docker ps`` command.

> We advise choosing **NOT** to install docker from your package manager, as this tends to be out of date, and following the [official installation instructions](https://docs.docker.com/engine/install/) from docker's wiki instead, for your distro.

#### GNU Bash

You should have [GNU Bash](https://www.gnu.org/software/bash/) 4.1 or greater installed.

### 2.  Install this tool

1.  You know what to do:

```sh
git clone 'https://github.com/loopyd/DockerOpenDevin' ./ddod
cd ./ddod
```

### 3.  Start the manager stack

Now you can run:

```sh
opendevin manager up
```

To install some useful core services to monitor your installation.  These currently include:

- [Docker Registry](https://hub.docker.com/_/registry) -- for locally managing your own container registry.  This is required by the build process in the next step.
- [Portainer](https://hub.docker.com/r/portainer/portainer) -- for viewing locally running containers, volumes, images, services, and stacks, as well as getting into a shell via a web browser.  This isn't required, but is highly recommended by us as an alternative over installing Docker Desktop, as our tool just uses the raw Docker Engine, where that is unessecary.

### 4.  Build the opendevin runtime

Next, you'll need to build the opendevin runtime.   You can do so with the following command:

```sh
opendevin gen build
```

### 5.  Run the opendevin docker stack

Once your build of the opendevin runtime image is successful, you can do:

```sh
opendevin gen up
```

To deploy the docker stack!

### 6. Explore your OpenDevin installation

Open a web browser, and navigate to one of the following:

- Your frontend (nodejs/python) OpenDevin service is available at [localhost:3001](localhost:3001)
- Your backend (fastapi) OpenDevin service is available at [localhost:3000](localhost:3001)

An overlay network allows the two containers to communicate with each other!  Voila!  You're done.

## Additional help

You can pass the ``-h`` or ``--help`` flag to any command to see additional **usage information**.  This can help you a bit when you get stuck or forget what actions have been made available to you.

You can pass the ``--debug`` flag to enable printing extra output.  This can help you diagnose problems, and you definitely should show ``--debug`` output when [contributing](./CONTRIBUTING.md)

## About the Maintainer

This repository currently has **1** Maintainer

### DeityDragon

Hi, I'm DeityDragon, your friendly full stack developer.  I've been working as a software consultant for the last 10 years.  I started writing software when I was 6.  I have many years of experience working with many different projects.  Thank you so much for visiting my repository.  If you like my work, RAWR!  Give it a star!





