# creacion de un layout
Write-Output "Descargando VsCommunity"
$url = "https://download.visualstudio.microsoft.com/download/pr/e8bc3741-cb70-42aa-9b4e-2bd497de85dd/6b53cd77feaf149d8baca22797482e4af7f68964809e074a772eddf67f618fe5/vs_Community.exe"
$output = "$PSScriptRoot\vs_community.exe"

try  
{  
    Invoke-WebRequest -Uri $url -OutFile $output
}  
catch [System.Net.WebException]  
{
    Write-Error "No se puede descargar desde $url" -ErrorAction Stop

}

.\vs_community.exe --layout .\vslayoutswift "--add", "Component.CPython3.x64", "--add", "Microsoft.VisualStudio.Component.Git", 
            "--add", "Microsoft.VisualStudio.Component.VC.ATL", "--add", "Microsoft.VisualStudio.Component.VC.CMake.Project", 
            "--add", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64", "--add", "Microsoft.VisualStudio.Component.Windows10SDK",
            "--add", "Microsoft.VisualStudio.Component.Windows10SDK.17763" --lang es-ES