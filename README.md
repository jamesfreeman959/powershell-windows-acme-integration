# Installation

If you've already installed the Posh-ACME module, you will need to:

1. Ensure that you've created `C:\Cert\Posh-ACME`
2. Copy the existing data from the module install as follows - otherwise you'll get a failure about no server defined:
   1. `cd %localappdata%\Posh-ACME`
   2. `xcopy /s /e *.* c:\Cert\Posh-ACE`
3. (optional) Update the module with `Install-Module Posh-ACME -Force`
4. 
