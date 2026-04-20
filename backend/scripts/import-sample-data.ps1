param(
    [string]$Host = "localhost",
    [int]$Port = 5432,
    [string]$Database = "dashboarddb",
    [string]$Username = "postgres",
    [string]$Password = "postgres"
)

$scriptPath = Join-Path $PSScriptRoot "import-sample-data.sql"

if (-not (Test-Path $scriptPath)) {
    Write-Error "SQL file not found: $scriptPath"
    exit 1
}

$psql = Get-Command psql -ErrorAction SilentlyContinue
if (-not $psql) {
    Write-Error "psql command not found. Please install PostgreSQL client tools and ensure psql is in PATH."
    exit 1
}

$env:PGPASSWORD = $Password

Write-Host "Importing sample data to $Database on $Host:$Port as $Username..."
& psql -h $Host -p $Port -U $Username -d $Database -v ON_ERROR_STOP=1 -f $scriptPath
$exitCode = $LASTEXITCODE

Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue

if ($exitCode -ne 0) {
    Write-Error "Import failed with exit code $exitCode"
    exit $exitCode
}

Write-Host "Sample data imported successfully."
