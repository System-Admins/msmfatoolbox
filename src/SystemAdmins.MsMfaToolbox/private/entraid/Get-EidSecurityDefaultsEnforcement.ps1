function Get-EidSecurityDefaultsEnforcement
{
    <#
    .SYNOPSIS
        Get Entra security defaults.
    .DESCRIPTION
        Returns true or false if security defaults are enabled.
    .EXAMPLE
       Get-EidSecurityDefaultsEnforcement;
    #>
    [cmdletbinding()]
    [OutputType([bool])]
    param
    (
    )

    begin
    {
        # Write to log.
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation ('Retrieving Entra security default state');

        # Boolean to store result.
        [bool]$isEnabled = $false;
    }
    process
    {
        # Get security defaults.
        $policy = Invoke-MgGraphRequest `
            -Method GET `
            -Uri 'https://graph.microsoft.com/v1.0/policies/identitySecurityDefaultsEnforcementPolicy' `
            -ErrorAction SilentlyContinue;

        # If policy is null.
        if ($true -eq $policy.IsEnabled)
        {
            # Write to log.
            Write-CustomLog -Message ('Security defaults are enabled') -Level 'Verbose';

            # Set result to true.
            $isEnabled = $true;
        }
        else
        {
            # Write to log.
            Write-CustomLog -Message ('Security defaults are disabled or not found') -Level 'Verbose';

        }
    }
    end
    {
        # Write to log.
        Write-CustomProgress @customProgress;

        # Return result.
        return $isEnabled;
    }
}