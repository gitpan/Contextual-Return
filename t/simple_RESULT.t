use Contextual::Return;

sub bar {
    return 'in bar';
}

sub foo {
    return
        BOOL      { RESULT { 0 }; undef }
        LIST      { RESULT { 1,2,3 }; undef }
        NUM       { RESULT { 42 }; undef }
        STR       { RESULT { 'forty-two' }; undef }
        SCALAR    { RESULT { 86 }; undef }
        SCALARREF { RESULT { \7 }; undef }
        HASHREF   { RESULT { { name => 'foo', value => 99} }; undef }
        ARRAYREF  { RESULT { [3,2,1] }; undef }
        GLOBREF   { RESULT { \*STDERR }; undef }
        CODEREF   { RESULT { \&bar }; undef }
    ;
}

package Other;
use Test::More 'no_plan';

is_deeply [ ::foo() ], [1,2,3]                  => 'LIST context';

is do{ ::foo() ? 'true' : 'false' }, 'false'    => 'BOOLEAN context';

is 0+::foo(), 42                                => 'NUMERIC context';

is "".::foo(), 'forty-two'                      => 'STRING context';

is ${::foo}, 7                                  => 'SCALARREF context';

is_deeply \%{::foo()},
          { name => 'foo', value => 99}         => 'HASHREF context';

is_deeply \@{::foo()}, [3,2,1]                  => 'ARRAYREF context';

is \*{::foo()}, \*STDERR                        => 'GLOBREF context';

is ::foo->(), 'in bar'                          => 'ARRAYREF context';
