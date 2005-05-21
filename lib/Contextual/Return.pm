package Contextual::Return;

use version; $VERSION = qv('0.0.1');

use warnings;
use strict;
use Carp;

# Hide this module from Carp...
BEGIN {
    for my $class (qw( Contextual::Return Contextual::Return::Value )) {
        $Carp::CarpInternal{$class}++;
        $Carp::Internal{$class}++;
    }
}

# Indentation corresponds to inherited fall-back relationships...
my @CONTEXTS = qw(
    DEFAULT
        VOID
        NONVOID
            LIST
            SCALAR
                VALUE
                    STR
                    NUM
                    BOOL
                REF
                    SCALARREF
                    ARRAYREF
                    CODEREF
                    HASHREF
                    GLOBREF
                    OBJREF
);

my %attrs_of;

sub import {
    my $caller = caller;
    for my $subname (@CONTEXTS ) {
        no strict qw( refs );
        *{$caller.'::'.$subname} = \&{$subname};
    }
}

use Scalar::Util qw( refaddr );

sub LIST (;&$) {
    my ($block, $crv) = @_;

    # Handle simple context tests...
    return !!(caller 1)[5] if !@_;

    # Ensure we have an object...
    my $attrs;
    if (!refaddr $crv) {
        my $args = do{ package DB; ()=caller(1); [@DB::args] };
        my $subname = (caller(1))[3];
        $crv = bless \my $scalar, 'Contextual::Return::Value';
        $attrs = $attrs_of{refaddr $crv} = { args => $args, sub => $subname };
    }
    else {
        $attrs = $attrs_of{refaddr $crv};
    }

    # Identify context...
    my $wantarray = wantarray;

    # Handle list context directly...
    return $block->(@{$attrs->{args}}) if $wantarray;

    # Handle void context directly...
    if (!defined $wantarray) {
        $attrs->{VOID}->(@{$attrs->{args}}) if $attrs->{VOID};
        return;
    }

    # Otherwise, cache handler...
    $attrs->{LIST} = $block;
    return $crv;
}


sub VOID (;&$) {
    my ($block, $crv) = @_;

    # Handle simple context tests...
    return !defined( (caller 1)[5] ) if !@_;

    # Ensure we have an object...
    my $attrs;
    if (!refaddr $crv) {
        my $args = do{ package DB; ()=caller(1); [@DB::args] };
        my $subname = (caller(1))[3];
        $crv = bless \my $scalar, 'Contextual::Return::Value';
        $attrs = $attrs_of{refaddr $crv} = { args => $args, sub => $subname };
    }
    else {
        $attrs = $attrs_of{refaddr $crv};
    }

    # Identify context...
    my $wantarray = wantarray;

    # Handle list context directly, if possible...
    if (wantarray) {
        for my $context_handler (qw(LIST NONVOID DEFAULT)) {
            my $handler = $attrs->{$context_handler} or next;
            return $handler->(@{$attrs->{args}});
        }
        if (my $handler = $attrs->{ARRAYREF}) {
            my $array_ref = $handler->(@{$attrs->{args}});
            return @{$array_ref} if (ref $array_ref||q{}) eq 'ARRAY';
        }
        croak "Can't call $attrs->{sub} in list context";
    }

    # Handle void context directly...
    if (!defined $wantarray) {
        $block->(@{$attrs->{args}});
        return;
    }

    # Otherwise, cache handler...
    $attrs->{VOID} = $block;
    return $crv;
}

