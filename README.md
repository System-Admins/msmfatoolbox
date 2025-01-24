# Introduction
Welcome to the Microsoft Entra MFA toolbox PowerShell (SystemAdmins.MsEntraMfaToolbox) module!

This tool was originally developed to get users that are not fully protected by MFA (all apps in Entra ID). Over time, it will evolve to include a comprehensive set of features aimed at enhancing the MFA state of a Microsoft 365 environment. By leveraging this module, administrators can gain valuable insights into their organization's security posture and take proactive measures to mitigate potential risks.

## :ledger: Index

- [About](#beginner-about)
- [Usage](#zap-usage)
  - [Installation](#electric_plug-installation)
  - [Commands](#package-commands)
  - [Cmdlets](#cmdlets)
    - [Send-EntraUserMfaStatusReport](#Send-EntraUserMfaStatusReport)
- [FAQ](#question-faq)

##  :beginner: About
This module also includes a feature that sends an email report of users who are not fully covered by MFA. By running the appropriate command, administrators can generate a detailed report and have it automatically emailed to specified recipients. This ensures that key stakeholders are kept informed about the MFA coverage status within the organization, enabling timely actions to enhance security.


## :zap: Usage
To get started with the Microsoft Entra MFA toolbox module, simply follow the instructions outlined in the documentation provided in this repository. You'll find detailed guidance on installation, configuration, and usage, enabling you to seamlessly integrate the module into your existing workflows.

###  :electric_plug: Installation

Before installing the module, the following prerequisites must be fulfilled:

- [ ] **PowerShell 7** installed, [see this for more information](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.4).
- [ ] The running account must have the following scopes 'Policy.Read.All', 'GroupMember.Read.All', 'User.Read.All', 'RoleManagement.Read.All' and 'Mail.Send'
- [ ] Exchange Online license assigned to the account running the script (this is required to send an e-mail).

###  :package: Commands
1. To install the module and it dependencies, run the following in a PowerShell 7 session:

   ```powershell
   Install-Module -Name 'Microsoft.Graph.Entra' -AllowPrerelease -Scope CurrentUser -Force;
   Install-Module -Name 'Microsoft.Graph.Groups', 'Microsoft.Graph.Users', 'Microsoft.Graph.Users.Actions', 'Microsoft.Graph.Identity.DirectoryManagement' -Scope CurrentUser -Force;
   Install-Module -Name 'SystemAdmins.MsEntraMfaToolbox' -Scope CurrentUser -Force;
   ```

   > **Note:** After installing the dependencies, you need to close the PowerShell session and open a new. This is due to Microsoft not handling the assemblies correctly if multiple modules is installed. Hopefully this is sorted in the future by Microsoft.

2. Import the module dependencies in the PowerShell 7 session.

   ```powershell
   Import-Module -Name 'Microsoft.Graph.Entra', 'Microsoft.Graph.Groups', 'Microsoft.Graph.Users', 'Microsoft.Graph.Users.Actions', 'Microsoft.Graph.Identity.DirectoryManagement' -Force;
   ```

3. Login to Microsoft Entra using the following.

   ```powershell
   Connect-Entra -Scopes 'Policy.Read.All', 'GroupMember.Read.All', 'User.Read.All', 'RoleManagement.Read.All', 'Mail.Send';
   ```

3. Import the module in the PowerShell 7 session.

   ```powershell
   Import-Module -Name 'SystemAdmins.MsEntraMfaToolbox' -Force;
   ```

4. Open a new PowerShell 7 session, and run one of the cmdlets.

   ```powershell
   Send-EntraUserMfaStatusReport -EmailAddress 'abc@contoso.com';
   ```

6. When you are finished with running the cmdlet(s) you can run the following to logout from the Microsoft 365 in the PowerShell 7 session.

   ```powershell
   Disconnect-Entra
   ```



## Cmdlets

### Send-EntraUserMfaStatusReport

#### Synopsis

Send a report about user MFA status in Microsoft Entra.

#### Parameter(s)

| Type   | Parameter    | Description                                                  | Optional | Accepted Values |
| ------ | ------------ | ------------------------------------------------------------ | -------- | --------------- |
| String | EmailAddress | E-mail to who should receive the report. Defaults to logged-in user in Microsoft Entra | True     | abc@contoso.com |

#### Example(s)

Send a report about user MFA status in Microsoft Entra to logged-in user.

```powershell
Send-EntraUserMfaStatusReport
```

Send a report about user MFA status in Microsoft Entra to abc@contoso.com.

```powershell
Send-EntraUserMfaStatusReport -EmailAddress 'abc@contoso.com'
```

### Output

Void



## :question: FAQ

- **Are the module modifying anything in my Microsoft 365 tenant?**

  No, it only reads data and don't modify anything

- **What scopes are used by the SystemAdmins.MsEntraMfaToolbox module?**

   'Policy.Read.All'

   'GroupMember.Read.All'

   'User.Read.All'

   'RoleManagement.Read.All'

   'Mail.Send'

- **Why is it free?**

  Why shouldn't it be.