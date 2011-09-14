#!/bin/sh

LIBDIR=target/dependency/
CLASSPATH=`find $LIBDIR -name \*.jar -exec echo -n {}: ';'`:target/datadigest-1.0-SNAPSHOT.jar

set -- "${@}"

java -Xmx1g -cp $CLASSPATH edu.rpi.tw.data.digest.GraphDigest $@
