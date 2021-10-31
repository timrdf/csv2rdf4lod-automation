#!/bin/bash

gnaw () {
   # Determine what properties are or could be declared about the subject.
   # Example contents of $subject that finds both 'num_wires' and '#network':
   #    - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   #    num_wires=3
   #    #3> <#network> prov:specializationOf <todo>;
   #    #3>     rdfs:comment "The first three parts of an IP" .
   #    #network=192.168.1
   #    - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   # https://github.com/timrdf/csv2rdf4lod-automation/wiki/H0n3y-BadgeR
   local subject="$1"
   # ^ File path of a resource represention describing subject of interest.
   grep "^.*=" $subject | sed 's/=.*$//'
   # properties beginning with '#' are not declared but could be.
}

splash () {
   # Export every declared property into the Bash execution scope.
   # This allows a property e.g. '^num_wires=3` to be available as $num_wires.
   # https://github.com/timrdf/csv2rdf4lod-automation/wiki/H0n3y-BadgeR
   local subject="$1"
   # ^ File path of a resource represention describing subject of interest.
   alias=${subject%.properties} && alias=`basename "$alias"` # => 'nas'
   >&2 echo "\"$alias\" (according to some of the $(wc -l "$subject" | awk '{print $1}') characters within $subject)"
   tab=$(echo "$alias" | sed 's/./ /g')
   for predicate in $(gnaw "$device" | grep -v '^#'); do
      # Only those that are actually declared --^^
      object=$(bite "$device" "$predicate")
      export $predicate="$object" # TODO: could we just have sourced the thing? :-)
      >&2 echo "$tab $predicate: $object"
   done
}

bite () {
   # Determine the [object] value of a given property of a given subject.
   # https://github.com/timrdf/csv2rdf4lod-automation/wiki/H0n3y-BadgeR
   local subject="$1"
   # ^ File path of a resource represention describing subject of interest.
   local predicate="$2"
   # ^ Relative path within $subject to a particular [object] value to obtain.
   grep "^$predicate=" $device | sed 's/^.*=//;s/\s*$//'
}

# https://github.com/timrdf/csv2rdf4lod-automation/wiki/H0n3y-BadgeR
err='BadgeR did not find a value for this property; check the property file and try again.'

tuft='#!/bin/bash
#3> <> dcterms:format <https://github.com/timrdf/csv2rdf4lod-automation/wiki/H0n3y-BadgeR> .'
