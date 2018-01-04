param(
 [Parameter(Mandatory=$true)][string]$Source,
 [Parameter(Mandatory=$true)][string]$Target
)
Write-Host "Source is $Source"
Write-Host "Destination is $Target"

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
		[int]$Nfiles = 10;

        if(! [System.IO.Directory]::Exists($targetDir) ){
           [System.IO.Directory]::CreateDirectory($targetDir) | Out-Null
            Set-DateAttributes -OriginalFilePath $sourceDir -TargetFilePath $targetDir -folder
            #add 1 directory to the total
            $GLOBAL:TotalDirectories++
            #Write-Log -Level Load -Message "Folder ""$targetDir"" created..."
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
			
			<# New Files #>
            if(![System.IO.File]::Exists($FilePath) ){ #If doesn't exists, add to the copiedfiles copy the file and set attributes
                [System.IO.File]::Copy($file, $FilePath)
				Write-Host "Coping files from $Source to $Target"
                Set-DateAttributes -OriginalFilePath $file -TargetFilePath $FilePath
                $GLOBAL:FilesCopied++
            }
			
			<# Modified Files #>
			elseif ([System.IO.File]::Exists($FilePath)){ #If file exists but source and target file's lengths are not equal 
				$TargetFileInfo = new-object System.IO.FileInfo($FilePath)
				if($FileInfoNew.Length -ne $TargetFileInfo.Length){				
					Write-Host "$file is different in src and target"
					[System.IO.File]::Copy($file, $FilePath, $TRUE)
					Write-Host "Coping modified files from $Source to $Target"
					Set-DateAttributes -OriginalFilePath $file -TargetFilePath $FilePath
					$GLOBAL:FilesCopied++
				}
			}
            else{
			    $FileInfoExisting = new-object System.IO.FileInfo($FilePath)
			    $FileInfoNew      = new-object System.IO.FileInfo($file)
                $GLOBAL:FilesExisting++
                #setattributes
                Set-DateAttributes -OriginalFilePath $file -TargetFilePath $FilePath
            }

            if($IsMultipleOfNFiles){
                #Write-Log -Level Info -Message "Writing ""$FilePath""`tCreatedDirectories:$GLOBAL:TotalDirectories`tCopied:$GLOBAL:FilesCopied`tExisting:$GLOBAL:FilesExisting"
            }
        }

        foreach($dir in [System.IO.Directory]::GetDirectories($sourceDir) ){
            $test = [System.IO.Path]::Combine($targetDir, (New-Object -TypeName System.IO.DirectoryInfo -ArgumentList $dir).Name)
            Copy-Recursive -sourceDir $dir -targetDir $test
            Set-DateAttributes -OriginalFilePath $dir -TargetFilePath $test -folder
            #GetandSetACL -OriginalFilePath $dir -TargetFilePath $test
        }
    }
    END{}
    

    #get source files
    
 }
function Set-DateAttributes{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]$OriginalFilePath,
        [Parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true)]$TargetFilePath,
        [Parameter(Mandatory=$false,Position=2,ValueFromPipeline=$true)][switch]$folder
    )
    BEGIN{
        [int]$logcounter=0
    }
    PROCESS{
        if(!($folder)){
            [System.IO.FileInfo] $fi = New-Object System.IO.FileInfo -ArgumentList $originalFilePAth
            [System.IO.File]::SetCreationTime($targetFilePath,$fi.CreationTime)
            [System.IO.File]::SetLastWriteTime($TargetFilePath,$fi.LastWriteTime)
            [System.IO.File]::SetLastAccessTime( $TargetFilePath,$fi.LastAccessTime)
        }
        else{
            [System.IO.DirectoryInfo]$di = New-Object System.IO.DirectoryInfo -ArgumentList $OriginalFilePath
            [System.IO.Directory]::SetCreationTime($TargetFilePath,$di.CreationTime)
            [System.IO.Directory]::SetLastWriteTime($TargetFilePath,$di.LastWriteTime)
            [System.IO.Directory]::SetLastAccessTime($TargetFilePath,$di.LastAccessTime)
        }
    }
    END{
        
    }
}
 Copy-Recursive -sourceDir $source -targetDir $target

 <#
Try{
	Copy-Item $Source\* $Target -recurse -ErrorAction Stop
	Write-Host "Coping files from $Source to $Target"
	Write-Host "Successfully Copied"
}
Catch{
	$ErrorMessage = $_.Exception.Message
	Write-Host "Error: $ErrorMessage"
	Break
}
#>