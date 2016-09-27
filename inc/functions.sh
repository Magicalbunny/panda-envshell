#main functions

#show some messages
function msg(){
    echo `date +"%Y-%m-%d %H:%M:%S"`\("$1"\): "$2"
}

#show info message
function info(){
    msg info "$1"
}

#show warn message
function warn(){
    msg warn "$1"
}

#show error message
function error(){
    msg error "$1"
    exit
}

#show debug message
function debug(){
    if [ $DEBUG -eq 1 ]; then
        msg debug "$1"
    elif [ $DEBUG -eq 2 ]; then
        msg debug "$1"
        read -t 10 -p 'press enter to continue...'
    fi
}

#show help we need
show_help() {
    echo 'Usage: '`basename $1`' -n appname [-v version]'
    echo `basename $1 .sh`' application in the newest or specific version'
    echo '  -n appname'
    echo '  -v specific version'
    echo '  -h show this help'
    exit
}

#parse what todo
parse_bin(){
    while getopts 'n:v:h' arg; do
        case $arg in
            v) BIN_VERSION=$OPTARG
                ;;
            n) BIN_NAME=$OPTARG
                ;;
            h) show_help $0
                ;;
            ?) show_help $0
                ;;
        esac
    done
	
    debug 'app name we got was: '$BIN_NAME
    debug 'app version we got was: '$BIN_VERSION

    if [ -z $BIN_NAME ]; then
        show_help $0
    fi

    EXEC_DIR_ASSEMBLE_BIN=$EXEC_DIR_ASSEMBLE'/'$BIN_NAME
    info 'app assemble dir is: '$EXEC_DIR_ASSEMBLE_BIN
        	
    if [ -d $EXEC_DIR_ASSEMBLE_BIN ]; then
        if [ -z $BIN_VERSION ]; then
            BIN_VERSION=`ls -r $EXEC_DIR_ASSEMBLE_BIN | head -1`
            if [ -z $BIN_VERSION ]; then
                error 'assemble('$BIN_NAME') have no version.'
            fi
            EXEC_DIR_ASSEMBLE_BIN_VERSION=$EXEC_DIR_ASSEMBLE_BIN'/'$BIN_VERSION
            debug 'versioned app assemble dir is: '$EXEC_DIR_ASSEMBLE_BIN_VERSION
        else
            EXEC_DIR_ASSEMBLE_BIN_VERSION=$EXEC_DIR_ASSEMBLE_BIN'/'$BIN_VERSION
            debug 'versioned app assemble dir is: '$EXEC_DIR_ASSEMBLE_BIN_VERSION
            if [ ! -d $EXEC_DIR_ASSEMBLE_BIN_VERSION ]; then
                error 'assemble('$BIN_NAME'), version('$BIN_VERSION') does not exist.'
            fi
        fi
    else
        error 'assemble('$BIN_NAME') does not exist.'
    fi
}

#create dir
function create_dir(){
	debug 'create dir: '$1' start.'
	if [ -d $1 ]; then
		debug 'dir '$1' is exists.'
		if [ ! -z "$2" ]; then
			debug $1' will be cleaned.'
			rm -rf $1
			mkdir -p $1
			chown $ENV_USER:$ENV_GROUP $1 -R
			chmod 0755 $1 -R	
		fi
	else
		mkdir -p $1
		chown $ENV_USER:$ENV_GROUP $1 -R
		chmod 0755 $1 -R
	fi
	debug 'create dir: '$1' successfully.'
}

#load assemble file
function source_assemble_file(){
	EXEC_FILE_ASSEMBLE_BIN_VERSION_FILE=$EXEC_DIR_ASSEMBLE_BIN_VERSION'/'$1
	debug 'load assemble '$1' file: '$EXEC_FILE_ASSEMBLE_BIN_VERSION_FILE'.'
	if [ ! -f $EXEC_FILE_ASSEMBLE_BIN_VERSION_FILE ];then
        	error $EXEC_FILE_ASSEMBLE_BIN_VERSION_FILE' does not exists.'
	fi
	source $EXEC_FILE_ASSEMBLE_BIN_VERSION_FILE
}

#configure app from its template with frame var
#configure_bin $EXEC_DIR_ASSEMBLE_BIN_VERSION'/conf/bashrc' '/etc/bashrc' '#custom bashrc start from here:' '#custom bashrc end here.'
function configure_bin(){
    info 'configure '$2' start.'
    BACK_FILE=$2'.'`date +%s`
    #info $2
    if [ ! -f $2 ];then
        touch $2
    fi
    cp -f $2 $BACK_FILE

    if [ ! -z "$3" ] && [ ! -z "$4" ]; then
        START_LINE=`grep -n "$3" $2 | awk -F '[:]' '{print $1}'`
        END_LINE=`grep -n "$4" $2 | awk -F '[:]' '{print $1}'`
        TOTAL_LINE=`wc -l $1 | awk '{print $1}'`

        if [ -z $START_LINE ]; then
            START_LINE=0
        fi

        if [ -z $END_LINE ]; then
            END_LINE=0
        fi

        if [ -z $TOTAL_LINE ]; then
            TOTAL_LINE=0
        fi

        debug 'START_LINE:'$START_LINE
        debug 'END_LINE:'$END_LINE
        debug 'TOTAL_LINE:'$TOTAL_LINE

        ERROR_MSG='can not parse '$2', file may modified manually.'

        if [ 0 -eq $START_LINE ];then
            if [ 0 -lt $END_LINE ];then
                error "$ERROR_MSG"
            fi
        else
            if [ $START_LINE -gt $END_LINE ] || [ $START_LINE -eq $END_LINE ];then
                error "$ERROR_MSG"
            fi
        fi

        if [ 0 -eq $START_LINE ];then
            echo $3 >> $2
            cat $1 >> $2
            echo $4 >> $2
        else
            head -n $[$START_LINE-1] $BACK_FILE > $2
            echo $3 >> $2
            cat $1 >> $2
            echo $4 >> $2
            tail -n $[$TOTAL_LINE-$END_LINE] $BACK_FILE >> $2
        fi
    else
        if [ -f $1 ];then
            cp -f -p $1 $2
        fi
    fi
    for EXEC_CONFIGURE_NAME in $BIN_CONFIGURE_FRAME_VARS
    do
        eval EXEC_CONFIGURE_VAL="\$$EXEC_CONFIGURE_NAME"
        EXEC_CONFIGURE_SCRIPT='s#{{'$EXEC_CONFIGURE_NAME'}}#'$EXEC_CONFIGURE_VAL'#g'
        sed -i "$EXEC_CONFIGURE_SCRIPT" $2
    done
    for EXEC_CONFIGURE_NAME in $BIN_CONFIGURE_VARS
    do
        eval EXEC_CONFIGURE_VAL="\$$EXEC_CONFIGURE_NAME"
        EXEC_CONFIGURE_SCRIPT='s#{{'$EXEC_CONFIGURE_NAME'}}#'$EXEC_CONFIGURE_VAL'#g'
        sed -i "$EXEC_CONFIGURE_SCRIPT" $2
    done
    info 'configure '$2' success.'
}