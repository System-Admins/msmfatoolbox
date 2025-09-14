function Get-EidConditionalAccessPolicy
{
    <#
    .SYNOPSIS
        Get all conditional access policies from Microsoft Entra ID.
    .DESCRIPTION
        Sanitize the results to include only relevant information.
    .EXAMPLE
        Get-EidConditionalAccessPolicy;
    #>
    [cmdletbinding()]
    [OutputType([System.Collections.ArrayList])]
    param
    (
    )

    begin
    {
        # Write to log.
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation 'Retrieving conditional access policies from Microsoft Entra ID';

        # New arraylist to store results.
        $results = New-Object -TypeName System.Collections.ArrayList;

        # Get all conditional access policies.
        $entraConditionalAccessPolicies = Get-EntraConditionalAccessPolicy;
    }
    process
    {
        # Forach conditional access policy.
        foreach ($entraConditionalAccessPolicy in $entraConditionalAccessPolicies)
        {
            # Create result object.
            $result = [PSCustomObject]@{
                Id               = $entraConditionalAccessPolicy.Id;
                DisplayName      = $entraConditionalAccessPolicy.DisplayName;
                State            = '';
                Description      = $entraConditionalAccessPolicy.Description;
                CreatedDateTime  = $entraConditionalAccessPolicy.CreatedDateTime;
                ModifiedDateTime = $entraConditionalAccessPolicy.ModifiedDateTime;
                Users            = $null;
                TargetResources  = $null;
                Network          = $null;
                Conditions       = $null;
                Grant            = $null;
                Session          = $null;
            };

            # Set state.
            switch ($entraConditionalAccessPolicy.State)
            {
                # If the policy is enabled.
                'enabled'
                {
                    # Set state to Enabled.
                    $result.State = 'Enabled';
                }
                # If the policy is disabled.
                'disabled'
                {
                    # Set state to Disabled.
                    $result.State = 'Disabled';
                }
                # If the policy is enabled for reporting but not enforced.
                'enabledForReportingButNotEnforced'
                {
                    # Set state to ReportOnly.
                    $result.State = 'ReportOnly';
                }
            }

            # Get user assignment.
            $result.Users = Get-EidConditionalAccessPolicyUser `
                -PolicyId $entraConditionalAccessPolicy.Id;

            # Get target resources.
            $result.TargetResources = Get-EidConditionalAccessPolicyTargetResource `
                -PolicyId $entraConditionalAccessPolicy.Id;

            # Get network.
            $result.Network = Get-EidConditionalAccessPolicyNetwork `
                -PolicyId $entraConditionalAccessPolicy.Id;

            # Get conditions.
            $result.Conditions = Get-EidConditionalAccessPolicyCondition `
                -PolicyId $entraConditionalAccessPolicy.Id;

            # Get grant.
            $result.Grant = Get-EidConditionalAccessPolicyGrant `
                -PolicyId $entraConditionalAccessPolicy.Id;

            # Get session.
            $result.Session = Get-EidConditionalAccessPolicySession `
                -PolicyId $entraConditionalAccessPolicy.Id;

            # Add result to results arraylist.
            $null = $results.Add($result);
        }
    }
    end
    {
        # Write to log.
        Write-CustomProgress @customProgress;

        # Return results.
        return $results;
    }
}