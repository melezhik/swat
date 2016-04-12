use inc::Module::Install;

# Define metadata
name           'swat';
abstract       'simple web application tests';

all_from       'lib/swat.pm';

# Specific dependencies
requires    'Test::More';
requires    'Test::Harness';
requires    'File::Temp';
requires    'Outthentic::DSL' => '0.0.10';
requires    'Config::Tiny';
requires    'YAML';
requires    'Term::ANSIColor' => '4.02';

license     'perl';
repository  'https://github.com/melezhik/swat';

install_script 'bin/swat';
no_index    directory => 'examples';

WriteAll;

