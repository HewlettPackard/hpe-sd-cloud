ENV_PREFIX=SDCONF_
VARFILE=/docker/ansible/extra_vars
SECRETS_ROOT=/secrets

function build_ansible_varfile {
  echo > $VARFILE

  while IFS='=' read -r -d '' n v; do
    if [[ $n == ${ENV_PREFIX}* ]]; then
      n=${n#$ENV_PREFIX}
      echo "$n: $v" >> $VARFILE
    fi
  done < <(env -0)

  if [[ -d $SECRETS_ROOT ]]; then
    for f in $(find $SECRETS_ROOT -follow -type f -maxdepth 1); do
      n=$(basename $f)
      if [[ ! -v ${ENV_PREFIX}${n} ]]; then
          v=$(cat $f)
          echo "$n: $v" >> $VARFILE
        fi
    done
  fi
}

function enable_rootless {
  if ! whoami > /dev/null 2>&1; then
    echo Could not resolve UID, injecting NSS wrapper...

    export LD_PRELOAD=/usr/lib64/libnss_wrapper.so
    export NSS_WRAPPER_PASSWD=/docker/passwd
    export NSS_WRAPPER_GROUP=/etc/group

    cp /etc/passwd $NSS_WRAPPER_PASSWD

    echo sd:x:$(id -u):$(id -g)::$HOME:/bin/false >> $NSS_WRAPPER_PASSWD
  fi
}
