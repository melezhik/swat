use inc::Module::Install;

# Define metadata
name           'swat';
abstract       'simple web application tests';

all_from       'lib/swat.pm';

# Specific dependencies
requires    'Test::More';
requires    'Test::Harness';
requires    'File::ShareDir'; 
requires    'File::Temp';
license     'perl';

install_script 'bin/swat';
no_index    directory => 'examples';

WriteAll;

