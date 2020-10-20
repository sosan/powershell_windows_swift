# ejecutar en modo administrador
# powershell -ExecutionPolicy Unrestricted -NoProfile .\init.ps1

# actualizar el powershell
powershell.exe -NoLogo -NoProfile -Command 'Install-Module -Name PackageManagement -Force -MinimumVersion 1.4.6 -Scope CurrentUser -AllowClobber'

# https://github.com/compnerd/swift-build/releases/latest
$download = Read-Host "Quieres bajarte Componentes de Swift (s/y (ya los tengo)?"
if ($download -eq "s")
{

    Write-Output "Descargando Componenetes de Swift"
    
    Write-Output "Descargando Icu.msi"
    $url = "https://github.com/compnerd/swift-build/releases/download/v5.3/icu.msi"
    $output = "$PSScriptRoot\icu.msi"
    $start_time = Get-Date
    Invoke-WebRequest -Uri $url -OutFile $output
    Write-Output "Descarga tardado: $((Get-Date).Subtract($start_time).Seconds) segundos"

    $url = "https://github.com/compnerd/swift-build/releases/download/v5.3/installer.exe"
    $output = "$PSScriptRoot\installer.exe"
    $start_time = Get-Date
    Invoke-WebRequest -Uri $url -OutFile $output
    Write-Output "Descarga tardado: $((Get-Date).Subtract($start_time).Seconds) segundos"

    $url = "https://github.com/compnerd/swift-build/releases/download/v5.3/sdk.msi"
    $output = "$PSScriptRoot\sdk.msi"
    $start_time = Get-Date
    Invoke-WebRequest -Uri $url -OutFile $output
    Write-Output "Descarga tardado: $((Get-Date).Subtract($start_time).Seconds) segundos"

    $url = "https://github.com/compnerd/swift-build/releases/download/v5.3/toolchain.msi"
    $output = "$PSScriptRoot\toolchain.msi"
    $start_time = Get-Date
    Invoke-WebRequest -Uri $url -OutFile $output
    Write-Output "Descarga tardado: $((Get-Date).Subtract($start_time).Seconds) segundos"

}


$instalar = Read-Host "Quieres instalar Componentes de Swift (s/n)?"
if ($instalar -eq "n")
{
	Write-Error "FIN" -ErrorAction Stop
}

if ($instalar -eq "s")
{

	if (-not(Test-Path -Path $PSScriptRoot\icu.msi) -or -not(Test-Path -Path $PSScriptRoot\installer.exe) -or 
        -not(Test-Path -Path $PSScriptRoot\sdk.msi) -or -not(Test-Path -Path $PSScriptRoot\toolchain.msi)
 )  
	{
        Write-Error "No encontramos el instalador" -ErrorAction Stop
    }
		
	# esperar a que termine
    Start-Process -FilePath $PSScriptRoot\installer.exe -Wait
}


# preguntar si queremos instalar actualizar visual studio
$instalar = Read-Host "Quieres instalar Visual Studio (s/n)?"
if ($instalar -eq "s")
{
    # esperar que acabe de actualizar
    Write-Output "Descargando VsCommunity"
    $url = "https://download.visualstudio.microsoft.com/download/pr/e8bc3741-cb70-42aa-9b4e-2bd497de85dd/6b53cd77feaf149d8baca22797482e4af7f68964809e074a772eddf67f618fe5/vs_Community.exe"
    $output = "$PSScriptRoot\vs_community.exe"
    $start_time = Get-Date

    try  
    {  

        Import-Module BitsTransfer
        $downloading = Start-BitsTransfer -Source $url -Destination $output -Asynchronous

        while (($downloading.JobState -eq "Transferring") -or ($downloading.JobState -eq "Connecting"))
        {
            sleep 5;
        } 

        Switch($downloading.JobState)
        {
            "Transferred" { Complete-BitsTransfer -BitsJob $downloading }
            "Error" { $downloading | Format-List }
            default {
                Write-Error "No se puede descargar desde $url" -ErrorAction Stop
            }
        }

        Write-Output "Descarga tardado: $((Get-Date).Subtract($start_time).Seconds) segundos"

    }  
    catch [System.Net.WebException]  
    {
        Write-Error "No se puede descargar desde $url" -ErrorAction Stop
    
    }


}



# comprobar si ya esta instalado
$regKey = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\devenv.exe"
$visualStudioDir = ""

