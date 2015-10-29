#!/bin/bash
#-------------------------------------------------------------------------------
# (C) British Crown Copyright 2012-5 Met Office.
#
# This file is part of Rose, a framework for meteorological suites.
#
# Rose is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Rose is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Rose. If not, see <http://www.gnu.org/licenses/>.
#-------------------------------------------------------------------------------
# Test rose_bunch built-in application.
#-------------------------------------------------------------------------------
. $(dirname $0)/test_header
#-------------------------------------------------------------------------------
tests 39
#-------------------------------------------------------------------------------
# Run the suite, and wait for it to complete
export ROSE_CONF_PATH=
TEST_KEY=$TEST_KEY_BASE
mkdir -p $HOME/cylc-run
SUITE_RUN_DIR=$(mktemp -d --tmpdir=$HOME/cylc-run 'rose-test-battery.XXXXXX')
NAME=$(basename $SUITE_RUN_DIR)
run_pass "$TEST_KEY" \
    rose suite-run -C $TEST_SOURCE_DIR/$TEST_KEY_BASE --name=$NAME \
    --no-gcontrol --host=localhost -- --debug
#-------------------------------------------------------------------------------
CYCLE=2010010000
LOG_DIR="$SUITE_RUN_DIR/log/job/$CYCLE"
#-------------------------------------------------------------------------------
# Testing successful runs
#-------------------------------------------------------------------------------
APP=bunch
#-------------------------------------------------------------------------------
# Confirm launching set of commands
TEST_KEY_PREFIX=launch-ok
FILE=$LOG_DIR/$APP/NN/job.out
for ARGVALUE in 0 1 2 3; do
    TEST_KEY=$TEST_KEY_PREFIX-$ARGVALUE
    file_grep $TEST_KEY \
    "\[INFO\] Adding command $ARGVALUE to pool: echo arg1: $(expr $ARGVALUE + 1)"\
     $FILE
done
#-------------------------------------------------------------------------------
# Check output to separate files is correct
TEST_KEY_PREFIX=check-logs
FILE_PREFIX=$LOG_DIR/$APP/NN
for ARGVALUE in 0 1 2 3; do
    TEST_KEY=$TEST_KEY_PREFIX-$ARGVALUE
    file_grep $TEST_KEY \
        "arg1: $(expr $ARGVALUE + 1)" $FILE_PREFIX/bunch.$ARGVALUE.out
done
#-------------------------------------------------------------------------------
# Testing abort on fail
#-------------------------------------------------------------------------------
APP=bunch_fail
#-------------------------------------------------------------------------------
TEST_KEY_PREFIX=abort-on-fail
FILE=$LOG_DIR/$APP/NN/job.out
file_grep_fail $TEST_KEY_PREFIX-no-run \
    "\[INFO\] Adding command 2 to pool: banana" $FILE
FILE=$LOG_DIR/$APP/NN/job.err
file_grep $TEST_KEY_PREFIX-record-error \
    "\[FAIL\] 1 # return-code=1" $FILE
#-------------------------------------------------------------------------------
# Testing incremental mode
#-------------------------------------------------------------------------------
APP=bunch_incremental
#-------------------------------------------------------------------------------
TEST_KEY_PREFIX=incremental
#-------------------------------------------------------------------------------
# First run files
#-------------------------------------------------------------------------------
FILE=$LOG_DIR/$APP/01/job.err
file_grep $TEST_KEY_PREFIX-record-error \
    "\[FAIL\] 1 # return-code=1" $FILE
FILE=$LOG_DIR/$APP/01/job.out
file_grep $TEST_KEY_PREFIX-ran-0 \
    "\[INFO\] Adding command 0 to pool: true" $FILE
file_grep $TEST_KEY_PREFIX-ran-1 \
    "\[INFO\] Adding command 1 to pool: false" $FILE
file_grep $TEST_KEY_PREFIX-ran-2 \
    "\[INFO\] Adding command 2 to pool: true" $FILE
#-------------------------------------------------------------------------------
# Second run files
#-------------------------------------------------------------------------------
FILE=$LOG_DIR/$APP/02/job.out
file_grep_fail $TEST_KEY_PREFIX-not-ran-0 \
    "\[INFO\] Adding command 0 to pool: true" $FILE
file_grep $TEST_KEY_PREFIX-skip-0 \
    "\[SKIP\] 0: previously ran and succeeded" $FILE
file_grep $TEST_KEY_PREFIX-reran-1 \
    "\[INFO\] Adding command 1 to pool: false" $FILE
file_grep_fail $TEST_KEY_PREFIX-not-ran-2 \
    "\[INFO\] Adding command 2 to pool: true" $FILE
file_grep $TEST_KEY_PREFIX-skip-2 \
    "\[SKIP\] 2: previously ran and succeeded" $FILE
#-------------------------------------------------------------------------------
# Testing works ok with double digit population size
#-------------------------------------------------------------------------------
APP=bunch_bigpop
#-------------------------------------------------------------------------------
TEST_KEY_PREFIX=big-pop
FILE=$LOG_DIR/$APP/01/job.out
for INSTANCE in $(seq 0 14); do
file_grep $TEST_KEY_PREFIX-ran-$INSTANCE \
    "\[OK\] $INSTANCE" $FILE
done
#-------------------------------------------------------------------------------
# Testing names works ok
#-------------------------------------------------------------------------------
APP=bunch_names
#-------------------------------------------------------------------------------
TEST_KEY_PREFIX=names
FILE=$LOG_DIR/$APP/01/job.out
for NAME in foo bar baz qux; do
file_grep $TEST_KEY_PREFIX-ran-$NAME \
    "\[OK\] $NAME" $FILE
done
#-------------------------------------------------------------------------------
rose suite-clean -q -y $NAME
exit 0