for my $context (qw( SCALAR NONVOID )) {
    no strict qw( refs );
    *{$context} = sub (;&$) {
        my ($block, $crv) = @_;

        # Handle simple context tests...
        if (!@_) {
            my $callers_context = (caller 1)[5];
            return defined $callers_context
                && ($context eq 'NONVOID' || !$callers_context);
        }

        # Ensure we have an object...
        my $attrs;
        if (!refaddr $crv) {
            my $args = do{ package DB; ()=caller(1); [@DB::args] };
            my $subname = (caller(1))[3];
            $crv = bless \my $scalar, 'Contextual::Return::Value';
            $attrs = $attrs_of{refaddr $crv}
                    = { args => $args, sub => $subname };
        }
        else {
            $attrs = $attrs_of{refaddr $crv};
        }

        # Make sure this block is a possibility too...
        $attrs->{$context} = $block;

        # Identify context...
        my $wantarray = wantarray;

        # Handle list context directly, if possible...
        if (wantarray) {
            for my $context_handler (qw(LIST NONVOID DEFAULT)) {
                my $handler = $attrs->{$context_handler} or next;
                return $handler->(@{$attrs->{args}});
            }
            if (my $handler = $attrs->{ARRAYREF}) {
                my $array_ref = $handler->(@{$attrs->{args}});
                return @{$array_ref} if (ref $array_ref||q{}) eq 'ARRAY';
            }
            croak "Can't call $attrs->{sub} in list context";
        }

        # Handle void context directly...
        if (!defined $wantarray) {
            $attrs->{VOID}->(@{$attrs->{args}}) if $attrs->{VOID};
            return;
        }

        # Otherwise, defer evaluation by returning an object...
        return $crv;
    }
}

for my $context (@CONTEXTS) {
    next if $context eq 'LIST'     # These
         || $context eq 'VOID'     #  three
         || $context eq 'SCALAR'   #   handled
         || $context eq 'NONVOID'; #    separately

    no strict qw( refs );
    *{$context} = sub (&;$) {
        my ($block, $crv) = @_;

        # Ensure we have an object...
        my $attrs;
        if (!refaddr $crv) {
            my $args = do{ package DB; ()=caller(1); [@DB::args] };
            my $subname = (caller(1))[3];
            $crv = bless \my $scalar, 'Contextual::Return::Value';
            $attrs = $attrs_of{refaddr $crv}
                   = { args => $args, sub => $subname };
        }
        else {
            $attrs = $attrs_of{refaddr $crv};
        }

        # Make sure this block is a possibility too...
        $attrs->{$context} = $block;

        # Identify context...
        my $wantarray = wantarray;

        # Handle list context directly, if possible...
        if (wantarray) {
            for my $context_handler (qw(LIST NONVOID DEFAULT)) {
                my $handler = $attrs->{$context_handler} or next;
                return $handler->(@{$attrs->{args}});
            }
            if (my $handler = $attrs->{ARRAYREF}) {
                my $array_ref = $handler->(@{$attrs->{args}});
                return @{$array_ref} if (ref $array_ref||q{}) eq 'ARRAY';
            }
            croak "Can't call $attrs->{sub} in list context";
        }

        # Handle void context directly...
        if (!defined $wantarray) {
            $attrs->{VOID}->(@{$attrs->{args}}) if $attrs->{VOID};
            return;
        }

        # Otherwise, defer evaluation by returning an object...
        return $crv;
    }
}

package Contextual::Return::Value;
use Carp;
use Scalar::Util qw( refaddr );

