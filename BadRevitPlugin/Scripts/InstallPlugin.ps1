
param(
    # [string]$2021Path = "C:\ProgramData\Autodesk\Revit\Addins\2021"
    [string]$2022Path = "C:\ProgramData\Autodesk\Revit\Addins\2022"
)


$scriptDirectory = $PSScriptRoot

$relativePath = "..\BadRevitPlugin\bin\Debug\net48\"
$buildDir = Join-Path -Path $scriptDirectory -ChildPath $relativePath


$addinFiles = Get-ChildItem -Path $scriptDirectory -Filter *.addin
if ($addinFiles.Count -eq 0) {
    Write-Host "No base addin file found"
    Read-Host -Prompt "Press Enter to exit"
    return
}

$addinFile = $addinFiles[0]

$xml = [xml](get-content $addinFile.FullName -Encoding UTF8);
$assemblyNode = $xml.SelectSingleNode("//RevitAddIns/AddIn/Assembly")


$addinDllName = "BadRevitPlugin.dll"
$fullPath = Join-Path -Path $buildDir -ChildPath $addinDllName


$fullPath = Resolve-Path -Path $fullPath
$fullPathString = $fullPath.Path

$assemblyNode.InnerText = $fullPathString
$saveLocation = Join-Path -Path $2022Path -ChildPath "BadRevitPlugin.addin"
$xml.Save($saveLocation)

Write-Host "Addin Installation in $($saveLocation) is at pointed to $($assemblyNode.InnerText)"


Write-Host "Done"

Read-Host -Prompt "Press Enter to exit"