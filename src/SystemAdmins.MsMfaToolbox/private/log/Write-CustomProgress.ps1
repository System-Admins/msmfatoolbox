function Write-CustomProgress
{
    <#
    .SYNOPSIS
        Write progress to the screen.
    .DESCRIPTION
        Wrap Write-Progress used in the module.
    .PARAMETER Activity
        Name of the activity.
    .PARAMETER CurrentOperation
        Current operation.
    .PARAMETER Type
        Start or end.
    .EXAMPLE
        $progress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation 'Getting all certificate';
        Write-CustomProgress -Id $progress -Activity $MyInvocation.MyCommand.Name -CurrentOperation 'Getting all certificate' -Type 'End';

    #>
    [cmdletbinding()]
    [OutputType([hashtable])]
    param
    (
        # Name of the function.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Activity = $MyInvocation.MyCommand.Name,

        # Current operation.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CurrentOperation,

        # Begin or end.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Begin', 'End')]
        [string]$Type = 'Begin',

        # Id of the progress.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$ProgressId = (Get-Random -Minimum 0 -Maximum ([int]::MaxValue))
    )

    BEGIN
    {
        # Create splat to return.
        [hashtable]$splat = @{
            ProgressId       = $ProgressId;
            Activity         = $Activity;
            CurrentOperation = $CurrentOperation;
            Type             = 'End';
        };
    }
    PROCESS
    {
        # If type is "Start".
        if ($Type -eq 'Begin')
        {
            # Write to log.
            Write-CustomLog -Message ("Begin processing '{0}' with ID '{1}'" -f $Activity, $ProgressId) -Level Verbose;

            # Write progress.
            Write-Progress -Id $ProgressId -Activity $Activity -CurrentOperation $CurrentOperation;
        }
        # Else if type is "End".
        else
        {
            # Write progress.
            Write-Progress -Id $ProgressId -Activity $Activity -CurrentOperation $CurrentOperation -Completed;

            # Write to log.
            Write-CustomLog -Message ("Ending process '{0}' with ID '{1}'" -f $Activity, $ProgressId) -Level Verbose;
        }
    }
    END
    {
        # If type is "Begin".
        if ($Type -eq 'Begin')
        {
            # Return splat.
            return $splat;
        }
    }
}