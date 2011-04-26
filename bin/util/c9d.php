<?
$DATASET_URI = $node->field_dataset_uri[0]['url'];
$ENDPOINT    = 'http://logd.tw.rpi.edu/sparql'; // 'http://logd.tw.rpi.edu:8890/sparql'

$conversion = 'http://purl.org/twc/vocab/conversion/';

/*
* DEBUG: WHAT FUNCTIONS ARE DEFINED?
*/
/*$see_functions = get_defined_functions();
print_r($see_functions['user']);*/






class C9D {

/* Utility functions */
static function bind_variable($template, $variable, $binding) {
   return str_replace($variable,'<'.$binding.'>',$template);
}

static function prepare_query($query, $endpoint) {
   $params           = array();
   $params["query"]  = $query;
   $params["output"] = 'sparql';
   $query= $endpoint . '?' . http_build_query($params,'','&') ;
   return $query;
}

static function request_query($query, $endpoint) {
   return json_decode(file_get_contents(prepare_query($query, $endpoint)), true);
}

static function prepopulate_query_ui($QUERY, $ENDPOINT, $DATASET_URI) {
   // TODO: find more interesting default query
   if( !strlen($query) ) {
      $QUERY = <<<______________________________
prefix rdfs:       <http://www.w3.org/2000/01/rdf-schema#>
prefix void:       <http://rdfs.org/ns/void#>             
prefix ov:         <http://open.vocab.org/terms/>         
prefix conversion: <http://purl.org/twc/vocab/conversion/>

select distinct *
where {
  graph ?:dataset {
    ?s ?p ?o
  }
} limit 25
______________________________;
      $QUERY = bind_variable($QUERY,'?:dataset',$DATASET_URI);
   }
   return $ENDPOINT . '?query-option=text&query=' . urlencode($QUERY) . '&output=html&ui-option=query';
}

static function startsWith($haystack,$needle,$case=true) {
    if($case){return (strcmp(substr($haystack, 0, strlen($needle)),$needle)===0);}
    return (strcasecmp(substr($haystack, 0, strlen($needle)),$needle)===0);
}

static function c9d_best_namespace_for($URI, $PREFIXES) {
   $longestNamespace = '';
   foreach( $PREFIXES as $namespace => $prefix ) {
      //echo '   so far '.$longestNamespace.', but '.$URI.' startsWith '.$namespace.' ? '.strpos($URI,$namespace) . '<br/>'; //URI.startsWith(namespace));
      if( startsWith($URI,$namespace) && strlen($namespace) > strlen($longestNamespace) ) {
         $longestNamespace = $namespace;
      }
   }
   return $longestNamespace;
}

static function c9d_best_qname_for($URI, $PREFIXES) {
   $best_qname = $URI;
   //echo $URI . ' just is ' . $best_qname . '<br/>';

   $best_ns = c9d_best_namespace_for($URI, $PREFIXES);
   if( strlen($best_ns) > 0 && strlen($best_ns) < strlen($URI) ) {
      $best_qname = $PREFIXES[$best_ns] . ':' . substr($URI,strlen($best_ns));
      //echo $URI . ' has prefix ' . $best_qname . '<br/>';
   }
   if( $PREFIXES[$URI] ) {
      $best_qname = $PREFIXES[$URI];
      //echo $URI . ' a namespace ' . $best_qname . '<br/>';
   }
   return $best_qname;
}

static function pretty_date($XSD_DATETIME) {
   return substr($XSD_DATETIME,0,10) . ' at ' . substr($XSD_DATETIME,11,5);
}





/* Display code */



/* ---------- */
static function get_types($DATASET_URI, $ENDPOINT) {
   $query = <<<______________________________
   prefix conversion: <http://purl.org/twc/vocab/conversion/>
    
   select ?type
   WHERE { 
     graph <http://logd.tw.rpi.edu/vocab/Dataset> {  
       ?:dataset a ?type
     } 
   } order by ?type
______________________________;
   $query = bind_variable($query,'?:dataset',$DATASET_URI);

   // TODO: echo '<code style="display:none">'.$query.'</code>';
   $result = request_query($query, $ENDPOINT);

   $ISA = array();

   if( isset($result['results']['bindings']) ) {
      foreach($result['results']['bindings'] as $binding){
         $type = $binding['type']['value'];
         $ISA[$type] = $type;
      }
   }
   return $ISA;
}


