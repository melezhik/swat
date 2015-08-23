use inc::Module::Install;

# Define metadata
name           'swat';
all_from       'lib/swat.pm';

# Specific dependencies
requires       'Test::More';
requires       'Test::Harness';

license 'perl';

WriteAll;

