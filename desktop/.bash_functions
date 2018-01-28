abediff ()
{
    for i in "$@";
    do
        ediff $AROOT$i $BROOT$i;
    done
}

aliases ()
{
    OLDIFS="$IFS";
    export IFS="|";
    args="$*";
    export IFS="$OLDIFS";
    alias | egrep "^alias [^=]*($args)[^=]*="
}

allcalls()
{
    TMPF=${TMPDIR:=/tmp}/allcalls.$$
    trap "rm -f $TMPF.*;trap - 0 1 2 3 15;return 1" 0 1 2 3 15
    jcgs $1 >$TMPF.1
    shift
    calls $TMPF.1 "$@" >$TMPF.2
    oldcount=0
    newcount=$(wc -l <$TMPF.2)
    while ((newcount != oldcount))
    do calls $TMPF.1 $(cat $TMPF.2) >>$TMPF.2;sort -o $TMPF.2 -u $TMPF.2
       ((oldcount = newcount))
       newcount=$(wc -l <$TMPF.2)
    done
    cat $TMPF.2
    rm -f $TMPF.*
    trap - 0 1 2 3 15
}

appendExistingPath()
{
    dirlist=
    for dir in "$@";
    do
        if   [[ -d "$dir" ]]
        then dirlist="$dirlist $dir";
        fi
    done;
    if [[ -n ${dirlist## } ]]
    then set $dirlist;
         appendPath "$@"
    fi
}

appendPath ()
{
    for dir in "$@";
    do
        if inPath "$dir"; then
            :;
        else
            PATH="$PATH:$dir";
        fi;
    done
}

calls ()
{
    file=$1
    shift
    for method in "$@";
    do
        method=${method%\$[0-9]*};
        sed -e "/ .*$method.*$/"'!d' -e 's///' \
	    -e 's/^[MC]://' \
	    -e 's/$[1-9][0-9]*$//' \
	    -e 's/$[1-9][0-9]*:/:/' $file;
    done
}

cediff ()
{
    NEW=$1;
    OLD=${NEW%/*}/.#${NEW##*/}*;
    set $OLD;
    if (($# != 1)); then
        ls -FC -1tr $OLD | tail -1 | read OLD;
    fi;
    echo ediff of $OLD $NEW;
    ediff $OLD $NEW
}

checkConflictsResolved ()
{
    files=$(git status|sed -e '/both [am][a-z]*:/!d' -e 's/^.*both [am][a-z]*: *//');
    conflicts=$(egrep -l  '^(<<<<<<< |=======$|>>>>>>> )' $files);
    count=$(echo "$conflicts" | grep -v '^$'|wc -l);
    if (( count == 0 )); then
        echo No unresolved conflicts;
    fi;
    if (( count == 1 )); then
        echo One unresolved conflict file $conflicts;
    fi;
    if (( count > 1 )); then
        echo Multiple unresolved conflict files:;
        echo "$conflicts";
    fi
}

cleanup ()
{
    rm -f *~ .*~
}

cls ()
{
    sed -e 's/, /,\
/g' "$@"
}

CR ()
{
    for i in "$@";
    do
        if [[ $i = ${i#[1-9]} ]]; then
            open "$CR_URL/$i";
        else
            open "$CR_URL/CR-$i";
        fi;
    done
}

# This defines datenow one of two ways, depending on the OS to
# account for variations in how the command arguments to parse dates
# work. NOTE that this requires an argument, and is really an internal
# funciton. Used todate instead.
case $(uname -s) in
    Linux)  datenow() {
                 now=$1
                 shift
                 if [[ $now = ${now##*-} ]]
                 then date -d @$now "$@"
                 else date -d "$now 00:00:00" "$@"
                 fi
             }
            ;;

    Darwin) datenow() {
                  now=$1
                  shift
                  if [[ $now = ${now##*-} ]]
                  then date -r $now "$@"
                  else date -j -f "%Y-%m-%d %H:%M:%S" "$now 00:00:00" "$@"
                  fi
              }
            ;;
    *)      echo 1>&2 "$ME: will only run properly on Linux or Mac OSX systems"
            exit 1
            ;;
esac

deepclone ()
{
    if   [[ -z "$GIT_CLONE_PREFIX" ]]
    then echo 1.&2 "deepclone: Please set GIT_CLONE_PREFIX first"
	 return 1;
    fi

    for i in "$@";
    do
        echo -n "Cloning ${i}... ";
	if   [[ ${i%%/*} = $i ]]
	then echo 1>&2 "No namespach specified, assuming ${GIT_TEAM:-global}"
	     sleep 5
	     gitpath=${GIT_TEAM:-global}/${i%%.git}
	else gitpath=${i%%.git}
	fi
        git clone $GIT_CLONE_PREFIX${gitpath}.git ~/src/${gitpath};
        echo -n "Making ~/src/$gitpath unshallow...";
        ( cd ~/src/${gitpath};
        git fetch --unshallow );
        echo "Done with $gitpath";
    done
}

did ()
{
    echo "$(date '+%F T %T %Z'): $*" >> ~/DONE
}

diffToFiles()
{
    grep '^diff' | sed -e 's,^.*git a/,,' -e 's, b/.*$,,'
}

dkh ()
{
    (for i in $*;
     do  echo $i;
    done | sort -nru | sed -e 's/$/d/';
    echo w;
    echo q ) | ed ~/.ssh/known_hosts
}

dumpFunctions ()
{
    for f in $(functions "$@"|sed -e 's/()//g');
    do
        type $f | sed -e 1d;
    done
}

dumpVariables ()
{
    OLDIFS="$IFS";
    export IFS="|";
    args="$*";
    export IFS="$OLDIFS";
    set | egrep "^($args)[^=]*="| sed -e 's/^/export /' -e "s/=/='/" -e "s/$/'/"
}

ediff ()
{
    emacs -eval "(ediff-files \"$1\" \"$2\")" &
}

ff ()
{
    grep "^[^ ]* \(\) $" "$@"
}

ffmOn ()
{
    defaults write com.apple.Terminal FocusFollowsMouse -boolean YES;
    defaults write org.x.X11 wm_ffm -boolean true
}

ffmOff ()
{
    defaults write com.apple.Terminal FocusFollowsMouse -boolean NO;
    defaults write org.x.X11 wm_ffm -boolean false
}

functions ()
{
    OLDIFS="$IFS";
    export IFS="|";
    args="$*";
    export IFS="$OLDIFS";
    set | egrep "^[^ ]*($args)[^ ]* \(\) $"
}

getval(){
    # parses var=val with possible spaces tabs, " and '.  Actually,
    # get the shell to do the work. But pull the correct line.
    #
    # Arg 1 is the variable to get, arg 2 is the lines from which to
    # get them.
    eval $(echo "$2" | tr '\t' ' ' |sed -e "/^ *$1 *= */"'!d' -e 's//echo /')
}

git2vps ()
{
    if   [[ -z $GIT_VPS_SCP_PATH ]]
    then echo 1>&2 "git2vps: you must set GIT_VPS_SCP_PATH first"
	 return 1
    fi

    (cd $(git root)
     if [[ ! -f .git/config ]]; then
	 echo 'Not within a git archive or "git root" not defined.' 1>&2;
	 echo '(To define "git root" type:' 1>&2
	 echo "    git config --global --add alias.root '!pwd'" 1>&2
	 echo ' to your shell)' 1>&2
	 return 1;
     fi;
     for i in $(git status --porcelain | cut -c 4-);
     do
	 if   [[ -d $i ]]
	 then dir=${i%/*/}
	      scp -r $i $GIT_VPS_SCP_PATH/$dir;
	 else scp $i $GIT_VPS_SCP_PATH/$i
	 fi
     done)
}

gitCrucible ()
{
    export CR=$1
    if [[ $CR != ${CR#-} ]]
    then echo 1>&2 "Usage: gitCrucible [existing-CR]"
	 echo 1>&2 "  uses $(git root)/.git/reviewers for reviewers"
	 echo 1>&2 "  anchors repository and gets the review title from"
	 echo 1>&2 "  your last git commit. So commit first"
	 return 1
    fi
    (cd $(git root)
     if [[ ! -f .git/config ]]; then
	 echo 'Not within a git archive or "git root" not defined.' 1>&2;
	 echo '(To define "git root" type:' 1>&2
	 echo "    git config --global --add alias.root '!pwd'" 1>&2
	 echo ' to your shell)' 1>&2
	 return 1;
     fi;
     repository=$(sed -e '/url/!d' \
                      -e 's/^.*://' -e s'/\.git$//' .git/config)
     if [[ -z $CR ]]
     then # New review, set it up
	 reviewers=
	 if [[ .git/reviewers ]]
	 then for reviewer in $(sed -e 's/#.*$//' -e '/^$/d' .git/reviewers)
	      do reviewers="$reviewers @$reviewer"
	      done
	      reviewers=${reviewers# }
	 fi
	 title=$(git log -1 --oneline)
	 mytitle=$(git log -1 --author=$(id -nu) --oneline)
	 if [[ $title != $mytitle ]]
	 then echo "The last commit is not yours, commit first." 1>&2
	      return 1
	 fi
	 title=$(echo "$title" | sed -e 's/^[^ ]* //' -e "s/'/'\"'\"'/g")
	 TMPF=${TMPDIR:=/tmp}/gitCrucible.$$
	 trap "rm -f $TMPF.*;trap - 0 1 2 3 15;return 1" 0 1 2 3 15
	 GIT="gitDiffFilesToReview"
	 CRUCIBLE="crucible.py -m '$title' -r '$repository' CR $reviewers"
	 echo "$GIT | $CRUCIBLE" >>$TMPF.1
	 echo Edit the command line. Empty file aborts.
	 ${VISUAL:-${EDITOR:-ed}} $TMPF.1
	 if [[ -z $TMPF.1 ]]
	 then echo "File '$TMPF.1' empty, review aborted" 1>&2
	      return 1
	 fi
	 if (($(sed -e 's/#.*$//' -e '/^$/d' $TMPF.1 | wc -l) == 0))
	 then echo "File '$TMPF.1' empty, review aborted" 1>&2
	      return 1
	 fi
	 source $TMPF.1
	 rm -f $TMPF.*
	 trap - 0 1 2 3 15
     else # this is an increment
	 gitDiffFilesToReview | crucible.py -r "$repository" $CR
     fi
    )
}

gitDiffFilesToReview ()
{
    branch=$(git branch -q| sed -e '/^\*/!d' -e 's/^\*.//')
    config=$(git root)/.git/config
    section=$(sed -e "/^\[branch *\"$branch\"]/,/^\[/"'!d' $config)
    if [[ -z $section ]]
    then echo 1>&2 "There is no tracking information for branch '$branch'"
	 echo 1>&2 "To set this branch to track origin/master, do this:"
	 echo 1>&2 "    git branch --set-upstream-to=origin/master $branch"
	 return 1
    fi
    remote=$(getval remote "$section")
    merge=$(getval merge "$section")
    git diff $remote/${merge#refs/heads/}
}

gitFilesToReview ()
{
    gitDiffFilesToReview | diffToFiles
}

gitLabCrucible ()
{
    export CR=$1
    if [[ $CR != ${CR#-} ]]
    then echo 1>&2 "Usage: gitLabCrucible [existing-CR]"
	 echo 1>&2 "  uses $(git root)/.git/reviewers for reviewers"
	 echo 1>&2 "  anchors repository and gets the review title from"
	 echo 1>&2 "  your last git commit. So commit first"
	 return 1
    fi
    (cd $(git root)
     if [[ ! -f .git/config ]]; then
	 echo 'Not within a git archive or "git root" not defined.' 1>&2;
	 echo '(To define "git root" type:' 1>&2
	 echo "    git config --global --add alias.root '!pwd'" 1>&2
	 echo ' to your shell)' 1>&2
	 return 1;
     fi;
     repository=$(sed -e '/url/!d' \
                      -e 's/^.*://' -e s'/\.git$//' .git/config)
     # remove the first compoent gitlab added that crucible doesn't
     # know about.
     repository=${repository#*/}
     if [[ -z $CR ]]
     then # New review, set it up
	 reviewers=
	 if [[ .git/reviewers ]]
	 then for reviewer in $(sed -e 's/#.*$//' -e '/^$/d' .git/reviewers)
	      do reviewers="$reviewers @$reviewer"
	      done
	      reviewers=${reviewers# }
	 fi
	 title=$(git log -1 --oneline)
	 mytitle=$(git log -1 --author=$(id -nu) --oneline)
	 if [[ $title != $mytitle ]]
	 then echo "The last commit is not yours, commit first." 1>&2
	      return 1
	 fi
	 title=$(echo "$title" | sed -e 's/^[^ ]* //' -e "s/'/'\"'\"'/g")
	 TMPF=${TMPDIR:=/tmp}/gitCrucible.$$
	 trap "rm -f $TMPF.*;trap - 0 1 2 3 15;return 1" 0 1 2 3 15
	 GIT="gitDiffFilesToReview"
	 CRUCIBLE="crucible.py -m '$title' -r '$repository' CR $reviewers"
	 echo "$GIT | $CRUCIBLE" >>$TMPF.1
	 echo Edit the command line. Empty file aborts.
	 ${VISUAL:-${EDITOR:-ed}} $TMPF.1
	 if [[ -z $TMPF.1 ]]
	 then echo "File '$TMPF.1' empty, review aborted" 1>&2
	      return 1
	 fi
	 if (($(sed -e 's/#.*$//' -e '/^$/d' $TMPF.1 | wc -l) == 0))
	 then echo "File '$TMPF.1' empty, review aborted" 1>&2
	      return 1
	 fi
	 source $TMPF.1
	 rm -f $TMPF.*
	 trap - 0 1 2 3 15
     else # this is an increment
	 gitDiffFilesToReview | crucible.py -r "$repository" $CR
     fi
    )
}

gitMarkConflictsResolved ()
{
   git add $(git status|sed -e '/both [am][a-z]*:/!d' -e 's/^.*both [am][a-z]*: *//')
}

hostClass()
{
    HOST=$(uname -n);
    HOST_CORP=${HOST%%.$CORP_DOMAIN};
    HOST_CLASS=${HOST_CORP##*.};
    echo $HOST_CLASS
}

inPath ()
{
    if [[ "$1" == "$PATH" ]]; then
        return 0;
    fi;
    if [[ "${PATH%*:$1}" != "$PATH" ]]; then
        return 0;
    fi;
    if [[ "${PATH##$1:*}" != "$PATH" ]]; then
        return 0;
    fi;
    if [[ "${PATH##*$1:*}" != "$PATH" ]]; then
        return 0;
    fi;
    return 1
}

issue ()
{
    for i in "$@";
    do
        open "$ISSUE_URL/$i";
    done
}

cff ()
{
  grep -n "^[_a-zA-Z0-9* 	]*([][_a-zA-Z0-9* 	,]*)[^;]*$" "$@"
}

jff ()
{
    grep '^[^-+*/{[(=~!@#$%^&`":;<>?,.|\'\'']*[A-Za-z_][A-Za-z_0-9]*[ 	][ 	]*[A-Za-z_][A-Za-z_0-9]*(' "$@"
}

lastlog ()
{
    HEAD=$1;
    TAIL=$2;
    N=`lastver "$HEAD" "$TAIL"`;
    if [ -n "$N" ]; then
        echo ${HEAD}${N}${TAIL};
    else
        echo $N;
    fi
}

lastver ()
{
    HEAD=$1;
    TAIL=$2;
    N=`/bin/ls -1 ${HEAD}[0-9]*${TAIL} 2>/dev/null | \
    		sed -e "s ^$HEAD  " -e "s $TAIL\$  " | sort -nr | head -1`;
    echo $N
}

lognohup ()
{
    LOGFILE=`logof "$@"`;
    nohup ${SHELL:-/bin/sh} -c "uname -a;pwd;date;$@;date" > $LOGFILE 2>&1 &
}

lognull ()
{
    LOGFILE=`logof "$@"`;
    ( uname -a;
    pwd;
    date;
    "$@";
    date ) > $LOGFILE 2>&1
}

logof ()
{
    LOG=`echo "$*" | cat -tv | tr -d '\"#$&'\''()*;<>?[]^\`{|}~\\\' |
		tr ' /' '.%;'`;
    nextlog ${LOGDIR:-${TMPDIR:-$HOME}}/${LOG}. ${TAIL:-.log}
}

logtail ()
{
    TAILFILE=`logof "$@"`;
    nohup ${SHELL:-/bin/sh} -c "uname -a;pwd;date;$*;date" > $TAILFILE 2>&1 & tail -f $TAILFILE
}

logtee ()
{
    TEEFILE=`logof "$@"`;
    ( uname -a;
    pwd;
    date;
    "$@";
    date ) 2>&1 | tee $TEEFILE
}

ltl ()
{
    LD=${LOGDIR:-${TMPDIR:-$HOME}};
    LOGFILE=`/bin/ls -1tr $LD|tail -${1:-1}|head -1`;
    echo $LOGFILE;
    tail -f $LOGFILE
}

mergeConflictEdit ()
{
 ${VISUAL} $(git status|sed -e '/both [am][a-z]*:/!d' -e 's/^.*both [am][a-z]*: *//')
}

mirrorSites ()
{
    ( export LOGDIR=.;
    for site in "$@";
    do
        wget -m -k -K -E -o `logof $site` -p $site &
    done;
    wait )
}

nextlog ()
{
    HEAD=$1;
    TAIL=$2;
    N=`lastver "$HEAD" "$TAIL"`;
    if [ -z "$N" ]; then
        N=0;
    else
        N=`expr $N + 1`;
    fi;
    echo ${HEAD}${N}${TAIL}
}

onallfiles ()
{
    find . -type f -print | egrep -v "$ALLFILESEXCEPT" | tr '\n' '\0' | \
	xargs -0 "$@"
}

onallvps() {
    for i in $(cat $VPSNAMEFILE)
    do ssh -x -n $(id -nu)-$i.vps.$CORP_DOMAIN "$*" | sed -e "s/^/$i: /"
    done
}

ppjson ()
{
    python -m json.tool
}

prependExistingPath ()
{
    for dir in "$@";
    do
	if   [[ -d "$dir" ]]
	then dirlist="$dirlist $dir";
	fi
    done;
    set $dirlist;
    prependPath "$@"
}

prependPath ()
{
    dirlist="$1";
    shift;
    for dir in "$@";
    do
        dirlist="$dir $dirlist";
    done;
    set $dirlist;
    for dir in "$@";
    do
        if inPath "$dir"; then
            :;
        else
            PATH="$dir":$PATH;
        fi;
    done
}

ratio ()
{
    num=$1;
    denom=$2;
    echo "9k $num $denom /pq" | dc
}

reverseHost ()
{
    # Silly, text based fun
    echo "$@" | sed '/\n/!G;s/\(.\)\(.*\n\)/&\2\1/;//D;s/.//'
}

rmlastlog ()
{
    HEAD=$1;
    TAIL=$2;
    rm $HEAD`lastver $HEAD $TAIL`$TAIL
}

serve ()
{
    python -m SimpleHTTPServer $1
}

spiderSites ()
{
    ( export LOGDIR=.;
    for site in "$@";
    do
        wget --spider -m -k -K -E -o `logof $site` -p $site &
    done;
    wait )
}

sql ()
{
    DB=${DB:=$DEFAULT_DB}
    CONF_DIR=${CONF_DIR:=$DEFAULT_CONF_DIR}
    DBHOST=${DBHOST:=$DB.$DEFAULT_DBDOMAIN}
    CONF_FILE=${CONF_DIR}/$DB.conf

    HOST=$(uname -n);
    HOST_CORP=${HOST%%.$CORPDOMAIN};
    HOST_CLASS=${HOST_CORP##*.};
    if [[ -f $CONF_FILE ]]; then
        if grep -q -s "^$HOST_CLASS.$DB" $CONF_FILE; then
            CONN=$(sed -e "/^$HOST_CLASS.$DB.*{/,/^}/"'!d' $CONF_FILE);
        else
            CONN=$(sed -e "/^$DB.*{/,/^}/"'!d' $CONF_FILE);
        fi;
        user=$(getval user "$CONN");
        password=$(getval password "$CONN");
        url=$(getval url "$CONN");
        hostport=${url#*://};
        hostport=${hostport%%/*};
        host=${hostport%:*};
        port=${hostport#*:};
        if [[ $port = $hostport ]]; then
            port=$DEFAULT_PORT;
        fi;
        mysql -D fulfillment -B -h "$host" -P "$port" -u "$user" --password="$password" -e "$*";
    else
        ssh -n -x $DBHOST "sudo -H mysql -D fulfillment -B -e '$*'";
    fi
}

sqlin ()
{
    in=;
    for i in "$@";
    do
        in="$in, '$i'";
    done;
    in=${in#, };
    echo $in
}

svc ()
{
    for s in "$@";
    do
        grep "\W$s/" /etc/services;
    done
}

taillog ()
{
    HEAD=$1;
    TAIL=$2;
    tail -f $HEAD`lastver $HEAD $TAIL`$TAIL
}

ticket ()
{
    for i in "$@";
    do
        if [[ $i = ${i#[1-9]} ]]; then
            open "$TICKET_URL/$i";
        else
            open "$TICKET_URL/${DEFAULT_TICKET_PREFIX}-$i";
        fi;
    done
}

todate(){
    datenow $(date +%s) "$@"
}

tomorrowdate() {
    tomorrownow $(date +%s) "$@"
}

tomorrownow() {
    # Like datenow, but rolls forward a day first. Handles leap
    # seconds, too. Start by converting the date to epoch seconds
    now=$(datenow $1 +%s)
    shift
    # roll forward a day 24(h/d) * 60(m/h) * 60(s/m) = 86400 s/d
    tomorrownow=$((now + 86400))
    # handle leap seconds. If tomorrownow and now, both in epoch
    # seconds, still fall on the same day, roll forward tomorrownow one
    # second at a time until they don't
    while [[ "$(datenow $now +%d)" = "$(datenow $tomorrownow  +%d)" ]]
    do ((tomorrownow++))
    done
    datenow $tomorrownow "$@"
}

tsv2json() {
    echo "{ "
    cs=
    for i in "$@"
    do  echo -n "$cs\"$i\": ["
        cs=", "
        comma=
        headers=($(head -1 $i))       # load array with headers
        sed -e 1d $i | while read line
        do echo $comma
           comma=,
           echo -n "{ "
            col=0;echo "$line" | tr '\t' '\n' | while read field
           do echo -n "\"${headers[col++]}\": \"$field\""
              if ((col < ${#headers[@]}))
              then echo -n ", "
              fi
           done
           echo -n " }"
        done
        echo -n " ]"
    done
    echo " }"
}

variables ()
{
    OLDIFS="$IFS";
    export IFS="|";
    args="$*";
    export IFS="$OLDIFS";
    set | egrep "^[_a-zA-Z0-9]*($args)[_a-zA-Z0-9]*="
}

xcd ()
{
    cd $1;
    host=`uname -n`;
    PWD=`pwd`;
    xttitle $host $PWD;
    xticon `echo $host| sed -e 's/\..*//'` `basename $PWD`
}

xticon ()
{
    echo -n "]1;$*"
}

xtlabel ()
{
    xticon "$*";
    xttitle "$*"
}

xttitle ()
{
    echo -n "]2;$*"
}

yesterdate() {
    yesternow $(date +%s) "$@"
}

yesternow() {
    # Like datenow, but backs up a day first. Handles leap seconds,
    # too. Start by converting the date to epoch seconds.
    now=$(datenow $1 +%s)
    shift
    # back up a day 24(h/d) * 60(m/h) * 60(s/m) = 86400 s/d
    yesternow=$((now - 86400))
    # handle leap seconds. If yesternow and now, both in epoch
    # seconds, still fall on the same day, back up yesternow one
    # second at a time until they don't
    while [[ "$(datenow $now +%d)" = "$(datenow $yesternow  +%d)" ]]
    do ((yesternow--))
    done
    datenow $yesternow "$@"
}
authExport ()
{
    echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > ~/.ssh/auth_socket
}
authImport ()
{
    source ~/.ssh/auth_socket
}
hfs ()
{
    cmd=$1;
    shift;
    hadoop fs -$cmd "$@"
}
hfsGetFromShared()
{
    for i in "$@"
    do hadoop distcp -pb -update $HDFS_SHARED/$i $i
    done
}
onallnodes ()
{
    for i in $(yarn node -list 2>/dev/null|sed -e 1,2d -e 's/:.*$//' );
    do ssh $i "$@" 2>&1 | sed -e "s/^/$i: /"
    done
}
distYarnSite()
{
    for i in $(cat ~/nodes.txt);
    do  scp /etc/hadoop/conf/yarn-site.xml $i:/tmp;
        ssh $i "sudo mv /tmp/yarn-site.xml /etc/hadoop/conf/";
        ssh $i yarn resourcemanager stop
        ssh $i sudo /etc/init.d/hadoop-yarn-nodemanager restart
    done
    sudo /etc/init.d/hadoop-yarn-resourcemanager restart
}

getApplicationId ()
{
    sed -e '/Application .* has started running./!d' -e 's/^.*: Application //' -e 's/ has started running.$//' $1
}
wlogs ()
{
    for file in "$@";
    do
        yarn logs --applicationId $(getApplicationId "$file");
    done
}
hki ()
{
    USER=$(id -nu);
    KEYTAB=/etc/hadoop/conf/$USER.keytab;
    PRINCIPAL=$(klist -k $KEYTAB | fgrep $USER | sed -e 's/^.* //' -e '$!d');
    kinit -k -t $KEYTAB $PRINCIPAL
}
finderShowHiddenFiles ()
{
    defaults write com.apple.finder AppleShowAllFiles TRUE
}
gitfixup ()
{
    git commit -a --fixup=$(git rev-parse HEAD);
}
gitpwb ()
{
    git branch | sed -e '/^\* /!d' -e 's///';
}
pff ()
{
    egrep --color=auto "^[ 	]*def[ 	]+[a-zA-Z0-9_]+\(" "$@"
}
bff ()
{
    egrep "^[^ ]* *\(\) *$" "$@"
}
gittag2commit ()
{
    git show --format=format:"commit %H (%D)" "$@" | grep '^commit'
}
ghc ()
{
    ( cd ~/github;
    group=$1 project=$2;
    if [[ ! -d $group ]]; then
        mkdir $group;
    fi;
    cd $group;
    git clone git@github.com:$group/$project.git )
}
