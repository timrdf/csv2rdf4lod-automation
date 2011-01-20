#include <time.h>
#include <stdio.h>
#include <inttypes.h>
#include <getopt.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/stat.h>
#include <pcre.h>
#include <raptor.h>
#include <redland.h>
#include <sys/time.h>
#include <time.h>
#include "avl.h"

typedef struct {
	pcre *re_resource_matches;
	struct avl_table* file_cache;
	struct avl_table* bnode_heads;
	struct avl_table* filename_cache;
	librdf_model* model;
	librdf_storage* storage;
	struct timeval execution_start_time;
	long count;
	const char* rdf_filename;
	const char* url;
	const char* base;
	char* in_format;
	char* out_formats;
	char* uri_pattern;
	char* file_pattern;
	int apache;
	int dryrun;
	int verbose;
	int progress;
} parser_ctx;

typedef struct {
	char* filename;
	FILE* fp;
} file_cache_item;

typedef struct {
	char* uri;
	char* filename;
} filename_cache_item;

typedef struct {
	char* uri;
	raptor_sequence* seq;
} bnode_heads_item;

static librdf_world* world;
static int MAX_OPEN_FILES				= 240;
static int FILE_CACHE_REFRESH_INTERVAL	= 4096;

void help (int argc, char** argv) {
	fprintf( stderr, "Usage: %s data.rdf\n\n", argv[0] );
}

int _str_ptr_cmp ( const void* _a, const void* _b, void* param ) {
	const char** a	= (const char**) _a;
	const char** b	= (const char**) _b;
	return strcmp(*a, *b);
}

int myavl_strcmp (  const void* _a, const void* _b, void* param ) {
	return strcmp(_a, _b);
}

void myavl_free ( void* avl_item, void* avl_param ) {
	free(avl_item);
}

void _file_cache_free_item ( void* avl_item, void* avl_param ) {
	file_cache_item* item	= (file_cache_item*) avl_item;
	free(item->filename);
	fclose(item->fp);
	free(item);
}

void _bnode_heads_free_item ( void* avl_item, void* avl_param ) {
	bnode_heads_item* item	= (bnode_heads_item*) avl_item;
	free(item->uri);
	raptor_free_sequence(item->seq);
	free(item);
}

void _filename_cache_free_item ( void* avl_item, void* avl_param ) {
	filename_cache_item* item	= (filename_cache_item*) avl_item;
	free(item->uri);
	free(item->filename);
	free(item);
}

double elapsed_time ( parser_ctx* ctx ) {
	struct timeval t;
	gettimeofday(&t, NULL);
	long sec	= t.tv_sec - ctx->execution_start_time.tv_sec;
	long usec	= t.tv_usec - ctx->execution_start_time.tv_usec;
	if (usec < 0.0) {
		sec		-= 1.0;
		usec	= 1000000 + usec;
	}
	
	double elapsed	= ((double) sec) + ((double) usec / 1000000);
	return elapsed;
}

char* copy_string ( const char* src ) {
	char* dest	= malloc( strlen(src) + 1 );
	strcpy( dest, src );
	return dest;
}

int file_exists ( parser_ctx* ctx, const char* filename ) {
	struct stat info;
	int ret = -1;
	ret = stat(filename, &info);
	if(ret == 0)  {
		//stat() is able to get the file attributes,
		//so the file obviously exists
		return 1;
    } else {
		//stat() is not able to get the file attributes,
		//so the file obviously does not exist or
		//more capabilities is required
		return 0;
    }
}

void make_path ( parser_ctx* ctx, const char* path ) {
	char* parent	= copy_string( path );
	char* p			= rindex(parent, '/');
	if (p != NULL) {
		*p			= '\0';
		if (!file_exists(ctx, parent)) {
			if (ctx->verbose)
				fprintf( stderr, "parent dir: %s\n", parent );
			make_path( ctx, parent );
		}
	}
	free(parent);
	if (!file_exists(ctx, path)) {
		if (ctx->verbose)
			fprintf( stderr, "creating %s\n", path );
		mkdir(path,0777);
	}
}