use overload (
    q{""} => sub {
        my ($self) = @_;
        my $attrs = $attrs_of{refaddr $self};
        for my $context_handler (qw(STR SCALAR VALUE NONVOID DEFAULT NUM)) {
            my $handler = $attrs->{$context_handler} or next;
            return scalar $handler->(@{$attrs->{args}});
        }
        croak "Can't call $attrs->{sub} in string context";
    },

    q{0+} => sub {
        my ($self) = @_;
        my $attrs = $attrs_of{refaddr $self};
        for my $context_handler (qw(NUM SCALAR VALUE NONVOID DEFAULT STR)) {
            my $handler = $attrs->{$context_handler} or next;
            return scalar $handler->(@{$attrs->{args}});
        }
        croak "Can't call $attrs->{sub} in numeric context";
    },

    q{bool} => sub {
        my ($self) = @_;
        my $attrs = $attrs_of{refaddr $self};
        for my $context_handler (qw(BOOL SCALAR VALUE NONVOID DEFAULT)) {
            my $handler = $attrs->{$context_handler} or next;
            return scalar $handler->(@{$attrs->{args}});
        }
        croak "Can't call $attrs->{sub} in boolean context";
    },
    '${}' => sub {
        my ($self) = @_;
        my $attrs = $attrs_of{refaddr $self};
        for my $context_handler (qw(SCALARREF REF NONVOID DEFAULT)) {
            my $handler = $attrs->{$context_handler} or next;
            return $handler->(@{$attrs->{args}});
        }
        for my $context_handler (qw(STR NUM SCALAR VALUE)) {
            my $handler = $attrs->{$context_handler} or next;
            my $value = $handler->(@{$attrs->{args}});
            return \$value;
        }
        return \$self;
    },
    '@{}' => sub {
        my ($self) = @_;
        my $attrs = $attrs_of{refaddr $self};
        for my $context_handler (qw(ARRAYREF REF)) {
            my $handler = $attrs->{$context_handler} or next;
            return $handler->(@{$attrs->{args}});
        }
        for my $context_handler (qw(LIST VALUE NONVOID DEFAULT)) {
            my $handler = $attrs->{$context_handler} or next;
            return [$handler->(@{$attrs->{args}})];
        }
        return [ $self ];
    },
    '%{}' => sub {
        my ($self) = @_;
        my $attrs = $attrs_of{refaddr $self};
        for my $context_handler (qw(HASHREF REF NONVOID DEFAULT)) {
            my $handler = $attrs->{$context_handler} or next;
            return scalar $handler->(@{$attrs->{args}});
        }
        croak "$attrs->{sub} can't return a hash reference";
    },
    '&{}' => sub {
        my ($self) = @_;
        my $attrs = $attrs_of{refaddr $self};
        for my $context_handler (qw(CODEREF REF NONVOID DEFAULT)) {
            my $handler = $attrs->{$context_handler} or next;
            return scalar $handler->(@{$attrs->{args}});
        }
        croak "$attrs->{sub} can't return a subroutine reference";
    },
    '*{}' => sub {
        my ($self) = @_;
        my $attrs = $attrs_of{refaddr $self};
        for my $context_handler (qw(GLOBREF REF NONVOID DEFAULT)) {
            my $handler = $attrs->{$context_handler} or next;
            return scalar $handler->(@{$attrs->{args}});
        }
        croak "$attrs->{sub} can't return a typeglob reference";
    },

    fallback => 1,
);

sub DESTROY {
    delete $attrs_of{refaddr shift};
    return;
}

sub AUTOLOAD {
    my ($self) = shift;
    my $attrs = $attrs_of{refaddr $self};
    our $AUTOLOAD;
    $AUTOLOAD =~ s/.*:://xms;
    for my $context_handler (qw(OBJREF STR SCALAR VALUE NONVOID DEFAULT)) {
        my $handler = $attrs->{$context_handler} or next;
        my $object  = scalar $handler->(@{$attrs->{args}});
        if (wantarray) {
            my @result = eval { $object->$AUTOLOAD(@_) };
            return @result if !$@;
        }
        else {
            my $result = eval { $object->$AUTOLOAD(@_) };
            return $result if !$@;
        }
        croak "Can't call method '$AUTOLOAD' on $context_handler value returned by $attrs->{sub}";
    }
    croak "Can't call method '$AUTOLOAD' on value returned by $attrs->{sub}";
}

1; # Magic true value required at end of module

__END__

=head1 NAME

Contextual::Return - Create context-senstive return values


=head1 VERSION

This document describes Contextual::Return version 0.0.1


=head1 SYNOPSIS

    use Contextual::Return;
    use Carp;

    sub foo {
        return
            SCALAR { 'thirty-twelve' }
            BOOL   { 1 }
            NUM    { 7*6 }
            STR    { 'forty-two' }

            LIST   { 1,2,3 }

            HASHREF   { {name => 'foo', value => 99} }
            ARRAYREF  { [3,2,1] }

            GLOBREF   { \*STDOUT }
            CODEREF   { croak "Don't use this result as code!"; }
        ;
    }

    # and later...

    if (my $foo = foo()) {
        for my $count (1..$foo) {
            print "$count: $foo is:\n"
                . "    array: @{$foo}\n"
                . "    hash:  $foo->{name} => $foo->{value}\n"
                ;
        }
        print {$foo} $foo->();
    }