/* ---------- */
static function is_abstract($DATASET_URI, $ENDPOINT) {
   $query = <<<______________________________
   prefix void:       <http://rdfs.org/ns/void#>
   prefix conversion: <http://purl.org/twc/vocab/conversion/>
        
   ask
   where { 
     graph <http://logd.tw.rpi.edu/vocab/Dataset> {   
       ?:dataset void:subset [ a conversion:VersionedDataset ] .
     }   
   }
______________________________;
   $query = bind_variable($query,'?:dataset',$DATASET_URI);

   $result = request_query($query, $ENDPOINT); // Example results from an ASK query: 
                                               //  { "head": { "link": [] }, "boolean": true}

   return isset($result['boolean']) && $result['boolean'];
}

/* ---------- */
static function versioned_abstract($DATASET_URI, $ENDPOINT) {
   $query = <<<______________________________
   prefix void:       <http://rdfs.org/ns/void#>
   prefix conversion: <http://purl.org/twc/vocab/conversion/>
        
   select ?abstract
   WHERE { 
     graph <http://logd.tw.rpi.edu/vocab/Dataset> {   
       ?abstract void:subset ?:dataset .
       ?:dataset a conversion:VersionedDataset .
     }   
   } limit 1
______________________________;
   $query = bind_variable($query,'?:dataset',$DATASET_URI);

   $result = request_query($query, $ENDPOINT);

   $ABSTRACT_DATASET_URI = isset($result['results']['bindings']) ? 
                              $ABSTRACT_DATASET_URI = $result['results']['bindings'][0]['abstract']['value'] : '';
   return $ABSTRACT_DATASET_URI;
}

/* ---------- */
static function layer_abstract($DATASET_URI, $ENDPOINT) {
   $query = <<<______________________________
   prefix void:       <http://rdfs.org/ns/void#>
   prefix conversion: <http://purl.org/twc/vocab/conversion/>
        
   select ?abstract
   WHERE { 
     graph <http://logd.tw.rpi.edu/vocab/Dataset> {   
       ?abstract void:subset [ a conversion:VersionedDataset; void:subset ?:dataset ] .
     }   
   } limit 1
______________________________;
   $query = bind_variable($query,'?:dataset',$DATASET_URI);

   $result = request_query($query, $ENDPOINT);

   $ABSTRACT_DATASET_URI = isset($result['results']['bindings']) ? 
                              $ABSTRACT_DATASET_URI = $result['results']['bindings'][0]['abstract']['value'] : '';
   return $ABSTRACT_DATASET_URI;
}








/* ---------- */
static function show_supersets($DATASET_URI, $ENDPOINT) {
   $query = <<<______________________________
   prefix dcterms:    <http://purl.org/dc/terms/>
   prefix void:       <http://rdfs.org/ns/void#>
   prefix conversion: <http://purl.org/twc/vocab/conversion/>
        
   select distinct ?superset
   WHERE { 
     graph <http://logd.tw.rpi.edu/vocab/Dataset> {   
       ?superset void:subset ?:dataset .
      # optional { ?:dataset conversion:version_identifier ?version_id }
     }   
   }
______________________________;
   $query = bind_variable($query,'?:dataset',$DATASET_URI);

   // TODO: echo '<code style="display:none">'.$query.'</code>';
   $result = request_query($query, $ENDPOINT);

   echo '<div>';
   if( isset($result['results']['bindings']) ) {
      $no = count($result['results']['bindings']) == 0 ? 'No ' : '';
      echo '<table about="'.$DATASET_URI.'">';
      echo '  <tr><th>'.$no.'Supersets</th></tr>';
      foreach( $result['results']['bindings'] as $binding ) {
         $superset = $binding['superset']['value'];
         echo "  <tr><td property='conversion:todo'><a rel='conversion:todo' href='".$superset."'>".$superset."</a></td></tr>";
      }
      echo "</table>";
   }
   echo '</div>';
}




