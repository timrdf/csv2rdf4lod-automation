#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/triff.sh>;
#3>    prov:wasDerivedFrom   <https://github.com/timrdf/prov-wg/issues/12>;
#3> .

if [[ "$1" == '--clean' ]]; then
   rm ___triff___*
   exit
fi

yW='200'
if [[ "$1" == '--help' || "$1" == '-h' || $# -lt 2 ]]; then
   echo "usage: `basename $0` [--syntax {turtle,nt}] [-W <width=$yW>] <an-rdf-file> <a-slightly-different-rdf-file>"
   exit
fi

normalform='nt'
normalform='ttl'
if [[ "$1" == '--syntax' ]]; then
   if [[ ! -e "$2" ]]; then
      normalform="$2"   
      shift
   fi
   shift
fi

if [[ "$1" == '-W' ]]; then
   if [[ ! -e "$2" ]]; then
      yW="$2"   
      shift
   fi
   shift
fi

 left="$1"
right="$2"

function download() {
   file="$1"
   link="___triff___`md5.sh -qs "$file"`"
   if [[ -e "$file" ]]; then
      ln -sf "$file" "$link"
   elif [[ "$file" =~ http* ]]; then
      curl -sL "$file" > $link
      ln -sf "$file" $link.url
   fi
   echo $link
}

function normalize() {
   file="$1"
   norm="$file.norm.$normalform"
   rdf2$normalform.sh $file > $norm
   echo $norm
}

function sortnorm() {
   file="$1"
   sorted="$file.sorted.$normalform"
   cat "$file" | sort > $sorted
   echo $sorted
}

function showdiff() {
   local title="$1"
   local  left="$2"
   local  right="$3"
   local _left="$4"
   local _right="$5"
   diffs=`diff --brief $_left $_right`
   if [ ${#diffs} -gt 0 ]; then
      echo "$lpad`pad ${#left} ' '`${#diffs} $title"
      echo "$lpad // $left   <|>   $right"
      echo $div
      diff -y -W $yW "$_left" "$_right" | grep -v '^@prefix'
   else
      echo "$lpad`pad ${#left} ' '`${#diffs} $title" >&2
   fi
}

function pad() {
   count="$1"
   char="$2"
   echo "`head -c $count < /dev/zero | tr '\0' "$char"`"
}

yw=$(( $yW / 2 )) # diff -y -W
#lpadw=$(( ( ( $yw - ${#left} ) / 2 ) - 2 )) # to center in its column
lpadw=$(( ( $yw - ${#left} ) - 9 ))
#rpadw=$(( ( ( $yw - ${#left} ) / 2 ) - 2 ))
lpad=`head -c ${lpadw} < /dev/zero | tr '\0' ' '`
#rpad=`head -c ${rpadw} < /dev/zero | tr '\0' ' '`
div="`head -c $yW < /dev/zero | tr '\0' '-'`"

_left=`download "$left"`
_left_=`normalize "$_left"`
_left__=`sortnorm "$_left_"`
_right=`download "$right"`
_right_=`normalize "$_right"`
_right__=`sortnorm "$_right_"`

diffs=`diff --brief $_left $_right`
if [ ${#diffs} -gt 0 ]; then
   echo "$lpad`pad ${#left} ' '`${#diffs} textual differences"
fi

diffs=`diff --brief $_left_ $_right_`
if [ ${#diffs} -gt 0 ]; then
   echo "$lpad`pad ${#left} ' '`${#diffs} normalized differences"
   echo "$lpad // $left   <|>   $right"
   #echo "`head -c $yW < /dev/zero | tr '\0' '-'`"
   echo $div
   diff -y -W $yW "$_left_" "$_right_" | grep -v '^@prefix'
fi

showdiff 'sorted normalized differences' "$left" "$right" "$_left__" "$_right__"
