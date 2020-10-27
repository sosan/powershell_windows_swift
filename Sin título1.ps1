$salir = "0"
while($salir -eq "0")
{

    $directorio_library = Read-Host "Directorio Library (default (d): c:\Library)?"

    if ($directorio_library -eq "d")
    {
        $directorio_library = "c:\Library"
    }

    Set-Location -Path c:\

    $directorio_valido = Resolve-Path $directorio_library -ErrorAction SilentlyContinue -ErrorVariable _frperror

    if ($directorio_valido)
    {
        Write-Output "directorio existe"

        if(!(Test-Path -Path $directorio_library ))
        {
            New-Item -Path $directorio_library -ItemType Directory
        }

        if(Test-Path -Path $directorio_library )
        {
           $salir = "1"
        }
        else
        {
            Write-Output "directorio no valido"
        }

    }
    else
    {

        if(!(Test-Path -Path $directorio_library ))
        {
            New-Item -Path $directorio_library -ItemType Directory
        }

        if(Test-Path -Path $directorio_library )
        {
           $salir = "1"
        }
        else
        {
            Write-Output "No directorio no valido"
        }


    }


}
