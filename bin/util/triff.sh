#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/triff.sh>;
#3>    prov:wasDerivedFrom   <https://github.com/timrdf/prov-wg/issues/12>;
#3> .

if [[ "$1" == '--help' || "$1" == '-h' || $# -ne 2 ]]; then
   echo "usage: $0"
   exit
fi

 left="$1" &&  _left="_`basename $0`_left"  &&  _left_=${_left}_
right="$2" && _right="_`basename $0`_right" && _right_=${_right_}_ 

function download() {
   file="$1"
   link="_triff_`md5.sh -qs "$file"`"
   if [[ -e "$file" ]]; then
      ln -sf "$file" "$link"
   elif [[ "$file" =~ http* ]]; then
      curl -sL "$file" > $link
   fi
   echo $link
}

function normalize() {
   file="$1"
   norm="$file.norm.ttl"
   rdf2ttl.sh $file > $norm
   echo $norm
}

function pad() {
   count="$1"
   char="$2"
   echo "`head -c $count < /dev/zero | tr '\0' "$char"`"
}

yW=200 && yw=$(( $yW / 2 )) # diff -y -W
#lpadw=$(( ( ( $yw - ${#left} ) / 2 ) - 2 )) # to center in its column
lpadw=$(( ( $yw - ${#left} ) - 9 ))
#rpadw=$(( ( ( $yw - ${#left} ) / 2 ) - 2 ))
lpad=`head -c ${lpadw} < /dev/zero | tr '\0' ' '`
#rpad=`head -c ${rpadw} < /dev/zero | tr '\0' ' '`

_left=` download "$left"`
_right=`download "$right"`

diffs=`diff --brief $_left $_right`
if [ ${#diffs} -gt 0 ]; then
   echo "$lpad`pad ${#left} ' '`${#diffs} textual differences"
fi

_left_=` normalize "$_left"`
_right_=`normalize "$_right"`

diffs=`diff --brief $_left_ $_right_`
if [ ${#diffs} -gt 0 ]; then
   echo "$lpad`pad ${#left} ' '`${#diffs} normalized differences"
   echo "$lpad // $left   <|>   $right"
   echo "`head -c $yW < /dev/zero | tr '\0' '-'`"
   diff -y -W $yW "$_left_" "$_right_" | grep -v '^@prefix'
fi
