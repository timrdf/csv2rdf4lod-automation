#!/bin/bash
#
# run from source/cybershare-utep-edu/GravityMapPML/version/2011-Jul-25/
#
# CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT
# was 
# 
# when this script was created. 

CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT=${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

verbose="no"
if [ $# -gt 0 -a ${1:-""} == "-v" ]; then
  verbose="yes"
  shift
fi

symbolic=""
pwd=""
if [[ $# -gt 0 && ${1:-""} == "-s" || \
      ${CSV2RDF4LOD_PUBLISH_VARWWW_LINK_TYPE:-"."} == "soft" ]]; then
  symbolic="-sf "
  pwd=`pwd`/
  shift
fi

sudo="sudo"
if [ `whoami` == root ]; then
   sudo=""
fi

##################################################
# Link all original files from the provenance_file directory structure to the web directory.
# (these are from source/)
if [ -e "source/006021185888999658_gravityDataset.txt" ]; then 
   wwwfile="$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/provenance_file/GravityMapPML/version/2011-Jul-25/source/006021185888999658_gravityDataset.txt"
   if [ -e $wwwfile ]; then 
     $sudo rm -f $wwwfile
   else
     $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic "${pwd}source/006021185888999658_gravityDataset.txt" "$wwwfile"
else
   echo "  -- source/006021185888999658_gravityDataset.txt omitted --"
fi

if [ -e "source/006021185888999658_gravityDataset.txt.pml.ttl" ]; then
   wwwfile="$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/provenance_file/GravityMapPML/version/2011-Jul-25/source/006021185888999658_gravityDataset.txt.pml.ttl"
   if [ -e "$wwwfile" ]; then 
     $sudo rm -f $wwwfile
   else
     $sudo mkdir -p `dirname "$wwwfile"`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic "${pwd}source/006021185888999658_gravityDataset.txt.pml.ttl" "$wwwfile"
else
   echo "  -- source/006021185888999658_gravityDataset.txt.pml.ttl omitted --"
fi

##################################################
# Link all INPUT CSV files from the provenance_file directory structure to the web directory.
# (this could be from manual/ or source/
if [ -e "manual/006021185888999658_gravityDataset.txt.tsv" ]; then 
   wwwfile="$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/provenance_file/GravityMapPML/version/2011-Jul-25/manual/006021185888999658_gravityDataset.txt.tsv"
   if [ -e "$wwwfile" ]; then 
      $sudo rm -f "$wwwfile"
   else
      $sudo mkdir -p `dirname "$wwwfile"`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic "${pwd}manual/006021185888999658_gravityDataset.txt.tsv" "$wwwfile"
else
   echo "  -- manual/006021185888999658_gravityDataset.txt.tsv omitted --"
fi

##################################################
# Link all raw and enhancement PARAMETERS from the provenance_file file directory structure to the web directory.
#
if [ -e "automatic/006021185888999658_gravityDataset.txt.tsv.raw.params.ttl" ]; then 
   wwwfile="$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/provenance_file/GravityMapPML/version/2011-Jul-25/automatic/006021185888999658_gravityDataset.txt.tsv.raw.params.ttl"
   if [ -e "$wwwfile" ]; then 
     $sudo rm -f "$wwwfile"
   else
     $sudo mkdir -p `dirname "$wwwfile"`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic "${pwd}automatic/006021185888999658_gravityDataset.txt.tsv.raw.params.ttl" "$wwwfile"
else
   echo "  -- automatic/006021185888999658_gravityDataset.txt.tsv.raw.params.ttl omitted --"
fi

if [ -e "manual/006021185888999658_gravityDataset.txt.tsv.e1.params.ttl" ]; then 
   wwwfile="$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/provenance_file/GravityMapPML/version/2011-Jul-25/manual/006021185888999658_gravityDataset.txt.tsv.e1.params.ttl"
   if [ -e "$wwwfile" ]; then 
     $sudo rm -f "$wwwfile"
   else
     $sudo mkdir -p `dirname "$wwwfile"`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic "${pwd}manual/006021185888999658_gravityDataset.txt.tsv.e1.params.ttl" "$wwwfile"
else
   echo "  -- manual/006021185888999658_gravityDataset.txt.tsv.e1.params.ttl omitted --"
fi

##################################################
# Link all PROVENANCE files that describe how the input CSV files were obtained.
#
if [ -e "manual/006021185888999658_gravityDataset.txt.tsv.pml.ttl" ]; then 
   wwwfile="$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/provenance_file/GravityMapPML/version/2011-Jul-25/manual/006021185888999658_gravityDataset.txt.tsv.pml.ttl"
   if [ -e "$wwwfile" ]; then
     $sudo rm -f "$wwwfile"
   else
     $sudo mkdir -p `dirname "$wwwfile"`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic "${pwd}manual/006021185888999658_gravityDataset.txt.tsv.pml.ttl" "$wwwfile"
else
   echo "  -- manual/006021185888999658_gravityDataset.txt.tsv.pml.ttl omitted --"
fi

##################################################
# Link all bundled RDF output files from the source/.../provenance_file directory structure to the web directory.
#
dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
    $sudo rm -f $wwwfile.gz
   else
     $sudo mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   $sudo ln $symbolic ${pwd}publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      $sudo rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- full ttl omitted -- "
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
    $sudo rm -f $wwwfile.gz
   else
     $sudo mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   $sudo ln $symbolic ${pwd}publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      $sudo rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- full nt omitted -- "
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
    $sudo rm -f $wwwfile.gz
   else
     $sudo mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   $sudo ln $symbolic ${pwd}publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      $sudo rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- full rdf omitted -- "
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.raw.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      $sudo rm -f $wwwfile.gz
   else
      $sudo mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   $sudo ln $symbolic ${pwd}publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      $sudo rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- raw ttl omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.raw.sample.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- raw sample ttl omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.raw.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      $sudo rm -f $wwwfile.gz
   else
      $sudo mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   $sudo ln $symbolic ${pwd}publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      $sudo rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- raw nt omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.raw.sample.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- raw sample nt omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.raw.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      $sudo rm -f $wwwfile.gz
   else
      $sudo mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   $sudo ln $symbolic ${pwd}publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      $sudo rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- raw rdf omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.raw.sample.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- raw sample rdf omitted --"
fi


dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.e1.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      $sudo rm -f $wwwfile.gz
   else
      $sudo mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   $sudo ln $symbolic ${pwd}publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      $sudo rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- e1 ttl omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.e1.sample.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- e1 sample ttl omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.e1.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      $sudo rm -f $wwwfile.gz
   else
      $sudo mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   $sudo ln $symbolic ${pwd}publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      $sudo rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- e1 nt omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.e1.sample.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- e1 sample nt omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.e1.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      $sudo rm -f $wwwfile.gz
   else
      $sudo mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   $sudo ln $symbolic ${pwd}publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      $sudo rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- e1 rdf omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.e1.sample.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- e1 sample rdf omitted --"
fi


dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.sameas.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      $sudo rm -f $wwwfile.gz
   else
      $sudo mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   $sudo ln $symbolic ${pwd}publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      $sudo rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- sameas ttl omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.sameas.sample.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- sameas sample ttl omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.sameas.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      $sudo rm -f $wwwfile.gz
   else
      $sudo mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   $sudo ln $symbolic ${pwd}publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      $sudo rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- sameas nt omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.sameas.sample.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- sameas sample nt omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.sameas.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      $sudo rm -f $wwwfile.gz
   else
      $sudo mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   $sudo ln $symbolic ${pwd}publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      $sudo rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- sameas rdf omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.sameas.sample.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- sameas sample rdf omitted --"
fi


dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.void.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      $sudo rm -f $wwwfile.gz
   else
      $sudo mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   $sudo ln $symbolic ${pwd}publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      $sudo rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- void ttl omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.void.sample.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- void sample ttl omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.void.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      $sudo rm -f $wwwfile.gz
   else
      $sudo mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   $sudo ln $symbolic ${pwd}publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      $sudo rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- void nt omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.void.sample.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- void sample nt omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.void.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      $sudo rm -f $wwwfile.gz
   else
      $sudo mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   $sudo ln $symbolic ${pwd}publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      $sudo rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- void rdf omitted --"
fi

dump=cybershare-utep-edu-GravityMapPML-2011-Jul-25.void.sample.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/cybershare-utep-edu/file/GravityMapPML/version/2011-Jul-25/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      $sudo rm -f $wwwfile
   else
      $sudo mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   $sudo ln $symbolic ${pwd}publish/$dump $wwwfile
else
   echo "  -- void sample rdf omitted --"
fi


