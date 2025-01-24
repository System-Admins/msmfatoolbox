function Test-Guid
{
    <#
    .SYNOPSIS
        Test if input is a guid.
    .DESCRIPTION
        Uses .NET method to test if input is a guid.
        Returns true if input is a guid, otherwise false.
    .PARAMETER InputObject
        Guid format such as "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108" (without quotes).
    .EXAMPLE
        Test-Guid -InputObject "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108"
    #>
    [cmdletbinding()]
    [OutputType([bool])]
    param
    (
        # Backup path.
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$InputObject
    )

    BEGIN
    {
        # Write to log.
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation 'Test GUID';
    }
    PROCESS
    {
        # Test if input is a guid.
        [bool]$isValid = [guid]::TryParse($InputObject, $([ref][guid]::Empty));

        # If input is a guid.
        if($true -eq $isValid)
        {
            # Write to log.
            Write-CustomLog -Message ("Input '{0}' is a GUID" -f $InputObject) -Level 'Verbose';
        }
        else
        {
            # Write to log.
            Write-CustomLog -Message ("Input '{0}' is not a GUID" -f $InputObject) -Level 'Verbose';
        }
    }
    END
    {
        # Write to log.
        Write-CustomProgress @customProgress;

        # Return result.
        return $isValid;
    }
}