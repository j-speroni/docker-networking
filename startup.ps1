# startup.ps1
Write-Host "Beginning startup procedures... " -ForegroundColor Cyan

Write-Host "Starting docker compose..." -ForegroundColor Cyan
docker compose up -d
if ($LASTEXITCODE -ne 0) { Write-Host "docker compose failed, aborting." -ForegroundColor Red; exit 1 }


# Manager
Write-Host "Beginning manager node startup..." -ForegroundColor Cyan

Write-Host "Copying image tarballs to manager node for its Daemon..." -ForegroundColor Cyan
docker cp dn-node.tar docker-networking-manager1-1:/dn-node.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker cp dn-csv-db.tar docker-networking-manager1-1:/dn-csv-db.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker cp dn-nginx.tar docker-networking-manager1-1:/dn-nginx.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker cp dn-visualizer.tar docker-networking-manager1-1:/dn-visualizer.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Loading images in manager's Daemon..." -ForegroundColor Cyan
docker exec docker-networking-manager1-1 docker load -i /dn-node.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker exec docker-networking-manager1-1 docker load -i /dn-csv-db.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker exec docker-networking-manager1-1 docker load -i /dn-nginx.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker exec docker-networking-manager1-1 docker load -i /dn-visualizer.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Copying stack.yml to manager node for swarm..." -ForegroundColor Cyan
docker cp stack.yml docker-networking-manager1-1:/stack.yml
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Initializing swarm..." -ForegroundColor Cyan
docker exec docker-networking-manager1-1 docker swarm init
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
$joinToken = docker exec docker-networking-manager1-1 docker swarm join-token worker -q
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }


# Worker 1
Write-Host "Copying image tarballs to worker1 node for its Daemon..." -ForegroundColor Cyan
docker cp dn-node.tar docker-networking-worker1-1:/dn-node.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker cp dn-csv-db.tar docker-networking-worker1-1:/dn-csv-db.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker cp dn-nginx.tar docker-networking-worker1-1:/dn-nginx.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker cp dn-visualizer.tar docker-networking-worker1-1:/dn-visualizer.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Loading images in worker1's Daemon..." -ForegroundColor Cyan
docker exec docker-networking-worker1-1 docker load -i /dn-node.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker exec docker-networking-worker1-1 docker load -i /dn-csv-db.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker exec docker-networking-worker1-1 docker load -i /dn-nginx.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker exec docker-networking-worker1-1 docker load -i /dn-visualizer.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Joining the swarm..."
docker exec docker-networking-worker1-1 docker swarm join --token $joinToken docker-networking-manager1-1:2377
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }


# Worker 2
Write-Host "Copying image tarballs to worker2 node for its Daemon..." -ForegroundColor Cyan
docker cp dn-node.tar docker-networking-worker2-1:/dn-node.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker cp dn-csv-db.tar docker-networking-worker2-1:/dn-csv-db.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker cp dn-nginx.tar docker-networking-worker2-1:/dn-nginx.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker cp dn-visualizer.tar docker-networking-worker2-1:/dn-visualizer.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Loading images in worker2's Daemon..." -ForegroundColor Cyan
docker exec docker-networking-worker2-1 docker load -i /dn-node.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker exec docker-networking-worker2-1 docker load -i /dn-csv-db.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker exec docker-networking-worker2-1 docker load -i /dn-nginx.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker exec docker-networking-worker2-1 docker load -i /dn-visualizer.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Joining the swarm..."
docker exec docker-networking-worker2-1 docker swarm join --token $joinToken docker-networking-manager1-1:2377
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }


# Worker 3
Write-Host "Copying image tarballs to worker3 node for its Daemon..." -ForegroundColor Cyan
docker cp dn-node.tar docker-networking-worker3-1:/dn-node.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker cp dn-csv-db.tar docker-networking-worker3-1:/dn-csv-db.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker cp dn-nginx.tar docker-networking-worker3-1:/dn-nginx.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker cp dn-visualizer.tar docker-networking-worker3-1:/dn-visualizer.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Loading images in worker3's Daemon..." -ForegroundColor Cyan
docker exec docker-networking-worker3-1 docker load -i /dn-node.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker exec docker-networking-worker3-1 docker load -i /dn-csv-db.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker exec docker-networking-worker3-1 docker load -i /dn-nginx.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker exec docker-networking-worker3-1 docker load -i /dn-visualizer.tar
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Joining the swarm..." -ForegroundColor Cyan
docker exec docker-networking-worker3-1 docker swarm join --token $joinToken docker-networking-manager1-1:2377
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }


# Deploying
Write-Host "Deploying the stack..." -ForegroundColor Cyan
docker exec docker-networking-manager1-1 docker stack deploy -c stack.yml swarm-test
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Done! Stack is up." -ForegroundColor Green