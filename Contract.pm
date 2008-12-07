
package Contract;

use strict;

use Exporter qw/import/;
our @EXPORT = qw/contract/;

use Carp qw/croak/;

use Sub::Override;

use Contract::Predicate;

my $err_not_sub = "Not a subroutine name";
my $err_not_pred = "Not a predicate";
my $err_arg_contract = "Argument contract violated: expected ";
my $err_ret_contract = "Return contract violated: expected ";

# When an override objects get destroyed, the original subroutine is 
# restored. To avoid that happening, we keep all the override objects.
my @overs;

sub contract ($$$) {
	my ($sub_name, $args_predicate, $return_predicate) = @_;
	my ($in_package) = caller;
	my $full_sub_name = $in_package . '::' . $sub_name;
	my $original_sub = eval "\\&$full_sub_name";
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
	my $over;
	unless ($over = Sub::Override->new($full_sub_name, $contract_sub)) {
		croak "Error adding contract to subroutine";
	}
	push @overs, $over;
	return undef;
}

1;

