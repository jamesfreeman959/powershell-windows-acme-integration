# Installation

## Privileges

If you're running this on anything other than an administrator account (even if it's an AD account with local admin privileges), it'll fall over badly when you try and run it. You **must** run it from an elevated powershell session even if the account you're on is a local admin.

## Install Posh-ACME

```
Install-Module Posh-ACME
```

If the auto config fails (e.g. non-elevated console):

```
Set-PAServer
New-PAAccount -Contact "sysadmin@hkskies.com" -AcceptTOS
```

## Running scripts

If you've not previously run PowerShell scripts, you will need to run:

```
Set-ExecutionPolicy RemoteSigned
```

## Previous installs

If you've already installed the Posh-ACME module, you will need to:

1. Ensure that you've created `C:\Cert\Posh-ACME`
2. Copy the existing data from the module install as follows - otherwise you'll get a failure about no server defined:
   1. `cd %localappdata%\Posh-ACME`
   2. `xcopy /s /e *.* c:\Cert\Posh-ACE`
3. (optional) Update the module with `Install-Module Posh-ACME -Force`
4. 
