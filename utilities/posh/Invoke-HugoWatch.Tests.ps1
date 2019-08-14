$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Invoke-HugoWatch" {
    Context "ContextName" {
        It "should assert true is indeed true" {
            $true | Should -Be $true
        }
    }

    Context "Docker Calls" {
        It "should call Start-Hugo once" {
            Mock Test-Path {return $true}
            Mock Start-Hugo { return $true }
            Mock Read-Host { return "q"}
            Mock Stop-Hugo { return $true }
            Invoke-HugoWatch -Year 2019 -City Auckland
            Assert-MockCalled Start-Hugo -Exactly 1
        }

        It "should call Stop-Hugo once" {
            Mock Test-Path {return $true}
            Mock Start-Hugo { return $true }
            Mock Read-Host { return "q"}
            Mock Stop-Hugo { return $true }
            Invoke-HugoWatch -Year 2019 -City Auckland
            Assert-MockCalled Stop-Hugo -Exactly 1 -Scope It
        }
    }

    Context "File Watcher" {
        it "should work" {
            Get-ContainerCommand
        }
    }
}

