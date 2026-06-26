Write-Host "Building images..." -ForegroundColor Cyan
docker build -t dn-node:v1 ./node
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker build -t dn-csv-db:v1 ./csv-db
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker build -t dn-nginx:v1 ./nginx
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker build -t dn-visualizer:v1 ./visualizer
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Saving image tarballs..." -ForegroundColor Cyan
docker save -o dn-node.tar dn-node:v1
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker save -o dn-csv-db.tar dn-csv-db:v1
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker save -o dn-nginx.tar dn-nginx:v1
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }
docker save -o dn-visualizer.tar dn-visualizer:v1
if ($LASTEXITCODE -ne 0) { Write-Host "failed, aborting." -ForegroundColor Red; exit 1 }

Write-Host "Done! Image tars saved." -ForegroundColor Green
