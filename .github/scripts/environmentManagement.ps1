param (
    [String] $repoPath,
    [String] $action,
    [String] $empresa
)
Install-Module -Name BcContainerHelper -Force -AllowClobber

Import-Module BcContainerHelper

$clientID = $env:CLIENTID
$clientSecret = $env:CLIENTSECRET

$tenants = @(
    
)

foreach ($tenant in $tenants) {
    $authContext = New-BcAuthContext -clientID $tenant.clientID -clientSecret $tenant.clientSecret -tenantID $tenant.tenantID

    $app = Get-Content './app.json' -Raw | ConvertFrom-Json
    $appName = $app.name

    $repoName = Split-Path -Path $repoPath -Leaf
    $environmentsBC = Get-BcEnvironments -bcAuthContext $authContext
    $environmentsGH = (gh api repos/$env:OWNER/$repoName/environments) | ConvertFrom-Json
    $environmentsGHNames = $environmentsGH.environments.Name
    $environmentsBCNames = @()
    $empresas = @()
    if ($action -eq 'crear') {
        for ($i = 0; $i -lt $environmentsBC.length; $i++) {
            $environmentsBCNames += $environmentsBC[$i].Name
        }
        foreach ($empresa in $environmentsBCNames) {
            $appNames = @()
            $clientApps = @()
            Write-Host "Evaluando al cliente $empresa"
            $clientApps = Get-BcPublishedApps -bcAuthContext $authContext -environment $empresa

            for ($i = 0; $i -lt $clientApps.Length; $i++) {
                $appNames += $clientApps[$i].Name + ""
            }
            if ($appNames.Contains($appName)) {
                $empresas += $empresa + " "
                if ($environmentsGHNames.Contains($empresa)) {
                    Write-Warning "El entorno $empresa ya existe por lo que no se creará ningún entorno con ese nombre"
                }
                else {
                    gh api --method PUT -H "Accept: application/vnd.github+json" repos/$env:OWNER/$repoName/environments/$empresa
                    Write-Host "Entorno $empresa creado correctamente"
                }
            }
            else {
                Write-Warning "La aplicación $appName no está publicada en el entorno $empresa, por lo que no se creará ningún entorno con ese nombre"
            }
        }
    }
    elseif ($action -eq 'actualizarPTE') {
        $settings = Get-Content '.github\AL-Go-Settings.json' -Raw | ConvertFrom-Json
        $PTE = @{
            "scope" = "PTE"
        }

        $settings | Add-Member -NotePropertyName "DeployTo$empresa" -NotePropertyValue $PTE
        $settings | ConvertTo-Json -Depth 10 | Set-Content '.github\AL-Go-Settings.json'
    }
}