librdf_node* new_node ( const void* node, raptor_identifier_type type, char* lang, raptor_uri* dt ) {
	librdf_node* n	= NULL;
	char* value;
	char* language;
	librdf_uri* datatype;
	switch (type) {
		case RAPTOR_IDENTIFIER_TYPE_RESOURCE:
		case RAPTOR_IDENTIFIER_TYPE_PREDICATE:
			value		= (char*) raptor_uri_as_string((raptor_uri*)node);
			n			= librdf_new_node_from_uri_string(world, (unsigned char*) value);
			break;
		case RAPTOR_IDENTIFIER_TYPE_ANONYMOUS:
			value		= (char*) node;
			n			= librdf_new_node_from_blank_identifier(world, (unsigned char*) value);
			break;
		case RAPTOR_IDENTIFIER_TYPE_LITERAL:
			value		= (char*)node;
			if(lang && type == RAPTOR_IDENTIFIER_TYPE_LITERAL) {
				language	= (char*) lang;
				n			= librdf_new_node_from_typed_literal(world, (unsigned char*) value, language, NULL);
			} else if (dt) {
				datatype	= librdf_new_uri(world, (unsigned char*) raptor_uri_as_string((raptor_uri*) dt));
				n			= librdf_new_node_from_typed_literal(world, (unsigned char*) value, NULL, datatype);
			} else {
				n			= librdf_new_node_from_typed_literal(world, (unsigned char*) value, NULL, NULL);
			}
			break;
		case RAPTOR_IDENTIFIER_TYPE_XML_LITERAL:
			value		= (char*) node;
			n			= librdf_new_node_from_literal(world, (unsigned char*) value, NULL, 1);
			break;
		case RAPTOR_IDENTIFIER_TYPE_ORDINAL:
			value		= (char*) malloc( 64 );
			if (value == NULL) {
				fprintf( stderr, "*** malloc failed in _hx_parser_node\n" );
			}
			sprintf( value, "http://www.w3.org/1999/02/22-rdf-syntax-ns#_%d", *((int*) node) );
			n			= librdf_new_node_from_uri_string(world, (unsigned char*) value);
			free(value);
			break;
		case RAPTOR_IDENTIFIER_TYPE_UNKNOWN:
		default:
			fprintf(stderr, "*** unknown node type %d\n", type);
			return NULL;
	}
	return n;
}

char* filename_for_node( parser_ctx* ctx, char* uri ) {
	filename_cache_item* item	= (filename_cache_item*) avl_find( ctx->filename_cache, &uri );
	if (item)
		return copy_string(item->filename);
	
	
	char* p;
	int OVECCOUNT	= 30;
	int ovector[OVECCOUNT];
	int rc = pcre_exec(
		ctx->re_resource_matches,	/* the compiled pattern */
		NULL,						/* no extra data - we didn't study the pattern */
		uri,						/* the subject string */
		strlen(uri),				/* the length of the subject */
		0,							/* start at offset 0 in the subject */
		0,							/* default options */
		ovector,					/* output vector for substring information */
		OVECCOUNT					/* number of elements in the output vector */
	);
	if (rc < 0) {
		switch(rc) {
			case PCRE_ERROR_NOMATCH: break;
			default: printf("Matching error %d\n", rc); break;
		}
		return NULL;
	}
	if (rc == 0) {
		rc = OVECCOUNT/3;
		printf("ovector only has room for %d captured substrings\n", rc - 1);
	}
	
	size_t len;
	char* substituted_file;
	char* file	= copy_string( ctx->file_pattern );
	raptor_iostream* iostr	= raptor_new_iostream_to_string((void**) &substituted_file, &len, NULL);
	
	p	= file;
	while (*p != '\0') {
		if ((*p == '\\' || *p == '$') && (p[1] >= '0' && p[1] <= '9')) {
			p++;
			int capture	= atoi(p);
			while (p[0] >= '0' && p[0] <= '9')
				p++;
			char *substring_start = uri + ovector[2*capture];
			int substring_length = ovector[2*capture+1] - ovector[2*capture];
			raptor_iostream_write_counted_string(iostr, substring_start, substring_length);
		} else {
			raptor_iostream_write_byte(iostr,*p);
			p++;
		}
	}
	raptor_free_iostream(iostr);
	free(file);
	file	= substituted_file;
	char* filename	= malloc( strlen(ctx->base) + strlen(file) + 4 );
	sprintf( filename, "%s%s.nt", ctx->base, file );
	free(file);
	
	
	item			= malloc(sizeof(filename_cache_item));
	item->uri		= copy_string(uri);
	item->filename	= copy_string(filename);
	avl_insert( ctx->filename_cache, item );
	
	return filename;
}

