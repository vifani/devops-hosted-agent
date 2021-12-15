$URL = if ($Env:AZP_URL -ne $null) { $Env:AZP_URL } else { $null }
$URL = if ($URL -eq $null) { $Env:APPSETTING_AZP_URL } else { $URL }
$TOKEN_FILE = if ($Env:AZP_TOKEN_FILE -ne $null) { $Env:AZP_TOKEN_FILE } else { $null }
$TOKEN_FILE = if ($TOKEN_FILE -eq $null) { $Env:APPSETTING_AZP_TOKEN_FILE } else { $TOKEN_FILE }
$TOKEN = if ($Env:AZP_TOKEN -ne $null) { $Env:AZP_TOKEN } else { $null }
$TOKEN = if ($TOKEN -eq $null) { $Env:APPSETTING_AZP_TOKEN } else { $TOKEN }
$WORK = if ($Env:AZP_WORK -ne $null) { $Env:AZP_WORK } else { $null }
$WORK = if ($WORK -eq $null) { $Env:APPSETTING_AZP_WORK } else { $WORK }
$POOL = if ($Env:AZP_POOL -ne $null) { $Env:AZP_POOL } else { $null }
$POOL = if ($POOL -eq $null) { $Env:APPSETTING_AZP_POOL } else { $POOL }
$AGENT_NAME = if ($Env:AZP_AGENT_NAME -ne $null) { $Env:AZP_AGENT_NAME } else { $null }
$AGENT_NAME = if ($AGENT_NAME -eq $null) { $Env:APPSETTING_AZP_AGENT_NAME } else { $AGENT_NAME }

if ($URL -eq $null) {
  Write-Error "error: missing AZP_URL environment variable"
  exit 1
}
  
if ($TOKEN_FILE -eq $null) {
  if ($TOKEN -eq $null) {
    Write-Error "error: missing AZP_TOKEN environment variable"
    exit 1
  }
  
  $TOKEN_FILE = "\azp\.token"
  $TOKEN | Out-File -FilePath $TOKEN_FILE
}
  
if (($WORK -ne $null) -and -not (Test-Path $WORK)) {
  New-Item $WORK -ItemType directory | Out-Null
}
  
New-Item "\azp\agent" -ItemType directory | Out-Null
  
# Let the agent ignore the token env variables
$Env:VSO_AGENT_IGNORE = "AZP_TOKEN,AZP_TOKEN_FILE"
  
Set-Location "\azp\agent"
  
Write-Host "1. Determining matching Azure Pipelines agent..." -ForegroundColor Cyan
  
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$(Get-Content ${TOKEN_FILE})"))
$package = Invoke-RestMethod -Headers @{Authorization = ("Basic $base64AuthInfo") } "$(${URL})/_apis/distributedtask/packages/agent?platform=win-x64&`$top=1"
$packageUrl = $package[0].Value.downloadUrl
  
Write-Host $packageUrl
  
Write-Host "2. Downloading and installing Azure Pipelines agent..." -ForegroundColor Cyan
  
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($packageUrl, "$(Get-Location)\agent.zip")
  
Expand-Archive -Path "agent.zip" -DestinationPath "\azp\agent"
  
try {
  Write-Host "3. Configuring Azure Pipelines agent..." -ForegroundColor Cyan
  
  .\config.cmd --unattended `
    --agent "$(if ($AGENT_NAME -ne $null) { ${AGENT_NAME} } else { ${Env:computername} })" `
    --url "$(${URL})" `
    --auth PAT `
    --token "$(Get-Content ${TOKEN_FILE})" `
    --pool "$(if ($POOL -ne $null) { ${POOL} } else { 'Default' })" `
    --work "$(if ($WORK -ne $null) { ${WORK} } else { '_work' })" `
    --replace
  
  Write-Host "4. Running Azure Pipelines agent..." -ForegroundColor Cyan
  
  .\run.cmd
}
finally {
  Write-Host "Cleanup. Removing Azure Pipelines agent..." -ForegroundColor Cyan
  
  .\config.cmd remove --unattended `
    --auth PAT `
    --token "$(Get-Content ${TOKEN_FILE})"
}