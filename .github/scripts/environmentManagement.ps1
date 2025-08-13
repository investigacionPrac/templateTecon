param (
    [String] $repoPath,
    [String] $action,
    [String] $client
)

$data = Get-Content '.\.github\metadata\clientes-de-testing.json' | ConvertFrom-Json

$appRepo = Split-Path $repoPath -Leaf

$environments = (gh api repos/$env:OWNER/$appRepo/environments) | ConvertFrom-Json
$names = $environments.environments.Name
Write-Host "Entornos en el repo: $names"
if ($action -eq 'crear') { 
    foreach ($client in $data.PSObject.Properties.Name) {
        Write-Host "Evaluando al cliente $client"
        if ($data.$client.Contains($appRepo)) {
            $clientes += $client + " "
            if ($names.Contains($client)) {
                Write-Warning "El entorno $client ya existe por lo que no se creará ningún entorno con ese nombre"
            }
            else {
                gh api --method PUT -H "Accept: application/vnd.github+json" repos/$env:OWNER/$appRepo/environments/$client
                Write-Host "Entorno $client creado correctamente"
            }
            
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

Write-Host "Los clientes que tienen la app buscada son: $clientes"
