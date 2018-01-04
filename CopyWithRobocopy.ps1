<#
.Synopsis
   Copy Files from a source Folder to a Destination recursively using powershell
.DESCRIPTION
   Only copy the new or modified files 
.EXAMPLE
   

.INPUTS
    Mandatory
    Source: Source Folder Path
    Target: Target Folder path

.OUTPUTS
   The output

#>

param(
 [Parameter(Mandatory=$true)][string]$Source,
 [Parameter(Mandatory=$true)][string]$Destination,
 [Parameter(Mandatory=$false)][string]$Option
)

Write-Host "Source is $Source"
Write-Host "Destination is $Destination"

robocopy $Source $Destination /MIR $Option