void clear_file_cache (parser_ctx* ctx) {
	avl_destroy( ctx->file_cache, _file_cache_free_item );
	ctx->file_cache	= avl_create( _str_ptr_cmp, NULL, &avl_allocator_default );
}

FILE* open_file ( parser_ctx* ctx, const char* filename, int* should_close ) {
	FILE* fp;
	file_cache_item* item;
	item	= (file_cache_item*) avl_find( ctx->file_cache, &filename );
	if (item) {
// 		fprintf( stderr, "Got cached file pointer for %s\n", filename );
		fp	= item->fp;
		*should_close	= 0;
		return fp;
	}
	fp	= fopen(filename, "a");
	if (!fp) {
		perror( "Cannot open ntriples file" );
		return NULL;
	}
	
	long count	= avl_count(ctx->file_cache);
// 	fprintf( stderr, "Cache has %ld items\n", count );
	if (count < MAX_OPEN_FILES) {
		if (!item) {
			item			= malloc(sizeof(file_cache_item));
			item->filename	= copy_string(filename);
			item->fp		= fp;
			if (ctx->verbose)
				fprintf( stderr, "Caching file pointer for %s\n", filename );
			avl_insert( ctx->file_cache, item );
		}
	} else {
		*should_close	= 1;
	}
	return fp;
}

void append_triple_to_file ( parser_ctx* ctx, const raptor_statement* triple, const char* filename ) {
	int should_close	= 0;
	FILE* fp	= open_file( ctx, filename, &should_close );
	
	raptor_iostream* iostr	= raptor_new_iostream_to_file_handle(fp);
	raptor_iostream_write_statement_ntriples(iostr,triple);
	raptor_free_iostream(iostr);
	
	if (should_close)
		fclose(fp);
}

int cond_add_triple_for_node ( parser_ctx* ctx, const raptor_statement* triple, librdf_node* term ) {
	char* p;
	librdf_node_type type	= librdf_node_get_type(term);
	if (type != LIBRDF_NODE_TYPE_RESOURCE)
		return 0;
	char* uri		= (char*) librdf_uri_to_string(librdf_node_get_uri(term));
	char* filename	= filename_for_node( ctx, uri );
	if (!filename)
		return 0;
// 	fprintf( stderr, "*** full filename: %s\n", full_filename );
	char* path			= malloc( strlen(filename) + 1 );
	p				= rindex(filename, '/');
	strncpy(path, filename, (p-filename));
// 	fprintf( stderr, "*** path: %s\n", path );
	
// 	(undef, my $path, my $thing)	= File::Spec->splitpath( File::Spec->catfile( $base, $file ) );
// 	unless ($paths{ $path }) {
// 		warn "Creating directory $path ...\n" if ($debug > 1);
// 		$paths{ $path }++;
// 		$files_per_dir{ $path }	= 0;
// 		unless ($dryrun) {
// 			make_path( $path );
// 		}
// 	}
	free(path);
	
// 	fprintf(stderr, "filename: %s\n", filename);
	if (!ctx->dryrun) {
		char* path	= copy_string( filename );
		char* p		= rindex(path, '/');
		*p			= '\0';
		make_path( ctx, path );
		free(path);
	}

	
	if (!file_exists(ctx, filename)) {
		if (ctx->verbose)
			fprintf( stderr, "Creating file %s\n", filename );


// 		$files_per_dir{ $path }++;
// 		if ($files_per_dir > 0 and $files_per_dir{ $path } > $files_per_dir) {
// 			warn "*** Hit maximum file limit in directory $path. Materialized data will be incomplete.\n";
// 			next;
// 		}
// 		$files_created++;
// 		$files{ $filename }++;
	}
	if (!ctx->dryrun) {
		append_triple_to_file( ctx, triple, filename );
	}
	free(filename);
	return 1;
}

