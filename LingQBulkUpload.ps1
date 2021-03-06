Param (
	[Parameter(Mandatory=$true, HelpMessage="Your LingQ username")]
	[string] $username,
	
	[Parameter(Mandatory=$true,HelpMessage="Your LingQ account password")]
	[string] $password,
	
	[Parameter(Mandatory=$true, HelpMessage="Course ID")]
	[string] $courseId,
	
	[Parameter(Mandatory=$true,HelpMessage="Language code")]
	[string] $languageCode,
	
	[Parameter(Mandatory=$true, HelpMessage="Path to input folder with your text files")]
	[string] $inputFolder,
	
	[Parameter(HelpMessage="Number of retries for failed import")]
	[int] $retries=10
	)
	
function ImportFile($file, $retry)
{
	try{



	$title = [System.IO.Path]::GetFileNameWithoutExtension($file.FullName)
	
	$data = Get-Content $file.FullName -Encoding UTF8
	$importUrl = "http://www.lingq.com/learn/{0}/import/contents/?add=&collection={1}" -f $languageCode, $courseId
	
	#wait before trying to load the page again
	if($retry -gt 0)
	{
		Start-Sleep -Seconds $retry
	}
    	$d = $driver.Navigate().GoToUrl($importUrl) 
		
	#wait for the page to load
	if($retry -gt 0)
	{
		Start-Sleep -Seconds $retry
	}
	$d = $driver.FindElementsById("id_title").SendKeys($title)
	$d = $driver.SwitchTo().Frame("id_text_ifr")
	$body = $driver.FindElementsByTagName("body")
	$body.Click()
	foreach($line in $data)
	{
		$body.SendKeys($line)
		$body.SendKeys("`n")
	}
	$d =$driver.SwitchTo().DefaultContent()
	$d = $driver.FindElementsByClassName("save-button").Click()
	$zz = $d
	}
	catch
	{
		return $false
	}
	return $true
}

$path = Split-Path $script:MyInvocation.MyCommand.Path
$time	 = Get-Date
Write-Host "Script started on $time" 
Write-Host "Loading DLLs..."
$ErrorActionPreference = 'silentlycontinue'
Add-Type -Path "$path\ThoughtWorks.Selenium.Core.dll" 
Add-Type -Path "$path\Selenium.WebDriverBackedSelenium.dll" 
Add-Type -Path "$path\Selenium.WebDriver.dll" 
Add-Type -Path "$path\WebDriver.dll" 
Add-Type -Path "$path\WebDriver.Support.dll" 
Write-Host "Starting Firefox..." 
$ErrorActionPreference = 'continue'

$driver = New-Object OpenQA.Selenium.FireFox.FirefoxDriver
$driver.Navigate().GoToUrl("https://www.lingq.com/accounts/login/") | out-null
$driver.FindElementsById("id_username").SendKeys($username);
$driver.FindElementsById("id_password").SendKeys($password);
$driver.FindElementsById("submit-button").Click();

if($driver.Url -match 'https://www.lingq.com/learn/.*/welcome/')
{
	Write-Host "Login successful."
}
else
{
Write-Host "Login failed. Check your username and password and try again." -ForegroundColor Red
return
}

$ToNatural = { [regex]::Replace($_, '\d+', { $args[0].Value.PadLeft(20) }) }
$files = Get-ChildItem -File $inputFolder | Sort-Object $ToNatural
$c = $files.lengh
$time = Get-Date

#### this is how pro's debug PowerShell
if($false)
{

Write-Host "Import started on $time"
if($c -eq 0)
{
	Write-Host "No lessons found in input folder. Terminating script."
	return
}
if($c -eq 1)
{
	Write-Host "1 lesson found."
}
if($c -gt 1)
{
	Write-Host "$c lessons found."
}
$n = 1
$fails = 0
foreach($f in $files)
{
	$title = [System.IO.Path]::GetFileNameWithoutExtension($f.FullName)
	[Console]::OutputEncoding = [System.Text.Encoding]::Unicode
	[Console]::WriteLine("Importing lesson: $title ... ") # <-doesn't write jack in PowerGui???








	Write-Host "Importing lesson $n of $c`: '$title' ... " -NoNewline
	$success = ImportFile $f 0
	if($success)
	{


		Write-Host -ForegroundColor Green "import successful."
	}


	else
	{
		Write-Host -ForegroundColor Yellow "import failed."
		if($retries -gt 0)
		{
			Write-Host "Retrying:"
			$ss = $false
			for($i = 1; $i -le $retries; $i++)
			{
				Write-Host " - Retry number $i ... " -NoNewline
				$success = ImportFile $f $i
				if($success)
				{
					Write-Host -ForegroundColor Green "import successful."
					$ss = $true
					break;
				}
				Write-Host -ForegroundColor Yellow "import failed."
			}
			if($ss -eq $false)
			{
				Write-Host -ForegroundColor Red "'$title' - import failed after $retries retries."
				$fails++
			}
		}
		else
		{
			Write-Host -ForegroundColor Red "'$title' - import failed. No retries were made."
			$fails++
		}
	}
	$n++
}

### debug if ends here
}

$courseUrl = "https://www.lingq.com/learn/{0}/import/collections/{1}/" -f $languageCode, $courseId
$d = $driver.Navigate().GoToUrl($courseUrl)




$time = Get-Date
Write-Host "Import completed on $time" 
if($fails -gt 0)
{
	$t = if($fails -eq 1){"lesson"} else { "lessons"}
	Write-Host "$fails $t failed to import. Check script output for details."
}

### Verify presence of imported lessons
Write-Host "Verifying imported lessons"

$lll = $driver.FindElementsByXPath("//td/a[contains(@href,'/import/contents/')]")
$verifyLinks = New-Object System.Collections.ArrayList 
foreach($l in $lll)
{
	if(-not [string]::IsNullOrEmpty($l.Text))
	{
		$stfu = $verifyLinks.Add($l.Text)
	}
}
$missingCount = 0
foreach($f in $files)
{
	$title = [System.IO.Path]::GetFileNameWithoutExtension($f.FullName)
	if(-not $verifyLinks.Contains($title))
	{
		Write-Host "Lesson '$title' is missing." -ForegroundColor Red
		$missingCount++
	}
}
Write-Host "Verification complete."
if($missingCount -eq 0)
{
	Write-Host "All lessons have been imported."
}
else
{
	Write-Host "$missingCount lessons are missing. Check script output and reupload missing lessons." -ForegroundColor Red
}