/* ---------- */
static function show_metadata($DATASET_URI, $ENDPOINT, $ABSTRACT_DATASET_URI) {
   $query = <<<______________________________
   prefix dcterms:    <http://purl.org/dc/terms/>
   prefix ov:         <http://open.vocab.org/terms/>
   prefix conversion: <http://purl.org/twc/vocab/conversion/>
        
   select distinct ?title ?description ?subject ?homepage ?source ?source_id ?dataset_id  max(?modified) as ?last_modified
   WHERE { 
     graph <http://purl.org/twc/vocab/conversion/MetaDataset> {   
       ?:abstract ov:csvRow [] .
       optional { ?:abstract dcterms:title                 ?title       }
       optional { ?:abstract dcterms:description           ?description }
       optional { ?:abstract dcterms:subject               ?subject     }
       optional { ?:abstract foaf:homepage                 ?homepage    }
       # optional { ?:abstract dcterms:isReferencedBy        ?homepage    }
     }   
     graph <http://logd.tw.rpi.edu/vocab/Dataset> {
       ?:abstract a void:Dataset .
       optional { ?:abstract dcterms:contributor           ?source      }
       optional { ?:abstract conversion:source_identifier  ?source_id   }
       optional { ?:abstract conversion:dataset_identifier ?dataset_id  }
       optional { ?:abstract dcterms:modified              ?modified    }
     }
   }
______________________________;
   $query = bind_variable($query,'?:abstract',$ABSTRACT_DATASET_URI);

   //echo '<code style="display:none">'.$query.'</code>';
   $result = request_query($query, $ENDPOINT);

   echo '<div>';
   if( isset($result['results']['bindings']) ) {
      echo '<table about="'.$ABSTRACT_DATASET_URI.'">';
      $abstract_ref = $ABSTRACT_DATASET_URI == $DATASET_URI ? $ABSTRACT_DATASET_URI 
                                                                  : '<a href="'.$ABSTRACT_DATASET_URI.'">'.$ABSTRACT_DATASET_URI.'</a>';
      echo '  <tr><th colspan="2">'.$abstract_ref.'</th></tr>';
      foreach( $result['results']['bindings'] as $binding ) {
         $homepage = isset($binding['homepage']) ? $binding['homepage']['value'] : '';
         echo '  <tr><td>Homepage:</td><td property="foaf:homepage"><a href="'.$homepage.'">'.$homepage.'</a></td></tr>';

         $title = isset($binding['title']) ? $binding['title']['value'] : '';
         echo '  <tr><td>Title:</td><td property="conversion:todo">'.$title.'</td></tr>';

         $description = isset($binding['description']) ? $binding['description']['value'] : '';
         echo '  <tr><td>Description:</td><td property="conversion:todo">'.$description.'</td></tr>';

         $subject = isset($binding['subject']) ? $binding['subject']['value'] : '';
         echo '  <tr><td>Subjects:</td><td property="conversion:todo">'.$subject.'</td></tr>';

         $source = $binding['source']['value'];
         $label  = isset($binding['source_id']) ? $binding['source_id']['value'] : $source;
         echo '  <tr><td>Source Identifier:</td><td property="dcterms:source"><a rel="dcterms:source" href="'.$source.'">'.$label.'</a></td></tr>';

         $dataset_id = isset($binding['dataset_id']) ? $binding['dataset_id']['value'] : '';
         echo '  <tr><td>Dataset Identifier:</td><td property="conversion:version_identifier">'.$dataset_id.'</td></tr>';

         $modified = isset($binding['last_modified']) ? $binding['last_modified']['value'] : '';
         $modifiedL = C9D::pretty_date($modified); //substr($modified,0,10) . ' at ' . substr($modified,11,5);
         echo '  <tr><td>Last modified:</td><td property="conversion:version_identifier">'.$modifiedL.'</td></tr>';
      }
      echo "</table>";
   }
   echo '</div>';
}

