# Docker Networking and Swarm Exercise
This repository contains a small distributed service that transforms a message into "text-speak." The application itself is intentionally simple—the primary goal of the project was to explore Docker networking, service isolation, reverse proxies, and Docker Swarm rather than build a production application.

This service utilizes two pipelines to complete this task.
- Step 1:  Match key words with known shorthands. (i.e. "later" -> "l8tr")
- Step 2: Pipeline diverges into paths "a" and "b"
  - Path a: 
    - Step 2a: Remove all vowels
    - Step 3a: Force all letters to lower case
  - Path b: 
    - Step 2b: Only take first letter of each word (acronym)
    - Step 3b: Force all letters to capital (to fit acronym format)
  - Step 4: Collect both candidate messages and choose the shortest one.

This project is an exercise I built to familiarize myself with the technologies of docker networking and docker swarm. For this reason the service is not intended to be smart or useful, just simply meaningful for visualizing network and node isolation.

## Usage
### Prerequisites
- Windows
- Docker Desktop
- PowerShell 

First, navigate the to home directory `cd /path/to/Docker-Networking`.

The startup script deploys a multi-node Docker-in-Docker swarm. Because each simulated machine requires a local copy of every service image, the images must first be exported as tarballs. If you do not already have these tarballs, run the Powershell script `./save-tars.ps1`. This will take a few seconds (about 30 seconds on my machine).

Now, to run the application, simply invoke the startup Powershell script: `./startup.ps1`. This will take a few minutes (about 3.5 mins on my machine) as it copies and loads all of the images in each of the 4 DinD containers. Once it is done it will output "Done! Stack is up." in green text. You can now navigate to http://localhost and use the service. 

To shut down the program, invoke the shutdown Powershell script: `./shutdown.ps1` from the home directory. This will take a few seconds (about 30 seconds on my machine) as each node leaves the swarm before shutting down the swarm and shutting down the DinD containers. It will output `Done! Shutdown successful.` in green text when it is fully shut down.

## Exercise Structure
### Phase 1: Agentic AI
In phase 1 I utilized Claude Code, an agentic AI coding system, to build thefrontend and backend scaffolding. This was a micro-exercise to expose myselfto agentic ai coding systems as I only had prior experience with AI workflows.

### Phase 2: Docker Images/Containers
In phase 2 I refreshed my prior knowledge with Docker. I built custom images with custom Dockerfiles and created docker containers for each step in the pipelines above including multiple containers of one image.
#### Structure
- **Images**
  - Node: Message transformers
  - Visualizer: Flask Application that prompts for a message, displays the node pipelines, and displays the message passing between nodes.
- **Containers**
  - Node 1: Matches message tokens with shorthands from a csv
  - Node 2a: Removes all vowels
  - Node 2b: Makes acronyms out of the message
  - Node 3a: To lower case
  - Node 3b: To capitals
  - Node 4: Choose best (shortest) message
  - Visualizer: Display web-page

### Phase 3: Docker Networking
In phase 3 I briefly looked into the different network drivers offered by Docker Networking and build a single-bridge-network application. This allowed all containers to freely communicate with each other. Exposed me to Docker Compose and the basics of Docker Networking.
#### Structure
- **Network: Mesh-net**
  - Node 1
  - Node 2a
  - Node 2b
  - Node 3a
  - Node 3b
  - Node 4
  - Visualizer

### Phase 4: Multi-Network Services
In phase 4 I expanded the project to include a csv-database service so I could practice isolation, multi-network services, and multi-homed containers.
#### Structure
- **New Images**
  - csv-db: A flask app that opens a csv and hosts lookups to the csv
- **New Container**
  - csv-db
  - Node 1: Logic file altered to poll the csv-db service
- **Networks**
  - db-net
    - csv-db
    - Node 1
  - worker-net
    - Node 1
    - Node 2a
    - Node 2b
    - Node 3a
    - Node 3b
    - Node 4
    - Visualizer

### Phase 5: Reverse Proxies
In phase 5 I introduced a NGINX container to only expose a reverse proxy port and further isolate the service from the user. Additionally, I tested with the load balancing algorithms. I did this by creating duplicate visualizers.
#### Structure
- **New Image**
  - NGINX
- **New Container**
  - NGINX
- **Networks**
  - worker-net
    - added NGINX

### Phase 6: Docker Swarm Intro
By now I wanted to expand the application so that each node could act as its own compute node in a network of devices. To that end I needed to expose myself to Docker Swarm. In phase 6 I begin to learn this technology by learning the format of and how to build a stack.yml, and how to deploy networks as a stack. I used this technology to replace my manual duplication of the visualizer service with Docker Swarm's replicas of the visualizer service using both stack.yml and `docker service scale`. By doing this I could watch the fault-tolerance of Docker Swarm when I killed one of the visualizer containers.
#### Structure
- **Swarm**
  - Manager: My host machine
- **Services**
  - NGINX
  - csv-db
  - Node 1
  - Node 2a
  - Node 2b
  - Node 3a
  - Node 3b
  - Node 4
  - Visualizer
- **Networks**
  - worker-net and db-net are the same but now use the overlay driver

### Phase 7: Multi-Host Swarm
In phase 7 I wanted to expose myself to how easy/hard it is to deploy a swarm across multiple machines / Docker Daemons. In order to do this, on my limited hardware, I used the docker:dind image. This image spins up a Docker Daemon inside an isolated environment, simulating another machine's Docker Daemon. By creating 4 DinD (Docker in Docker) containers and copying all images to each container, I was able to deploy the previous stack over 4 simulated machines. I also got to watch Docker Swarm's load balancing in action as I scaled and killed containers.

An emergent lesson I learned from this exercise was pinning services in a stack. As I tried to deploy this stack across multiple machines I encountered the issue that each machine cant expose port 80:80 for NGINX. Therefore I had to pin the NGINX service and establish the manager node as the web-server of the program.

## Notes
As a side note for anyone viewing this repository, I left some files in it as artifacts of the earlier phases of my development. These files no longer hold any purpose in the program. Additionally, I, in no way, attempted to optimize or clean up the code.