Write-Host "Starting shut down procedures..." -ForegroundColor Cyan

Write-Host "Shutting down stack..." -ForegroundColor Cyan
docker exec docker-networking-manager1-1 docker stack rm swarm-test
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Worker1 leaving swarm..." -ForegroundColor Cyan
docker exec docker-networking-worker1-1 docker swarm leave
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Worker2 leaving swarm..." -ForegroundColor Cyan
docker exec docker-networking-worker2-1 docker swarm leave
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Worker3 leaving swarm..." -ForegroundColor Cyan
docker exec docker-networking-worker3-1 docker swarm leave
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Manager leaving swarm (with force)..." -ForegroundColor Cyan
docker exec docker-networking-manager1-1 docker swarm leave --force
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Shutting down DinD containers..." -ForegroundColor Cyan
docker compose down
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Done! Shutdown finished." -ForegroundColor Green