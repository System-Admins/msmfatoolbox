# Variable for script path.
[string]$scriptPath = '';

# If we are running in VSCode, use the PSScriptRoot.
if ($null -ne $psEditor)
{
    # Use info from variable psEditor.
    $scriptPath = Split-Path -Path ($psEditor.GetEditorContext().CurrentFile.Path);
}
# Else use the current working directory.
else
{
    # Use the current working directory.
    $scriptPath = $PSScriptRoot;
}

# Set script variable.
$Script:scriptPath = $scriptPath;

# Paths to the private and public folders.
[string]$privatePath = Join-Path -Path $scriptPath -ChildPath 'private';
[string]$publicPath = Join-Path -Path $scriptPath -ChildPath 'public';

# Object array to store all PowerShell files to dot source.
$ps1Files = New-Object -TypeName System.Collections.ArrayList;

# Get all the files in the src (private and public) folder.
$privatePs1Files = Get-ChildItem -Path $privatePath -Recurse -File -Filter *.ps1;
$publicPs1Files = Get-ChildItem -Path $publicPath -Recurse -File -Filter *.ps1;

# Add the private and public files to the object array.
$ps1Files += ($privatePs1Files).FullName;
$ps1Files += ($publicPs1Files).FullName;

# Loop through each PowerShell file.
foreach ($ps1File in $ps1Files)
{
    # If line is empty.
    if ([string]::IsNullOrEmpty($ps1File))
    {
        # Skip to next line.
        continue;
    }

    # Try to dot source the file.
    try
    {
        # Write to log.
        Write-Debug -Message ("Dot sourcing the PowerShell file '{0}'" -f $ps1File);

        # Dot source the file.
        . $ps1File;
    }
    catch
    {
        # Throw execption.
        throw ("Something went wrong while importing the PowerShell file '{0}', the execption is:`r`n{1}" -f $ps1File, $_);
    }
}

# Write to log.
Write-CustomLog -Message ("Script path is '{0}'" -f $scriptPath) -Level Verbose;

# Get all the functions in the public section.
$publicFunctions = $publicPs1Files.Basename;

# Global variables.
## Module.
$script:ModuleName = 'SystemAdmins.MsMfaToolbox';

## Logging.
$script:ModuleTempFolderPath = ('{0}\{1}' -f ([System.IO.Path]::GetTempPath()), $script:ModuleName);
$script:ModuleLogFolder = ('{0}\Log' -f $script:ModuleTempFolderPath);
$script:ModuleLogFileName = ('{0}_EntraMfaToolbox.log' -f (Get-Date -Format 'yyyyMMddHHmmss'));
$script:ModuleLogPath = Join-Path -Path $ModuleLogFolder -ChildPath $ModuleLogFileName;

# Required Microsoft Graph API scopes.
$GraphApiScopes = @(
    'Policy.Read.All',
    'GroupMember.Read.All',
    'User.Read.All',
    'RoleManagement.Read.All'
    'RoleManagement.Read.Directory',
    'Mail.Send'
);

# Test the connection to Entra.
$entraConnection = Test-EidConnection `
    -RequiredScope $GraphApiScopes;

# If connection is not valid.
if ($false -eq $entraConnection)
{
    # Write to log.
    Write-CustomLog -Message ('Please connect to Entra using the following code:') -Level 'Warning' -NoLogLevel $true -NoDateTime;
    Write-CustomLog -Message ("Connect-Entra -Scopes '{0}' -NoWelcome -ContextScope Process" -f ($GraphApiScopes -join "', '")) -Level 'Warning' -NoLogLevel $true -NoDateTime;
    Write-CustomLog -Message ('After connecting to Entra, import the module again using the following:') -Level 'Warning' -NoLogLevel $true -NoDateTime;
    Write-CustomLog -Message ('Import-Module -Name "{0}"' -f $script:ModuleName) -Level 'Warning' -NoLogLevel $true -NoDateTime;

    # Throw exception.
    throw ('Authentication needed. Please call Connect-Entra.');
}

# Foreach function in the public functions.
foreach ($exportFunction in $publicFunctions)
{
    # Write to log.
    Write-CustomLog -Message ("Exporting the function '{0}'" -f $exportFunction) -Level Verbose;
}

<# Export functions.
Export-ModuleMember `
    -Function $publicFunctions `
    -ErrorAction SilentlyContinue;#>