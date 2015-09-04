# 0.1.40
- fix for bash global startup script
- export port variable

# 0.1.39
- swat cleanup/startup hooks
- route_dir variable in lib/swat.pm

# 0.1.38
- small documentation changes

# 0.1.37
- bash hooks

# 0.1.36
- fix for default host for swat packages


# 0.1.35
- swat.my settings to override project based swat.ini files
- all bash variables get unset before a new route is started 
- added examples to cpan distro

# 0.1.34
- removed pwd from require path to hook.pm files
- fix for regexp checks with quoted patterns

# 0.1.33
- documentation typo fixes - thanks to @zoffixznet - pull/1
- small refactoring ( better names for variables )
- added abstract and copyright sections


# 0.1.32
- small documentation fixes
- does not print result of File::ShareDir::module_dir in conditional statement  
- respect prove_options set as environment variable

# 0.1.31
- correct calculation of swat settings 

# 0.1.30
- hotfix for curl_params='' issue 

# 0.1.29
- technical release, ./examples directory removed from CPAN archive   

# 0.1.28
- Makefile.PL - use Module::Install instead of ExtUtils::MakeMaker
- swatman is depricated
- now swat packages as cpan packages
- apply environment settings with highest priority


# 0.1.27
- prove options could be set by prove_options environment variable 
- typos fixes in documentation
- default host  feature 
- host validation

# 0.1.24
- fix for running swat ./

# 0.1.23
- dynamic routes

# 0.1.22
- removed none ASCII symbols from pod

# 0.1.21
- swat hooks
- documentation fixes 

# 0.1.20
- a documentation release

# 0.1.18
- swat packages support
- PERL5LIB in swat doc


# 0.1.17
- update documentation
- add version() function to get swat package version


# 0.1.15
- update documentation 
- noproxy deprecated
- multiline entities

# 0.1.13
- Add swat entities generators 
- Add noproxy settings
- Fix pod documentation 


# 0.1.12
- Add pod documentation to lib/swat.pm

# 0.1.11
- Makefile.PL sets swat.pm version in provides hash to make it visible at CPAN

# 0.1.10
- CPAN compatible version ( minor fixes in Makefile.PL )

# 0.1.9
- Makefile.PL - does not require any specific version of perl 

# 0.1.8
- http port variable
- update documentation 
- improve examples


# 0.1.7
- small fixes related swat settings 
- add some extra info in swat output 
- a lot of improvements to documentation
- add todo list

# 0.1.6
- does not add http:// for requested url 

# 0.1.5
- curl_params variable now is respected 
- small internal changes ( path to session file )


# 0.1.4
- fix typos in README
- notion of prove options in README
- add some extra info in swat output 


# 0.1.3
- fix for case when post and get check patterns files exist for the same route
- typo fixes in lib/swat.pm help info 

# 0.1.1
- increase connect-timeout to 20 seconds


# 0.1.0
- first version
