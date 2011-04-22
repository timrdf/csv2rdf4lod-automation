#!/bin/bash
#
# run from source/dpdoughtroy-com/menu-on-wall-transcription/version/2011-Apr-22/
#
# CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT
# was 
# 
# when this script was created. 

CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT=${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT:?"not set; source csv2rdf4lod/source-me.sh"}

##################################################
# Link all original files from the provenance_file directory structure to the web directory.
# (these are from source/)
if [ -e "source/menu-on-wall-transcription.csv" ]; then 
   wwwfile="$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/provenance_file/menu-on-wall-transcription/version/2011-Apr-22/source/menu-on-wall-transcription.csv"
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln "source/menu-on-wall-transcription.csv" "$wwwfile"
else
   echo "  source/menu-on-wall-transcription.csv omitted."
fi

if [ -e "source/menu-on-wall-transcription.csv.pml.ttl" ]; then
   wwwfile="$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/provenance_file/menu-on-wall-transcription/version/2011-Apr-22/source/menu-on-wall-transcription.csv.pml.ttl"
   if [ -e "$wwwfile" ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname "$wwwfile"`
   fi
   echo "  $wwwfile"
   ln "source/menu-on-wall-transcription.csv.pml.ttl" "$wwwfile"
else
   echo "  source/menu-on-wall-transcription.csv.pml.ttl omitted."
fi

##################################################
# Link all INPUT CSV files from the provenance_file directory structure to the web directory.
# (this could be from manual/ or source/
if [ -e "source/menu-on-wall-transcription.csv" ]; then 
   wwwfile="$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/provenance_file/menu-on-wall-transcription/version/2011-Apr-22/source/menu-on-wall-transcription.csv"
   if [ -e "$wwwfile" ]; then 
      rm -f "$wwwfile"
   else
      mkdir -p `dirname "$wwwfile"`
   fi
   echo "  $wwwfile"
   ln "source/menu-on-wall-transcription.csv" "$wwwfile"
else
   echo "  source/menu-on-wall-transcription.csv omitted."
fi

##################################################
# Link all raw and enhancement PARAMETERS from the provenance_file file directory structure to the web directory.
#
if [ -e "automatic/menu-on-wall-transcription.csv.raw.params.ttl" ]; then 
   wwwfile="$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/provenance_file/menu-on-wall-transcription/version/2011-Apr-22/automatic/menu-on-wall-transcription.csv.raw.params.ttl"
   if [ -e "$wwwfile" ]; then 
      rm -f "$wwwfile"
   else
      mkdir -p `dirname "$wwwfile"`
   fi
   echo "  $wwwfile"
   ln "automatic/menu-on-wall-transcription.csv.raw.params.ttl" "$wwwfile"
else
   echo "  automatic/menu-on-wall-transcription.csv.raw.params.ttl omitted."
fi

if [ -e "manual/menu-on-wall-transcription.csv.e1.params.ttl" ]; then 
   wwwfile="$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/provenance_file/menu-on-wall-transcription/version/2011-Apr-22/manual/menu-on-wall-transcription.csv.e1.params.ttl"
   if [ -e "$wwwfile" ]; then 
      rm -f "$wwwfile"
   else
      mkdir -p `dirname "$wwwfile"`
   fi
   echo "  $wwwfile"
   ln "manual/menu-on-wall-transcription.csv.e1.params.ttl" "$wwwfile"
else
   echo "  manual/menu-on-wall-transcription.csv.e1.params.ttl omitted."
fi

##################################################
# Link all PROVENANCE files that describe how the input CSV files were obtained.
#
if [ -e "source/menu-on-wall-transcription.csv.pml.ttl" ]; then 
   wwwfile="$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/provenance_file/menu-on-wall-transcription/version/2011-Apr-22/source/menu-on-wall-transcription.csv.pml.ttl"
   if [ -e "$wwwfile" ]; then
      rm -f "$wwwfile"
   else
      mkdir -p `dirname "$wwwfile"`
   fi
   echo "  $wwwfile"
   ln "source/menu-on-wall-transcription.csv.pml.ttl" "$wwwfile"
else
   echo "  source/menu-on-wall-transcription.csv.pml.ttl omitted."
fi

##################################################
# Link all bundled RDF output files from the source/.../provenance_file directory structure to the web directory.
#
dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      rm -f $wwwfile.gz
   else
      mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   ln publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "   ttl omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      rm -f $wwwfile.gz
   else
      mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   ln publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "   nt omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      rm -f $wwwfile.gz
   else
      mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   ln publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "   rdf omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.raw.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      rm -f $wwwfile.gz
   else
      mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   ln publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  raw ttl omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.raw.sample.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  raw sample ttl omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.raw.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      rm -f $wwwfile.gz
   else
      mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   ln publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  raw nt omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.raw.sample.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  raw sample nt omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.raw.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      rm -f $wwwfile.gz
   else
      mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   ln publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  raw rdf omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.raw.sample.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  raw sample rdf omitted."
fi


dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.e1.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      rm -f $wwwfile.gz
   else
      mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   ln publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  e1 ttl omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.e1.sample.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  e1 sample ttl omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.e1.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      rm -f $wwwfile.gz
   else
      mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   ln publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  e1 nt omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.e1.sample.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  e1 sample nt omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.e1.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      rm -f $wwwfile.gz
   else
      mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   ln publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  e1 rdf omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.e1.sample.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  e1 sample rdf omitted."
fi


dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.sameas.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      rm -f $wwwfile.gz
   else
      mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   ln publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  sameas ttl omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.sameas.sample.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  sameas sample ttl omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.sameas.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      rm -f $wwwfile.gz
   else
      mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   ln publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  sameas nt omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.sameas.sample.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  sameas sample nt omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.sameas.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      rm -f $wwwfile.gz
   else
      mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   ln publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  sameas rdf omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.sameas.sample.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  sameas sample rdf omitted."
fi


dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.void.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      rm -f $wwwfile.gz
   else
      mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   ln publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  void ttl omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.void.sample.ttl
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  void sample ttl omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.void.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      rm -f $wwwfile.gz
   else
      mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   ln publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  void nt omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.void.sample.nt
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  void sample nt omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.void.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump.gz ]; then 
   if [ -e $wwwfile.gz ]; then
      rm -f $wwwfile.gz
   else
      mkdir -p `dirname $wwwfile.gz`
   fi
   echo "  $wwwfile.gz"
   ln publish/$dump.gz $wwwfile.gz

   if [ -e $wwwfile ]; then
      echo "  $wwwfile" - removing b/c gz available
      rm -f $wwwfile # clean up to save space
   fi
elif [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  void rdf omitted."
fi

dump=dpdoughtroy-com-menu-on-wall-transcription-2011-Apr-22.void.sample.rdf
wwwfile=$CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT/source/dpdoughtroy-com/file/menu-on-wall-transcription/version/2011-Apr-22/conversion/$dump
if [ -e publish/$dump ]; then 
   if [ -e $wwwfile ]; then 
      rm -f $wwwfile
   else
      mkdir -p `dirname $wwwfile`
   fi
   echo "  $wwwfile"
   ln publish/$dump $wwwfile
else
   echo "  void sample rdf omitted."
fi


