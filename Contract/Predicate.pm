
package Contract::Predicate;

use strict;

use Exporter qw/import/;
our @EXPORT = qw/
	two_of repeats repeats_n list_of integer class num_val str_val one_of
	all_of inverse none_of not_all_of meets
/;

use overload '""' => \&to_string;

sub new {
	my ($class, $accepts, $to_string) = @_;
	return bless {
		'accepts' => $accepts,
		'to_string' => $to_string
	}, $class;
}

sub accepts {
	my ($self, @args) = @_;
	return $self->{'accepts'}->(@args);
}

sub to_string {
	my ($self) = @_;
	return $self->{'to_string'}->();
}

sub meets ($) {
	my ($pred) = @_;
	return __PACKAGE__->new($pred, $pred);
}

sub two_of ($) {
	my ($pred) = @_;
	return repeats_n($pred, 2, 2);
}

sub repeats_n ($$$) {
	my ($pred, $min, $max) = @_;
	return __PACKAGE__->new(
		sub {
			my $count = 0;
			foreach (@_) {
				++$count;
				return 0 unless $pred->accepts($_);
			}
			return 0 if $count < $min || $count > $max;
			return 1;
		},
		sub {
			return 
				"repeat $min" . 
				($max == $min ? '' : " to $max") . 
				" times ($pred)";
		}
	);
}

sub repeats ($) {
	my ($pred) = @_;
	return __PACKAGE__->new(
		sub {
			foreach (@_) {
				return 0 unless $pred->accepts($_);
			}
			return 1;
		},
		sub {
			return "repeat ($pred)";
		}
	);
}

sub list_of {
	my (@preds) = @_;
	return __PACKAGE__->new(
		sub {
			return 0 unless @preds == @_;
			foreach (0 .. @_ - 1) {
				return 0 unless $preds[$_]->accepts($_[$_]);
			}
			return 1;
		},
		sub {
			return "(" . join(', ', @preds) . ")";
		}
	);
}

sub integer () {
	return __PACKAGE__->new(
		sub {
			my $n = shift;
			return 0 if @_;
			return $n eq int $n;
		},
		sub {
			return "int";
		}
	);
}

sub class ($) {
	my ($type) = @_;
	return __PACKAGE__->new(
		sub {
			my $o = shift;
			return 0 if @_;
			eval {
				if ($o->isa($type)) {
					return 1;
				}
			};
			return 0;
		},
		sub {
			return "isa $type";
		}
	);
}

sub num_val ($) {
	my ($val) = @_;
	return __PACKAGE__->new(
		sub {
			my $n = shift;
			return 0 if @_;
			return $val == $n;
		},
		sub {
			return "== $val";
		}
	);
}

sub str_val ($) {
	my ($val) = @_;
	return __PACKAGE__->new(
		sub {
			my $n = shift;
			return 0 if @_;
			return $val eq $n;
		},
		sub {
			return "eq $val";
		}
	);
}

sub one_of {
	my (@preds) = @_;
	return __PACKAGE__->new(
		sub {
			my $arg = shift;
			return 0 if @_;
			foreach (@preds) {
				if ($_->accepts($arg)) {
					return 1;
				}
			}
			return 0;
		},
		sub {
			return "one of (" . join(', ', @preds) . ")";
		}
	);
}

sub all_of {
	my (@preds) = @_;
	return __PACKAGE__->new(
		sub {
			my $arg = shift;
			return 0 if @_;
			foreach (@preds) {
				unless ($_->accepts($arg)) {
					return 0;
				}
			}
			return 1;
		},
		sub {
			return "all of (" . join(', ', @preds) . ")";
		}
	);
}

sub inverse ($) {
	my ($pred) = @_;
	return __PACKAGE__->new(
		sub {
			return !$pred->accepts(@_);
		},
		sub {
			return "not $pred";
		}
	);
}

sub none_of {
	return inverse(is_one_of(@_));
}

sub not_all_of {
	return inverse(is_all_of(@_));
}

1;

