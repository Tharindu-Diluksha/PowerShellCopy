param(
 [Parameter(Mandatory=$true)][string]$Source,
 [Parameter(Mandatory=$true)][string]$Destination
)

Write-Host "Source is $Source"
Write-Host "Destination is $Destination"

Try{
	Copy-Item $Source\* $Destination -recurse -ErrorAction Stop
	Write-Host "Coping files from $Source to $Destination"
	Write-Host "Successfully Copied"
}
Catch{
	$ErrorMessage = $_.Exception.Message
	Write-Host "Error: $ErrorMessage"
	Break
}


#foreach($file in [System.IO.Directory]::GetFiles($Source) ){