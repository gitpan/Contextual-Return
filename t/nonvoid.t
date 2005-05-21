use Contextual::Return;
use Test::More 'no_plan';
use Carp;

sub foo {
    return
        NONVOID { 4.2, 9.9 }
        VOID    { croak 'Useless use of foo() in void context' }
    ;
}

# and later...

$foo = foo();
ok $foo                            => 'BOOLEAN context';

is 0+$foo, 9.9                     => 'NUMERIC context';

is "$foo", 9.9                     => 'STRING context';

is join(q{,}, foo()), '4.2,9.9'    => 'LIST context';

ok !eval{ ;foo(); 1; }             => 'VOID context fails';

like $@, qr/\QUseless use of foo() in void context/
                                   => 'Error msg correct';
