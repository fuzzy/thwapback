#!/bin/sh
#set -x

# This will grab our configuration from a file instead of the environment. Cron works better this way
CONFIG_FILE=${TB_CONFIG_FILE:="${HOME}/.thwapback"}
if test -e ${CONFIG_FILE}; then
    source ${CONFIG_FILE}
elif test ! -e ${CONFIG_FILE} && test "${1}" != "install"; then
    printf "\033[1;31m!!\033[0m Missing configuration, please run '${0} install'.\n" >/dev/stderr
    exit 1
fi

# These can be set via environment variables, otherwise, here are the defaults
#
# Our base backup directory
BASE_D=${SOURCE_DIR:="${HOME}/"}
# Our target directory to backup
TARGET_D=${TARGET_DIR:="${HOME}/.backups"}

OSSL_ARGS="-des3 -base64 -pass pass:$(hostname -s) -pbkdf2"
# Our settings for maximum number of XXX type of backups.
MAX_HOURLIES=${MAX_HOURLIES:=6}
MAX_DAILIES=${MAX_DAILIES:=7}
MAX_WEEKLIES=${MAX_WEEKLIES:=4}
MAX_MONTHLIES=${MAX_MONTHLIES:=6}
MAX_YEARLIES=${MAX_YEARLIES:=5}
MAX_RANDOMS=${MAX_RANDOMS:=5}

# Exclude directives go here
EXCLUDES=${IGNORE_DIR:=""}

# our command can be in a special custom place, or we'll find it if it's there
BORG_CMD=${BORG_CMD:=$(which borg 2>/dev/null || echo NONE)}
if test ! -z "${SOURCE_DIR}"; then
    export BORG_PASSPHRASE=$(echo ${TARGET_PP}|openssl enc -d ${OSSL_ARGS})
fi

# get our backup type from the commandline, or it's absence
test -z "${BKUP_CMD}" && BKUP_CMD=${1}

borg_cmd() {
    mout=$(${BORG_CMD} ${@} 2>&1)
    case "${mout}" in
        (*PASSPHRASE*)
            printf "\033[1;31m!!\033[0m Invalid password.\n" >/dev/stderr
            exit 1
            ;;
        (*not\ a\ valid*)
            printf "\033[1;32m>>\033[0m Initializing ${TARGET_D}\n" >/dev/stderr
            out=$(${BORG_CMD} init -e keyfile ${TARGET_D} 2>&1)
            if test $? -ne 0; then
                printf "\033[1;31m!!\033[0m Could not initialize ${TARGET_D}.\n" >/dev/stderr
                echo ${out} >/dev/stderr
                exit 1
            fi
            mout=$(${BORG_CMD} ${@} 2>&1)
            ;;
    esac
    echo ${mout}
}

bkup_pruner() {
    case "${1}" in
        (hourly) max=${MAX_HOURLIES} ;;
        (daily)  max=${MAX_DAILIES}  ;;
        (weekly) max=${MAX_WEEKLIES} ;;
        (yearly) max=${MAX_YEARLIES} ;;
        (*)      max=${MAX_RANDOMS}  ;;
    esac
    tot=$(${BORG_CMD} list ${TARGET_D}|grep ${1}|wc -l)
    if test ${tot} -gt ${max}; then
        tod=$((${tot} - ${max}))
        for tag in $(${BORG_CMD} list ${TARGET_D}|awk '{print $1}'|grep ${1}|sort|head -n${tod}); do
            test ! -z "${OUTPUT_ARGS}" && printf "\033[1;32m>>\033[0m Deleting backup tag: ${tag}\n"
            ${BORG_CMD} delete ${TARGET_D}::${tag}
        done
    fi
}

