#!/bin/bash

VERBOSITY=30
function debug() { [[ $VERBOSITY -le 10 ]] && echo "$@" ; }
function info() { [[ $VERBOSITY -le 20 ]] && echo "$@" ; }
function warning() { [[ $VERBOSITY -le 30 ]] && echo "$@" ; }
function error() { [[ $VERBOSITY -le 40 ]] && echo "$@" ; }

function help() {
	warning "Usage ./breaker.sh [-h] [options] [FILE]"
	warning "  Perform X no-ops by appending APPENDAGE to every file given,"
	warning "  then do a breaking change by replacing all instances of REG "
	warning "  with REP in all given files, and lastly perform Y no-ops as "
	warning "  as above. Commits after every append and the breaking       "
	warning "  change with the same message M.                             "
	warning "                                                              "
	warning " --help           Show this help message                      "
	warning " --pre X          Perform X no-ops before breaking            "
	warning " --post Y         Perform Y no-ops after breaking             "
	warning " --regex REG      Pattern of what to break                    "
	warning " --replace REP    What to replace with                        "
	warning " --message M      Commit message for every change             "
	warning " --append         What to append to the end as no-ops         "
	warning "      APPENDAGE                                               "
	warning " -v --verbose     Increase verbosity (defaults to warning)    "
	warning " -q --quiet       Only show errors                            "
	warning "                                                              "
}
function short_help() { warning "Usage ./breaker.sh [-h] [options] [FILE]" ; }
function error_message() { error "Invalid usage; at least one file must be specified!" ; }

info "Handling options"
while [[ $1 =~ -[a-z-] ]]
do
	info "Handling option $1"
	case $1 in
		-v|--verbose)
			VERBOSITY=20
			shift
			;;
		-v--verbose)
			VERBOSITY=20
			shift
			;;
		-vv|--very-verbose)
			VERBOSITY=10
			shift
			;;
		-q|--quiet)
			VERBOSITY=40
			shift
			;;
		-h|--help)
			help
			exit 0
			shift
			;;
		--pre)
			shift
			N_PRE=$1
			shift
			;;
		--post)
			shift
			N_POST=$1
			shift
			;;
		--regex)
			shift
			REGEX=$1
			shift
			;;
		--replace)
			shift
			REPLACE=$1
			shift
			;;
		--message)
			shift
			COMMIT_MESSAGE=$1
			shift
			;;
		--append)
			shift
			APPEND=$1
			shift
			;;
		-n|--dry)
			DRY=true
			shift
			;;
		--cheat)
			CHEAT=true
			shift
			;;
	esac
done

info "Setting defaults"
CHEAT=${CHEAT:-false}
REGEX=${REGEX:-a}
REPLACE=${REPLACE:-b}
N_PRE=${N_PRE:-100}
N_POST=${N_POST:-200}
[[ -n $1 ]] && TARGET=("$@")
[[ "${#TARGET[@]}" -eq 0 ]] && TARGET=("${TARGET[@]:-bbup.cpp}")
COMMIT_MESSAGE=${COMMIT_MESSAGE:-"breaker.sh breaking"}
APPEND=${APPEND:-//breaker.sh}
DRY=${DRY:-false}
GIT_VERBOSITY=''
[[ $VERBOSITY -ge 10 ]] && GIT_VERBOSITY='-vv'
[[ $VERBOSITY -ge 20 ]] && GIT_VERBOSITY='-v'
[[ $VERBOSITY -ge 30 ]] && GIT_VERBOSITY=''
[[ $VERBOSITY -ge 40 ]] && GIT_VERBOSITY='-q'

[[ "${#TARGET[@]}" -eq 0 ]] && error_message && short_help && exit 1

info "Pre-breaking"
for (( i = 0; i <= N_PRE; i++ ))
do
	for f in "${TARGET[@]}"
	do
		debug "Breaking (pre) round $i in file $f"
		[[ $DRY == true ]] && continue
		echo "$APPEND" >> "$f"
		git commit $GIT_VERBOSITY -am "$COMMIT_MESSAGE" 2>/dev/null
	done
done

info "Breaking"
for f in "$@"
do
	debug "Breaking change in file $f"
	[[ $DRY == true ]] && continue
	sed --in-place='' "s/$REGEX/$REPLACE/g" "$f"
	old="$COMMIT_MESSAGE"
	[[ $CHEAT == true ]] && COMMIT_MESSAGE="--- BREAKING CHANGE ---"
	git commit $GIT_VERBOSITY -am "$COMMIT_MESSAGE" 2>/dev/null
	COMMIT_MESSAGE="$old"
done

info "Post-breaking"
for (( i = 0; i <= N_POST; i++ ))
do
	for f in "${TARGET[@]}"
	do
		debug "Breaking (post) round $i in file $f"
		[[ $DRY == true ]] && continue
		echo "$APPEND" >> "$f"
		git commit $GIT_VERBOSITY -am "$COMMIT_MESSAGE" 2>/dev/null
	done
done

info "DONE"
