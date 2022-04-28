#!/bin/bash

VERBOSITY=30
function debug() { [[ $VERBOSITY -le 10 ]] && echo "$@" ; }
function info() { [[ $VERBOSITY -le 20 ]] && echo "$@" ; }
function warning() { [[ $VERBOSITY -le 30 ]] && echo "$@" ; }
function error() { [[ $VERBOSITY -le 40 ]] && echo "$@" ; }

function help() {
	warning "Usage ./finder.sh [-h] [options] [COMMAND]"
	warning "  Use git-bisect to find the breaking change. COMMAND is the  "
	warning "  command used, and CLEAN is used before each run of COMMAND. "
	warning "  GOOD indicates the last-good commit, and BAD the last-bad   "
	warning "  commit.                                                     "
	warning "                                                              "
	warning " --help             Show this help message                    "
	warning " --good GOOD        Last good commit (default origin/main)    "
	warning " --bad BAD          Latest bad commit (defaults to current)   "
	warning " --command COMMAND  Command to run for testing commit         "
	warning " --clean CLEAN      Cleaning command to remove e.g. cache     "
	warning "                                                              "
}
function short_help() {
	warning "Usage ./breaker.sh [-h] [options] [FILE]"
}
function error_message() {
	error "Invalid usage; at least one file must be specified!"
}


info "Handling options"
while [[ $1 =~ -[a-z-] ]]
do
	info "Handling option $1"
	case $1 in
		-h|--help)
			help
			exit 0
			;;
		--good)
			GOOD=$1
			shift
			;;
		--bad)
			BAD=$1
			shift
			;;
		--comand)
			COMMAND=$1
			shift
			;;
		--clean)
			CLEAN=$1
			shift
			;;
		*)
			error error_message
			exit 1
			;;
	esac
done

COMMAND=${COMMAND:-bazel build --spawn_strategy=standalone //src:*}
CLEAN=${CLEAN:-bazel clean}
GOOD=${GOOD:-$(git rev-parse origin/main)}
BAD=${BAD:-$(git log -n 1 --format=%h)}

git bisect reset
git bisect start
git bisect good "$GOOD"
git bisect bad "$BAD"
git bisect run sh -c "$CLEAN && $COMMAND"
