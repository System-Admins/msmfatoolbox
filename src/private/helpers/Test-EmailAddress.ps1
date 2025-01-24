function Test-EmailAddress
{
    <#
    .SYNOPSIS
        Test if input is a valid email address.
    .DESCRIPTION
        Uses .NET method to test if input is a valid email address.
        Returns true if input is a valid, otherwise false.
    .PARAMETER InputObject
        Email such as "abc@contoso.com" (without quotes).
    .EXAMPLE
        Test-EmailAddress -InputObject "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108"
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
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation 'Test e-mail address';

        # Is valid.
        [bool]$isValid = $false;
    }
    PROCESS
    {
        # Try to parse input as email address.
        try
        {
            # Test if input is a valid email address.
            [void][System.Net.Mail.MailAddress]::new($InputObject);

            # If input is a valid email address.
            $isValid = $true;

            # Write to log.
            Write-CustomLog -Message ("Input '{0}' is a valid e-mail address" -f $InputObject) -Level 'Verbose';
        }
        catch
        {
            # Write to log.
            Write-CustomLog -Message ("Input '{0}' is not a valid e-mail address" -f $InputObject) -Level 'Verbose';
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