function Get-RideAlong
{
    Param($StartMonth = 1,$EndMonth = 6, $CSAs)
    $hostcsas = $CSAs
    $guestcsas = $CSAs

    # Create an array of all possible combinations of Host_CSA,Guest_CSA
    [array]$pairidlist = $null
    $pairidlist = foreach ($hostcsa in ($hostcsas | Get-Random -Count 99))
    {
	    foreach ($guestcsa in ($guestcsas | where {$_ -ne $hostcsa}))
        {
            $hostcsa + ',' + $guestcsa
        }
    }

    $months = $StartMonth..$EndMonth | % {(Get-Culture).DateTimeFormat.GetMonthName((Get-Date).AddMonths($_).Month)}

    foreach ($month in $months)
    {   
        [array]$assignedcsas = $null
   
        foreach ($hostcsa in ($hostcsas | Get-Random -Count 99))
        {
            $pairid = $null
            
            $pairid = Get-Random -InputObject ($pairidlist | where {$_ -Like "$hostcsa*" -and $_.Split(',')[1] -notin $assignedcsas})

            $guestcsa = $pairid.Split(',')[1]
                      
            [array]$assignedcsas += $guestcsa

            [pscustomobject]@{
                Month = $month
                Host_CSA = $hostcsa
                Guest_CSA = $guestcsa
                PairId = $pairid
            }
            $pairidlist = $pairidlist | where {$_ -ne $pairid} # Recreate the pairidlist array and remove the utilized PairID
        }
    }
}

function Invoke-TryLoop
{
    # Isaac H. Roitman, 2016
    # Runs a command or scriptblock repeatedly, until it completes with no errors or defined retry thresholds are met

    Param([string]$ScriptBlock,[int]$RetrySeconds,[int]$Retries = 20)
    $stoploop = $false
    [int]$retrycount = 0
    
    do
    {
	    try 
        {
		    $obj = $null # Ensures that only the last / successful run is returned
            $obj = Invoke-Expression -Command $ScriptBlock -ErrorAction Stop
            Write-Host "Command completed successfully after $retrycount retries!" -ForegroundColor Green
            $stoploop = $true
	    }
	    catch 
        {
		    if ($retrycount -ge $Retries)
            {
			    Write-Host "Could not complete command "$ScriptBlock" after $Retries retries." -ForegroundColor Yellow
			    $stoploop = $true
		    }
		    else 
            {
			    Write-Host "Could not complete command, retrying in $RetrySeconds seconds..." -ForegroundColor Yellow
			    Start-Sleep -Seconds $RetrySeconds
			    $retrycount = $retrycount + 1
		    }
	    }
    }
    until ($stoploop -eq $true)
    return $obj
}

# Below example runs 10 times inside of Invoke-TryLoop, produces 10 successful CSV outputs, with 99 retries before failure and 0 seconds between retries

# 1..10 | % {$run = $_ ; Invoke-TryLoop -ScriptBlock {Get-RideAlong -CSAs (Get-Content C:\TEMP\CSA_List.txt)} -RetrySeconds 0 -Retries 99 | Export-Csv C:\Temp\CSA_Ride_Along_$run.csv -NoTypeInformation}