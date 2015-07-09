use 5.020002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'swat',
    VERSION_FROM      => 'lib/swat.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/swat.pm', # retrieve abstract from module
    AUTHOR            => 'Alexey Melezhik <melezhik@gmail.com>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI

    PREREQ_PM => {
        "Test::More" => 0,
        "Test::Harness" => 0,
    }
);