int parser_handle_triple_node (parser_ctx* ctx, const raptor_statement* triple, const void* node, raptor_identifier_type type, char* lang, raptor_uri* dt, raptor_sequence* added, raptor_sequence* bnodes) {
	int bnode	= 0;
	int add	= 0;

	librdf_node* term	= new_node( node, type, lang, dt );
	if (type == RAPTOR_IDENTIFIER_TYPE_ANONYMOUS) {
		bnode	= 1;
		raptor_sequence_push( bnodes, librdf_new_node_from_node(term) );
	}
	add	= cond_add_triple_for_node( ctx, triple, term );
	if (add) {
		raptor_sequence_push( added, librdf_new_node_from_node(term) );
	}
	librdf_free_node(term);
	return bnode;
}

void parser_handle_triple (void* user_data, const raptor_statement* triple) {
	parser_ctx* ctx	= (parser_ctx*) user_data;
	ctx->count++;
	
	if (ctx->progress) {
		if (ctx->count % ctx->progress == 0) {
			double elapsed	= elapsed_time(ctx);
			double tps		= ((double) ctx->count) / elapsed;
			fprintf( stderr, "\rParsed %ld triples (%.1lf triples/second)", ctx->count, tps );
		}
	}
	
	if (ctx->count % FILE_CACHE_REFRESH_INTERVAL == 0) {
		clear_file_cache(ctx);
	}
	
	int bnode	= 0;
	raptor_sequence* added	= raptor_new_sequence(NULL,NULL);
	raptor_sequence* bnodes	= raptor_new_sequence(NULL,NULL);
	
	librdf_node* s	= new_node( (void*) triple->subject, triple->subject_type, NULL, NULL );
	librdf_node* p	= new_node( (void*) triple->predicate, triple->predicate_type, NULL, NULL );
	librdf_node* o	= new_node( (void*) triple->object, triple->object_type, (char*) triple->object_literal_language, triple->object_literal_datatype );
	librdf_statement* st	= librdf_new_statement_from_nodes(world,s,p,o);
	
	bnode		|= parser_handle_triple_node( ctx, triple, triple->subject, triple->subject_type, NULL, NULL, added, bnodes );
	bnode		|= parser_handle_triple_node( ctx, triple, triple->object, triple->object_type, (char*) triple->object_literal_language, triple->object_literal_datatype, added, bnodes );
	
	if (bnode) {
		librdf_model_add_statement(ctx->model, st);
		
		int i;
		int added_seq_size	= raptor_sequence_size(added);
		for (i = 0; i < added_seq_size; i++) {
			librdf_node* u	= (librdf_node*) raptor_sequence_get_at(added,i);
			char* uri	= (char*) librdf_uri_to_string(librdf_node_get_uri(u));
			bnode_heads_item* item	= (bnode_heads_item*) avl_find( ctx->bnode_heads, &uri );
			if (!item) {
				item	= malloc(sizeof(bnode_heads_item));
				item->uri	= copy_string(uri);
				item->seq	= raptor_new_sequence(NULL,NULL);
				avl_insert(ctx->bnode_heads, item );
			}
			int j;
			int list_size	= raptor_sequence_size(bnodes);
			for (j = 0; j < list_size; j++) {
				raptor_sequence_push(item->seq, raptor_sequence_get_at(bnodes,j));
			}
		}
	} else {
		librdf_free_statement(st);
	}
// 	
// 	if ($count) {
// 		if ($triples_processed % $count == 0) {
// 			print_progress();
// 		}
// 	}
	
	raptor_free_sequence(added);
	raptor_free_sequence(bnodes);
	
}

