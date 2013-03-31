#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojolicious::Static;

use lib 'lib';
use MyUsers;
use Products;
use Data::Dumper;

# Set the App secret for the signed cookies
app->secret('foo.Bar.####...##..#.#.#.#.ä2.123.12356');

# Documentation browser under "/perldoc"
plugin 'PODRenderer';
plugin Charset => {charset => 'utf-8'};


# User Authentication Helper
helper users => sub { state $users = MyUsers->new };
helper products => sub { state $products = Products->new() };

get '/' => sub {
  my $self = shift;
  $self->render('index');
};

any '/login' => sub {
	my $self = shift;
	my $user = $self->param('user');
	my $pass = $self->param('pass');

    $self->session('authenticated_as' => $user)
      if $self->users->verify($user, $pass);

    # Failed
    $self->render('login') 
       unless $self->session('authenticated_as');

    $self->render('account')
    	if $self->session('authenticated_as');

};

get '/account' => sub {
	my $self = shift;

	$self->render('account');
};

get '/products' => sub {
	my $self = shift;

	$self->products->_build_product_raw_data();

	my %products = %{$self->products->getProduct()};
	my @productNames = keys %products;

	$self->stash(productnames => [@productNames]);
	$self->stash(products => {%products}); 

	$self->render('product_list');
};

get '/products/:product_id' => sub {
	my $self = shift;
	my $product_id = $self->param('product_id') || '';


	$self->products->_build_product_raw_data();

	# $self->app->log->debug(Dumper($self->products->getProduct()));

	my %products = %{$self->products->getProduct()};

    #my %meta        = ();
    #$meta{lc $1}    = $2 while $raw =~ s/^(\w+): (.+)\n+//

	my $zutaten = $products{$product_id}{zutaten};

	$self->stash(description => $products{$product_id}{description});
	$self->stash(preis => $products{$product_id}{preis});
	$self->stash(zutaten => $zutaten);
	$self->stash(naehrwerte => $products{$product_id}{naehrwerte});
	$self->stash(produktbild => $products{$product_id}{produktbild});

	$self->render('product');
};

get '/categories' => sub {
	my $self = shift;

	$self->render('categoryList');
};

get '/categories/:category' => sub {
	my $self = shift;
	my $category = $self->param('category');
	my %categories = %{$self->products->build_categories()};
	
	$self->products->_build_product_raw_data();

	my %products = %{$self->products->getProduct()};

	$self->stash('productlist' 	=> $categories{$category});
	$self->stash(products => {%products}); 

	$self->render('category');
}; 

get '/warenkorb' => sub {
	my $self = shift;
	my @cart = $self->session('cart');
	$self->stash(cart 	=> 	@cart);


	$self->render('cart');
};

get '/warenkorb/add/:product' => sub {
	my $self = shift;

	my @oldproducts = @{$self->session('cart') || []};
	push @oldproducts, $self->param('product');

	$self->session(cart => [@oldproducts]);

	$self->app->log->debug(Dumper($self->session()));

	$self->flash(message => 'Produkt erfolgreich hinzugefügt');
	$self->redirect_to('/');
};

get '/warenkorb/del/:position' => sub {
	my $self = shift;
};

