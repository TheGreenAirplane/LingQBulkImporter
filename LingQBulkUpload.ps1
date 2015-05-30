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
	[string] $inputFolder
	)

$path = Split-Path $script:MyInvocation.MyCommand.Path

Add-Type -Path "$path\ThoughtWorks.Selenium.Core.dll"
Add-Type -Path "$path\Selenium.WebDriverBackedSelenium.dll"
Add-Type -Path "$path\Selenium.WebDriver.dll"
Add-Type -Path "$path\WebDriver.dll"
Add-Type -Path "$path\WebDriver.Support.dll"

$driver = New-Object OpenQA.Selenium.FireFox.FirefoxDriver
$driver.Navigate().GoToUrl("https://www.lingq.com/accounts/login/") | out-null
$driver.FindElementsById("id_username").SendKeys($username);
$driver.FindElementsById("id_password").SendKeys($password);
$driver.FindElementsById("submit-button").Click();

$ToNatural = { [regex]::Replace($_, '\d+', { $args[0].Value.PadLeft(20) }) }
$files = Get-ChildItem $inputFolder | Sort-Object $ToNatural
foreach($f in $files)
{
	$title = [System.IO.Path]::GetFileNameWithoutExtension($f.FullName)
	Write-Host "Importing lesson: " $title
	$data = Get-Content $f.FullName -Encoding UTF8
	$importUrl = "http://www.lingq.com/learn/{0}/import/contents/?add=&collection={1}" -f $languageCode, $courseId
    $driver.Navigate().GoToUrl($importUrl) 
	$driver.FindElementsById("id_title").SendKeys($title)
	$driver.SwitchTo().Frame("id_text_ifr")
	$body = $driver.FindElementsByTagName("body")
	$body.Click()
	foreach($line in $data)
	{
		$body.SendKeys($line)
		$body.SendKeys("`n")
	}
	$driver.SwitchTo().DefaultContent()
	$driver.FindElementsByClassName("save-button").Click()
}
