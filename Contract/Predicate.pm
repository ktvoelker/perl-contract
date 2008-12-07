
package Contract::Predicate;

use strict;
use warnings;

use Exporter;
our @EXPORT = qw//;

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

sub repeats {
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

sub is_list_of {
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

sub is_int {
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

sub is_class {
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

sub is_num_value {
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
	});
}

sub is_str_value {
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
	});
}

sub is_one_of {
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

sub is_all_of {
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

sub inverse {
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

sub is_none_of {
	return inverse(is_one_of(@_));
}

sub is_not_all_of {
	return inverse(is_all_of(@_));
}

1;

