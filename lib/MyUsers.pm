package MyUsers;

use strict;
use warnings;

my $USERS = {
		florian => 'password',
		admin => 'password'
	};

sub new { bless {}, shift }

sub verify {
	my ($self, $user, $pass) = @_;

	return 1 if $USERS->{$user} && $USERS->{$user} eq $pass;

	return undef;
}

'false';