void bounded_description ( parser_ctx* ctx, librdf_model* model, librdf_node* blank, char* uri ) {
	librdf_statement* st	= librdf_new_statement_from_nodes(world, blank, NULL, NULL);
	librdf_stream* s		= librdf_model_find_statements(ctx->model, st);
	while (!librdf_stream_end(s)) {
		librdf_statement* t	= librdf_stream_get_object(s);
		librdf_model_add_statement(model, t);
		librdf_node* obj	= librdf_statement_get_object(t);
		librdf_node_type o_type	= librdf_node_get_type(obj);
		if (o_type == LIBRDF_NODE_TYPE_BLANK) {
			bounded_description(ctx, model, obj, uri);
		}
// FOR EACH TRIPLE t IN BOUNDED DESCRIPTION:
// 		next if ($t->subject->isa('RDF::Trine::Node::Resource') and $t->subject->uri_value eq $uri);
// 		next if ($t->object->isa('RDF::Trine::Node::Resource') and $t->object->uri_value eq $uri);
// 		cond_add_triple_for_node( $t, RDF::Trine::Node::Resource->new($uri) );
		librdf_stream_next(s);
	}
	librdf_free_stream(s);
	return;
}

void new_config ( parser_ctx* ctx, int argc, char** argv ) {
	int argi					= 1;
	int requiredi				= 0;
	ctx->count					= 0;
	ctx->file_cache				= avl_create( _str_ptr_cmp, NULL, &avl_allocator_default );
	ctx->bnode_heads			= avl_create( _str_ptr_cmp, NULL, &avl_allocator_default );
	ctx->filename_cache			= avl_create( _str_ptr_cmp, NULL, &avl_allocator_default );
	gettimeofday(&(ctx->execution_start_time), NULL);
	
	ctx->storage				= librdf_new_storage(world, "trees", "test", "new='yes'");
	if (!(ctx->storage))
		ctx->storage			= librdf_new_storage(world, "hashes", "test", "hash-type='memory',new='yes'");
	if (!(ctx->storage)) {
		fprintf( stderr, "Cannot construct storage object\n" );
		exit(1);
	}
		
	ctx->model					= librdf_new_model(world, ctx->storage, NULL);
	if (!(ctx->model)) {
		fprintf( stderr, "Cannot construct model object\n" );
		exit(1);
	}
	ctx->dryrun					= 0;
	ctx->verbose				= 0;
	ctx->progress				= 0;
	ctx->rdf_filename			= NULL;
	ctx->url					= NULL;
	ctx->base					= NULL;
	ctx->in_format				= "rdfxml";
	ctx->out_formats			= "rdfxml-abbrev";
	ctx->uri_pattern			= "/resource/(.*)";
	ctx->file_pattern			= "/data/$1";
	ctx->apache					= 0;
	
	while (argi < argc) {
		if (*(argv[argi]) == '-') {
			if (strncmp(argv[argi], "-i=",3) == 0) {
				ctx->in_format	= malloc(strlen(argv[argi]) - 2);
				strcpy(ctx->in_format, &(argv[argi][3]));
			} else if (strncmp(argv[argi], "-o=",3) == 0) {
				ctx->out_formats	= malloc(strlen(argv[argi]) - 2);
				strcpy(ctx->out_formats, &(argv[argi][3]));
			} else if (strncmp(argv[argi], "--directoryindex=",17) == 0) {
				// ignore for now
			} else if (strncmp(argv[argi], "--concurrency=",14) == 0) {
				if (ctx->verbose)
					fprintf( stderr, "Ignoring %s argument\n", argv[argi] );
				// ignore for now
			} else if (strncmp(argv[argi], "--progress=",11) == 0) {
				ctx->progress	= atoi(&(argv[argi][11]));
			} else if (strncmp(argv[argi], "--buffer-size=",13) == 0) {
				if (ctx->verbose)
					fprintf( stderr, "Ignoring %s argument\n", argv[argi] );
				// ignore for now
			} else if (strncmp(argv[argi], "--uripattern=",13) == 0) {
				ctx->uri_pattern	= malloc(strlen(argv[argi]) - 12);
				strcpy(ctx->uri_pattern, &(argv[argi][13]));
			} else if (strncmp(argv[argi], "--filepattern=",14) == 0) {
				ctx->file_pattern	= malloc(strlen(argv[argi]) - 13);
				strcpy(ctx->file_pattern, &(argv[argi][14]));
			} else if (strcmp(argv[argi], "-D") == 0) {
				if (ctx->verbose)
					fprintf( stderr, "Ignoring %s %s argument\n", argv[argi], argv[argi+1] );
				// ignore for now
				argi++;
			} else if (strcmp(argv[argi], "--apache") == 0) {
				ctx->apache++;
			} else if (strcmp(argv[argi], "-v") == 0) {
				ctx->verbose++;
			} else {
				fprintf( stderr, "Unrecognized option %s\n", argv[argi] );
				exit(1);
			}
		} else {
			switch (requiredi) {
				case 0:
					ctx->rdf_filename	= argv[argi];
					break;
				case 1:
					ctx->url			= argv[argi];
					break;
				case 2:
					ctx->base			= argv[argi];
					break;
			};
			requiredi++;
		}
// 		if (strcmp(argv[argi], "-nodemap") == 0) {
// 			argi++;
// 		}
		argi++;
	}
	
	const char *error;
	int erroffset;
	char* resource_matches_pattern	= malloc(2+strlen(ctx->url)+strlen(ctx->uri_pattern));
	sprintf(resource_matches_pattern,"^%s%s", ctx->url, ctx->uri_pattern);
// 	fprintf( stderr, "PATTERN: %s\n", resource_matches_pattern );
	ctx->re_resource_matches = pcre_compile(
		resource_matches_pattern,	/* the pattern */
		0,							/* default options */
		&error,						/* for error message */
		&erroffset,					/* for error offset */
		NULL						/* use default character tables */
	);
	if (ctx->re_resource_matches == NULL) {
		printf("PCRE compilation failed at offset %d: %s\n", erroffset, error);
		exit(1);
	}
}

