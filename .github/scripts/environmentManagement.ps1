param (
    [String] $repoPath,
    [String] $action,
    [String] $client
)
Install-Module -Name BcContainerHelper -Force -AllowClobber

Import-Module BcContainerHelper


Write-Host "Dentro de la función"
Write-Host "clientID: $env:CLIENTID         length: $($env:CLIENTID.Length)"
Write-Host "clientSecret: $env:CLIENTSECRET length: $($env:CLIENTSECRET.Length)"
Write-Host "tenantID: $env:TENANTID         length: $($env:TENANTID.Length)"

$authContext = New-BcAuthContext -clientID $env:CLIENTID -clientSecret $env:CLIENTSECRET -tenantID $env:TENANTID

Write-Host "AuthContext $authContext"

$app = Get-Content './app.json' -Raw | ConvertFrom-Json
$appName = $app.name


$environmentsBC = Get-BcEnvironments -bcAuthContext $authContext
$environmentsGH = (gh api repos/$env:OWNER/$appName/environments) | ConvertFrom-Json
$environmentsGHNames = $environmentsGH.environments.Name
$environmentsBCNames = @()
$clientes = @()
if ($action -eq 'crear') {
    for ($i = 0; $i -lt $environmentsBC.length; $i++) {
        $environmentsBCNames += $environmentsBC[$i].Name
    }
    foreach ($client in $environmentsBCNames) {
        $appNames = @()
        $clientApps = @()
        Write-Host "Evaluando al cliente $client"
        $clientApps = Get-BcPublishedApps -bcAuthContext $authContext -environment $client
        
        for ($i = 0; $i -lt $clientApps.Length; $i++) {
            $appNames += $clientApps[$i].Name + ""
        }
        if ($appNames.Contains($appName)) {
            $clientes += $client + " "
            if ($environmentsGHNames.Contains($client)) {
                Write-Warning "El entorno $client ya existe por lo que no se creará ningún entorno con ese nombre"
            }
            else {
                gh api --method PUT -H "Accept: application/vnd.github+json" repos/$env:OWNER/$appName/environments/$client
                Write-Host "Entorno $client creado correctamente"
            }
        }
        else {
            Write-Warning "La aplicación $appName no está publicada en el entorno $client, por lo que no se creará ningún entorno con ese nombre"
        }
    }
}
elseif ($action -eq 'actualizarPTE') {
    $settings = Get-Content '.github\AL-Go-Settings.json' -Raw | ConvertFrom-Json
    $PTE = @{
        "scope" = "PTE"
    }

    $settings | Add-Member -NotePropertyName "DeployTo$client" -NotePropertyValue $PTE
    $settings | ConvertTo-Json -Depth 10 | Set-Content '.github\AL-Go-Settings.json'
}