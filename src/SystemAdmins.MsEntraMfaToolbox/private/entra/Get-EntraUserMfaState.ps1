function Get-EntraUserMfaState
{
    <#
    .SYNOPSIS
        Get Entra user mfa state (disabled, enabled or enforced).
    .DESCRIPTION
        Retrieve the MFA state for a user in Entra ID.
    .PARAMETER Id
        The Entra user ID.
    .EXAMPLE
        Get-EntraUserMfaState;
    .EXAMPLE
        Get-EntraUserMfaState -Id 9117d4d2-db51-439b-8f18-0de64c24bc68;
    #>
    [cmdletbinding()]
    [OutputType([pscustomobject[]])]
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
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation 'Get Entra user MFA state';

        # If Id is not null.
        if (-not [string]::IsNullOrEmpty($Id))
        {
            # Get all users.
            $entraUsers = Get-EntraUser -UserId $Id;
        }
        else
        {
            # Get all users.
            $entraUsers = Get-EntraUser -All;
        }

        # Get MFA user states.
        $authenticationMethodUserRegistrationDetails = Get-MgReportAuthenticationMethodUserRegistrationDetail -All;

        # Result object.
        $users = @();
    }
    PROCESS
    {
        # Write to log.
        Write-CustomLog -Message ('Found {0} Entra users' -f $entraUsers.Count) -Level 'Verbose';

        # Foreach user.
        foreach ($entraUser in $entraUsers)
        {
            # Try to get user state.
            try
            {
                # Request user state from Graph API.
                $userState = Invoke-MgGraphRequest -Method GET -Uri ('https://graph.microsoft.com/beta/users/{0}/authentication/requirements' -f $entraUser.Id) -OutputType PSObject -ErrorAction Stop;
            }
            catch
            {
                # Write to log.
                Write-CustomLog -Message ("Failed to get state for user '{0}', exception was: `r`n{1}" -f $entraUser.UserPrincipalName) -Level 'Verbose';

                # Continue to next user.
                continue;
            }

            # If user state is null.
            if ($null -eq $userState)
            {
                # Continue to next user.
                continue;
            }

            # Write to log.
            Write-CustomLog -Message ("User state for '{0}' is '{1}'" -f $entraUser.userPrincipalName, $userState.perUserMfaState) -Level 'Verbose';

            # Get user registration details.
            $userRegistrationDetails = $authenticationMethodUserRegistrationDetails | Where-Object { $_.Id -eq $entraUser.Id };

            # Object to store the user.
            $user = [PSCustomObject]@{
                Id                = $entraUser.Id;
                DisplayName       = $entraUser.DisplayName;
                UserPrincipalName = $entraUser.UserPrincipalName;
                AccountType       = $userRegistrationDetails.UserType;
                AccountEnabled    = $entraUser.accountEnabled;
                PerUserMfaState   = $userState.perUserMfaState;
                IsMfaCapable      = $userRegistrationDetails.IsMfaCapable;
                IsMfaRegistered   = $userRegistrationDetails.IsMfaRegistered;
                IsAdmin           = $userRegistrationDetails.IsAdmin;
            };

            # Add to result.
            $users += $user;
        }
    }
    END
    {
        # Write to log.
        Write-CustomProgress @customProgress;

        # If users is empty.
        if ($users.Count -eq 0)
        {
            # Throw exception.
            throw ('No user state were found');
        }

        # Return result.
        return $users;
    }
}