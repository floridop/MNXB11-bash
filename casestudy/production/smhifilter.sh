#!/bin/bash

########################################################################
# 
# shmifilter.sh - A filter script that uses smhicleaner.sh bare data
#
# Author: Florido Paganelli florido.paganelli@fysik.lu.se
#
# Description: this script manuipulates a baredata dataset generated by 
#              smhicleaner.sh to apply some filters.
#              smhicleaner.sh needs to be in the same folder as this script
#              for this to work.
#
# Examples:
#        ./smhifilter.sh ../data/smhi-opendata_1_52240_20200905_163726.csv
#
# NOTE: the paths above are examples.
# So you should NOT assume the file is exactly in any of the above paths.
# The code must be able to process any possible file path.
#
#
########################################################################

# Memorize script name
FILTER_SCRIPTNAME=`basename $0`

###### Functions #######################################################

## usage
# this function takes no parameters and prints an error with the 
# information on how to run this script.
usage(){
	echo "----"
	echo -e "  To call this script please use"
	echo -e "   $0 '<path-to-datafile>'"
	echo -e "  Example:"
    echo -e "   $0 '../data/smhi-opendata_1_52240_20200905_163726.csv'"
	echo "----"
}

## log functions
# Create log file with date
# Usage: 
#   createlog
createlog(){
  FILTER_DATE=`date +%F`
  FILTER_LOGFILE=${FILTER_DATE}_${FILTER_SCRIPTNAME}.log
  touch $FILTER_LOGFILE
  if [[ $? != 0 ]]; then
     echo "cannot write logfile, exiting" 1>&2
     exit 1
  fi
  echo "Redirecting filter logs to $FILTER_LOGFILE"
}

# logging utility
# Adds a timestamp to a log message and writes to file created with createlog
# Usage:
#   log "message"
# If logfile missing use default CLEANER_LOGFILE
log(){
  if [[ "x$FILTER_LOGFILE" == "x" ]]; then
    echo "Undefined variable FILTER_LOGFILE, please check code: createlog() missing. Exiting" 1>&2
    exit 1
  fi
  FILTER_LOGMESSAGE=$1
  FILTER_LOGTIMESTAMP=`date -Iseconds`
  # Create timestamped message
  FILTER_OUTMESSAGE="[${FILTER_LOGTIMESTAMP} Filter]: $FILTER_LOGMESSAGE"
  # Output to screen
  echo $FILTER_OUTMESSAGE
  # Output to file
  echo $FILTER_OUTMESSAGE >> ${FILTER_LOGFILE}
}

###### Functions END =##################################################

# Exit immediately if the smhicleaner.sh script is not found
if [ ! -f 'smhicleaner.sh' ]; then
   echo "shmicleaner.sh script not found in $PWD. Cannot continue. Exiting"
   exit 1
fi
 
# Create logfile
createlog

# Get the first parameter from the command line:
# and put it in the variable FILTER_SMHIINPUT
FILTER_SMHIINPUT=$1

# Input parameter validation:
# Check that the variable FILTER_SMHIINPUT is defined, if not, 
# inform the user, show the script usage by calling the usage() 
# function in the library above and exit with error
# See Tutorial 4 Slide 45-47 and exercises 4.14, 4.15
if [[ "x$FILTER_SMHIINPUT" == 'x' ]]; then
   echo "Missing input file parameter, exiting" 1>&2
   usage
   exit 1
fi

# Extract filename:
# Extract the name of the file using the "basename" command 
# basename examples: https://www.geeksforgeeks.org/basename-command-in-linux-with-examples/
# then store it in a variable FILTER_DATAFILE
FILTER_DATAFILE=$(basename $FILTER_SMHIINPUT)

# Call smhicleaner

log "Calling smhicleaner.sh script"
./smhicleaner.sh $FILTER_SMHIINPUT

if [[ $? != 0 ]]; then
   echo "smhicleaner.sh failed, exiting..." 1>&2
   exit 1
fi

# smhicleaner.sh generates a filename that starts with baredata_<datafilename>
# So storing it in a variable for convenience.
CLEANER_BAREDATAFILENAME="baredata_$FILTER_DATAFILE"

log "Begin filtering..."

##############################
# Filtering
##############################
# Here one can write some filters to further pre-select only wanted data.
# NOTE: avoid doing any maths in BASH. If your filters requires
# calculations, then do it in C++ or ROOT.

# base output filename for filtering. The name can be changed to something more relevant.
FILTER_FILTEREDFILENAME="filtered_${FILTER_DATAFILE}"

# Some examples:
# Select only measurements done exactly at 13:00:00
FILTER_FILTERFILENAME_ONLYAT13="onlyat13_$FILTER_FILTEREDFILENAME"
log "Filtering on only measurements taken at exactly 13:00:00, writing to $FILTER_FILTERFILENAME_ONLYAT13"
grep '13:00:00' $CLEANER_BAREDATAFILENAME > $FILTER_FILTERFILENAME_ONLYAT13

# Select only measurements done in April
FILTER_FILTERFILENAME_ONLYAPRIL="april_$FILTER_FILTEREDFILENAME"
log "Filtering on only measurements taken in April, writing to $CLEANER_FILTERFILENAME_ONLYAPRIL"
grep '\-04\-' $CLEANER_BAREDATAFILENAME > $FILTER_FILTERFILENAME_ONLYAPRIL

# Select only measurements with negative temperature
## Using the awk programming language. Below, $0 is a whole line, while
## $3 is a field of the csv line. 
## The awk default field separator is one or more spaces, but it can be redefined with the -F option
## More about awk: <https://www.tutorialspoint.com/awk/awk_basic_examples.htm>
FILTER_FILTERFILENAME_ONLYNEGATIVE="onlynegative_$FILTER_FILTEREDFILENAME"
log "Filtering on only negative temperatures, writing to $FILTER_FILTERFILENAME_ONLYNEGATIVE"
awk '$3 < 0 {print $0}' $CLEANER_BAREDATAFILENAME > $FILTER_FILTERFILENAME_ONLYNEGATIVE
