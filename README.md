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

## Examples

### Cli usage

```
$ thwapback.sh info
daily-1691583424                     Wed, 2023-08-09 05:17:13 [43f8ff2366e4dfa83bb510e91bf4fe462520a2e275e379afaae7bbc91f3d8f17]
hourly-1691586001                    Wed, 2023-08-09 06:00:06 [79723b3e41c8b7b85766c7820a1f8548ce97e7fa29c705288f527b0e4d7ad129]
------------------------------------------------------------------------------
Repository ID: bdbeb48d8ff22cf02ec9dd6cb064e7574ce9c27c10e4fca9578c17eaeac5a3d1
Location: ...
Encrypted: Yes (key file)
Key file: ....25
Cache: .../.cache/borg/bdbeb48d8ff22cf02ec9dd6cb064e7574ce9c27c10e4fca9578c17eaeac5a3d1
Security dir: .../.config/borg/security/bdbeb48d8ff22cf02ec9dd6cb064e7574ce9c27c10e4fca9578c17eaeac5a3d1
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
All archives:               58.02 GB             48.49 GB             22.50 GB

                       Unique chunks         Total chunks
Chunk index:                  125759               304655

$ thwapback.sh
>> Creating backup tag: random-1691587500
------------------------------------------------------------------------------
Repository: ...
Archive name: random-1691587500
Archive fingerprint: 159c20e68c55024d72e46428b02e3c880deb5e9faa6c8039bfa5ce7d82e127a1
Time (start): Wed, 2023-08-09 06:25:05
Time (end):   Wed, 2023-08-09 06:25:17
Duration: 11.80 seconds
Number of files: 143060
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:               29.01 GB             24.25 GB              7.40 MB
All archives:               87.03 GB             72.74 GB             22.51 GB

                       Unique chunks         Total chunks
Chunk index:                  125840               457036
------------------------------------------------------------------------------
```

### Crontab usage

Thwapback uses the config file located at `${HOME}/.thwapback` by default, this
is pretty straightforward, and allows multiple configurations to be specified.

(*NOTE*: Make sure the user the cron jobs are running as, has appropriate read
permissions for all of the source directories.)

```
# This will be used by everything
USER=fuzzy
PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin

# The THWAP backup jobs
0  * * * * thwapback.sh hourly
10 0 * * * thwapback.sh daily
20 0 * * 0 thwapback.sh weekly
30 0 1 * * thwapback.sh monthly
40 0 1 1 * THWAPBACK_CONFIG=/etc/thwapback/yearly.config thwapback.sh yearly
```