/* ---------- */
static function show_siblings($DATASET_URI, $ENDPOINT, $ISA, $ABSTRACT_DATASET_URI, $LABEL) {
   if( $DATASET_URI != $ABSTRACT_DATASET_URI ) {
         $query = <<<________________________________________
         prefix dcterms: <http://purl.org/dc/terms/>
         prefix void:    <http://rdfs.org/ns/void#>

         select ?sibling max(?modified) as ?last_modified
         WHERE { 
           graph <http://logd.tw.rpi.edu/vocab/Dataset> {   
             [] void:subset ?:dataset; void:subset ?sibling .
             ?sibling dcterms:modified ?modified .
           }   
         } order by desc(?last_modified)
________________________________________;

         $query = bind_variable($query,'?:dataset',$DATASET_URI);
         $result = request_query($query, $ENDPOINT);

         $LABEL = strlen($LABEL) ? ' '.$LABEL : $LABEL;
         if( isset($result['results']['bindings']) && count($result['results']['bindings']) > 1 ) {
            echo '<table about="'.$DATASET_URI.'">';
               echo '<tr><th>Sibling'.$LABEL.'s</th>   <th>Last Modified</th></tr>';
               foreach($result['results']['bindings'] as $binding){
                  $sibling       = $binding['sibling']['value'];
                  $last_modified = $binding['last_modified']['value'];
                  echo '<tr>';
                  if( $sibling == $DATASET_URI ) {
                     echo '  <td property="conversion:todo"><b>'.$sibling.'</b></td>';
                  }else {
                     echo '  <td property="conversion:todo"><a rel="conversion:todo" href="'.$sibling.'">'.$sibling.'</a></td>';
                  }
                  echo '  <td property="conversion:todo">'.C9D::pretty_date($last_modified).'</td>';
                  echo '</tr>';
                  $SIBING[$sibling] = $sibling;
               }
            echo "</table>";
         }else {
            echo '<p>'.$DATASET_URI.' is the only version of '.$ABSTRACT_DATASET_URI.'</p>'; 
         }
   }
}





/* ---------- */
static function show_loaded_in_endpoint($DATASET_URI, $ENDPOINT, $TYPE_LABEL='') {
   $queryFull = <<<______________________________
   prefix void: <http://rdfs.org/ns/void#>
   ask {
     graph ?:dataset {
       ?:dataset a void:Dataset .
     }
   }
______________________________;
   $querySample = <<<______________________________
   prefix void:       <http://rdfs.org/ns/void#>
   prefix conversion: <http://purl.org/twc/vocab/conversion/>
    
   SELECT DISTINCT ?sample_uri ?sample_dump ?full_dump
   WHERE {
     graph <http://logd.tw.rpi.edu/vocab/Dataset> {
       ?:dataset void:subset ?sample_uri .
                             ?sample_uri a conversion:DatasetSample .
       optional { ?:dataset   void:dataDump ?full_dump   }
       optional { ?sample_uri void:dataDump ?sample_dump }
     }
     graph ?sample_uri {
        ?sample_uri a void:Dataset .
     }
   } limit 1
______________________________;
   $queryFull   = bind_variable($queryFull,'?:dataset',$DATASET_URI);
   $querySample = bind_variable($querySample,'?:dataset',$DATASET_URI);

   $resultFull   = request_query($queryFull,   $ENDPOINT); // e.g. results: { "head": { "link": [] }, "boolean": false}
   $resultSample = request_query($querySample, $ENDPOINT);

   $largest_loaded_graph = '';

   $status = array(); $status['full'] = array(); $status['sample'] = array();
   if( $resultFull['boolean'] ) {
      $status['full']['sparql'] = '<a rel="conversion:todo" href="'.prepopulate_query_ui('',$ENDPOINT,$DATASET_URI).'">Build a query</a>';
      $largest_loaded_graph = $DATASET_URI;
   }else {
      $status['full']['sparql'] = 'Not loaded';
   }
   if( isset($resultSample['results']['bindings'][0]['full_dump']) ) {
      $dump = $resultSample['results']['bindings'][0]['full_dump']['value'];
      $status['full']['dump'] = '<a rel="conversion:todo" href="'.$dump.'">'.basename($dump).'</a>';
   }else {
      $status['full']['dump'] = 'Available at the Layer Level';
   }

   if( isset($resultSample['results']['bindings'][0]['sample_uri']) ) {
      $sample_uri = $resultSample['results']['bindings'][0]['sample_uri']['value'];
      $status['sample']['sparql'] = '<a rel="conversion:todo" href="'.prepopulate_query_ui('',$ENDPOINT,$sample_uri).'">Build a query</a>';
      if( $largest_loaded_graph == '' ) {
         $largest_loaded_graph = $sample_uri;
      }
   }else {
      $status['sample']['sparql'] = 'Not loaded';
   }
   if( isset($resultSample['results']['bindings'][0]['sample_dump']) ) {
      $dump = $resultSample['results']['bindings'][0]['sample_dump']['value'];
      $status['sample']['dump'] = '<a rel="conversion:todo" href="'.$dump.'">'.basename($dump).'</a>';
   }else {
      $status['sample']['dump'] = 'Available at the Layer Level';
   }

   echo '<div>';
   echo '  <table about="'.$DATASET_URI.'">';
   echo '    <tr><th></th>  <th>SPARQL Endpoint</th>  <th>Dump File</th></tr>';
   echo '    <tr>';
   echo '      <td>Full '.$TYPE_LABEL.'</td>';
   echo '      <td property="conversion:todo">'.$status['full']['sparql'].'</td>';
   echo '      <td property="conversion:todo">'.$status['full']['dump'].'</td>';
   echo '    </tr>';
   echo '    <tr>';
   echo '      <td>Sample</td>';
   echo '      <td property="conversion:todo">'.$status['sample']['sparql'].'</td>';
   echo '      <td property="conversion:todo">'.$status['sample']['dump'].'</td>';
   echo '    </tr>';
   echo '  </table>';
   echo '</div>';

   return $largest_loaded_graph;
}



