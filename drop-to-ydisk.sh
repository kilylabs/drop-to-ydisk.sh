#!/bin/sh

install () {

    rm -rf ./Dropbox-Uploader

    echo '### INSTALLING DROPBOX UPLOADER (https://github.com/andreafabrizi/Dropbox-Uploader.git)';
    git clone https://github.com/andreafabrizi/Dropbox-Uploader.git Dropbox-Uploader
    if [ ! $? = 0 ]; then
        echo "Install Dropbox-Uploader failed. Please see console output";
        exit 1
    fi

    echo '### CONFIGURING DROPBOX UPLOADER';
    bash ./Dropbox-Uploader/dropbox_uploader.sh info
    if [ ! $? = 0 ]; then
        echo "Configuring Dropbox-Uploader failed. Please see console output";
        exit 1
    fi

    echo '### DROPBOX UPLOADER INSTALLED';

    echo '### INSTALLING YDCMD (https://github.com/abbat/ydcmd.git)';
    git clone https://github.com/abbat/ydcmd.git ydcmd
    if [ ! $? = 0 ]; then
        echo "Install ydcmd failed. Please see console output";
        exit 1
    fi

    echo '### CONFIGURING YDCMD';
    chmod +x ./ydcmd/ydcmd.py
    ydisk_configure
    ./ydcmd/ydcmd.py --config=./ydcmd/ydcmd.cfg info
    if [ ! $? = 0 ]; then
        echo "Configure ydcmd failed. Please see console output";
        exit 1
    fi

    echo '### YDCMD INSTALLED';

    mkdir ./_tmp;

    return 0;

}

ydisk_configure () {
    echo 'Please, go to the https://oauth.yandex.ru/ and register new application.';
    echo 'Check "Web-services" mark and provide the following callback url: https://oauth.yandex.ru/verification_code';
    echo 'Also, check Yandex.Disk REST API:';
    echo ' - Доступ к информации о Диске';
	echo ' - Запись в любом месте на Диске';
	echo ' - Чтение всего Диска';
    echo
    echo 'After save, you will see ID and Password fields. Please provide:'
    while [ x$ydisk_app_id = x"" ]; do
        read -p "ID: " ydisk_app_id
        if [ x$ydisk_app_id = x"" ]; then
            echo "ERROR! ID is not provided"
        fi
    done
    while [ x$ydisk_app_pass = x"" ]; do
        read -p "Password: " ydisk_app_pass
        if [ x$ydisk_app_pass = x"" ]; then
            echo "ERROR! Password is not provided"
        fi
    done
    echo
    echo "Please, go here: https://oauth.yandex.ru/authorize?response_type=token&client_id=$ydisk_app_id"
    echo "You will see token. Please provide it below:"
    while [ x$ydisk_app_token = x"" ]; do
        read -p "Token: " ydisk_app_token
        if [ x$ydisk_app_token = x"" ]; then
            echo "ERROR! Tolen is not provided"
        fi
    done

    cat << EOF > ./ydcmd/ydcmd.cfg
[ydcmd]
token = $ydisk_app_token
EOF

}

checkinstalled () {
    OUT=`which -s python`
    if [ $? = 1 ]; then
        echo "You need install python first"
        return 2
    fi
    OUT=`which -s pip`
    if [ $? = 1 ]; then
        echo "You need install python pip"
        return 2
    fi
    OUT=`pip list|grep python-dateutil`
    if [ x"$OUT" = x ]; then
        echo "You need install python-dateutil"
        return 2
    fi
    if [ ! -e ./Dropbox-Uploader ]; then
        return 1
    fi
    if [ ! -e ./ydcmd ]; then
        return 1
    fi
    if [ ! -e ./_tmp ]; then
        return 1;
    fi
    return 0;
}

usage () {
    echo "$0 <dropbox folder to sync>";
}

run () {

    DIR=$1

    if [ x$DIR = x"" ]; then
        usage
        exit 1;
    elif [ x$DIR = xinstall ]; then
        install
        exit 0;
    fi

    checkinstalled
    RET=$?

    if [ $RET = 1 ]; then
        echo "drop-to-ydisk is not installed. Please run $0 install";
        exit 1;
    elif [ $RET = 2 ]; then
        exit 1;
    fi

    dropbox_list_files $DIR | while read line
    do
        if [ x`echo $line|cut -c 1` = x"!" ]; then
            nline=`echo $line|cut -c 2-10000`;
            echo -n "YDCMD: ";
            echo "Creating dir $nline";
            ./ydcmd/ydcmd.py --config=./ydcmd/ydcmd.cfg mkdir "$nline";
        else
	        BASENAME=`basename "$line"`;
            echo -n "DROPBOX: "
	        ./Dropbox-Uploader/dropbox_uploader.sh download "$line" "./_tmp/$BASENAME"
	        if [ -e "./_tmp/$BASENAME" ]; then
                echo -n "YDCMD: "
                echo "Uploading file $BASENAME to $line"
	            ./ydcmd/ydcmd.py --config=./ydcmd/ydcmd.cfg put "./_tmp/$BASENAME" "$line"
	            if [ $? = 0 ]; then
                    echo "LOCAL: Removing uploaded file ./_tmp/$BASENAME"
	                rm "./_tmp/$BASENAME"
	            fi
	        fi
        fi
    done

}

dropbox_list_files () {
    local DDIR=""
    local TYPE=""
    local NDIR=""

    DDIR=$1
    echo "!$DDIR"

    ./Dropbox-Uploader/dropbox_uploader.sh -q list "$DDIR" | while read line
    do
        TYPE=`echo $line|cut -f 1 -d ' '`
        if [ $TYPE = "[F]" ]; then
            echo -n $DDIR/
            echo $line|cut -f 3-100 -d ' '|sed 's,^ *,,; s, *$,,'|grep -v -e "^[[:space:]]*$"
        elif [ $TYPE = "[D]" ]; then
            NDIR=`echo $line|cut -f 2-100 -d ' '|sed 's,^ *,,; s, *$,,'|grep -v -e "^[[:space:]]*$"`
            dropbox_list_files "$DDIR/$NDIR"
        fi

    done

}

run $1
