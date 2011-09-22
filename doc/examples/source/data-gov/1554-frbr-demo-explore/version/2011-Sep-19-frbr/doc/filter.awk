{
        if ( $0~/#hasHash/ ) {}
   else if ( $0~/#TabularDigest/ ) {}
   else if ( $0~/#hashAlgorithm/ ) {}
   else if ( $0~/#hashValue/ ) {}
   else if ( $0~/#reproductionOf>.*<hash:Item/ ) {}
   else if ( $0~/<hash:Item.*frbr.core#>/ ) {}
   else if ( $0~/p.surfrdf/ ) {}
   else { print }
}