static function get_prefixes($DATASET_URI, $ENDPOINT, $LARGEST_LOADED_DATASET_URI) {
   $query = <<<______________________________
   prefix vann: <http://purl.org/vocab/vann/>

   SELECT distinct ?namespace ?prefix
   WHERE {
     GRAPH ?:dataset  {
       [] vann:preferredNamespacePrefix ?prefix;
          vann:preferredNamespaceUri    ?namespace .
     }
   } order by ?namespace
______________________________;
   $query  = bind_variable($query,'?:dataset',$LARGEST_LOADED_DATASET_URI);
   $result = request_query($query, $ENDPOINT); 

   $prefixes = array();

   echo '<div>';
   //echo '  <table about="'.$DATASET_URI.'">';
   //echo '     <tr><th>Prefixes</th></tr>';
   foreach( $result['results']['bindings'] as $binding ) {
      $prefix    = $binding['prefix']['value'];
      $namespace = $binding['namespace']['value'];
      // TODO: modify drupal/sites/all/themes/tw/style.css
      echo '  <a class="c9d_prefix c9d_to_namespace" href="'.$namespace.'">'.$prefix.'</a>';
      //echo '  <tr><td>'.$prefix.'</td><td property="conversion:todo"><a rel="conversion:todo" href="'.$namespace.'">'.$namespace.'</a></td></tr>';
      if( $prefix != 'todo' ) $prefixes[$namespace] = $prefix;
   }
   //echo '  </table>';
   echo '</div>';
   return $prefixes;
}



static function show_example_resources($DATASET, $ENDPOINT, $LARGEST_LOADED_DATASET_URI, $PREFIXES=array()) {
   $query = <<<______________________________
   prefix void:       <http://rdfs.org/ns/void#>
   PREFIX conversion: <http://purl.org/twc/vocab/conversion/>
   prefix ov:         <http://open.vocab.org/terms/>

   SELECT distinct ?s ?p ?o ?col
   WHERE {
     GRAPH ?:dataset {
       [] a void:Dataset;
          void:exampleResource ?s .
       ?s ?p ?o .
       optional { ?p ov:csvCol ?col }
     }
   } order by ?s ?col
______________________________;

   $query  = bind_variable($query,'?:dataset',$LARGEST_LOADED_DATASET_URI);
   $result = request_query($query, $ENDPOINT); 

   echo '<div>';
   echo '  <table about="'.$DATASET_URI.'">';
   echo '     <tr><th colspan="3">Sample Data Elements</th></tr>';
   $lastS = '__';
   foreach( $result['results']['bindings'] as $binding ) {
      $s   = $binding['s']['value'];
      $p   = $binding['p']['value'];
      $o   = $binding['o']['value'];
      $col = $binding['col']['value'];

      $sL = $s;
      $sL = '<a href="'.$s.'">'.c9d_best_qname_for($s,$PREFIXES).'</a>';
      
      // Suppress $sL if we said it last row.
      if( $lastS == '__' ) {
         $lastS = $s;
      }else if( $s == $lastS ) {
         $sL = '';
      }
      $pL = $p;
      if( $binding['p']['type'] == 'uri' ) {
         $pL = '<a href="'.$p.'">'.c9d_best_qname_for($p,$PREFIXES).'</a>';
      }
      $oL = $o;
      if( $binding['o']['type'] == 'uri' ) {
         $oL = '<a href="'.$o.'">'.c9d_best_qname_for($o,$PREFIXES).'</a>';
      }

      echo '  <tr>';
      echo '    <td>'.$sL.'</td>';
      echo '    <td>'.$pL.'</td>';
      echo '    <td>'.$oL.'</td>';
      echo '  </tr>';
      $lastS = $s;
   }
   echo '  </table>';
   echo '</div>';
}




