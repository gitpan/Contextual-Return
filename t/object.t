use Contextual::Return;
use Test::More 'no_plan';

sub foo_no_obj {
    return
        VALUE { bless {}, 'Bar' }
    ;
}

sub foo_with_obj {
    return
        VALUE { 1 } 
        OBJREF { bless {}, 'Bar' }
    ;
}

sub foo_bad_obj {
    return
        VALUE { 1 } 
        OBJREF { 1 }
    ;
}


is foo_no_obj()->bar, "baaaaa!\n"       => 'VALUE returns object';
ok !eval{ foo_no_obj()->baz }           => 'Object has no baz() method';
like $@,
     qr/\A\QCan't call method 'baz' on VALUE value returned by main::foo_no_obj/
                                        => 'Error msg was correct';

is foo_with_obj()->bar, "baaaaa!\n"     => 'OBJREF returns object';
ok !eval{ foo_with_obj()->baz }         => 'Object still has no baz() method';
like $@,
     qr/\A\QCan't call method 'baz' on OBJREF value returned by main::foo_with_obj/
                                        => 'Error msg was also correct';

ok !eval{ foo_bad_obj()->bar }          => 'OBJREF returns bad object';
like $@,
     qr/\A\QCan't call method 'bar' on OBJREF value returned by main::foo_bad_obj/
                                        => 'Error msg was still correct';
package Bar;

sub bar { "baaaaa!\n" }
