# Description

This module is a simple way to implement a mail daemon on your systems.

Ever felt it a pain to set up your mail system right? Anonymous sending is causing trouble, but you don't want to give every task user access to an account to do so? Wished it was as easy as writing a logfile and emails aren't lost during a downtime?

Then this module is for you!

# Main Features

 - Centralize mail sending, with dedicated account or credentials
 - Retry sending emails when service is unavailable
 - Full logging without having to worry about the logs - never again lose a message without being able to look up why
 - Easy to setup
 - Easy to use
 - Manageable by Group Policy / SCCM / Intune / ...

# Prerequisites

 - PowerShell 5.1
 - PowerShell Module: PSFramework

# Installation

To install the module from the PSGalelry, run this line:

```powershell
Install-Module MailDaemon
```

Setting up the Daemon on your system:

```powershell
Install-MDDaemon -SmtpServer mail.domain.com -SenderDefault 'support@domain.com' -RecipientDefault 'support@domain.com'
```

Setting it up an all^ machines^^:

```powershell
Get-ADComputer -Filter * | Install-MDDaemon -SmtpServer mail.domain.com -SenderDefault 'support@domain.com' -RecipientDefault 'support@domain.com'
```

^Will copy the modules needed if not already present

^^Expect some of them to fail, due to being offline ;)

# Sending Emails

Sending emails is a matter of up to three commands used during your script:

> Preparing your email meta information

Can be run any number of times to later specify other information

```powershell
Set-MDMail -From 'backuptask@domain.com' -To 'backupadmins@domain.com' -Subject 'Backup Failed'
```

> Adding content to the mailbody

Can also be specified/overwritten during Set-MDMail

```powershell
Add-MDMailContent "Backup on server $server failed due to $errorreason"
```

> Submitting mail for sending

```powershell
Send-MDMail -TaskName BackupTask
```

# Project Status

## 0.1.0 (2019-02-09)

Alpha Release. It "Should" do the job and do it well enough. Expect some changes based on feedback, some possibly breaking, until the first full 1.0.0 release.

After release as 1.0.0, it will be under the same [breaking change policy](https://github.com/PowershellFrameworkCollective/psframework/blob/development/PSFramework/The%20PSFramework%20Reliability%20Promise.md) as the PSFramework.
