# Introduction
Welcome to the Microsoft MFA toolbox PowerShell (SystemAdmins.MsMfaToolbox) module!

This tool was originally developed to get users that are not fully protected by MFA (all apps in Entra ID). Over time, it will evolve to include a comprehensive set of features aimed at enhancing the MFA state of a Microsoft 365 environment. By leveraging this module, administrators can gain valuable insights into their organization's security posture and take proactive measures to mitigate potential risks.

## :ledger: Index

- [About](#beginner-about)
- [Usage](#zap-usage)
  - [Installation](#electric_plug-installation)
  - [Commands](#package-commands)
  - [Cmdlets](#cmdlets)
    - [Send-EidUserMfaReport](#Send-EntraUserMfaStatusReport)
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
   - 'Policy.Read.All'
   - 'GroupMember.Read.All'
   - 'User.Read.All'
   - 'RoleManagement.Read.All
   - 'RoleManagement.Read.Directory'
   - 'Application.Read.All'
   - 'Directory.Read.All'
   - 'AuditLog.Read.All'
   - 'Mail.Send' (this is used to send a report)
- [ ] When using a delegated user to run the module a Exchange Online license assigned to the account running the cmdlet (this is required to send an e-mail).

###  :package: Commands
1. To install the module and it dependencies, run the following in a PowerShell 7 session:

   ```powershell
   Install-Module -Name 'Microsoft.Entra', 'SystemAdmins.MsMfaToolbox' -Scope CurrentUser -Force -AllowClobber;
   ```

   > **Note:** If there is already some PowerShell Microsoft Graph modules installed, they may conflict with the Microsoft.Entra module, please uninstall all installed modules to ensure a smooth run, see FAQ on how to uninstall those. Also make sure that after installing the dependencies, it's required to close the PowerShell session and open a new one to ensure now assemblies is loaded.

2. Import the module dependencies in the PowerShell 7 session.

   ```powershell
   Import-Module -Name 'Microsoft.Entra', 'SystemAdmins.MsMfaToolbox' -Force;
   ```

3. Login to Microsoft Entra using the following.

   ```powershell
   Connect-Entra -Scopes 'Policy.Read.All', 'GroupMember.Read.All', 'User.Read.All', 'RoleManagement.Read.All', 'RoleManagement.Read.Directory', 'Application.Read.All', 'Directory.Read.All', 'AuditLog.Read.All', 'Mail.Send' -NoWelcome -ContextScope Process;
   ```

4. Open a new PowerShell 7 session, and run one of the cmdlets.

   ```powershell
   Send-EidUserMfaReport -EmailAddress 'abc@contoso.com';
   ```

5. When you are finished with running the cmdlet(s) you can run the following to logout from the Microsoft 365 in the PowerShell 7 session.

   ```powershell
   Disconnect-Entra -ErrorAction SilentlyContinue;
   ```



## Cmdlets

### Send-EidUserMfaReport

#### Synopsis

Send a report about user MFA status in Microsoft Entra. The e-mail content only show the enabled users, but there is an attachment that have more details.

#### Parameter(s)

| Type   | Parameter | Description                                                  | Optional | Accepted Values |
| ------ | --------- | ------------------------------------------------------------ | -------- | --------------- |
| String | EmailAddress        | E-mail to who should receive the report. Defaults to logged-in user in Microsoft Entra. | True     | abc@contoso.com |
| String | From        | E-mail to send from, the e-mail address must exist in the Microsoft 365 tenant. | false     | from@contoso.com |

#### Example(s)

Send a report about user MFA status in Microsoft Entra to logged-in user.

```powershell
Send-EidUserMfaReport
```

Send a report about user MFA status in Microsoft Entra to abc@contoso.com.

```powershell
Send-EidUserMfaReport -EmailAddress 'abc@contoso.com'
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

   'AuditLog.Read.All'

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

- **If you have issues with modules overlapping (assembly conflict), you can try to uninstall all modules:**

  ```powershell
    # Get all installed modules.
    $installedModules = Get-InstalledModule;
  
    # Foreach install module.
    foreach ($installedModule in $installedModules)
    {
        # Get all versions.
        $versions = Get-InstalledModule -Name $installedModule.Name -AllVersions;
  
        # Foreach version.
        foreach ($version in $versions)
        {
            # Try to remove module.
            try
            {
                # Remove installed module.
                $null = Uninstall-Module `
                    -InputObject $version `
                    -Force `
                    -Confirm:$false `
                    -ErrorAction Stop `
                    -WarningAction SilentlyContinue;
  
                # Write to log.
                Write-Information `
                    -Message ("[SUCCESS] Removed module '{0}' version '{1}'" -f $version.Name, $version.Version) `
                    -InformationAction Continue;
            }
            catch
            {
                # Write to log.
                Write-Information `
                    -Message ("[ERROR] Cant remove module '{0}' version '{1}'. {2}" -f $version.Name, $version.Version, $_) `
                    -InformationAction Continue;
            }
        }
    }
  ```

  You can now try to run the [installation](#electric_plug-installation) again of this module

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
       'RoleManagement.Read.All',
       'RoleManagement.Read.Directory',
       'Application.Read.All',
       'Directory.Read.All',
       'AuditLog.Read.All',
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
  
- **If you need to install the required modules into a Azure Automation Account, use the following:**

   ```powershell
   # Automation account details.
   $subscriptionId = 'xxxxxx-xxxxxx-xxxx-xxxx-xxxxxxxxxx';
   $resourceGroupName = 'resourceGroupName';
   $automationAccountName = 'automationAccountName';
   
   # Install module.
   Install-Module -Name 'Az.Accounts', 'Az.Automation' -Scope CurrentUser -Force -AllowClobber;
   
   # Modules to install.
   $modulesToInstall = @{
       'Microsoft.Entra'                                = '1.0.12';
       'Microsoft.Entra.Applications'                   = '1.0.12';
       'Microsoft.Entra.Authentication'                 = '1.0.12';
       'Microsoft.Entra.CertificateBasedAuthentication' = '1.0.12';
       'Microsoft.Entra.DirectoryManagement'            = '1.0.12';
       'Microsoft.Entra.Governance'                     = '1.0.12';
       'Microsoft.Entra.Groups'                         = '1.0.12';
       'Microsoft.Entra.Reports'                        = '1.0.12';
       'Microsoft.Entra.SignIns'                        = '1.0.12';
       'Microsoft.Entra.Users'                          = '1.0.12';
       'Microsoft.Graph.Applications'                   = '2.25.0';
       'Microsoft.Graph.Authentication'                 = '2.25.0';
       'Microsoft.Graph.Groups'                         = '2.25.0';
       'Microsoft.Graph.Identity.DirectoryManagement'   = '2.25.0';
       'Microsoft.Graph.Identity.Governance'            = '2.25.0';
       'Microsoft.Graph.Identity.SignIns'               = '2.25.0';
       'Microsoft.Graph.Reports'                        = '2.25.0';
       'Microsoft.Graph.Users'                          = '2.25.0';
       'Microsoft.Graph.Users.Actions'                  = '2.25.0';
       'SystemAdmins.MsMfaToolbox'                      = '2.0.2';
   };
   
   # Connect to Azure account.
   Connect-AzAccount -Subscription $subscriptionId;
   
   # Foreach module.
   foreach ($moduleToInstall in $modulesToInstall.GetEnumerator())
   {
       # Get module name and version.
       $moduleName = $moduleToInstall.Key;
       $moduleVersion = $moduleToInstall.Value;
   
   
       # Try to install module.
       try
       {
           # Install module.
           New-AzAutomationModule -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName -Name $moduleName -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName/$moduleVersion" -RuntimeVersion '7.2' -ErrorAction Stop;
   
           # Write to host.
           Write-Host "Module $moduleName version $moduleVersion installed successfully";
       }
       # Something went wrong.
       catch
       {
           # Write to host.
           Write-Host "Module $moduleName version $moduleVersion could not be installed";
       }
   }
   
   ```

   
