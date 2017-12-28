#!/usr/bin/env powershell
#requires -version 4
[CmdletBinding(PositionalBinding = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$Command,
    [Parameter(Mandatory = $true)]
    [string]$RepoPath,
    [switch]$NoBuild = $false,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'

if (!$NoBuild) {
    & .\build.ps1 /p:SkipTests=$true
}

$toolsSource = "$PSScriptRoot/artifacts/"
$latestFile = Join-Path $toolsSource "korebuild/channels/dev/latest.txt"
$toolsVersion = $null
foreach ($line in Get-Content $latestFile) {
    $toolsVersion = $line.Split(":")[1]
    break
}

mkdir "$PSScriptRoot\obj\testbuild\" -ErrorAction Ignore
$versionPropsPath = "$PSScriptRoot\obj\testbuild\dotnetpackageversion.props"
$sourcePropsPath = "$PSScriptRoot\obj\testbuild\source.props"

$versionPropsValue = "<Project><PropertyGroup><InternalAspNetCoreSdkPackageVersion>$toolsVersion</InternalAspNetCoreSdkPackageVersion></PropertyGroup></Project>"

$packageDir = Join-Path $toolsSource "build\"
$sourcePropsValue = "<Project><PropertyGroup><DotNetRestoreSources>$packageDir</DotNetRestoreSources></PropertyGroup></Project>"

Out-File -FilePath $versionPropsPath -InputObject $versionPropsValue
Out-File -FilePath $sourcePropsPath -InputObject $sourcePropsValue

$Arguments += "/p:DotNetPackageVersionPropsPath=$versionPropsPath"
$Arguments += "/p:DotNetRestoreSourcePropsPath=$sourcePropsPath"

& .\scripts\bootstrapper\run.ps1 -Update -Reinstall -Command $Command -Path $RepoPath -ToolsSource $toolsSource @Arguments