if ($regKey -eq "")
{
    # no esta instalado
    $regKey="C:\Program Files (x86)\"
    $visualStudioDir = "C:\Program Files (x86)\"
}
else
{
    # ya esta instalado
    Write-Output "Ya esta instalado"
    $visualStudioDir = Get-ItemPropertyValue -Path $regKey -Name "(Default)"
    
    if ($visualStudioDir.Split("\").Length -le 5)
    {
        $a = $visualStudioDir.Split("\")[0]
        $b = $visualStudioDir.Split("\")[1] + "\"
        $visualStudioDir = $a + $b
    }
    else
    {
    
        $a = $visualStudioDir.Split("\")[-1]
        $b = $visualStudioDir.Split("\")[-2] + "\"
        $c = $visualStudioDir.Split("\")[-3] + "\"
        $d = $visualStudioDir.Split("\")[-4] + "\"
        $e = $visualStudioDir.Split("\")[-5] + "\"
        $f = $visualStudioDir.Split("\")[-6] + "\"
        
        $visualStudioDir = ($visualStudioDir.Replace($a,"")).replace($b,"").replace($c,"").Replace($d,"").Replace($e,"").Replace($f,"").Replace("devenv.exe","").replace("`"","")
    }

    Write-Output "Direccion Instalacion Visual Studio: $visualStudioDir"

    if ($instalar -eq "s")
    {
        Write-Output "Instalacion de visual studio 2019"
        try
        {
            $process = Start-Process -FilePath $PSScriptRoot\vs_community.exe -ArgumentList "--installPath", "$visualStudioDir",
            "--add", "Component.CPython3.x64", "--add", "Microsoft.VisualStudio.Component.Git", 
            "--add", "Microsoft.VisualStudio.Component.VC.ATL", "--add", "Microsoft.VisualStudio.Component.VC.CMake.Project", 
            "--add", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64", "--add", "Microsoft.VisualStudio.Component.Windows10SDK",
            "--add", "Microsoft.VisualStudio.Component.Windows10SDK.17763",
            "--passive", "--wait" -Wait -PassThru
            Write-Output "Terminado Instalacion:" $process.ExitCode

        }
        catch [System.InvalidOperationException]
        {
            Write-Error "No se puede ejecutar" -ErrorAction Stop
        }
    }


}

try
{
    # Activamos el developer mode
    Write-Output "Activamos el developer mode"
    $registroKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    if (-not(Test-Path -Path $registroKeyPath)) {
        New-Item -Path $registroKeyPath -ItemType Directory -Force
    }

    New-ItemProperty -Path $registroKeyPath -Name AllowDevelopmentWithoutDevLicense -PropertyType DWORD -Value 1 -Force

}
catch [System.Security.SecurityException]
{
    Write-Error "Ejecutar en modo administrador" -ErrorAction Stop
}



$directorio_library = Read-Host "Directorio Library (default (d): c:\Library)?"

if ($directorio_library -eq "d")
{
    $directorio_library = "c:\Library"
}

Set-Location -Path c:\

if(!(Test-Path -Path $directorio_library )){
    New-Item -Path $directorio_library -ItemType Directory
}
Set-Location -Path $directorio_library

subst S: $directorio_library

Set-Location -Path s:\

$download_librery = Read-Host "Deseas bajarte las librerias de github? (s/n)?"

if ($download_librery -eq "s")
{
    Write-Output "Bajandose LIBRERIAS"

    start-process -FilePath "git" -ArgumentList ("clone", "https://github.com/apple/llvm-project", "--branch", "swift/main llvm-project") -Wait
    start-process -FilePath "git" -ArgumentList ("clone", "-c", "core.autocrlf=input", "-c", "core.symlinks=true", "https://github.com/apple/swift", "swift") -Wait
    start-process -FilePath "git" -ArgumentList ("clone", "https://github.com/apple/swift-cmark", "cmark") -Wait
    start-process -FilePath "git" -ArgumentList ("clone", "https://github.com/apple/swift-corelibs-libdispatch", "swift-corelibs-libdispatch") -Wait
    start-process -FilePath "git" -ArgumentList ("clone", "https://github.com/apple/swift-corelibs-foundation", "swift-corelibs-foundation") -Wait
    start-process -FilePath "git" -ArgumentList ("clone", "https://github.com/apple/swift-corelibs-xctest", "swift-tools-support-core") -Wait
    start-process -FilePath "git" -ArgumentList ("-c", "core.symlinks=true", "clone", "https://github.com/apple/swift-llbuild", "swift-llbuild") -Wait
    start-process -FilePath "git" -ArgumentList ("clone", "https://github.com/JPSim/Yams", "Yams") -Wait
    start-process -FilePath "git" -ArgumentList ("clone", "https://github.com/apple/swift-driver", "swift-driver") -Wait
    start-process -FilePath "git" -ArgumentList ("clone", "https://github.com/apple/swift-argument-parser", "swift-argument-parser") -Wait
    start-process -FilePath "git" -ArgumentList ("clone", "-c", "core.autocrlf=input", "https://github.com/apple/swift-package-manager", "swift-package-manager") -Wait
    start-process -FilePath "git" -ArgumentList ("clone", "https://github.com/apple/indexstore-db", "indexstore-db") -Wait



}

Write-Output "Creando links"

$key = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Kits\Installed Roots"
$universalcrtpath = Get-ItemPropertyValue -Path $key -Name "KitsRoot10"
Write-Output "Direccion UniversalCRTSDK=" $universalcrtpath


if(!(Test-Path -Path $universalcrtpath ))
{
    Write-Error "No se ha podido encontrar el path" -ErrorAction Stop
}

$ucrtversion = Get-ChildItem -Path ($universalcrtpath + "include\") | Select-Object -Last 1 -ExpandProperty name

Write-Output "ucrtversion=$ucrtversion"

$regKey = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\devenv.exe"
$vctoolsinstalldir = ""

if ($regKey -eq "")
{
    # no esta instalado
    $regKey="C:\Program Files (x86)\"
    $vctoolsinstalldir = "C:\Program Files (x86)\"
}
else
{
    # ya esta instalado
    $vctoolsinstalldir = Get-ItemPropertyValue -Path $regKey -Name "(Default)"
    if ($vctoolsinstalldir.Split("\").Length -le 5)
    {

    }
    else
    {

        $a = $vctoolsinstalldir.Split("\")[-1]
        $b = $vctoolsinstalldir.Split("\")[-2] + "\"
        $c = $vctoolsinstalldir.Split("\")[-3] + "\"
        
        $vctoolsinstalldir = ($vctoolsinstalldir.Replace($c,"")).replace($b,"").replace($a,"").replace("`"","")
        $versionfile = $vctoolsinstalldir + "VC\Auxiliary\Build\Microsoft.VCToolsVersion.default.txt"

        if(!(Test-Path -Path $versionfile ))
        { 
            Write-Error "No se ha podido encontrar el path $versionfile" -ErrorAction Stop
        }

        $version = Get-Content $versionfile

        $vctoolsinstalldir = $vctoolsinstalldir + "VC\Tools\MSVC\" + $version

        if(!(Test-Path -Path $vctoolsinstalldir ))
        { 
            Write-Error "No se ha podido encontrar el path $vctoolsinstalldir" -ErrorAction Stop
        }

        Write-Output "Direccion VCToolsInstallDir=" $vctoolsinstalldir

        

    }


}

Set-Variable -Name "SDKROOT" -Value "$directorio_library\Developer\Platforms\Windows.platform\Developer\SDKs\Windows.sdk"
Get-Variable "SDKROOT"
Set-Variable -Name "SWIFTFLAGS" -Value "-sdk $env:SDKROOT -I $env:SDKROOT\usr\lib\swift -L $env:SDKROOT\usr\lib\swift\windows"

Set-Location -Path s:\

$url_urct_modulemap = $universalcrtpath + "Include\" + $ucrtversion + "\ucrt\module.modulemap"
$url_um_modulemap = $universalcrtpath + "Include\" + $ucrtversion + "\um\module.modulemap"
$url_modulemap = $vctoolsinstalldir + "\include\module.modulemap"
$url_api_notes = $vctoolsinstalldir + "\include\visualc.apinotes"

Copy-Item "$env:SDKROOT\usr\share\ucrt.modulemap" -Destination "$url_urct_modulemap"
Copy-Item "$env:SDKROOT\usr\share\winsdk.modulemap" -Destination "$url_um_modulemap"
Copy-Item "$env:SDKROOT\usr\share\visualc.modulemap"-Destination "$url_modulemap"
Copy-Item "$env:SDKROOT\usr\share\visualc.apinotes" -Destination "$url_api_notes"

write-output "Ahora toca instalar la ultima version del toolchain desde https://swift.org/download/#snapshots"
