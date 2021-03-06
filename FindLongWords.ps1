param 
(
	[Parameter(Mandatory=$true)]
	$path
)

function Check-File($filePath)
{
		
	$pattern = "\s"

	$currentLength = 0
	$max = 60
	$totalOversized = 0

	$file = Get-Content $filePath
	Write-Host "Checking file: $filePath ..."
	foreach($line in $file)
	{
		$currentLength = 0
		for($i = 0; $i -lt $line.length; $i++)
		{
			if(($line[$i] -match $pattern) -eq $true)
			{
				if($currentLength -gt $max)
				{
					$start = $i - $currentLength
					if($start -lt 0)
					{
						$start = 0
					}
					$longWord = $line.Substring($start,$i)
					Write-Host -ForegroundColor Red $longWord
					$totalOversized++
				}
				$currentLength = 0
			}
			else
			{
				$currentLength++
			}
		}
	}
	if($totalOversized -gt 0)
		{
			Write-Host "Total words longer than $max characters: $totalOversized"
		}
		else
		{
			Write-Host "No words longer than $max characters found."
		}
}

if(Test-Path $path)
{
	$a = Get-Item $path
	if($a -is [System.IO.DirectoryInfo])
	{
		$files = Get-ChildItem $a -File #-Include *.txt
		foreach($file in $files)
		{
			Check-File $file.FullName
		}
	}
	else
	{
		Check-File $a.FullName
	}

}
else
{
	Write-Host "Could not find the specified path."

}
Write-Host "Script execution completed."






