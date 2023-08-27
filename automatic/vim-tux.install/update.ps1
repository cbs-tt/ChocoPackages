﻿. $PSScriptRoot\..\..\scripts\all.ps1

$releases = "https://tuxproject.de/projects/vim/"
$checksumType = 'SHA256'

function global:au_SearchReplace {

    $embeddedFiles = (Get-ChildItem -Path 'tools\*.exe' | ForEach-Object {
        "    - {0}: {1} ({2})" -f $_.Name, (Get-FileHash -Path $_ -Algorithm $checksumType).Hash, $checksumType
    }) -join "`n"

    @{
        "$($Latest.PackageName).nuspec"   = @{
            "(\<releaseNotes\>).*?(\</releaseNotes\>)" = "`${1}$($Latest.ReleaseNotes)`$2"
        }
        ".\tools\chocolateyInstall.ps1" = @{
            '(?i)(^\s*\$versPath\s*=\s*)(''.*'')'     = "`$1'$($Latest.versionPath)'"
            '(?i)(^\s*\$filename32\s*=\s*)(".*")'   = "`$1""`$toolsDir\$($Latest.Url32Filename)"""
            '(?i)(^\s*\$filename64\s*=\s*)(".*")'   = "`$1""`$toolsDir\$($Latest.Url64Filename)"""
    }
        ".\tools\chocolateyUninstall.ps1" = @{
            '(?i)(^\s*\$versPath\s*=\s*)(''.*'')' = "`${1}'$($Latest.versionPath)'"
    }
        ".\tools\VERIFICATION.txt" = @{
            "(?i)(^\s*3.\s*The checksums should match the following\:).*"          = "`${1}`n$embeddedFiles"
        }
    }
}

function global:au_BeforeUpdate() {
    # Remove-Item -Path 'tools\*.exe' -Force -ErrorAction SilentlyContinue
    $Latest.Url32Filename = Split-Path -Path $Latest.Url32 -Leaf
    $Latest.Url64Filename = Split-Path -Path $Latest.Url64 -Leaf

    # Invoke-WebRequest -Uri $Latest.Url32 -OutFile "tools\$($Latest.Url32Filename)"
    # Invoke-WebRequest -Uri $Latest.Url64 -OutFile "tools\$($Latest.Url64Filename)"

    # $Latest.ChecksumType32 = $Latest.ChecksumType64 = 'SHA256'
    # $Latest.Checksum32 = (Get-FileHash -Path "tools\$Url32Filename" -Algorithm $Latest.ChecksumType32).Hash
    # $Latest.Checksum64 = (Get-FileHash -Path "tools\$Url64Filename" -Algorithm $Latest.ChecksumType64).Hash
}

function global:au_AfterUpdate {
    Set-DescriptionFromReadme -SkipFirst 2
}

function global:au_GetLatest {

    $matches = $null
    ((Invoke-WebRequest -Uri $releases -UseBasicParsing).RawContent.Split("`n") | Select-String '<title>') -match "(\d+)\.(\d+)\.\d+"
    $version = $matches[0]
    $versionPath = "vim" + $matches[1] + $matches[2]

    return @{
        Version         = $version
        VersionPath     = $versionPath
        Url32           = 'http://tuxproject.de/projects/vim/complete-x86.exe'
        Url64           = 'http://tuxproject.de/projects/vim/complete-x64.exe'
        ReleaseNotes    = "https://www.vim.org/$versionPath.php"
    }
}

Update-Package -ChecksumFor none