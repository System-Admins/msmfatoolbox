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
        [Parameter(Mandatory = $true)]
        [string[]]$RequiredScope
    )

    begin
    {
        # Write to log.
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation 'Testing connection to Microsoft Entra ID';

        # Boolean to store result.
        [bool]$connected = $false;
    }
    process
    {
        # Try to get entra context.
        try
        {
            # Get entra context.
            $entraContext = Get-EntraContext -ErrorAction Stop;

            # If context is not null.
            if ($null -ne $entraContext)
            {
                # Required scopes is in the context.
                $requiredScopeValid = $true;

                # Foreach required scope.
                foreach ($scope in $RequiredScopes)
                {
                    # If scope is not in the context.
                    if ($scope -notin $entraContext.Scopes)
                    {
                        # Write to log.
                        Write-CustomLog -Message ('The required scope "{0}" is not in the context' -f $scope) -Level 'Verbose';

                        # Set to false.
                        $requiredScopeValid = $false;
                    }
                }

                # If all required scopes is in the context.
                if ($true -eq $requiredScopeValid)
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
    end
    {
        # Write to log.
        Write-CustomProgress @customProgress;

        # Return result.
        return $connected;
    }
}