/* ---------- */
static function show_provenance($DATASET_URI, $ENDPOINT) {
   $query = <<<______________________________
   prefix dcterms:    <http://purl.org/dc/terms/>
   prefix conversion: <http://purl.org/twc/vocab/conversion/>
   prefix pmlp:       <http://inference-web.org/2.0/pml-provenance.owl#>
   prefix pmlj:       <http://inference-web.org/2.0/pml-justification.owl#>
   prefix httpget:    <http://inference-web.org/registry/MPR/HTTP_1_1_GET.owl#>

   select ?gov_url ?datetime ?cached
   where {
     graph <http://logd.tw.rpi.edu/vocab/Dataset>  {

       ?:version dcterms:source ?cached .

       [] a pmlj:NodeSet;
         pmlj:hasConclusion ?cached;
         pmlj:isConsequentOf [
           pmlj:hasInferenceRule httpget:HTTP_1_1_GET;
           pmlj:hasSourceUsage [ 
             pmlp:hasSource        ?gov_url;
             pmlp:hasUsageDateTime ?datetime;
           ];
         ]
       .
     }
   } 
______________________________;
   $query = bind_variable($query,'?:version',$DATASET_URI);

   $result = request_query($query, $ENDPOINT);

   echo '<div>';
   if( isset($result['results']['bindings']) ) {
      echo '<table about="'.$DATASET_URI.'">';
      echo '  <tr><th>Government Files Retrieved</th>   <th>Date Retrieved</th>   <th>Cached Version</th></tr>';
      foreach( $result['results']['bindings'] as $binding ) {
         $gov_url  = $binding['gov_url']['value'];
         $datetime = $binding['datetime']['value'];
         $cached   = $binding['cached']['value'];
         echo '  <tr>';
         echo '    <td property="conversion:todo"><a rel="conversion:todo" href="'.$gov_url.'">'.$gov_url.'</a></td>';
         echo '    <td>'.C9D::pretty_date($datetime).'</td>';
         echo '    <td property="conversion:todo"><a rel="conversion:todo" href="'.$cached.'">'.basename($cached).'</a></td>';
         echo '  </tr>';
      }
      echo "</table>";
   }
   echo '</div>';

   // HACK: implicit knowledge.
   $dump_dir = str_replace('/dataset/','/file/',$DATASET_URI) . '/conversion/';
   $prov_dir = str_replace('/dataset/','/provenance_file/',$DATASET_URI);
   echo '<table>';
   echo '  <tr><td>Dump directory:</td>       <td><a href='.$dump_dir.'>'.$dump_dir.'</a></td></tr>';
   echo '  <tr><td>Provenance directory:</td> <td><a href='.$prov_dir.'>'.$prov_dir.'</a></td></tr>';
   echo '</table>';
}


/* ---------- */
static function show_subsets($DATASET_URI, $ENDPOINT) {
   $query = <<<______________________________
   prefix dcterms:    <http://purl.org/dc/terms/>
   prefix void:       <http://rdfs.org/ns/void#>
     
   select distinct ?subset max(?modified) as ?datetime
   WHERE { 
     graph <http://logd.tw.rpi.edu/vocab/Dataset> {   
       ?:dataset void:subset ?subset .
       optional { ?subset dcterms:modified ?modified }
     }   
   } order by desc(?datetime)
______________________________;
   $query = bind_variable($query,'?:dataset',$DATASET_URI);

   // TODO: echo '<code style="display:none">'.$query.'</code>';
   $result = request_query($query, $ENDPOINT);

   echo '<div>';
   if( isset($result['results']['bindings']) ) {
      echo '<table about="'.$DATASET_URI.'">';
      echo '  <tr><th>Subsets</th></tr>';
      foreach( $result['results']['bindings'] as $binding ) {
         $subset = $binding['subset']['value'];
         echo "  <tr>";
         echo "     <td property='conversion:todo'><a rel='conversion:todo' href='".$subset."'>".$subset."</a></td>";
         if( isset($binding['datetime']) ) {
            $date = $binding['datetime']['value'];
            echo "  <td property='conversion:todo'>".C9D::pretty_date($date)."</td>";
         }
         echo "  </tr>";
      }
      echo "</table>";
   }
   echo '</div>';
}