=head1 DESCRIPTION

Usually, when you need to create a subroutine that returns different values in
different contexts (list, scalar, or void), you write something like:

    sub get_server_status {
        my ($server_ID) = @_;

        # Acquire server data somehow...
        my %server_data = _ascertain_server_status($server_ID);

        # Return different components of that data,
        # depending on call context...
        if (wantarray()) {
            return @server_data{ qw(name uptime load users) };
        }
        if (defined wantarray()) {
            return $server_data{load};
        }
        if (!defined wantarray()) {
            carp 'Useless use of get_server_status() in void context';
            return;
        }
        else {
            croak q{Bad context! No biscuit!};
        }
    }

That's works okay, but the code could certainly be more readable. In
it's simplest usage, this module makes that code more readable by
providing three subroutines--C<LIST()>, C<SCALAR()>, C<VOID()>--that
are true only when the current subroutine is called in the
corresponding context:

    use Contextual::Return;

    sub get_server_status {
        my ($server_ID) = @_;

        # Acquire server data somehow...
        my %server_data = _ascertain_server_status($server_ID);

        # Return different components of that data
        # depending on call context...
        if (LIST)   { return @server_data{ qw(name uptime load users) } }
        if (SCALAR) { return $server_data{load}                         }
        if (VOID)   { print "$server_data{load}\n"                      }
        else        { croak q{Bad context! No biscuit!}                 }
    }

=head2 Contextual returns

Those three subroutines can also be used in another way: as labels on a
series of I<contextual return blocks> (collectively known as a I<context
sequence>). When a context sequence is returned, it automatically
selects the appropriate contextual return block for the calling context.
So the previous example could be written even more cleanly as:

    use Contextual::Return;

    sub get_server_status {
        my ($server_ID) = @_;

        # Acquire server data somehow...
        my %server_data = _ascertain_server_status($server_ID);

        # Return different components of that data
        # depending on call context...
        return (
            LIST    { return @server_data{ qw(name uptime load users) } }
            SCALAR  { return $server_data{load}                         }
            VOID    { print "$server_data{load}\n"                      }
            DEFAULT { croak q{Bad context! No biscuit!}                 }
        );
    }

The context sequence automatically selects the appropriate block for each call
context.


=head2 Lazy contextual return values

C<LIST> and C<VOID> blocks are always executed during the C<return>
statement. However, C<SCALAR> blocks are not. Instead, in scalar
contexts, returning a C<SCALAR> block causes the subroutine to return an
object that lazily evaluates that block every time a value is required.

This means that returning a C<SCALAR> block is a convenient way to
implement a subroutine with a lazy return value. For example:

    sub digest {
        return SCALAR {
            my ($text) = @_;
            md5($text);
        }
    }

    my $digest = digest($text);

    print $digest;   # md5() called only when $digest used as string

That also means that the value returned via a C<SCALAR> block can be
"active", re-evaluated every time it is used:

    sub make_counter {
        my $counter = 0;
        return SCALAR { $counter++ }
    }

    my $idx = make_counter();

    print "$idx\n";    # 0
    print "$idx\n";    # 1
    print "$idx\n";    # 2


=head2 Finer distinctions of scalar context

Because the scalar values returned from a context sequence are lazily
evaluated, it becomes possible to be more specific about I<what kind> of
scalar value should be returned: a boolean, a number, or a string. To support
those distinctions, Contextual::Return provides three extra context blocks:
C<BOOL>, C<NUM>, and C<STR>:

    sub get_server_status {
        my ($server_ID) = @_;

        # Acquire server data somehow...
        my %server_data = _ascertain_server_status($server_ID);

        # Return different components of that data
        # depending on call context...
        return (
               LIST { @server_data{ qw(name uptime load users) }  }
               BOOL { $server_data{uptime} > 0                    }
                NUM { $server_data{load}                          }
                STR { "$server_data{name}: $server_data{uptime}"  }
               VOID { print "$server_data{load}\n"                }
            DEFAULT { croak q{Bad context! No biscuit!}           }
        );
    }

