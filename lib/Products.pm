package Products;

use strict;
use warnings;
use Mojo::Asset::File;
use Mojo::ByteStream 'b';

my $PRODUCT = {};
my $CATEGORIES = {};

sub new { 
	bless {}, shift;
 };

sub getProduct { 

	return $PRODUCT;

}

sub _build_product_raw_data {
	my $self = shift;
	my $product_id = shift;

    my @products;
    my @product_files   = sort glob 'products/*';
    @product_files      = grep { ! /\.bak$/ } @product_files;

    
    foreach my $product_file (@product_files) {# slurp
    	my $file    = Mojo::Asset::File->new(path => $product_file);
    	my $encoded = $file->slurp;

	    # decode
	    _build_product_data(b($encoded)->decode('utf-8')->to_string);
	}
}

sub _build_product_data {
	my $raw = shift;

	# extract and kill meta data
    my %meta        = ();
    $meta{lc $1}    = $2 while $raw =~ s/^(\w+): (.+)\n+//;

    # arrify tags
    $meta{tags} = [ split /,\s*/ => $meta{tags} // '' ];

	# arrify Zutaten
    $meta{zutaten} = [ split /,\s*/ => $meta{zutaten} // '' ];

	# arrify Nährwerte
    $meta{nährwerte} = [ split /;\s*/ => $meta{nährwerte} // '' ];

    # content is what meta isn't
    my $content = $raw;

    $PRODUCT->{$meta{name}} = {(
    	    	    		description => $content,
    	    	    		preis		=> $meta{preis},
    	    	    		zutaten 	=> $meta{zutaten},
    	    	    		naehrwerte 	=> $meta{nährwerte},
    	    	    		naehrwerte 	=> $meta{nährwerte},
    	    	    		produktbild => $meta{produktbild},
    	    	    		tags		=> $meta{tags},
    	    	    		)};



    return $content;
}

sub build_categories {
	my $self = shift;

	_build_categories();
}

sub _build_categories {
	_build_product_raw_data();

	$CATEGORIES = {};

	foreach my $product (keys $PRODUCT) {
		foreach my $tag (@{$PRODUCT->{$product}->{tags}}) {
			push @{$CATEGORIES->{$tag}}, $product;
		};
	};

	return $CATEGORIES;
}

'false';