function Get-EidConditionalAccessMfaPolicy
{
    <#
    .SYNOPSIS
        Get Entra conditional access policies that require MFA.
    .DESCRIPTION
        Return conditional access policies that require multi-factor authentication.
    .EXAMPLE
       Get-EidConditionalAccessMfaPolicy;
    #>
    [cmdletbinding()]
    [OutputType([PSCustomObject])]
    param
    (
    )

    begin
    {
        # Write to log.
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation ('Retrieving Entra conditional access policies that require MFA' -f $PolicyId);

        # Get all conditional access policies.
        $conditionalAccessPolicies = Get-EidConditionalAccessPolicy;

        # Object array to store policies that require multi-factor authentication.
        $result = @();
    }
    process
    {
        # Foreach conditional access policy.
        foreach ($conditionalAccessPolicy in $conditionalAccessPolicies)
        {
            # If the conditional access policy is not enabled.
            if ('Enabled' -ne $conditionalAccessPolicy.State)
            {
                # Write to log.
                Write-CustomLog -Message ("Skipping conditional access policy '{0}', because it's not enabled" -f $conditionalAccessPolicy.DisplayName) -Level 'Verbose';

                # Continue to the next conditional access policy.
                continue;
            }

            # If the conditional access does not require multi-factor authentication.
            if ($false -eq $conditionalAccessPolicy.Grant.RequireMfa -and
                $false -eq $conditionalAccessPolicy.Grant.RequireAuthenticationStrength)
            {
                # Write to log.
                Write-CustomLog -Message ("Skipping conditional access policy '{0}', because it do not require MFA" -f $conditionalAccessPolicy.DisplayName) -Level 'Verbose';

                # Continue to the next conditional access policy.
                continue;
            }

            # If the conditional access dont include either all applications or "Office 365" and "Microsoft Admin Portals".
            if ($false -eq $conditionalAccessPolicy.TargetResources.IncludeAllApplications -and
                (($conditionalAccessPolicy.TargetResources.TargetedApplications).DisplayName -notcontains 'Office365' -or
                ($conditionalAccessPolicy.TargetResources.TargetedApplications).DisplayName -notcontains 'MicrosoftAdminPortals'))
            {
                # Write to log.
                Write-CustomLog -Message ("Skipping conditional access policy '{0}', because it do not target all or best-practice cloud applications" -f $conditionalAccessPolicy.DisplayName) -Level 'Verbose';

                # Continue to the next conditional access policy.
                continue;
            }

            # If the conditional access policy does not target all network locations.
            if ($true -eq $conditionalAccessPolicy.Network.IsConfigured -and
                $false -eq $conditionalAccessPolicy.Network.IncludeAnyNetworkOrLocation)
            {
                # Write to log.
                Write-CustomLog -Message ("Skipping conditional access policy '{0}', because it do not target all network locations" -f $conditionalAccessPolicy.DisplayName) -Level 'Verbose';

                # Continue to the next conditional access policy.
                continue;
            }

            # If the conditional access exclude one or more device platforms.
            if ($true -eq $conditionalAccessPolicy.Conditions.DevicePlatforms.IsConfigured -and
                $conditionalAccessPolicy.Conditions.DevicePlatforms.ExcludePlatform.Count -gt 0)
            {
                # Write to log.
                Write-CustomLog -Message ("Skipping conditional access policy '{0}', because it exclude one or more device platforms" -f $conditionalAccessPolicy.DisplayName) -Level 'Verbose';

                # Continue to the next conditional access policy.
                continue;
            }

            # If the conditional access policy exclude one or more client app types.
            if ($true -eq $conditionalAccessPolicy.Conditions.ClientApps.IsConfigured -and
                $conditionalAccessPolicy.Conditions.ClientApps.ExcludedClientApps.Count -gt 0)
            {
                # Write to log.
                Write-CustomLog -Message ("Skipping conditional access policy '{0}', because it exclude one or more client app types" -f $conditionalAccessPolicy.DisplayName) -Level 'Verbose';

                # Continue to the next conditional access policy.
                continue;
            }

            # If the conditional access have user risk condition configured.
            if ($true -eq $conditionalAccessPolicy.Conditions.UserRiskLevels.IsConfigured)
            {
                # Write to log.
                Write-CustomLog -Message ("Skipping conditional access policy '{0}', because it have user risk condition configured" -f $conditionalAccessPolicy.DisplayName) -Level 'Verbose';

                # Continue to the next conditional access policy.
                continue;
            }

            # If the conditional access have sign-in risk condition configured.
            if ($true -eq $conditionalAccessPolicy.Conditions.SignInRiskLevels.IsConfigured)
            {
                # Write to log.
                Write-CustomLog -Message ("Skipping conditional access policy '{0}', because it have sign-in risk condition configured" -f $conditionalAccessPolicy.DisplayName) -Level 'Verbose';

                # Continue to the next conditional access policy.
                continue;
            }

            # Add the conditional access policy to the object array.
            $result += $conditionalAccessPolicy;
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