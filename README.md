# thwapback

A simple, but robust shell script, that wraps and manages backups using the borg
utility.

## General

In general, a simple interface is presented. Operation is driven through the
config file, which can be specified by setting the `THWAPBACK_CONFIG` variable
in the environment, or on the command line.

The usage of the script from the cli is defined like so:

```
thwapback.sh <COMMAND>

Backup Commands:

hourly        Tag an hourly backup
daily         Tag a daily backup
weekly        Tag a weekly backup
monthly       Tag a monthly backup
yearly        Tag a yearly backup

Information Commands:

info          Show backup archive Information
help          Show this help

Installation:

install       Run an interactive configuratior
```

## Configuration

An example configuration can be seen below, the retention periods shown are the defaults.

```
# What directory do we backup to, for example:
# TARGET_DIR="/mnt/borg/hostname/username"
TARGET_DIR="${USER}@swordfish:/borg/$(hostname -s)/${USER}"

# What directory we're backing up, for example:
# SOURCE_DIR="/home/username"
SOURCE_DIR="${HOME}"

# What directories should be excluded from the backups:
# IGNORE_DIR="${HOME}/.wine/ ${HOME}/Downloads/"
IGNORE_DIR="${HOME}/.cache/ ${HOME}/.wine/ ${HOME}/.local/share/Steam/ ${HOME}/.arduino/ ${HOME}/.platformio/ ${HOME}/Downloads/ ${HOME}/.cache/"

# Our encrypted passphrase
TARGET_PP="U2FsdGVkX1+XK4D49b40zImJoSi6tnN2srW8guApGL2SX/p6OXpn/CECzIgFFe6/"

# Our snapshot retention limits
MAX_HOURLIES=6
MAX_DAILIES=7
MAX_WEEKLIES=4
MAX_YEARLIES=5
MAX_RANDOMS=5
```

## Crontab usage

Thwapback uses the config file located at `${HOME}/.thwapback` by default, this
is pretty straightforward, and allows multiple configurations to be specified.

(*NOTE*: Make sure the user the cron jobs are running as, has appropriate read
permissions for all of the source directories.)

```
# This will be used by everything
USER=fuzzy
PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin

# The THWAP backup jobs
0  * * * * /home/fuzzy/.local/bin/backup.sh hourly
10 0 * * * /home/fuzzy/.local/bin/backup.sh daily
20 0 * * 0 /home/fuzzy/.local/bin/backup.sh weekly
30 0 1 * * /home/fuzzy/.local/bin/backup.sh monthly
40 0 1 1 * /home/fuzzy/.local/bin/backup.sh yearly
```
