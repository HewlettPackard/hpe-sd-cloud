#!/bin/bash

VOLUMEROOT=/initvolumes

echo "Starting volume initialization..."

for v in $(find /initvolumes -type d -empty)
do
  o=${v#"$VOLUMEROOT"}
  echo "Populating '$v' from '$o'..."
  time cp -a $o/. $v/
  echo
done

echo "Volume initialization done in $SECONDS seconds"
