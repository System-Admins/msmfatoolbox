function Test-EntraConnection
{
    <#
    .SYNOPSIS
        Test if entra connection is valid.
    .DESCRIPTION
        Return true or false based on if a valid connection to Entra is established.
    .EXAMPLE
        Test-EntraConnection;
    #>
    [cmdletbinding()]
    [OutputType([bool])]
    param
    (
    )

    BEGIN
    {
        # Write to log.
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation 'Test Microsoft Entra connection';

        # Boolean to store result.
        [bool]$connected = $false;

        # Required Entra scopes.
        $requiredScopes = @(
            'Policy.Read.All',
            'GroupMember.Read.All',
            'User.Read.All',
            'RoleManagement.Read.All',
            'Mail.Send'
        );
    }
    PROCESS
    {
        # Try to get entra context.
        try
        {
            # Get entra context.
            $entraContext = Get-EntraContext -ErrorAction Stop;

            # If context is not null.
            if($null -ne $entraContext)
            {
                # Required scopes is in the context.
                $requiredScopesValid = $true;

                # Foreach required scope.
                foreach ($requiredScope in $requiredScopes)
                {
                    # If scope is not in the context.
                    if ($requiredScope -notin $entraContext.Scopes)
                    {
                        # Write to log.
                        Write-CustomLog -Message ('The required scope "{0}" is not in the context' -f $requiredScope) -Level 'Verbose';

                        # Set to false.
                        $requiredScopesValid = $false;
                    }
                }

                # If all required scopes is in the context.
                if ($requiredScopesValid)
                {
                    # Set to true.
                    $connected = $true;
                }
            }
        }
        catch
        {
            # Set to false.
            $connected = $false;
        }
    }
    END
    {
        # Write to log.
        Write-CustomProgress @customProgress;

        # Return result.
        return $connected;
    }
}