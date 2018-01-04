param(
 [Parameter(Mandatory=$true)][string]$Source,
 [Parameter(Mandatory=$true)][string]$Target
)
Write-Host "=============================================="
Write-Host "You are copying from: $Source"
Write-Host "You are copying to: $Target"
Write-Host "=============================================="
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
        [Parameter(Position=1,mandatory=$true)] [string]$targetDir
        #[Parameter(Position=2,mandatory=$false)] [switch]$NTFS=$false
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
            $TargetFilePath=[System.IO.Path]::Combine($targetDir, [System.IO.Path]::GetFileName($file))
            $CopyingFileInfo = new-object System.IO.FileInfo($file)
			
			<# New Files #>
            if(![System.IO.File]::Exists($TargetFilePath) ){ #If doesn't exists, add to the copiedfiles copy the file and set attributes
                [System.IO.File]::Copy($file, $TargetFilePath)
				Write-Host "Copying files from $Source to $Target"
				Write-Host "=============================================="
                Set-DateAttributes -OriginalFilePath $file -TargetFilePath $TargetFilePath
                $GLOBAL:FilesCopied++
            }
			
			<# Modified Files #>
			else{  
				$TargetFileInfo = new-object System.IO.FileInfo($TargetFilePath)
				if($CopyingFileInfo.Length -ne $TargetFileInfo.Length){ #If file exists but source and target file's sizes are not equal				
					Write-Host "File modified: $file"
					[System.IO.File]::Copy($file, $TargetFilePath, $TRUE)
					Write-Host "Copying modified files from $Source to $Target"
					Write-Host "=============================================="
					Set-DateAttributes -OriginalFilePath $file -TargetFilePath $TargetFilePath
					$GLOBAL:FilesCopied++
				}
				
				elseif($CopyingFileInfo.LastWriteTime - $TargetFileInfo.LastWriteTime -gt 0 ){ #If file exists but source has been modified later without affecting its size
					Write-Host "Modified later in src: $file"
					[System.IO.File]::Copy($file, $TargetFilePath, $TRUE)
					Write-Host "Copying modified files from $Source to $Target"
					Write-Host "=============================================="
					Set-DateAttributes -OriginalFilePath $file -TargetFilePath $TargetFilePath
					$GLOBAL:FilesCopied++
				}
				
				elseif($CopyingFileInfo.LastWriteTime - $TargetFileInfo.LastWriteTime -lt 0 ){ #If file exists but target file has been modified later without affecting its size
					Write-Host "Modified later in target: $file"
					Write-Host "=============================================="
				}
				
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
        #[int]$logcounter=0 # TO log 
    }
    PROCESS{
        if(!($folder)){
            [System.IO.FileInfo] $fi = New-Object System.IO.FileInfo -ArgumentList $OriginalFilePAth
            [System.IO.File]::SetCreationTime($TargetFilePath,$fi.CreationTime)
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

<# Start script #>
Copy-Recursive -sourceDir $source -targetDir $target