bkup_installer() {
    printf "\033[1;32m>>\033[0m Installing thBackup\n" >/dev/stderr
    printf "\033[1;32m>>\033[0m What directory will be backed up: " >/dev/stderr
    SOURCE_DIR=$(read -r ans; echo -n ${ans})
    printf "\033[1;32m>>\033[0m What directory will we back up to: " >/dev/stderr
    TARGET_DIR=$(read -r ans; echo -n ${ans})
    printf "\033[1;32m>>\033[0m What directories should we exclude: " >/dev/stderr
    IGNORE_DIR=$(read -r ans; echo -n ${ans})
    printf "\033[1;32m>>\033[0m What passphrase should we encrypt with: " >/dev/stderr
    PASSPHRASE=$(read -rs ans; echo -n ${ans}|openssl enc -e ${OSSL_ARGS})
    cat >${CONFIG_FILE} <<EOF
# What directory do we backup to, for example:
# TARGET_DIR="\${USER}@backup.host:/borg/\$(hostname -s)/\${USER}"
TARGET_DIR="${TARGET_DIR}"

# What directory we're backing up, for example:
# SOURCE_DIR="\${HOME}"
SOURCE_DIR="${SOURCE_DIR}"

# What directories should be excluded from the backups:
# IGNORE_DIR="\${HOME}/.wine/ \${HOME}/Downloads/"
IGNORE_DIR="${IGNORE_DIR}"

# Our encrypted passphrase
TARGET_PP="${PASSPHRASE}"

# Our snapshot retention limits
MAX_HOURLIES=${MAX_HOURLIES}
MAX_DAILIES=${MAX_DAILIES}
MAX_WEEKLIES=${MAX_WEEKLIES}
MAX_YEARLIES=${MAX_YEARLIES}
MAX_RANDOMS=${MAX_RANDOMS}
EOF
    printf "\n\033[1;32m>>\033[0m Please check ${CONFIG_FILE} for further customization.\n" >/dev/stderr
    test -e ${CONFIG_FILE} && source ${CONFIG_FILE}
    export BORG_PASSPHRASE=$(echo ${PASSPHRASE}|openssl enc -d ${OSSL_ARGS})
    # and init the remote archive
    printf "\033[1;32m>>\033[0m Initialize ${TARGET_DIR}\n" >/dev/stderr
    ${BORG_CMD} init -e keyfile ${TARGET_DIR}
    exit 0
}

case "${1}" in
    (hourly)  BKUP_TAG="hourly-$(date +%s)"  ;;
    (daily)   BKUP_TAG="daily-$(date +%s)"   ;;
    (weekly)  BKUP_TAG="weekly-$(date +%s)"  ;;
    (monthly) BKUP_TAG="monthly-$(date +%s)" ;;
    (yearly)  BKUP_TAG="yearly-$(date +%s)"  ;;
    (install) bkup_installer                 ;;
    (info)
        ${BORG_CMD} list ${TARGET_D}
        echo '------------------------------------------------------------------------------'
        ${BORG_CMD} info ${TARGET_D}
        exit 0
        ;;
    (help|-h|--help)
        cat >/dev/stderr <<EOF
$(basename ${0}) <COMMAND>

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

EOF
        exit 0
        ;;
    (*)       BKUP_TAG="random-$(date +%s)"  ;;
esac

# generate our exclude arguments
EXCLUDE_ARGS=""
for exclude in ${EXCLUDES}; do
    EXCLUDE_ARGS="${EXCLUDE_ARGS} -e ${exclude}"
done

# generate our output arguments
OUTPUT_ARGS=""
test -t 0 && OUTPUT_ARGS="--stats --progress"

# check to see if our backup already exists
if test -z "$(borg_cmd list ${TARGET_D}|grep ${BKUP_TAG})"; then
    test ! -z "${OUTPUT_ARGS}" && printf "\033[1;32m>>\033[0m Creating backup tag: ${BKUP_TAG}\n"
    ${BORG_CMD} create ${EXCLUDE_ARGS} ${OUTPUT_ARGS} ${TARGET_D}::${BKUP_TAG} ${BASE_D}/
else
    printf "\033[1;31m!!\033[0m This backup tag (${BKUP_TAG}) already exists.\n"
fi

bkup_pruner ${BKUP_CMD}
