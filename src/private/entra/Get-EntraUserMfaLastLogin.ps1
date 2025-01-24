function Get-EntraUserMfaLastLogin
{
    <#
    .SYNOPSIS
        Get Entra user last MFA login.
    .DESCRIPTION
        Retrieves the last MFA login by user.
    .PARAMETER UserPrincipalName
        (Optional) The Entra user principal name.
    .EXAMPLE
        Get-EntraUserMfaLogin;
    .EXAMPLE
        Get-EntraUserMfaLogin -UserPrincipalName 'abc@contoso.com';
    #>
    [cmdletbinding()]
    [OutputType([pscustomobject[]])]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$UserPrincipalName
    )

    BEGIN
    {
        # Write to log.
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation 'Get Entra user last login with MFA';

        # Users.
        $users = @();
    }
    PROCESS
    {
        # If user principal name is null.
        if ([string]::IsNullOrEmpty($UserPrincipalName))
        {
            # Get all users.
            $entraUsers = Get-EntraUser -All;

            # Array for storing batches.
            $batches = @();

            # Foreach user.
            foreach ($entraUser in $entraUsers)
            {
                # Add to batch.
                $batches += [PSCustomObject]@{
                    id     = $entraUser.UserPrincipalName;
                    method = 'GET';
                    URL    = ([URI]::EscapeUriString("/auditLogs/signins?&`$filter=UserPrincipalName eq '{0}' and authenticationRequirement eq 'multiFactorAuthentication'&`$top=1" -f $entraUser.UserPrincipalName));
                }
            }

            # Array to store the last login.
            $lastLogins = New-Object -TypeName System.Collections.ArrayList;

            # Initialize batch request body.
            $batchRequestBody = [PSCustomObject]@{
                requests = New-Object -TypeName System.Collections.ArrayList;
            };

            # Process batches in chunks of 20.
            while ($batches.Count -gt 0)
            {
                # Take the first 20 items from the batches.
                $currentBatch = $batches[0..([Math]::Min(19, $batches.Count - 1))]

                # Add to batch request.
                $batchRequestBody.requests += $currentBatch;

                # Remove the processed items from the original batches.
                $batches = $batches[$currentBatch.Count..($batches.Count - 1)];

                # Convert to JSON.
                $body = $batchRequestBody | ConvertTo-Json -Depth 4;

                # Write to log.
                Write-CustomLog -Message ('Fetching results for {0} batches' -f $currentBatch.Count) -Level 'Verbose';

                # Send the requests and make sure to catch the results.
                $results = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/beta/$batch' -Body $body -ContentType 'application/json' -OutputType PSObject -ErrorAction SilentlyContinue;

                # Clear the batch request (prepare for next batch).
                $batchRequestBody.requests = (New-Object -TypeName System.Collections.ArrayList);

                # If results is not null.
                if ($null -ne $results)
                {
                    # Add the results to the last Login array.
                    $lastLogins += $results;
                }

                # Write to log.
                Write-CustomLog -Message ('Still remaining {0} items to run in batch' -f $batches.Count) -Level 'Verbose';
            }

            # Foreach last login.
            foreach ($lastLogin in $lastLogins)
            {
                # Foreach response.
                foreach ($response in $lastLogin.responses)
                {
                    # Get entra user.
                    $entraUser = $entraUsers | Where-Object { $_.UserPrincipalName -eq $response.id };

                    # If user is null.
                    if ($null -eq $entraUser)
                    {
                        # Skip.
                        continue;
                    }

                    # Write to log.
                    Write-CustomLog -Message ("Last MFA login for user '{0}' is '{1}'" -f $entraUser.userPrincipalName, $response.body.value.createdDateTime) -Level 'Verbose';

                    # Add to users.
                    $users += [PSCustomObject]@{
                        UserPrincipalName = $entraUser.UserPrincipalName;
                        LastMfaLogin      = $response.body.value.createdDateTime;
                    }
                }
            }
        }
        # Else get user by user principal name.
        else
        {
            # Try to get user sign in log.
            try
            {
                # Write to log.
                Write-CustomLog -Message ('Getting sign in log for user "{0}"' -f $UserPrincipalName) -Level 'Verbose';

                # URI.
                $uri = ("https://graph.microsoft.com/beta/auditLogs/signins?&`$filter=UserPrincipalName eq '{0}' and authenticationRequirement eq 'multiFactorAuthentication'&`$top=1" -f $UserPrincipalName)

                # Request user sign in from Graph API.
                $userSignIn = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject -ErrorAction Stop;

                # Write to log.
                Write-CustomLog -Message ('Successfully retrieved sign in log for user "{0}"' -f $UserPrincipalName) -Level 'Verbose';
            }
            # Something went wrong with getting the sign in log.
            catch
            {
                # Throw execption.
                throw ("Failed to get sign in log for user '{0}', exception was: `r`n{1}" -f $UserPrincipalName, $_);
            }

            # Write to log.
            Write-CustomLog -Message ("Last MFA login for user '{0}' is '{1}'" -f $UserPrincipalName, $userSignIn.value.createdDateTime) -Level 'Verbose';

            # Add to users.
            $users += [PSCustomObject]@{
                UserPrincipalName = $UserPrincipalName;
                LastMfaLogin      = $userSignIn.value.createdDateTime;
            }
        }
    }
    END
    {
        # Write to log.
        Write-CustomProgress @customProgress;

        # Return result.
        return $users;
    }
}