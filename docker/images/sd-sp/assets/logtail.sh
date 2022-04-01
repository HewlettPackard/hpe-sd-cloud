case $EXPERIMENTAL_RFC5424_MODE in
  yes|YES|true|TRUE|True|1)
    tail -F "$JBOSS_HOME/standalone/log/server.log" | sed -uE \
      -e 's/SA  - - /SA - - - /' \
      -e 's/^<FINEST>/<15>/' \
      -e 's/^<FINER>/<15>/' \
      -e 's/^<TRACE>/<15>/' \
      -e 's/^<DEBUG>/<15>/' \
      -e 's/^<FINE>/<15>/' \
      -e 's/^<CONFIG>/<14>/' \
      -e 's/^<INFO>/<14>/' \
      -e 's/^<WARN>/<13>/' \
      -e 's/^<WARNING>/<12>/' \
      -e 's/^<ERROR>/<11>/' \
      -e 's/^<SEVERE>/<10>/' \
      -e 's/^<FATAL>/<9>/'
    ;;

  *)
    tail -F "$JBOSS_HOME/standalone/log/server.log"
    ;;
esac
