param(
 [Parameter(Mandatory=$true)][string]$Source,
 [Parameter(Mandatory=$true)][string]$Destination
)
Write-Host "Source is $Source"
Write-Host "Destination is $Destination"

#GLOBALs 
$global:ScriptLocation = $(get-location).Path
#$global:DefaultLog = "$global:ScriptLocation\copy.log"
[int]$GLOBAL:Opcount=0 #variable to count operations with files

[int]$GLOBAL:FilesCopied=0 #variable to determine the files that have been copied
[int]$GLOBAL:FilesExisting=0   #variable to determine the existing files
[int]$GLOBAL:TotalDirectories=0  #variable to determine the number of directories created

function Copy-Recursive{
    [CmdletBinding()]
    param(
        [Parameter(Position=0,mandatory=$true)] [string]$sourceDir,
        [Parameter(Position=1,mandatory=$true)] [string]$targetDir,
        [Parameter(Position=2,mandatory=$false)] [switch]$NTFS=$false
    )
    BEGIN{
        [int]$counter=0;
        [int]$LogCounter=0;
        [bool]$IsMultipleOfNFiles=$false

        if(! [System.IO.Directory]::Exists($targetDir) ){
           [System.IO.Directory]::CreateDirectory($targetDir) | Out-Null
            Set-DateAttributes -OriginalFilePath $sourceDir -TargetFilePath $targetDir -folder
            #add 1 directory to the total
            $GLOBAL:TotalDirectories++
            Write-Log -Level Load -Message "Folder ""$targetDir"" created..."
        }
    }
    PROCESS{
        foreach($file in [System.IO.Directory]::GetFiles($sourceDir) ){
            #generalcounter
            $GLOBAL:Opcount=$GLOBAL:FilesCopied+ $GLOBAL:FilesExisting + 1;
            $FilePath=[System.IO.Path]::Combine($targetDir, [System.IO.Path]::GetFileName($file))
            $FileInfoNew = new-object System.IO.FileInfo($file)

            if( ($GLOBAL:Opcount)%$Nfiles -eq 0  ){
                $IsMultipleOfNFiles = $true
            }
            else{
                $IsMultipleOfNFiles = $false
            }

            if(![System.IO.File]::Exists($FilePath) ){ #IF doesn't exists, add to the copiedfiles copy the file and set attributes
                [System.IO.File]::Copy($file, $FilePath)
				Write-Host "Coping files from $Source to $Destination"
                Set-DateAttributes -OriginalFilePath $file -TargetFilePath $FilePath
                $GLOBAL:FilesCopied++
            }
            else{
			    $FileInfoExisting = new-object System.IO.FileInfo($FilePath)
			    $FileInfoNew      = new-object System.IO.FileInfo($file)
                $GLOBAL:FilesExisting++
                #setattributes
                Set-DateAttributes -OriginalFilePath $file -TargetFilePath $FilePath
            }

            if($IsMultipleOfNFiles){
                Write-Log -Level Info -Message "Writing ""$FilePath""`tCreatedDirectories:$GLOBAL:TotalDirectories`tCopied:$GLOBAL:FilesCopied`tExisting:$GLOBAL:FilesExisting"
            }
        }

        foreach($dir in [System.IO.Directory]::GetDirectories($sourceDir) ){
            $test = [System.IO.Path]::Combine($targetDir, (New-Object -TypeName System.IO.DirectoryInfo -ArgumentList $dir).Name)
            Copy-Info -sourceDir $dir -targetDir $test
            Set-DateAttributes -OriginalFilePath $dir -TargetFilePath $test -folder
            #GetandSetACL -OriginalFilePath $dir -TargetFilePath $test
        }
    }
    END{}
    

    #get source files
    
 }

 <#
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
#>