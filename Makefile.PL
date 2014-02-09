#
# Copyright (C) 2014 by Tomasz Konojacki
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.18.2 or,
# at your option, any later version of Perl 5 you may have available.
#

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Tie::ConfigFile',
    VERSION_FROM      => 'lib/Tie/ConfigFile.pm',
    PREREQ_PM         => {
        IO::File   => 0,
        File::Temp => 0
    },
    ABSTRACT_FROM  => 'lib/Tie/ConfigFile.pm',
    AUTHOR         => 'Tomasz Konojacki <me@xenu.tk>',
    META_MERGE    => {
         resources => {
             repository => 'http://code.xenu.tk/repos.cgi/tie-configfile'
         }
    },
);