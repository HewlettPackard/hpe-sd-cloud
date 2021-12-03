if ! whoami > /dev/null 2>&1
then
    echo Could not resolve UID, injecting NSS wrapper...

    export LD_PRELOAD=/usr/lib64/libnss_wrapper.so
    export NSS_WRAPPER_PASSWD=/docker/passwd
    export NSS_WRAPPER_GROUP=/etc/group

    cp /etc/passwd $NSS_WRAPPER_PASSWD

    echo sd:x:$(id -u):$(id -g)::$HOME:/bin/false >> $NSS_WRAPPER_PASSWD
fi