With these in place, the object returned from a scalar-context call to
C<get_server_status()> now behaves differently, depending on how
it's used. For example:

    if ( my $status = get_server_status() ) {  # True if uptime > 0
        $load_distribution[$status]++;         # Evaluates to load value
        print "$status\n";                     # Prints name: uptime
    }


=head2 Referential contexts

The other major kind of scalar return value is a reference.
Contextual::Return provides context blocks that allow you to specify
what to (lazily) return when the return value of a subroutine is used as
a reference to a scalar (C<SCALARREF {...}>), to an array (C<ARRAYREF
{...}>), to a hash (C<HASHREF {...}>), to a subroutine (C<CODEREF {...}>), or
to a typeglob (C<GLOBREF {...}>).

For example, the server status subroutine shown earlier could be extended to
allow it to return a hash reference, thereby supporting "named return values":

    sub get_server_status {
        my ($server_ID) = @_;

        # Acquire server data somehow...
        my %server_data = _ascertain_server_status($server_ID);

        # Return different components of that data
        # depending on call context...
        return (
               LIST { @server_data{ qw(name uptime load users) }  }
               BOOL { $server_data{uptime} > 0                    }
                NUM { $server_data{load}                          }
                STR { "$server_data{name}: $server_data{uptime}"  }
               VOID { print "$server_data{load}\n"                }
            HASHREF { return \%server_data                        }
            DEFAULT { croak q{Bad context! No biscuit!}           }
        );
    }

    # and later...

    my $users = get_server_status->{users};


    # or, lazily...

    my $server = get_server_status();

    print "$server->{name} load = $server->{load}\n";


=head2 Interpolative referential contexts

The C<SCALARREF {...}> and C<ARRAYREF {...}> context blocks are
especially useful when you need to interpolate a subroutine into
strings. For example, if you have a subroutine like:

    sub get_todo_tasks {
        return (
            SCALAR { scalar @todo_list }      # How many?
            LIST   { @todo_list        }      # What are they?
        );
    }

    # and later...

    print "There are ", scalar(get_todo_tasks()), " tasks:\n",
          get_todo_tasks();

then you could make it much easier to interpolate calls to that
subroutine by adding:

    sub get_todo_tasks {
        return (
            SCALAR { scalar @todo_list }      # How many?
            LIST   { @todo_list        }      # What are they?

            SCALARREF { \scalar @todo_list }  # Ref to how many
            ARRAYREF  { \@todo_list        }  # Ref to them
        );
    }

    # and then...

    print "There are ${get_todo_tasks()} tasks:\n@{get_todo_tasks()}";

In fact, this behaviour is so useful that it's the default. If you
don't provide an explicit C<SCALARREF {...}> block,
Contextual::Return automatically provides an implicit one that simply
returns a reference to whatever would have been returned in scalar context.
Likewise, if no C<ARRAYREF {...}> block is specified, the module supplies one
that returns the list-context return value wrapped up in an array reference.

So, in fact, you could just write:

    sub get_todo_tasks {
        return (
            SCALAR { scalar @todo_list }      # How many?
            LIST   { @todo_list        }      # What are they?
        );
    }

    # and still do this...

    print "There are ${get_todo_tasks()} tasks:\n@{get_todo_tasks()}";


=head2 Fallback contexts

As the previous sections imply, the C<BOOL {...}>, C<NUM {...}>, C<STR
{...}>, and various C<*REF {...}> blocks, are special cases of the
general C<SCALAR {...}> context block. If a subroutine is called in one
of these specialized contexts but does not use the corresponding context
block, then the more general C<SCALAR {...}> block is used instead (if
it has been specified).

So, for example:

    sub read_value_from {
        my ($fh) = @_;

        my $value = <$fh>;
        chomp $value;

        return (
            BOOL   { defined $value }
            SCALAR { $value         }
        );
    }

ensures that the C<read_value_from()> subroutine returns true in boolean
contexts if the read was successful. But, because no specific C<NUM {...}>
or C<STR {...}> return behaviours were specified, the subroutine falls back on
using its generic C<SCALAR {...}> block in all other scalar contexts.

