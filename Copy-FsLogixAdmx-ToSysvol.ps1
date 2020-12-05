#No matter  how you do it before editing the GPO you must copy the ADM files to the places below.

#This needs to be copied to one of the domain controllers.

$Path = $env:windir+"\PolicyDefinitions"

Copy-Item -Path .\FsLogix\fslogix.admx -Destination $Path -Force

Copy-item -Path .\FsLogix\fslogix.adml -Destination "$Path\en-US" -Force