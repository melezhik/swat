use inc::Module::Install;

# Define metadata
name           'swat';
all_from       'lib/swat.pm';

# Specific dependencies
requires    'Test::More';
requires    'Test::Harness';
requires    'File::ShareDir'; 
license     'perl';
install_script 'bin/swat';

WriteAll;

