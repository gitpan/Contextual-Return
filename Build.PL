use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Contextual::Return',
    license             => 'perl',
    dist_author         => 'Damian Conway <DCONWAY@cpan.org>',
    dist_version_from   => 'lib/Contextual/Return.pm',
    requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Contextual-Return-*' ],
);

$builder->create_build_script();
