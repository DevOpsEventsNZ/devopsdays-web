# You will need to make sure you have your C drive (or whatever drive you have the devopsdays code on) shared in Docker
# To expose these functions you will need to dot source this file '. .\hugoserver.ps1'


<#
.SYNOPSIS
Starts the hugo container on Windows with a hack/means to trigger the
Hugo Watch command when running Hugo in server mode. This allows for
faster feedback when developing locally on Windows with a container.

.DESCRIPTION
The Hugo watch native functionality does not work when runnning Hugo
in a container on Windows. See Notes for the details as to why. This
function will start the Hugo container, bind the volume and then wait
to execute a command in the container to trigger Hugo Watch functionality.

The command to trigger the watch will append "# Watch Triggered" to the
data file you're working on. This data file is determined by the Year
and City parameters provided to the function.

Side effects may include these addtional comments appended to the data file,
but it is presumed these comments will be cleaned up before the City's data
file PR is created.

Docker on windows has some non trivial constraints around Inotify.
The file notications do not work across the files systems between windows
and the Linux(Moby VM) where the containers run. See
https://github.com/docker/for-win/issues/56 for more information.

There have been some utilities created that provide work arounds, namely
https://github.com/merofeev/docker-windows-volume-watcher. This also fails
to work becuase the Hugo server implmentation discards CHMOD file change
events as noted here https://github.com/gohugoio/hugo/issues/4054. There are
plans to support this for Hugo, but the timeline reamins uncertain.

.EXAMPLE
Invoke-Hugo -Year 2019 -City auckland

.LINK
https://github.com/docker/for-win/issues/56

.LINK
https://github.com/merofeev/docker-windows-volume-watcher/issues/4

.LINK
https://github.com/gohugoio/hugo/issues/4054.

#>

function Invoke-HugoWatch {
  [CmdletBinding()]
  param (
    <# Conference Year - used to determine data file #>
    [Parameter(Mandatory=$true)]
    [string] $Year,

    <# Conference City (case sensitive) - used to determine data file #>
    [Parameter(Mandatory=$true)]
    [string] $City
  )

  begin {
    $confDataFile = "$Year-$City.yml"
    $confDataPath = Join-Path -Path 'data/events' -ChildPath $confDataFile
    if (!(Test-Path $confDataPath)){
      Write-Host -ForegroundColor Yellow "The data file $confDataPath could not be found. Please check filename"
      break
    }
  }

  process {
    Start-Hugo

    $nixDataFilePath = "data/events/$confDataFile"
    $tripWatchCommand = "echo '# Watch Triggered' >> $nixDataFilePath"

    while ($true) {
      $key = Read-Host 'Enter any key to trigger Hugo Watch. Q or q to stop container...'

      if ($key -eq 'Q' -or $key -eq 'q') {
        Write-Host 'Now stopping...'
        break
      }

      docker exec hugo-server sh -c ($tripWatchCommand)
    }
  }

  end {
    Stop-Hugo
  }
}

function Get-ContainerCommand {
  [CmdletBinding()]
  param (

  )

  begin {
  }

  process {
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = 'C:\repo\DevOpsEventsNZ\devopsdays-web\'
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true

    $updated = {Write-Host "File: " $EventArgs.FullPath " " $EventArgs.ChangeType; $global:UpdateEvent = $EventArgs}

    if($ChangedEvent) {$ChangedEvent.Dispose()}

    $ChangedEvent = Register-ObjectEvent $watcher "Changed" -Action $updated


    while ($true) {
      $key = Read-Host 'Enter any key to trigger Hugo Watch. Q or q to stop container...'

      if ($key -eq 'Q' -or $key -eq 'q') {
        Write-Host 'Now stopping...'
        break
      }
    }
  }
  end {
    if($ChangedEvent) {$ChangedEvent.Dispose()}
  }
}

function Start-Hugo {
  [CmdletBinding()]
  param ()

  begin {
    $MyPath = $PSScriptRoot
    $ErrorActionPreference = "Stop"
  }

  process {
    try{
      $command = docker run -d --rm -p 1313:1313 -v ${MyPath}:/src -e HUGO_WATCH=1 -e HUGO_BASEURL="http://localhost:1313" --name hugo-server jojomi/hugo:0.53

      $checkContainer = docker ps -a -q --filter name=hugo-server

      if(!($checkContainer)){
        Write-Host -ForegroundColor Red "An error occured trying to start the hugo-server container. Check Docker is working"
        break
      }
    }
    catch {
      Write-Host -ForegroundColor Red "An error occured trying to start the hugo-server container"
      Write-Host $_
    }

  }

  end {
  }
}

function Stop-Hugo {
  [CmdletBinding()]
  param ()

  begin {}

  process {
    docker stop hugo-server
  }

  end {}
}