void print_apache_config (parser_ctx* ctx) {
	printf( "\n# Apache Configuration:\n" );
	printf( "#######################\n" );
	char* match	= &((ctx->uri_pattern)[1]);
	char* p	= ctx->file_pattern;
// 		my $redir	= $outre;
// 		$redir		=~ s/\\(\d+)/\$$1/g;
// 		if ($dir_index) {
// 			print "DirectoryIndex $dir_index\n\n";
// 		}
	printf( "Options +MultiViews\n" );
	printf( "AddType text/turtle .ttl\n" );
	printf( "AddType text/plain .nt\n" );
	printf( "AddType application/rdf+xml .rdf\n" );
	printf( "\n" );
	printf( "RewriteEngine On\n" );
	printf( "RewriteBase /\n" );
	printf( "RewriteRule ^%s$ ", match );
	while (*p != '\0') {
		if (*p == '\\') {
			char* q = p+1;
			if (*q >= '0' && *q < '9') {
				int capture	= atoi( q );
				printf( "$%d", capture );
				while (*q >= '0' && *q < '9') {
					q++;
				}
				p	= q-1;
			} else {
				printf( "\\" );
			}
		} else {
			printf( "%c", *p );
		}
		p++;
	}
	printf( "\t[R=303,L]\n" );
	printf( "#######################\n\n" );
}


