function Get-EntraConditionalAccessPolicyMfa
{
    <#
    .SYNOPSIS
        Get one or more Entra conditional access policies that require MFA.
    .DESCRIPTION
        Return list of policies that require multi-factor authentication.
    .EXAMPLE
        Get-EntraConditionalAccessPolicyMfa;
    #>
    [cmdletbinding()]
    [OutputType([System.Array])]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Guid -InputObject $_ })]
        [string]$Id
    )

    BEGIN
    {
        # Write to log.
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation 'Get Microsoft Entra conditional access policies that require MFA';

        # If Id is not null.
        if (-not [string]::IsNullOrEmpty($Id))
        {
            # Get conditional access policy.
            $conditionalAccessPolicies = Get-EntraConditionalAccessPolicy -PolicyId $Id -ErrorAction SilentlyContinue;
        }
        else
        {
            # Get conditional access policies.
            $conditionalAccessPolicies = Get-EntraConditionalAccessPolicy;
        }

        # Result object.
        $policies = @();
    }
    PROCESS
    {
        # Write to log.
        Write-CustomLog -Message ('Found {0} conditional access policies' -f $conditionalAccessPolicies.Count) -Level 'Verbose';

        # Foreach conditional access policy.
        foreach ($conditionalAccessPolicy in $conditionalAccessPolicies)
        {
            # Booleans.
            [bool]$requireMfa = $false;
            [bool]$requireAuthenticationStrength = $false;
            [bool]$includeAllApps = $false;

            # If policy requires MFA.
            if ('mfa' -in $conditionalAccessPolicy.GrantControls.BuiltInControls)
            {
                # Set to true.
                $requireMfa = $true;

                # Write to log.
                Write-CustomLog -Message ("Conditional access policy '{0}' requires multi-factor authentication" -f $conditionalAccessPolicy.Id) -Level 'Verbose';
            }

            # Get authentication strengths.
            $authenticationStengths = $conditionalAccessPolicy.GrantControls.AuthenticationStrength;

            # Foreach authentication strength.
            foreach ($authenticationStength in $authenticationStengths)
            {
                # If there is at least one allowed combination.
                if ($authenticationStength.AllowedCombinations.Count -gt 0)
                {
                    # Set to true.
                    $requireAuthenticationStrength = $true;

                    # Write to log.
                    Write-CustomLog -Message ("Conditional access policy '{0}' requires authentication strength using '{1}'" -f $conditionalAccessPolicy.Id, $authenticationStength.DisplayName) -Level 'Verbose';
                }
            }

            # If policy targets all apps.
            if ('All' -in $conditionalAccessPolicy.Conditions.Applications.IncludeApplications -and
                'All' -notin $conditionalAccessPolicy.Conditions.Applications.ExcludeApplications)
            {
                # Set to true.
                $includeAllApps = $true;
            }

            # Array to store apps.
            $apps = @();

            # Foreach app in included.
            foreach ($includedApp in $conditionalAccessPolicy.Conditions.Applications.IncludeApplications)
            {
                # If application is not in excluded.
                if ($includedApp -notin $conditionalAccessPolicy.Conditions.Applications.ExcludeApplications)
                {
                    # Add to array.
                    $apps += $includedApp;
                }
            }

            # Determine if the policy require MFA.
            if ($true -eq $requireMfa -or $true -eq $requireAuthenticationStrength)
            {
                # Object to store the policy.
                $policy = [PSCustomObject]@{
                    Id                     = $conditionalAccessPolicy.Id;
                    Name                   = $conditionalAccessPolicy.DisplayName;
                    State                  = $conditionalAccessPolicy.State;
                    MFA                    = $requireMfa;
                    AuthenticationStrength = $requireAuthenticationStrength;
                    AllApps                = $includeAllApps;
                    Apps                   = $apps;
                };

                # Add to result.
                $policies += $policy;
            }
        }
    }
    END
    {
        # Write to log.
        Write-CustomProgress @customProgress;

        # Return result.
        return $policies;
    }
}