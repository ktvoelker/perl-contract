
package Contract;

use strict;
use warnings;

use Exporter;
our @EXPORT = qw/contract/;

use Carp qw/croak/;

use Contract::Predicate;

my $err_not_sub = "Not a subroutine name";
my $err_not_pred = "Not a predicate";
my $err_arg_contract = "Argument contract violated: expected ";
my $err_ret_contract = "Return contract violated: expected ";

sub contract {
	my ($sub_name, $args_predicate, $return_predicate) = @_;
	my ($in_package) = caller;
	my $original_sub = eval "\\&$in_package::$sub_name";
	if ($@) {
		croak $err_not_sub;
	}
	eval {
		unless (
				$args_predicate->isa('Contract::Predicate') && 
				$return_predicate->isa('Contract::Predicate')) {
			croak $err_not_pred;
		}
	};
	if ($@) {
		croak $err_not_pred;
	}
	my $contract_sub = sub {
		my @args = @_;
		if ($args_predicate->accepts(@args)) {
			my $err = $err_ret_contract . $return_predicate;
			my $wa = wantarray;
			if ($wa) {
				my @ret = $original_sub->(@_);
				if ($return_predicate->accepts(@ret)) {
					return @ret;
				}
				else {
					croak $err;
				}
			}
			elsif (defined $wa) {
				my $ret = $original_sub->(@_);
				if ($return_predicate->accepts($ret)) {
					return $ret;
				}
				else {
					croak $err;
				}
			}
			else {
				return $original_sub->(@_);
			}
		}
		else {
			croak $err_arg_contract . $args_predicate;
		}
	};
	eval "\\*$in_package::$sub_name = \$contract_sub";
	if ($@) {
		croak "Error adding contract to subroutine";
	}
	return undef;
}

1;

