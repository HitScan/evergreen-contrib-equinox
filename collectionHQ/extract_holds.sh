#!/bin/bash

#    Copyright (C) 2011-2012 Equinox Software Inc.
#    Ben Ostrowsky <ben@esilibrary.com>
#    Galen Charlton <gmc@esilibrary.com>
#
#    Original version sponsored by the King County Library System
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

LIBRARYNAME="LIBRARYCODE" # library code assigned by collectionHQ
DATE=`date +%Y%m%d`
FILE="Holds-$LIBRARYNAME""$DATE".csv
FTPUSER="user"
FTPPASS="passwd"
FTPSITE="ftp.collectionhq.com"
EMAILFROM="you@example.org"
EMAILTO="thee@example.org"

function get_data_from_sql {
  echo The hold extract for $DATE has begun. | ./send-email.pl --from "$EMAILFROM" --to "$EMAILTO" --subject "collectionHQ hold extraction has begun"
  date
  echo Fetching Holds...
  psql -A -t -U evergreen < get_items.sql 2>&1 | cut -c8- | perl -ne 'if (m/^[0-9]+ rows written/) { print STDERR; } else { print; }' > $FILE
  date
  NUMHOLDS=`wc -l $FILE | cut -d' ' -f1`
  echo done.
}

function upload_data {
  gzip --best $FILE
  ftp -v -n $FTPSITE <<END_SCRIPT
passive
quote USER $FTPUSER
quote PASS $FTPPASS
binary
put $FILE.gz
quit
END_SCRIPT
}

function clean_up {
  mv $FILE.gz old/
  echo The holds extract for $DATE has finished. We uploaded data on $NUMHOLDS holds. | \
    ./send-email.pl --from "$EMAILFROM" --to "$EMAILTO" --subject "collectionHQ hold extraction has finished"
}

get_data_from_sql && \
      upload_data && \
         clean_up #.
exit
