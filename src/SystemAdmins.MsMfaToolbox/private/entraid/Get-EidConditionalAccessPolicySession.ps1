function Get-EidConditionalAccessPolicySession
{
    <#
    .SYNOPSIS
        Get Entra conditional access policy session controls.
    .DESCRIPTION
        Get session controls from a conditional access policy (e.g. app enforced restrictions, sign-in frequency, persistent browser).
    .PARAMETER PolicyId
        Guid format such as "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108" (without quotes).
    .EXAMPLE
       Get-EidConditionalAccessPolicySession -PolicyId "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108";
    #>
    [cmdletbinding()]
    [OutputType([PSCustomObject])]
    param
    (
        # Backup path.
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Guid -InputObject $_ })]
        [string]$PolicyId
    )

    begin
    {
        # Write to log.
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation ('Retrieving Entra conditional access policy session for policy ({0})' -f $PolicyId);

        # Get conditional access policy by id.
        $entraConditionalAccessPolicy = Get-EntraConditionalAccessPolicy `
            -PolicyId $PolicyId `
            -ErrorAction SilentlyContinue;

        # If policy is null.
        if ($null -eq $entraConditionalAccessPolicy)
        {
            # Write to log.
            Write-CustomLog -Message ("No conditional access policy found with ID '{0}'" -f $PolicyId) -Level 'Verbose';

            # Throw exception.
            throw "No conditional access policy found with ID '$PolicyId'";
        }

        # Get session controls.
        $sessionControls = $entraConditionalAccessPolicy.SessionControls;

        # Create custom object.
        $result = [PSCustomObject]@{
            'AppEnforcedRestrictions'         = $false;
            'ConditionalAccessAppControl'     = $false;
            'ConditionalAccessAppControlType' = $null;
            'SignInFrequency'                 = $false;
            'SignInFrequencySettings'         = [PSCustomObject]@{
                'Value'             = $null;
                'Type'              = $null;
                'FrequencyInterval' = $null;
            };
            'PersistentBrowser'               = $false;
            'PersistantBrowserMode'           = $null;
            #'CustomContinuousAccessEvaluation' = $false;
            'ResilientDefault'                = $false;
            #'RequireTokenProtection'          = $false;
            #'GlobalSecureAccessProfile'       = $false;
        };
    }
    process
    {
        # If app enforced restrictions is enabled.
        if ($true -eq $sessionControls.ApplicationEnforcedRestrictions.IsEnabled)
        {
            # Set app enforced restrictions to true.
            $result.AppEnforcedRestrictions = $true;
        }

        # If conditional access app control is enabled.
        if ($true -eq $sessionControls.CloudAppSecurity.IsEnabled)
        {
            # Set conditional access app control to true.
            $result.ConditionalAccessAppControl = $true;

            # Set conditional access app control type.
            $result.ConditionalAccessAppControlType = $sessionControls.CloudAppSecurity.CloudAppSecurityType;
        }

        # If sign-in frequency is enabled.
        if ($true -eq $sessionControls.SignInFrequency.IsEnabled)
        {
            # Set sign-in frequency to true.
            $result.SignInFrequency = $true;

            # Set sign-in frequency settings.
            $result.SignInFrequencySettings.Value = $sessionControls.SignInFrequency.Value;
            $result.SignInFrequencySettings.Type = $sessionControls.SignInFrequency.Type;
            $result.SignInFrequencySettings.FrequencyInterval = $sessionControls.SignInFrequency.FrequencyInterval;
        }

        # If persistent browser is enabled.
        if ($true -eq $sessionControls.PersistentBrowser.IsEnabled)
        {
            # Set persistent browser.
            $result.PersistentBrowser = $true;

            # Set persistent browser mode.
            $result.PersistantBrowserMode = $sessionControls.PersistentBrowser.Mode;
        }

        # If default resilient access is enabled.
        if ($true -eq $sessionControls.ResilientDefault.IsEnabled)
        {
            # Set default resilient access to true.
            $result.ResilientDefault = $true;
        }
    }
    end
    {
        # Write to log.
        Write-CustomProgress @customProgress;

        # Return result.
        return $result;
    }
}