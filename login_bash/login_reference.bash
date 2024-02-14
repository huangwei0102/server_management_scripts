#!/bin/bash
# save as /public/login.bash
# chmod a+x /public/login.bash

IP=$(ifconfig em1 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
PORT=$(cat /public/ports/$USER)
INFO=$(lxc-info -n $USER)

function print_help {
    echo "========== Tips:"
    printf "Start your container: \e[96;1mssh $USER@$IP\e[0m\n"
    printf "Login your container: \e[96;1mssh $USER@$IP -p$PORT\e[0m\n"
    printf "Change password: \e[96;1mssh -t $USER@$IP passwd\e[0m\n"
    printf "Manually stop your container: \e[96;1mssh $USER@$IP stop\e[0m\n"
    printf "Use \e[96;1mscp\e[0m or \e[96;1mSFTP\e[0m to transfer data to your container\n"
    printf "SSD mounted at \e[96;1m/SSD\e[0m\n"
    printf "NAS mounted at \e[96;1m/NAS\e[0m\n"
    printf "See GPU load: \e[96;1mnvidia-smi\e[0m\n"
    printf "More detailed guide: \e[96;1;4mhttp://apex.sjtu.edu.cn/guides/50\e[0m\n"
}

function do_stop {
    echo "========== Stopping your container..."
    LXCIP=$(lxc-info -n $USER | grep 'IP:' | grep -Eo '[0-9].+')
    sudo iptables -t nat -D PREROUTING -p tcp --dport $PORT -j DNAT --to-destination $LXCIP:22
    sudo iptables -t nat -D POSTROUTING -p tcp -d $LXCIP --dport 22 -j MASQUERADE
    lxc-stop -n $USER
    lxc-info -n $USER
}

function do_passwd {
    echo "$INFO" | grep RUNNING > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "========== It seems that your container is not running"
        echo "========== Please start your container first"
        exit 1
    fi
    echo "========== Changing password in the host..."
    passwd $USER
    echo "========== Changing password in your container..."
    lxc-attach -n $USER -- passwd $USER
}

function do_start {
    echo "$INFO" | grep RUNNING > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "========== It seems that your container is not running"
        echo "========== Starting your container..."
        lxc-start -n $USER -d
        if [ $? -ne 0 ]; then
           echo "========== Fail. Please contact administrators"
           exit 1
        fi
        sleep 2
        LXCIP=$(lxc-info -n $USER | grep 'IP:' | grep -Eo '[0-9].+')
        if [[ -z "$LXCIP" ]]; then
            lxc-stop -n $USER
            echo "Failed to get your container IP."
            echo "If this problem cannot be solved by retrying, please contact administrators."
            exit 1
        fi
        sudo iptables -t nat -A PREROUTING -p tcp --dport $PORT -j DNAT --to-destination $LXCIP:22
        sudo iptables -t nat -A POSTROUTING -p tcp -d $LXCIP --dport 22 -j MASQUERADE
        lxc-info -n $USER
    fi
    print_help
}


printf "========== Hi, \e[96;1m$USER\e[0m\n"
echo "========== Welcome to APEX GPU Server (IP: $IP)"

if [[ -z "$PORT" ]]; then
    echo "Failed to get your allocated port."
    echo "If this problem cannot be solved by retrying, please contact administrators."
    exit 1
fi

echo "========== Your LXC Container Information:"
echo "$INFO"

if   [ "$2" == "stop" ];   then do_stop
elif [ "$2" == "passwd" ]; then do_passwd
elif [ "$2" == "help" ];   then print_help
elif [[ -z "$2" ]];        then do_start
else
    echo "========== Unknown command"
    print_help
    exit 1
fi
echo "========== Have a good day :-)"