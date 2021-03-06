Param (
	[Parameter(Mandatory=$true, HelpMessage="Your LingQ username")]
	[string] $username,
	
	[Parameter(Mandatory=$true,HelpMessage="Your LingQ account password")]
	[string] $password,
	
	[Parameter(Mandatory=$true, HelpMessage="Course ID")]
	[string] $courseId,
	
	[Parameter(Mandatory=$true,HelpMessage="Language code")]
	[string] $languageCode
	)
	
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

$courseUrl = "https://www.lingq.com/learn/{0}/import/collections/{1}/" -f $languageCode, $courseId
$d = $driver.Navigate().GoToUrl($courseUrl)
$z = $driver.FindElementsByXPath("//a[contains(@href,'?del=')]")

$deleteLinks = New-Object System.Collections.ArrayList 
$cc = $z.Count
Write-Host "$cc courses found."  

$time = Get-Date
Write-Host "Deleting started on $time"

foreach($a in $z)
{
	$s = $deleteLinks.Add($a.GetAttribute("href"))
}
foreach($deleteLink in $deleteLinks)
{
	$d = $driver.Navigate().GoToUrl($deleteLink)
	Start-Sleep -Seconds 1
}
$d = $driver.Navigate().GoToUrl($courseUrl)

$time = Get-Date
Write-Host "Deleting finished on $time"