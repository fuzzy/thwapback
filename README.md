# thwapback
A simple, but robust shell script, that wraps and manages backups using the borg
utility.

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
