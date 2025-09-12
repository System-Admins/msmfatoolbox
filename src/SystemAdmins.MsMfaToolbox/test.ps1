# Get all conditional access policies.
$conditionalAccessPolicies = Get-EidConditionalAccessPolicy;

# Get Entra users.
$entraUsers = (Get-EntraUser -Property UserPrincipalName -All).UserPrincipalName;

# Object array to store policies that require multi-factor authentication.
$policiesRequiringMfa = @();

# Foreach conditional access policy.
foreach ($conditionalAccessPolicy in $conditionalAccessPolicies)
{
    #}
    # If the conditional access policy is not enabled.
    if ('Enabled' -ne $conditionalAccessPolicy.State)
    {
        # Write to log.
        Write-CustomLog -Message ("Skipping conditional access policy '{0}', because it's not enabled" -f $conditionalAccessPolicy.DisplayName) -Level 'Verbose';

        # Continue to the next conditional access policy.
        #continue;
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
    $policiesRequiringMfa += $conditionalAccessPolicy;
}

# Object array to store users that are exempted from multi-factor authentication.
$usersExemptedFromMfa = @();

# Foreach Entra user.
foreach ($entraUser in $entraUsers)
{
    # Boolean if user is a guest.
    [bool]$isGuestUser = $false;

    # If the Entra user is a guest user.
    if ($entraUser -like '*#EXT#@*')
    {
        # Set boolean to true.
        $isGuestUser = $true;
    }

    # Object array to store policies that is targeting the user.
    $policiesTargetingUser = @();

    # Foreach conditional access policy that require multi-factor authentication.
    foreach ($policyRequiringMfa in $policiesRequiringMfa)
    {
        # If the user is a guest user and the conditional access policy exclude one or more guest types.
        if ($true -eq $isGuestUser -and $policyRequiringMfa.Users.ExcludeGuestsOrExternalUsersTypes.Count -gt 0)
        {
            # Write to log.
            Write-CustomLog -Message ("User '{0}' is excluded from conditional access policy '{1}'" -f $entraUser, $policyRequiringMfa.DisplayName) -Level 'Verbose';

            # Continue to the next conditional access policy.
            continue;
        }

        # If the user is targeted by the conditional access policy.
        if ($entraUser -in $policyRequiringMfa.Users.TargetedUsers)
        {
            # Write to log.
            Write-CustomLog -Message ("User '{0}' is targeted by conditional access policy '{1}'" -f $entraUser, $policyRequiringMfa.DisplayName) -Level 'Verbose';

            # Add the conditional access policy to the object array.
            $policiesTargetingUser += $policyRequiringMfa;
        }
    }

    # If the user is not targeted by any conditional access policy that require multi-factor authentication.
    if ($policiesTargetingUser.Count -eq 0)
    {
        # Write to log.
        Write-CustomLog -Message ("User '{0}' is not targeted by any conditional access policy that require multi-factor authentication" -f $entraUser) -Level 'Verbose';

        # Add the user to the object array.
        $usersExemptedFromMfa += $entraUser;
    }
}

$usersExemptedFromMfa