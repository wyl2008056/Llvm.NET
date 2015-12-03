﻿[cmdletbinding()]
Param()

$srcDir = $env:BUILD_SOURCESDIRECTORY
if( [String]::IsNullOrWhiteSpace( $srcDir ) )
{
    $srcDir = (Get-Location).Path
}

# try getting private gallery path from environment first
# if it isn't available in current environmnet, check registry
# as it may have been set but not pulled into this active process
$privateNugetGalleryRoot = $env:PRIVATE_NUGET_GALLERY
if( [string]::IsNullOrWhiteSpace($privateNugetGalleryRoot) )
{
    #try per user settings first
    $privateNugetGalleryRoot = (get-item HKCU:Environment).GetValue( "PRIVATE_NUGET_GALLERY" )
    if( [string]::IsNullOrWhiteSpace($privateNugetGalleryRoot) )
    {
        $privateNugetGalleryRoot = ( get-item "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment").GetValue("PRIVATE_NUGET_GALLERY")
    }
}

# no gallery location is an error
if( [string]::IsNullOrWhiteSpace($privateNugetGalleryRoot) )
{
    throw "Private Nuget Galery location is unkown on this machine"
}

"Private Gallery location: $privateNugetGalleryRoot"

# Use relative root to form relative paths from source to create identical folder layout in target
$relatavieRoot = [System.IO.Path]::Combine( $srcDir, "BuildOutput\Nuget")

$pkgs = Get-ChildItem BuildOutput\Nuget\**\*.nupkg | select -ExpandProperty FullName
Foreach( $pkg in $pkgs )
{ 
    $targetFile = $pkg.Replace( $relatavieRoot, $privateNugetGalleryRoot)
    "Package found: $pkg"
    
    $targetFolder = [System.IO.Path]::GetDirectoryName( $pkg )
    if( ![System.IO.Directory]::Exists( $targetFolder ) )
    {
        "Creating TargetFolder: $targetFolder"
        [System.IO.Directory]::CreateDirectory( $targetFolder )
    }

    "copying $pkg -> $targetFile"
    Copy-Item $pkg $targetFile
}