param(
    [string]$Host = "localhost",
    [int]$Port = 6341,
    [string]$Database = "dashboarddb",
    [string]$Username = "postgres",
    [string]$Password = "E`$r7kfym"
)

$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
$createTablesScript = Join-Path $scriptDir "create-tables.sql"
$importDataScript = Join-Path $scriptDir "import-sample-data.sql"

# Check if files exist
if (-not (Test-Path $createTablesScript)) {
    Write-Error "Create tables script not found: $createTablesScript"
    exit 1
}

if (-not (Test-Path $importDataScript)) {
    Write-Error "Import data script not found: $importDataScript"
    exit 1
}

# Check if psql is available
$psql = Get-Command psql -ErrorAction SilentlyContinue
if (-not $psql) {
    Write-Error "psql command not found. Please install PostgreSQL client tools and ensure psql is in PATH."
    exit 1
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Dashboard Database Setup" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Host:     $Host" -ForegroundColor White
Write-Host "Port:     $Port" -ForegroundColor White
Write-Host "Database: $Database" -ForegroundColor White
Write-Host "Username: $Username" -ForegroundColor White
Write-Host ""

# Set password environment variable
$env:PGPASSWORD = $Password

try {
    # Step 1: Create tables
    Write-Host "[1/2] Creating database schema..." -ForegroundColor Yellow
    & psql -h $Host -p $Port -U $Username -d $Database -v ON_ERROR_STOP=1 -f $createTablesScript
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create tables"
    }
    Write-Host "✓ Tables created successfully" -ForegroundColor Green
    Write-Host ""

    # Step 2: Import sample data
    Write-Host "[2/2] Importing sample data..." -ForegroundColor Yellow
    & psql -h $Host -p $Port -U $Username -d $Database -v ON_ERROR_STOP=1 -f $importDataScript
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to import sample data"
    }
    Write-Host "✓ Sample data imported successfully" -ForegroundColor Green
    Write-Host ""

    # Success summary
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "✓ Database setup completed successfully!" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Sample dashboards created:" -ForegroundColor White
    Write-Host "  • Sales Analytics Dashboard (9 widgets)" -ForegroundColor Gray
    Write-Host "  • Executive Overview (6 widgets)" -ForegroundColor Gray
    Write-Host "  • Marketing Performance (7 widgets)" -ForegroundColor Gray
    Write-Host "  • Operations Monitor (8 widgets)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Widget types available: 14" -ForegroundColor White
    Write-Host ""
    Write-Host "Start backend with:" -ForegroundColor Yellow
    Write-Host "  cd backend" -ForegroundColor Gray
    Write-Host "  .\mvnw.cmd spring-boot:run `"-Dspring-boot.run.profiles=postgres`"" -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "✗ Setup failed: $_" -ForegroundColor Red
    exit 1
} finally {
    # Clean up password from environment
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}