any '/logout' => sub {
	my $self = shift;

	$self->session(expires => 1);

	$self->redirect_to('login');
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Willkommen';
<h2 style="border-bottom: 1px silver dotted;">Willkommen auf suessedeals.de</h2>
<p>Willkommen bei <strong>suessedeals.de</strong>, dem Mitarbeitershop 
der Siller AG. Hier finden sie eine tägliche aktuelle Auswahl an Süßigkeiten 
für Zwischendurch.</p>

<p>Bei Fragen zur Abwicklung und Lieferung bzw. Abholung wendet euch vertrauensvoll
 an <strong>Meik</strong>, bei Problemen mit der Technik steht <strong>Florian</strong> euch für Fragen zur Verfügung.</p>





@@ login.html.ep
% layout 'default';
% title 'Anmelden';
  %= form_for login => begin
    Name:<br>
    %= text_field 'user'
    <br>Password:<br>
    %= password_field 'pass'
    <br>
    %= submit_button 'Login'
  % end





@@ login_sidebar.html.ep
<h2>Anmelden</h2>
  %= form_for login => begin
    Benutzer: 
    %= text_field 'user'
    Kennwort: 
    %= password_field 'pass'
    <br>
    %= submit_button 'Login'
  % end





@@ account_sidebar.html.ep
<h3>Ihr Konto</h3>
<ul class="linkedList">
    <li class="first">
		Angemeldet als: <%= session 'authenticated_as' %>
    </li>
    <li>
    	Warenkorb
    </li>
    <li>
    	Bestellungen
    </li>
	<li class="last">
    	%= link_to 'Abmelden' => '/logout'
	</li>
</ul>





@@ bestseller.html.ep 
<h2>Bestseller</h2>
<ul class="linkedList">
    <li class="first">
    	%= link_to 'PickUp Black & White' => '/products/PickUp Black & White'
    </li>
    <li>
    	%= link_to 'Kinder Riegel' => '/products/Kinder Riegel'
    </li>
    <li>
    	%= link_to 'Maoam Stripes' => '/products/Maoam Stripes'
    </li>
    <li>
    	%= link_to 'Haribo Goldbären' => '/products/Haribo Goldbären'
    </li>
    <li>
    	%= link_to 'Milka & Daim' => '/products/Milka & Daim'
    </li>
	<li class="last">
		%= link_to 'Milka & Oreo' => '/products/Milka & Oreo'
	</li>
</ul>





@@ categories.html.ep
<h2>Kategorien</h2>
<ul class="linkedList">
    <li class="first">
    	%= link_to Gummibärchen => '/categories/Gummibärchen'
    </li>
    <li>
    	%= link_to Kaubonbons => '/categories/Kaubonbons'
    </li>
    <li>
        %= link_to Schokolade => '/categories/Schokolade'
    </li>
	<li class="last">

	</li>
</ul>





@@ product_list.html.ep
% layout 'default';
% title 'Produktübersicht';
<h2>Produktübersicht</h2>
% for my $product ( @$productnames ) {
	<div style="float: left; padding: 15px">
		<a href="/products/<%= $product %>">
		<img src="<%= $products->{$product}->{produktbild}  %>" height="120" width="120"><br />
		<%= $product %>
		</a>
	</div>
% }




@@ product.html.ep
% layout 'default';
% title 'Detailansicht';
<h2 style="border-bottom: 1px silver dotted;">Detailansicht: <%= $self->param('product_id');%></h2>
<div id="box2">
	<a rel="lightbox" href="<%= $produktbild %>">
		<img class="left" src="<%= $produktbild %>" alt="" />
	</a>

	<div style="float: left">
		Preis <%= $preis %> €
	</div>
	<div style="float: right; align: right">
		<%= link_to '/warenkorb/add/' . $self->param('product_id') => begin %><img src="/images/cart_add.png"><% end %>
	</div>

</div>
<div id="box3">
<%= $description %>

	<p> </p>
</div>
<div id="box1">
	<h3>Zutaten: </h3>
	<p>
	<ul class="linkedList">
		<li clasS="first"> <%= @$zutaten[0]; %></li>
		% my $last = @$zutaten[-1];
		% for (my $i = 1; $i < scalar(@{$zutaten}) -1 ; $i++) {
			<li><%= @$zutaten[$i] %></li>
		% }
		<li class="last"><%= $last %></li> 
	</ul>
	</p>

	<h3>Nährwertangaben:</h3> 
	<ul class="linkedList">
		<li clasS="first"> <%= @$naehrwerte[0]; %></li>
		% $last = @$naehrwerte[-1];
		% for (my $i = 1; $i < scalar(@{$naehrwerte}) -1 ; $i++) {
			<li><%= @$naehrwerte[$i] %></li>
		% }
		<li class="last"><%= $last %></li> 
	</ul>
</div>


@@ account.html.ep
% layout 'default';
% title 'Ihr Konto';
<h2>Ihr Konto</h2>
Angemeldet als: <%= session 'authenticated_as' %>
<br />
%= link_to Logout => '/logout'




@@ latest_products.html.ep 
<h2>Neue Produkte</h2>
<ul class="linkedList">
    <li class="first">
		<a href ="/images/daim.jpg" rel="lightbox[latest_products]"><img src="/images/daim_thumb.jpg"></a>
    </li>
</ul>




@@ categoryList.html.ep
% layout 'default';
% title 'Kategorien';
<h2>Kategorien</h2>



@@ category.html.ep
% layout 'default';
% title 'Kategorie';
<h2>Kategorie: <%= $self->param('category'); %></h2>
% foreach my $product (@{$productlist}) {
	<div style="float: left; padding: 15px">
		<a href="/products/<%= $product %>">
		<img src="<%= $products->{$product}->{produktbild}  %>" height="120" width="120"><br />
		<%= $product %>
		</a>
	</div>
% }

@@ cart.html.ep
% layout 'default';
% title 'Warenkorb';
<h2>Warenkorb</h2>
<table width="100%">
% my @cart = @{$cart};
% for my $item (@cart) {
	<tr>
		<td width="95%">
			<%= $item %>
		</td>
		<td><img src="/images/cart_delete.png" /></td>
	</tr>
% }
</table>

@@ layouts/default.html.ep
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<!--

	Design by Free CSS Templates
	http://www.freecsstemplates.org
	Released for free under a Creative Commons Attribution License

	Name       : Faux Mocha
	Version    : 1.0
	Released   : 20130222

-->
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta name="keywords" content="" />
        <meta name="description" content="" />
        <meta http-equiv="content-type" content="text/html; charset=utf-8" />
		<title>suessedeals.de : <%= title %></title>
        <link href="http://fonts.googleapis.com/css?family=Bitter" rel="stylesheet" type="text/css" />
        <link href="/style.css" rel="stylesheet" type="text/css" />
        <script src="/js/jquery-1.7.2.min.js"></script>
		<script src="/js/lightbox.js"></script>
		<link href="/css/lightbox.css" rel="stylesheet" />
    </head>
    <body>
        <div id="outer">
            <div id="header">
                <div id="logo">
                    <h1>
                        <a href="/">suessedeals.de</a>
                    </h1>
                </div>
                <div id="nav">
                    <ul>
                        <li class="first">
                            %= link_to "Ihr Konto" => '/account'
                        </li>
                        <li>
                            %= link_to 'Produkte' => '/products'
                        </li>
                        <li>
                            %= link_to "Warenkorb" => '/warenkorb'
                            % my @cart = @{(session 'cart')||[]};
                            (<%= @cart %>)
                        </li>
                        <li class="last">
                            <a href="#">Contact Us</a>
                        </li>
                    </ul>
                    <br class="clear" />
                </div>
            </div>
            <div id="main">
                <div id="content">
                    		% if (my $msg = flash 'message') {
    							<div style="border-bottom: 1px silver dotted; border-top: 1px silver dotted;">
    								<b><%= $msg %></b><br>
    							</div> 
    							<br />
  								<br />
  							% }

                    	<%= content %>
                    <br class="clear" />
                </div>
                <div id="sidebar1">
					%= $self->render('categories', partial => 1 );

                    % if ($self->session('authenticated_as')) {
                        %= $self->render('account_sidebar', partial => 1);
                    % } else {
                    	%= $self->render('login_sidebar', partial => 1);
                    % }
                </div>
                <div id="sidebar2">
                    %= $self->render('bestseller', partial => 1);

                    %= $self->render('latest_products', partial => 1);
                </div>
                <br class="clear" />
            </div>
        </div>
        <div id="copyright">
				&copy; Your Site Name | Design by <a href="http://www.freecsstemplates.org/">FCT</a>
        </div>
    </body>
</html>

