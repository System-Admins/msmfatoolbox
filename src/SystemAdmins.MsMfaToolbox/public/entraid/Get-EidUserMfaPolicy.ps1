function Get-EidUserMfaPolicy
{
    <#
    .SYNOPSIS
        Get all user multi-factor authentication conditional access policies from Microsoft Entra ID.
    .DESCRIPTION
        Return users that are exempt from multi-factor authentication (not fully covered).
    .PARAMETER UserPrincipalName
        UserPrincipalName such as "user@domain.com" (without quotes).
        If not specified, all users are returned.
    .PARAMETER OnlyEnabled
        If specified, only enabled users are returned.
    .EXAMPLE
        Get-EidUserMfaPolicy;
    #>
    [cmdletbinding()]
    [OutputType([array])]
    param
    (
        # UserPrincipalName.
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ $_ | ForEach-Object { Test-EmailAddress -InputObject $_ } })]
        [string[]]$UserPrincipalName,

        # Only enabled users.
        [Parameter(Mandatory = $false, Position = 1, ValueFromPipelineByPropertyName = $true)]
        [switch]$OnlyEnabled
    )

    begin
    {
        # Write to log.
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation 'Retrieving user(s) that are exempted from MFA for conditional access policies in Microsoft Entra ID';

        # Get all conditional access policies that require MFA.
        $conditionalAccessPolicies = Get-EidConditionalAccessMfaPolicy;

        # Entra properties to get.
        $entraUserProperties = @('Id', 'UserPrincipalName', 'DisplayName', 'AccountEnabled', 'onPremisesSyncEnabled', 'UserType', 'PasswordPolicies', 'SignInActivity', 'SignInSessionsValidFromDateTime', 'mail', 'proxyAddresses');

        # If only enabled users should be returned.
        if ($true -eq $OnlyEnabled)
        {
            # Write to log.
            Write-CustomLog -Message 'Only enabled users will be returned' -Level 'Verbose';

            # Get Entra (enabled) users.
            $entraUsers = (Get-EntraUser -Filter 'AccountEnabled eq true' -Property $entraUserProperties -All);
        }
        # Else get all users.
        else
        {
            # Write to log.
            Write-CustomLog -Message 'Both enabled and disabled users will be returned' -Level 'Verbose';

            # Get all Entra users.
            $entraUsers = (Get-EntraUser -Property $entraUserProperties -All);
        }

        # Object array to store users.
        $result = @();
    }
    process
    {
        # Foreach Entra user.
        foreach ($entraUser in $entraUsers)
        {
            # Protected by conditional access policy.
            [bool]$isProtectedByMFA = $true;

            # If UserPrincipalName parameter is specified and the user is not in the list.
            if ($PSBoundParameters.ContainsKey('UserPrincipalName') -and
                $entraUser.UserPrincipalName -notin $UserPrincipalName)
            {
                # Write to log.
                Write-CustomLog -Message ("Skipping user '{0}', because it's not in the list of specified users" -f $entraUser.UserPrincipalName) -Level 'Verbose';

                # Set isProtectedByMFA to false.
                $isProtectedByMFA = $false;
            }

            # Object array to store policies that is targeting the user.
            $policiesTargetingUser = @();

            # If there is no conditional access policies that require multi-factor authentication.
            if ($conditionalAccessPolicies.Count -eq 0)
            {
                # Write to log.
                Write-CustomLog -Message ("No conditional access policies require multi-factor authentication, user '{0}' is NOT protected by MFA" -f $entraUser.UserPrincipalName) -Level 'Verbose';

                # Set isProtectedByMFA to false.
                $isProtectedByMFA = $false;
            }

            # Foreach conditional access policy that require multi-factor authentication.
            foreach ($conditionalAccessPolicy in $conditionalAccessPolicies)
            {
                # If the user is a guest user and the conditional access policy exclude one or more guest types.
                if ($entraUser.userType -eq 'Guest' -and $conditionalAccessPolicy.Users.ExcludeGuestsOrExternalUsersTypes.Count -gt 0)
                {
                    # Write to log.
                    Write-CustomLog -Message ("Guest user '{0}' is excluded from conditional access policy '{1}'" -f $entraUser.UserPrincipalName, $conditionalAccessPolicy.DisplayName) -Level 'Verbose';

                    # Set isProtectedByMFA to false.
                    $isProtectedByMFA = $false;
                }

                # If the user is targeted by the conditional access policy.
                if ($entraUser.UserPrincipalName -in $conditionalAccessPolicy.Users.TargetedUsers)
                {
                    # Write to log.
                    Write-CustomLog -Message ("User '{0}' is targeted by conditional access policy '{1}'" -f $entraUser.UserPrincipalName, $conditionalAccessPolicy.DisplayName) -Level 'Verbose';

                    # Add the conditional access policy to the object array.
                    $policiesTargetingUser += $conditionalAccessPolicy;
                }
                # Else user is not targeted by the conditional access policy.
                else
                {
                    # Write to log.
                    Write-CustomLog -Message ("User '{0}' is NOT targeted by conditional access policy '{1}'" -f $entraUser.UserPrincipalName, $conditionalAccessPolicy.DisplayName) -Level 'Verbose';

                    # Set isProtectedByMFA to false.
                    $isProtectedByMFA = $false;
                }
            }

            # Create custom object to store user information.
            $user = [PSCustomObject]@{
                Id                      = $entraUser.Id;
                UserPrincipalName       = $entraUser.UserPrincipalName;
                DisplayName             = $entraUser.DisplayName;
                AccountEnabled          = $entraUser.AccountEnabled;
                DirSyncEnabled          = $false;
                UserType                = '';
                PasswordPolicies        = $entraUser.PasswordPolicies;
                LastSuccessfulSignIn    = $entraUser.SignInActivity.lastSuccessfulSignInDateTime;
                ConditionalAccessPolicy = ($policiesTargetingUser).DisplayName;
                IsProtected             = $false;
                HasMailbox              = $false;
            };

            # If the user is not a guest.
            if ($entraUser.userType -ne 'Guest')
            {
                # If proxyAddresses property is set.
                if ($false -eq [string]::IsNullOrEmpty($entraUser.proxyAddresses))
                {
                    # Boolean to track SMTP address found.
                    [bool]$smtpAddressFound = $false;

                    # Foreach proxy address.
                    foreach ($proxyAddress in $entraUser.proxyAddresses)
                    {
                        # If SMTP address is found, break the loop.
                        if ($true -eq $smtpAddressFound)
                        {
                            # If SMTP address is found, break the loop.
                            break;
                        }

                        # If the proxy address starts with "SMTP:" (primary SMTP address).
                        if ($proxyAddress -like 'SMTP:*')
                        {
                            # Set SMTP address found to true.
                            $smtpAddressFound = $true;
                        }
                    }

                    # If the user has a SMTP address.
                    if ($true -eq $smtpAddressFound)
                    {
                        # Set Mailbox to true.
                        $user.HasMailbox = $true;
                    }
                }
            }

            # If the user is a guest.
            if ($entraUser.UserType -eq 'Guest')
            {
                # Set UserType to Guest.
                $user.UserType = 'Guest';
            }
            # Else if the user is a member.
            elseif ($entraUser.UserType -eq 'Member')
            {
                # If the user principal name dont have '#EXT#@'.
                if ($entraUser.UserPrincipalName -notlike '*#EXT#@*')
                {
                    # Set UserType to Member.
                    $user.UserType = 'Member';
                }
                # Else the user is external.
                else
                {
                    # Set UserType to External.
                    $user.UserType = 'External';
                }
            }

            # If the user is synchronized from on-premises Active Directory.
            if ($true -eq $entraUser.onPremisesSyncEnabled)
            {
                # Set DirSyncEnabled to true.
                $user.DirSyncEnabled = $true;
            }

            # If the user is protected by MFA.
            if ($policiesTargetingUser.Count -gt 0)
            {
                # Write to log.
                Write-CustomLog -Message ("User '{0}' is protected by MFA" -f $entraUser.UserPrincipalName) -Level 'Verbose';

                # Set IsProtected to true.
                $user.IsProtected = $true;
            }
            # Else user is not protected by MFA.
            else
            {
                # Write to log.
                Write-CustomLog -Message ("User '{0}' is NOT protected by MFA" -f $entraUser.UserPrincipalName) -Level 'Verbose';
            }

            # Add the user to the object array.
            $result += $user;
        }
    }
    end
    {
        # Write to log.
        Write-CustomProgress @customProgress;

        # Return results.
        return $result;
    }
}