case $EXPERIMENTAL_RFC5424_MODE in
  yes|YES|true|TRUE|True|1)
    tail -qF /var/opt/uoc2/logs/{platform,server}.log | sed -uE \
      -e 's/^<TRACE>/<15>/' \
      -e 's/^<DEBUG>/<15>/' \
      -e 's/^<INFO>/<14>/' \
      -e 's/^<WARN>/<13>/' \
      -e 's/^<ERROR>/<11>/' \
      -e 's/^<FATAL>/<9>/' \
      -e 's/(^.*?)-(0000)/\1Z/' \
      -e 's/(^.*?)([+-])(([0-9]{2})([0-9]{2}))/\1\2\4:\5/'
    ;;

  *)
    tail -F /var/opt/uoc2/logs/{uoc_startup,server}.log
    ;;
esac
