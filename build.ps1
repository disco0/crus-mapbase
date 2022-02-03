#!pwsh
#Requires -Version 6

function local:rebuild()
{
    $local:ErrorActionPreference = ([System.Management.Automation.ActionPreference]::Stop)

    $moddir = Get-Item "$PSScriptRoot"
    $modName = $moddir.basename
    $modJson = Get-Item $moddir\mod.json
    $tmpZipDirPath = "$ENV:TEMP\${modname}-zip"
    if (Test-Path $tmpZipDirPath) { Remove-Item -Force -Recurse -Verbose $tmpZipDirPath }
    mkdir $tmpZipDirPath
    $tmpZipDir = Get-Item $tmpZipDirPath
    $tmpZipModContentDir = "${tmpZipDir}\MOD_CONTENT\$modname"

    $customModInstallDir = "C:\csquad\user\mods\$modName"
    $modInstallDir =
        if(Test-Path $customModInstallDir -PathType Container)
        {
            $customModInstallDir
        }
        else # Default expected user path for windows
        {
            "$ENV:APPDATA\Godot\app_userdata\Cruelty Squad\mods"
        }

    $copyExcludes = Write-Output .git media mod.zip mod.json $tmpZipDir

    Copy-Item -Recurse -Verbose -Exclude $copyExcludes "$modDir" "$tmpZipModContentDir\"

    $modZipOutPath = "$modInstallDir\mod.zip"
    if (Test-Path $modZipOutPath) { Remove-Item -Verbose $modZipOutPath }

    [System.IO.Compression.ZipFile]::CreateFromDirectory($tmpZipdir, $modZipOutPath)
    Copy-Item -v -Force $modJSON $modInstallDir

    if (Test-Path $modZipOutPath)
    {
        Write-Host -ForegroundColor Green 'Complete.'
        Remove-Item -Recurse -Force -Verbose $tmpZipDir
    }
    else
    {
        Write-Error "Expected mod.zip not found: $($PSStyle.Underline)$modZipOutPath$($PSStyle.UnderlineOff)"
    }
}

rebuild