/* ---------- */
static function show_types($DATASET_URI, $ISA, $PREFIXES=array()) {
   echo '<div>';
   echo '  <table about="'.$DATASET_URI.'">';
      echo "  <tr><th>Types</th></tr>";
      foreach($ISA as $type){
         echo "  <tr><td property='rdf:type'><a rel='rdf:type' href='".$type."'>".c9d_best_qname_for($type,$PREFIXES)."</a></td></tr>";
      }
   echo "  </table>";
   echo '</div>';
}

} /* End of C9D class */












$ISA     = array();
$SIBLING = array();
$LABELS  = array();

/*
 * Current code: http://logd.tw.rpi.edu/twc/apps/datasetcontentcode
 */

$ISA = C9D::get_types($DATASET_URI, $ENDPOINT);

$LABELS['an'] = '';
if( strlen(C9D::is_abstract($DATASET_URI, $ENDPOINT)) ) {
   $ABSTRACT_DATASET_URI = $DATASET_URI;
   $LABELS['type']      = 'Abstract Dataset';
   $LABELS['abbr-type'] = 'Abstract';
}else if( $ISA[$conversion.'VersionedDataset'] ) {
   $ABSTRACT_DATASET_URI = C9D::versioned_abstract($DATASET_URI, $ENDPOINT);
   $LABELS['type']      = 'Versioned Dataset';
   $LABELS['abbr-type'] = 'Version';
}else if( $ISA[$conversion.'LayerDataset'] ) {
   $ABSTRACT_DATASET_URI = C9D::layer_abstract($DATASET_URI, $ENDPOINT);
   $LABELS['type']      = 'Dataset Layer';
   $LABELS['abbr-type'] = 'Layer';
}

echo '<div style="border: 3px; border-style: dotted; border-color: red">';

echo '<center>';
echo '  <p>/var/www/html/logd.tw.rpi.edu/twc/apps/timincludefile.php - lebot\'s prototype dataset descriptions</p>';
echo '  <h3><span>'.$DATASET_URI.'</span></h3>';
echo '  <p>is a'.$LABELS['an'].' '.$LABELS['type'].'</p>';
echo '</center>';

echo '<ul>';
echo '<li>For a VersionedDataset, show the URLs of the cached copies of the files retrieved and the URLs from which they were retreived.</li>';
echo '<li>* Useful title
* Description
* Keywords
* When it is a "version," some detail on what makes it a "version" (a log or something)? </li>';
echo '<li>agency, description, etc - plus maybe some of our own metadata (last converted on, what demos it is used in, etc.)</li>';
echo '<li>'.$query.'</li>';
echo '</ul>';

C9D::show_supersets($DATASET_URI, $ENDPOINT);
C9D::show_metadata($DATASET_URI, $ENDPOINT, $ABSTRACT_DATASET_URI);

//C9D::show_types($DATASET_URI, $ISA);

C9D::show_siblings($DATASET_URI, $ENDPOINT, $ISA, $ABSTRACT_DATASET_URI, $LABELS['abbr-type']);

if( $ISA[$conversion.'UnVersionedDataset'] ) {
//   echo 'abstract';
}

$LARGEST_LOADED_DATASET_URI = C9D::show_loaded_in_endpoint($DATASET_URI, $ENDPOINT, $LABELS['type']);

//c9d_show_types($DATASET_URI, $ISA, $PREFIXES);

if( $ISA[$conversion.'LayerDataset'] ) {
   $PREFIXES = C9D::get_prefixes($DATASET_URI, $ENDPOINT, $LARGEST_LOADED_DATASET_URI);
   C9D::show_example_resources($DATASET, $ENDPOINT, $LARGEST_LOADED_DATASET_URI, $PREFIXES);
}

if( $ISA[$conversion.'VersionedDataset'] ) {
   C9D::show_provenance($DATASET_URI, $ENDPOINT);
}

C9D::show_subsets($DATASET_URI, $ENDPOINT);
echo '</div>'; 
?> 
