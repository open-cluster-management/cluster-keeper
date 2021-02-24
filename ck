#!/usr/bin/env bash
set -e -o posix

trap "exit 1" TERM
export TOP_PID=$$

DIR=$(dirname $(readlink $0 || echo $0))
. $DIR/lib/common.sh
SUBCOMMANDS=$(ls $DIR/subcommands)
for subcommand in $SUBCOMMANDS
do
  . $DIR/subcommands/$subcommand
done

function usage {
  errEcho "usage: $(basename ${0}) [OPTIONS] SUBCOMMAND"
  errEcho
  errEcho "    SUBCOMMAND is one of the following."
  errEcho
  for subcommandFile in $SUBCOMMANDS
  do
    local subcommand=$(basename $subcommandFile .sh)
    local subcommandFunction=$(echo "$subcommand" | tr '-' '_')
    errEcho "    $subcommand"
    errEcho "        $(${subcommandFunction}_description)"
  done
  errEcho
  errEcho "    The following OPTIONS are available:"
  errEcho
  errEcho "    -h    Display usage for SUBCOMMAND"
  errEcho "    -v    Verbosity level for information printed to stderr. Default: 0"
  errEcho
  abort
}

while getopts :v:h o 
do case "$o" in
  h)  HELP="true";;
  v)  VERBOSITY="$OPTARG";;
  [?]) usage;;
  esac
done
shift $(($OPTIND - 1))

subcommand="$1"
[[ -n $subcommand && -f $DIR/subcommands/${subcommand}.sh ]] || usage

subcommandFunction=$(echo "$subcommand" | tr '-' '_')
shift

if [[ -n $HELP ]]
then
  ${subcommandFunction}_usage
else
  if [[ -n $KUBECONFIG ]]
  then
    verbose -1 "WARNING: KUBECONFIG is set and is being ignored by $(basename ${0})"
    unset KUBECONFIG
  fi
  verifyContext $CLUSTERPOOL_CONTEXT_NAME
  $subcommandFunction "$@"
fi