Another way to think about this behaviour is that the various kinds of
scalar context blocks form a hierarchy:

    SCALAR
       ^
       |
       |--< BOOL
       |
       |--< NUM
       |
       `--< STR

Contextual::Return uses this hierarchical relationship to choose the most
specific context block available to handle any particular return context,
working its way up the tree from the specific type it needs, to the more
general type, if that's all that is available.

There are two slight complications to this picture. The first is that Perl
treats strings and numbers as interconvertable so the diagram (and the
Contextual::Return module) also has to allow these interconversions as a
fallback strategy:

    SCALAR
       ^
       |
       |--< BOOL
       |
       |--< NUM
       |    : ^
       |    v :
       `--< STR

The dotted lines are meant to indicate that this intraconversion is secondary
to the main hierarchical fallback. That is, in a numeric context, a C<STR
{...}> block will only be used if there is no C<NUM {...}> block I<and> no
C<SCALAR {...}> block. In other words, the generic context type is always
used in preference to string<->number conversion.

The second slight complication is that the above diagram only shows a
small part of the complete hierarchy of contexts supported by
Contextual::Return. The full fallback hierarchy (including dotted
interconversions) is:

    DEFAULT
       ^
       |
       |--< VOID
       |
       `--< NONVOID
               ^
               |
               |--< VALUE <..............
               |      ^                 :
               |      |                 :
               |      |--< SCALAR <.....:..
               |      |       ^           :
               |      |       |           :
               |      |       |--< BOOL   :
               |      |       |           :
               |      |       |--< NUM <..:..
               |      |       |    : ^      :
               |      |       |    v :      :
               |      |       `--< STR <....:..
               |      |                       :
               |      `--< LIST               :
               |            : ^               :
               |            : :               :
               `--- REF     : :               :
                     ^      : :               :
                     |      v :               :
                     |--< ARRAYREF            :
                     |                        :
                     |--< SCALARREF ..........:
                     |
                     |--< HASHREF
                     |
                     |--< CODEREF
                     |
                     |--< GLOBREF
                     |
                     `--< OBJREF

As before, each dashed arrow represents a fallback relationship. That
is, if the required context specifier isn't available, the arrows are
followed until a more generic one is found. The dotted arrows again
represent the interconversion of return values, which is
attempted only after the normal hierarchical fallback fails.

In other words, if a subroutine is called in a context that expects a
scalar reference, but no C<SCALARREF {...}> block is provided, then
Contextual::Return tries the following blocks in order:

        REF {...}
    NONVOID {...}
    DEFAULT {...}
        STR {...} (automatically taking a reference to the result)
        NUM {...} (automatically taking a reference to the result)
     SCALAR {...} (automatically taking a reference to the result)
      VALUE {...} (automatically taking a reference to the result)

Likewise, in a list context, if there is no C<LIST {...}> context block, the
module tries:

       VALUE {...}
     NONVOID {...}
     DEFAULT {...}
    ARRAYREF {...} (automatically dereferencing the result)

The more generic context blocks are especially useful for intercepting
unexpected and undesirable call contexts. For example, to turn I<off>
the automatic scalar-ref and array-ref interpolative behaviour described
in L<Interpolative referential contexts>, you could intercept I<all>
referential contexts using a generic C<REF {...}> context block:

    sub get_todo_tasks {
        return (
            SCALAR { scalar @todo_list }      # How many?
            LIST   { @todo_list        }      # What are they?

            REF { croak q{get_todo_task() can't be used as a reference} }
        );
    }

    print 'There are ', get_todo_tasks(), '...';    # Still okay
    print "There are ${get_todo_tasks()}...";       # Throws an exception

    

=head1 INTERFACE 

=head2 Context tests

=over 

=item C<< LIST() >>

Returns true if the current subroutine was called in list context.
A cleaner way of writing: C<< wantarray() >>

=item C<< SCALAR() >>

Returns true if the current subroutine was called in scalar context.
A cleaner way of writing: C<< defined wantarray() && ! wantarray() >>

=item C<< VOID() >>

Returns true if the current subroutine was called in void context.
A cleaner way of writing: C<< !defined wantarray() >>

=item C<< NONVOID() >>

Returns true if the current subroutine was called in list or scalar context.
A cleaner way of writing: C<< defined wantarray() >>

=back

=head2 Standard contexts

=over 

=item C<< LIST {...} >>

The block specifies what the context sequence should evaluate to when
called in list context.

=item C<< SCALAR {...} >>

The block specifies what the context sequence should evaluate to in
scalar contexts, unless some more-specific specifier scalar context specifier
(see below) also occurs in the same context sequence.

=item C<< VOID {...} >>

The block specifies what the context sequence should do when
called in void context.

=back

=head2 Scalar value contexts

=over

=item C<< BOOL {...} >>

The block specifies what the context sequence should evaluate to when
treated as a boolean value.

=item C<< NUM {...} >>

The block specifies what the context sequence should evaluate to when
treated as a numeric value.

=item C<< STR {...} >>

The block specifies what the context sequence should evaluate to when
treated as a string value.

=back

=head2 Scalar reference contexts

=over

=item C<< SCALARREF {...} >>

The block specifies what the context sequence should evaluate to when
treated as a reference to a scalar.

=item C<< ARRAYREF {...} >>

The block specifies what the context sequence should evaluate to when
treated as a reference to an array.

=item C<< HASHREF {...} >>

The block specifies what the context sequence should evaluate to when
treated as a reference to a hash.

Note that a common error here is to write:

    HASHREF { a=>1, b=>2, c=>3 }

The curly braces there are a block, not a hash constructor, so the block
doesn't return a hash reference and the interpreter throws an exception.
What's needed is:

    HASHREF { {a=>1, b=>2, c=>3} }

in which the inner braces I<are> a hash constructor.

=item C<< CODEREF {...} >>

The block specifies what the context sequence should evaluate to when
treated as a reference to a subroutine.

=item C<< GLOBREF {...} >>

The block specifies what the context sequence should evaluate to when
treated as a reference to a typeglob.

=item C<< OBJREF {...} >>

The block specifies what the context sequence should evaluate to when
treated as a reference to an object.

=back

=head2 Generic contexts

=over

=item C<< VALUE {...} >>

The block specifies what the context sequence should evaluate to when
treated as a non-referential value (as a boolean, numeric, string,
scalar, or list). Only used if there is no more-specific value context
specifier in the context sequence.

=item C<< REF {...} >>

The block specifies what the context sequence should evaluate to when
treated as a reference of any kind. Only used if there is no
more-specific referential context specifier in the context sequence.

=item C<< NONVOID {...} >>

The block specifies what the context sequence should evaluate to when
used in a non-void context of any kind. Only used if there is no
more-specific context specifier in the context sequence.

=item C<< DEFAULT {...} >>

The block specifies what the context sequence should evaluate to when
used in a void or non-void context of any kind. Only used if there is no
more-specific context specifier in the context sequence.

=back

=head1 DIAGNOSTICS

=over 

=item Can't call %s in %s context";

The subroutine you called uses a contextual return, but doesn't specify what
to return in the particular context in which you called it. You either need to
change the context in which you're calling the subroutine, or else add a
context block corresponding to the offending context (or perhaps a
C<DEFAULT {...}> block).

=item %s can't return a %s reference";

You called the subroutine in a context that expected to get back a
reference of some kind but the subroutine didn't specify the
corresponding C<SCALARREF>, C<ARRAYREF>, C<HASHREF>, C<CODEREF>,
C<GLOBREF>, or generic C<REF>, C<NONVOID>, or C<DEFAULT> handlers.
You need to specify the appropriate one of these handlers in the subroutine.

=item Can't call method '%s' on %s value returned by %s";

You called the subroutine and then tried to call a method on the return
value, but the subroutine returned a classname or object that doesn't
have that method. This probably means that the subroutine didn't return
the classname or object you expected. Or perhaps you need to specify
an C<OBJREF {...}> context block.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Contextual::Return requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
