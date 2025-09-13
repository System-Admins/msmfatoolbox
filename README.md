# Introduction
Welcome to the Microsoft Entra MFA toolbox PowerShell (SystemAdmins.MsMfaToolbox) module!

This tool was originally developed to get users that are not fully protected by MFA (all apps in Entra ID). Over time, it will evolve to include a comprehensive set of features aimed at enhancing the MFA state of a Microsoft 365 environment. By leveraging this module, administrators can gain valuable insights into their organization's security posture and take proactive measures to mitigate potential risks.

## :ledger: Index

- [About](#beginner-about)
- [Usage](#zap-usage)
  - [Installation](#electric_plug-installation)
  - [Commands](#package-commands)
  - [Cmdlets](#cmdlets)
    - [Send-EidUserMfaStatusReport](#Send-EntraUserMfaStatusReport)
    - [Get-EidUserMfaPolicy](#Get-EidUserMfaPolicy)
    - [Get-EidConditionalAccessPolicy](#Get-EidConditionalAccessPolicy)
- [FAQ](#question-faq)

##  :beginner: About
This module also includes a feature that sends an email report of users who are not fully covered by MFA. By running the appropriate command, administrators can generate a detailed report and have it automatically emailed to specified recipients. This ensures that key stakeholders are kept informed about the MFA coverage status within the organization, enabling timely actions to enhance security.


## :zap: Usage
To get started with the Microsoft MFA Toolbox module, simply follow the instructions outlined in the documentation provided in this repository. You'll find detailed guidance on installation, configuration, and usage, enabling you to seamlessly integrate the module into your existing workflows.

While using the PowerShell module, please be patient if have a mid to large size Microsoft 365 tenant. Running the commands may take up to 5-10 minutes during initial testing.

###  :electric_plug: Installation

Before installing the module, the following prerequisites must be fulfilled:

- [ ] **PowerShell 7** installed, [see this for more information](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.4).
- [ ] The running account must have the following scopes:
      'Policy.Read.All'
      'GroupMember.Read.All'
      'User.Read.All'
      'RoleManagement.Read.All
      'RoleManagement.Read.Directory'
      'Mail.Send' (this is used to send a report)
- [ ] Exchange Online license assigned to the account running the script (this is required to send an e-mail).

###  :package: Commands
1. To install the module and it dependencies, run the following in a PowerShell 7 session:

   ```powershell
   Install-Module -Name 'Microsoft.Entra', 'Microsoft.Graph.Grsoups', 'Microsoft.Graph.Users', 'Microsoft.Graph.Users.Actions', 'Microsoft.Graph.Identity.DirectoryManagement', 'Microsoft.Entra', 'Microsoft.Graph.Authentication' -Scope CurrentUser -Force;
   Install-Module -Name 'SystemAdmins.MsMfaToolbox' -Scope CurrentUser -Force;
   ```

   > **Note:** After installing the dependencies, you need to close the PowerShell session and open a new. This is due to Microsoft not handling the assemblies correctly if multiple modules is installed. Hopefully this is sorted in the future by Microsoft.

2. Import the module dependencies in the PowerShell 7 session.

   ```powershell
   Import-Module -Name 'Microsoft.Entra', 'Microsoft.Graph.Groups', 'Microsoft.Graph.Users', 'Microsoft.Graph.Users.Actions', 'Microsoft.Graph.Identity.DirectoryManagement', 'Microsoft.Entra', 'Microsoft.Graph.Authentication', 'SystemAdmins.MsMfaToolbox' -Force;
   ```

3. Login to Microsoft Entra using the following.

   ```powershell
   Connect-Entra -Scopes 'Policy.Read.All', 'GroupMember.Read.All', 'User.Read.All', 'RoleManagement.Read.All', 'RoleManagement.Read.Directory', 'Mail.Send' -NoWelcome -ContextScope Process;
   ```

4. Open a new PowerShell 7 session, and run one of the cmdlets.

   ```powershell
   Send-EidUserMfaStatusReport -EmailAddress 'abc@contoso.com';
   ```

5. When you are finished with running the cmdlet(s) you can run the following to logout from the Microsoft 365 in the PowerShell 7 session.

   ```powershell
   Disconnect-Entra -ErrorAction SilentlyContinue;
   Disconnect-MgGraph -ErrorAction SilentlyContinue;
   ```



## Cmdlets

### Send-EidUserMfaStatusReport

#### Synopsis

Send a report about user MFA status in Microsoft Entra. The e-mail content only show the enabled users, but there is an attachment that have more details.

#### Parameter(s)

| Type   | Parameter | Description                                                  | Optional | Accepted Values |
| ------ | --------- | ------------------------------------------------------------ | -------- | --------------- |
| String | To        | E-mail to who should receive the report. Defaults to logged-in user in Microsoft Entra. | True     | abc@contoso.com |

#### Example(s)

Send a report about user MFA status in Microsoft Entra to logged-in user.

```powershell
Send-EidUserMfaStatusReport
```

Send a report about user MFA status in Microsoft Entra to abc@contoso.com.

```powershell
Send-EidUserMfaStatusReport -EmailAddress 'abc@contoso.com'
```

### Output

Void



### Get-EidUserMfaPolicy

#### Synopsis

Get all users and if they are targeted by a Entra Conditional Access that requires MFA.

#### Parameter(s)

| Type   | Parameter         | Description                                    | Optional | Accepted Values |
| ------ | ----------------- | ---------------------------------------------- | -------- | --------------- |
| String | UserPrincipalName | If not specified, all users are returned.      | True     | abc@contoso.com |
| Switch | OnlyEnabled       | If specified, only enabled users are returned. | True     | N/A             |

#### Example(s)

Get users (only enabled) and if they are protected by a conditional access that requires MFA.

```powershell
Get-EidUserMfaPolicy -OnlyEnabled
```

Get only enabled user and conditional access that requires MFA to the account.

```powershell
Get-EidUserMfaPolicy -UserPrincipalName 'abc@contoso.com'
```

### Output

Array



### Get-EidConditionalAccessPolicy

#### Synopsis

Get all Entra conditional access policies format like the Entra Conditional Access web portal.

#### Parameter(s)

| Type | Parameter | Description | Optional | Accepted Values |
| ---- | --------- | ----------- | -------- | --------------- |
|      |           |             |          |                 |

#### Example(s)

Get all the Entra Conditional Access policies with information like users, conditions etc.

```powershell
Get-EidConditionalAccessPolicy
```

### Output

Array



## :question: FAQ

- **Are the module modifying anything in my Microsoft 365 tenant?**

  No, it only reads data and don't modify anything

- **What permission scopes are used by the module?**

   'Policy.Read.All'

   'GroupMember.Read.All'

   'User.Read.All'

   'RoleManagement.Read.All'

   'RoleManagement.Read.Directory'

   'MailboxSettings.Read'

   'Mail.Send'

- **Why is it free?**

  Why shouldn't it be.
  
- **If you need to assign permission scopes to a managed identity, you can run the following:**

  ```powershell
  # Managed Identity Display Name.
  $managedIdentityObjectId = 'OBJECT ID OF THE MANAGED IDENTITY';
  
  # Connect to Microsoft Graph (delegated permissions).
  Connect-MgGraph `
      -Scopes @('Directory.ReadWrite.All', 'AppRoleAssignment.ReadWrite.All') `
      -ContextScope Process;
  
  # Required Microsoft Graph API scopes.
  $graphApiScopes = @(
      'Policy.Read.All',
      'GroupMember.Read.All',
      'User.Read.All',
      'RoleManagement.Read.All'
      'RoleManagement.Read.Directory',
      'Mail.Send'
  );
  
  # Get managed identity.
  $managedIdentity = Get-MgServicePrincipal `
      -Filter "Id eq '$managedIdentityObjectId'";
  
  # Get Graph Service Principal.
  $graphSPN = Get-MgServicePrincipal `
      -Filter "AppId eq '00000003-0000-0000-c000-000000000000'";
  
  # Foreach required permission, assign to managed identity.
  foreach ($graphApiScope in $graphApiScopes)
  {
      # Get app role for permission.
      $appRole = $graphSPN.AppRoles |
          Where-Object { $_.Value -eq $graphApiScope } |
              Where-Object { $_.AllowedMemberTypes -contains 'Application' };
  
      # If app role not found.
      if ($null -eq $appRole)
      {
          # Continue to next permission.
          continue;
      }
  
      # Create app role assignment.
      $bodyParam = @{
          PrincipalId = $managedIdentity.Id
          ResourceId  = $graphSPN.Id
          AppRoleId   = $appRole.Id
      }
  
      # Assign app role to managed identity.
      New-MgServicePrincipalAppRoleAssignment `
          -ServicePrincipalId $managedIdentity.Id `
          -BodyParameter $bodyParam;
  }
  ```
