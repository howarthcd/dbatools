$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
$global:TestConfig = Get-TestConfig

<#
    Unit test is required for any command added
#>
Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object {$_ -notin ('whatif', 'confirm')}
        [object[]]$knownParameters = 'SqlInstance', 'SqlCredential', 'Database', 'ExcludeDatabase', 'IncludeSystemDBs', 'EnableException'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object {$_}) -DifferenceObject $params).Count ) | Should Be 0
        }
    }
}
# Get-DbaNoun
Describe "$CommandName Integration Tests" -Tags "IntegrationTests" {
    BeforeAll {
        $server = Connect-DbaInstance -SqlInstance $TestConfig.instance2
        $db1 = "dbatoolsci_testvlf"
        $server.Query("CREATE DATABASE $db1")
        $needed = Get-DbaDatabase -SqlInstance $TestConfig.instance2 -Database $db1
        $setupright = $true
        if ($needed.Count -ne 1) {
            $setupright = $false
            it "has failed setup" {
                Set-TestInconclusive -message "Setup failed"
            }
        }
    }
    AfterAll {
        Remove-DbaDatabase -Confirm:$false -SqlInstance $TestConfig.instance2 -Database $db1
    }

    Context "Command actually works" {
        $results = Measure-DbaDbVirtualLogFile -SqlInstance $TestConfig.instance2 -Database $db1

        It "Should have correct properties" {
            $ExpectedProps = 'ComputerName,InstanceName,SqlInstance,Database,Total,TotalCount,Inactive,Active,LogFileName,LogFileGrowth,LogFileGrowthType'.Split(',')
            ($results.PsObject.Properties.Name | Sort-Object) | Should Be ($ExpectedProps | Sort-Object)
        }

        It "Should have database name of $db1" {
            foreach ($result in $results) {
                $result.Database | Should Be $db1
            }
        }

        It "Should have values for Total property" {
            foreach ($result in $results) {
                $result.Total | Should Not BeNullOrEmpty
                $result.Total | Should BeGreaterThan 0
            }
        }
    }
}
