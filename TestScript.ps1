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

[int]$GLOBAL:FilesCopied=0 #variable to determine the files that have been copied
[int]$GLOBAL:FilesExisting=0   #variable to determine the existing files
[int]$GLOBAL:DirectoriesCreated=0  #variable to determine the number of directories created

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
            #add 1 directory to the total
            $GLOBAL:DirectoriesCreated++
            #Write-Log -Level Load -Message "Folder ""$targetDir"" created..."
        }
    }
    PROCESS{
		Try{
			$files = [System.IO.Directory]::GetFiles($sourceDir)
			$directories = [System.IO.Directory]::GetDirectories($sourceDir)
			
			<# Copy files in a Directory #>
			foreach($file in $files ){
				$GLOBAL:FilesExisting ++
				$targetFilePath=[System.IO.Path]::Combine($targetDir, [System.IO.Path]::GetFileName($file))
				$CopyingFileInfo = new-object System.IO.FileInfo($file)
				
				<# New Files #>
				if(![System.IO.File]::Exists($targetFilePath) ){ #If doesn't exists, add to the copiedfiles copy the file and set attributes
					[System.IO.File]::Copy($file, $targetFilePath)
					Write-Host "Copying files from $Source to $Target"
					Write-Host "=============================================="
					$GLOBAL:FilesCopied++
				}
				
				<# Modified Files #>
				else{  
					$TargetFileInfo = new-object System.IO.FileInfo($targetFilePath)
					if($CopyingFileInfo.Length -ne $TargetFileInfo.Length){ #If file exists but source and target file's sizes are not equal				
						Write-Host "File modified: $file"
						[System.IO.File]::Copy($file, $targetFilePath, $TRUE)
						Write-Host "Copying modified files from $Source to $Target"
						Write-Host "=============================================="
						$GLOBAL:FilesCopied++
					}
					
					elseif($CopyingFileInfo.LastWriteTime - $TargetFileInfo.LastWriteTime -gt 0 ){ #If file exists but source has been modified later without affecting its size
						Write-Host "Modified later in src: $file"
						[System.IO.File]::Copy($file, $targetFilePath, $TRUE)
						Write-Host "Copying modified files from $Source to $Target"
						Write-Host "=============================================="
						$GLOBAL:FilesCopied++
					}
					
					elseif($CopyingFileInfo.LastWriteTime - $TargetFileInfo.LastWriteTime -lt 0 ){ #If file exists but target file has been modified later without affecting its size
						Write-Host "Modified later in target: $file"
						Write-Host "=============================================="
					}
					
				}
			}
			
			<# Copy directories in a directory #>
			foreach($dir in $directories ){
				$test = [System.IO.Path]::Combine($targetDir, (New-Object -TypeName System.IO.DirectoryInfo -ArgumentList $dir).Name)
				Copy-Recursive -sourceDir $dir -targetDir $test
				#GetandSetACL -originalFilePath $dir -targetFilePath $test
			}
		}
		
		Catch{
			$ErrorMessage = $_.Exception.Message
			$FailedItem = $_.Exception.ItemName
			Write-Host "=============================================="
			Write-Host "$ErrorMessage"
			Write-Host "=============================================="
			Write-Host "$FailedItem"
			Break
		}
		
		Finally{
		}
		
    }
    END{}   
 }

<# Start script #>
Copy-Recursive -sourceDir $source -targetDir $target
Write-Host "Created Directories:$GLOBAL:DirectoriesCreated`t Files Copied:$GLOBAL:FilesCopied`t Files Existing:$GLOBAL:FilesExisting"

