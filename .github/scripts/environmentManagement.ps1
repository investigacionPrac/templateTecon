param (
    [String] $repoPath,
    [String] $action,
    [String] $envBC
)
Install-Module -Name BcContainerHelper -Force -AllowClobber

Import-Module BcContainerHelper

$clientID = $env:CLIENTID
$clientSecret = $env:CLIENTSECRET

$tenants = @(
    
)
if ($action -eq 'crear') {
    foreach ($tenant in $tenants) {
        Write-Host "Evaluando a la empresa/cliente $($tenant.name)"
        $authContext = New-BcAuthContext -clientID $tenant.clientID -clientSecret $tenant.clientSecret -tenantID $tenant.tenantID

        $app = Get-Content './app.json' -Raw | ConvertFrom-Json
        $appName = $app.name

        $repoName = Split-Path -Path $repoPath -Leaf
        $environmentsBC = Get-BcEnvironments -bcAuthContext $authContext
        $environmentsBCNames = @()

        $environmentsGH = (gh api repos/$env:OWNER/$repoName/environments) | ConvertFrom-Json
        $environmentsGHNames = $environmentsGH.environments.Name

        for ($i = 0; $i -lt $environmentsBC.length; $i++) {
            $environmentsBCNames += $environmentsBC[$i].Name
        }
        foreach ($envBC in $environmentsBCNames) {
            $appNames = @()
            $envApps = @()
            Write-Host "Evaluando al entorno $envBC"
            $envApps = Get-BcPublishedApps -bcAuthContext $authContext -environment $envBC

            for ($i = 0; $i -lt $envApps.Length; $i++) {
                $appNames += $envApps[$i].Name + ""
            }
            if ($appNames.Contains($appName)) {
                if ($environmentsGHNames.Contains($envBC)) {
                    Write-Warning "El entorno $envBC ya existe en GitHub por lo que no se creará ningún entorno con ese nombre"
                }
                else {
                    gh api --method PUT -H "Accept: application/vnd.github+json" repos/$env:OWNER/$repoName/environments/$envBC
                    Write-Host "Entorno $envBC creado correctamente"
                }
            }
            else {
                Write-Warning "La aplicación $appName no está publicada en el entorno $envBC, por lo que no se creará ningún entorno con ese nombre"
            }
        }
    }
}
elseif ($action -eq 'actualizarPTE') {
    $settings = Get-Content '.github\AL-Go-Settings.json' -Raw | ConvertFrom-Json
    $PTE = @{
        "scope" = "PTE"
    }

    $settings | Add-Member -NotePropertyName "DeployTo$envBC" -NotePropertyValue $PTE
    $settings | ConvertTo-Json -Depth 10 | Set-Content '.github\AL-Go-Settings.json'
}