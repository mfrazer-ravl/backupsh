# backupsh
Backupsh is a tool to help simplify backing up your network connected devices.

## Locations.cfg
To add a host to locations add a new line and use the following format:
<user-name>@<ip-add>:<directory>

## Backup
To backup your files use the -B flag.

By default -B will backup all locations in locations.cfg.

You can also specify a single line in the locations file by using the -L flag followed by the line of your choice (zero-based indexing)

## Restore
To restore files from your last backup use the -R flag.

By default -R will restore all locations in locations.cfg.

You can also specify a single line in the locations file by using the -L flag followed by the line of your choice (zero-based indexing)

## Phantom Protection
Backup.sh can detect if you have had any paranormal activity occur during your backup. This files will be marked with a .phantom.

To guarantee you do not get a .phantom file restored to your network device use the -I flag while you are restoring.

