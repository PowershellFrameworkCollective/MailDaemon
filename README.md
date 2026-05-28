# MailDaemon

## Description

This module is a simple way to implement a mail daemon on your systems.

Ever felt it a pain to set up your mail system right? Anonymous sending is causing trouble, but you don't want to give every task user access to an account to do so? Wished it was as easy as writing a logfile and emails aren't lost during a downtime?

Then this module is for you!

## Main Features

+ Centralize mail sending, with dedicated account or credentials
+ Retry sending emails when service is unavailable
+ Full logging without having to worry about the logs - never again lose a message without being able to look up why
+ Easy to setup
+ Easy to use
+ Manageable by Group Policy / SCCM / Intune / ...

## Prerequisites

+ PowerShell 5.1 (or later)
+ PowerShell Module: PSFramework
+ PowerShell Module: EntraAuth

## Installation

To install the module from the PSGallery, run this line:

```powershell
Install-Module MailDaemon
```

## Setting up the Daemon on your system

> Local using SMTP

```powershell
Install-MDDaemon -SmtpServer mail.domain.com -SenderDefault 'support@domain.com' -RecipientDefault 'support@domain.com'
```

> Local using Graph API

```powershell
Install-MDDaemon -SenderDefault 'support@domain.onmicrosoft.com' -ClientID $clientID -TenantID $tenantID -CertificateName 'CN=GraphMailCertificate'
```

> Remote Deployment

Setting it up an all^ machines^^:

```powershell
Get-ADComputer -Filter * | Install-MDDaemon -SmtpServer mail.domain.com -SenderDefault 'support@domain.com' -RecipientDefault 'support@domain.com'
```

^Will copy the modules needed if not already present

^^Expect some of them to fail, due to being offline ;)

## Setting up Sending emails via Graph

Some setup is required before you can send emails via Graph API.

> WARNING: Before you actually go and do it, read to the end of this section!!!

+ First: [Set up an application in Entra](https://github.com/FriedrichWeinmann/EntraAuth/blob/master/docs/creating-applications.md)
+ Second: [Configure Authentication via Certificate](https://github.com/FriedrichWeinmann/EntraAuth/blob/master/docs/authenticate-certificate.md). Alternative options such as Federated Credentials or Managed Identity exist, but are somewhat more complicated.
+ Third: [Assign _Application_ scopes to the application](https://github.com/FriedrichWeinmann/EntraAuth/blob/master/docs/api-permissions.md): `Mail.ReadWrite` and `Mail.Send`

The third step is an incredibly impactful step - it gives your application full access to every single mailbox in the tenant, which is almost certainly way too much!
You should [constrain the scope of your application's permission](https://learn.microsoft.com/en-us/exchange/permissions-exo/application-rbac) first before assigning those scopes.
This may need to be done by the Exchange ONline team.

## Sending Emails

Sending emails is a matter of up to three commands used during your script:

> Preparing your email meta information

Can be run any number of times to later specify other information

```powershell
Set-MDMail -From 'backuptask@domain.com' -To 'backupadmins@domain.com' -Subject 'Backup Failed'
```

> Adding content to the mail body

Can also be specified/overwritten during Set-MDMail

```powershell
Add-MDMailContent "Backup on server $server failed due to $errorreason"
```

> Submitting mail for sending

```powershell
Send-MDMail -TaskName BackupTask
```