// lod-materialize
// -i=ntriples
// --uripattern="/source/([^/]+)/dataset/(.*)"
// --filepattern="/source/\\1/file/\\2"
// --apache
// publish/data-gov-3250-2010-Aug-23.nt
// http://logd.tw.rpi.edu
// publish/lod-mat
int main (int argc, char** argv) {
	if (argc == 1) {
		help(argc, argv);
		exit(1);
	}
	raptor_init();
	world	= librdf_new_world();
	parser_ctx ctx;
	new_config( &ctx, argc, argv );
	
	fprintf( stderr, "Input format             : %s\n", ctx.in_format );
	fprintf( stderr, "Output formats           : %s\n", ctx.out_formats );
	fprintf( stderr, "URI Pattern              : %s\n", ctx.uri_pattern );
	fprintf( stderr, "File Pattern             : %s\n", ctx.file_pattern );
	
	if (ctx.apache) {
		print_apache_config(&ctx);
		exit(0);
	}
	
	if (argc < 4) {
		help(argc, argv);
		exit(1);
	}
	
	unsigned char* uri_string	= raptor_uri_filename_to_uri_string( ctx.rdf_filename );
	raptor_uri* uri				= raptor_new_uri(uri_string);
	const char* parser_name		= raptor_guess_parser_name(NULL, NULL, NULL, 0, uri_string);
	raptor_parser* rdf_parser	= raptor_new_parser( parser_name );
	raptor_uri *base_uri		= raptor_uri_copy(uri);
	
	raptor_set_statement_handler(rdf_parser, &ctx, parser_handle_triple);
//	raptor_set_generate_id_handler(rdf_parser, &ctx, _parser_generate_id);
	
	raptor_parse_file(rdf_parser, uri, base_uri);
	fprintf( stderr, "\nFinished parsing %ld triples\n", ctx.count );
	
	
	
	int bnode_model_size	= librdf_model_size(ctx.model);
	if (ctx.verbose)
		fprintf(stderr, "Blank Node model has size %d\n", bnode_model_size);
	if (bnode_model_size > 0) {
		struct avl_traverser iter;
		avl_t_init( &iter, ctx.bnode_heads );
		bnode_heads_item* item;
		while ((item = (bnode_heads_item*) avl_t_next( &iter )) != NULL) {
			librdf_storage* store	= librdf_new_storage(world, "hashes", "test", "hash-type='memory',new='yes'");
			librdf_model* bd_model	= librdf_new_model(world, store, NULL);
			char* uri				= item->uri;
			raptor_sequence* bnodes	= item->seq;
			struct avl_table* seen	= avl_create(myavl_strcmp, NULL, &avl_allocator_default);
			int size	= raptor_sequence_size(bnodes);
			int i;
			for (i = 0; i < size; i++) {
				librdf_node* blank	= raptor_sequence_get_at(bnodes,i);
				char* bnode_id		= (char*) librdf_node_get_blank_identifier(blank);
// 				fprintf( stderr, "adding blank node %s to file for %s\n", bnode_id, uri );
				char* p	= avl_find(seen, bnode_id);
				if (!p) {
					bounded_description( &ctx, bd_model, blank, uri );
// 					my $bditer	= $bnode_model->bounded_description( $blank );
// 					while (my $t = $bditer->next) {
// 					}
				}
			}
			avl_destroy(seen, myavl_free);
			
			
			int should_close	= 0;
			char* filename		= filename_for_node( &ctx, uri );
			if (filename) {
// 				fprintf( stderr, "serializing blank nodes for %s to file %s\n", uri, filename);
				FILE* fp			= open_file( &ctx, filename, &should_close );
				if (fp) {
					librdf_serializer* serializer	= librdf_new_serializer(world, "ntriples", NULL, NULL);
					librdf_serializer_serialize_model_to_file_handle(serializer, fp, NULL, bd_model);
					librdf_free_serializer(serializer);
					if (should_close)
						fclose(fp);
				} else {
					perror( "failed to open file" );
				}
			}
			
			librdf_free_model(bd_model);
			librdf_free_storage(store);
		}
	}
	
	
// 	if (ctx.verbose) {
// 		fprintf( stderr, "BNODES:\n" );
// 		raptor_iostream* iostr	= raptor_new_iostream_to_file_handle(stdout);
// 		librdf_model_write(ctx.model, iostr);
// 		raptor_free_iostream(iostr);
// 	}
	
	
	
	double elapsed	= elapsed_time(&ctx);
	double tps		= ((double) ctx.count) / elapsed;
	fprintf( stderr, "\rDone materializing %ld triples (%.1lf triples/second)", ctx.count, tps );
	
	
	
	pcre_free(ctx.re_resource_matches);     /* Release memory used for the compiled pattern */
//	free( uri_string );
	raptor_free_parser(rdf_parser);
	raptor_free_uri( base_uri );
	raptor_free_uri( uri );
	
	avl_destroy( ctx.file_cache, _file_cache_free_item );
	avl_destroy( ctx.bnode_heads, _bnode_heads_free_item );
	avl_destroy( ctx.filename_cache, _filename_cache_free_item );
	
	librdf_free_model(ctx.model);
	librdf_free_storage(ctx.storage);
	
	librdf_free_world(world);

	fprintf( stderr, "\nDone\n" );
	return 0;
}
