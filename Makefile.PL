use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	        => 'Palm::Progect',
    'VERSION_FROM'	=> 'lib/Palm/Progect.pm', # finds $VERSION
    'PREREQ_PM'	    => {
        'Palm::PDB'          => '1',
        'Palm::StdAppInfo'   => '1',
        'Palm::Raw'          => '1',
        'CLASS'              => '0',
        'Class::Accessor'    => '0',
        'Class::Constructor' => '0',
    },                              
    'EXE_FILES'     => [ 'bin/progconv' ],
    'PMLIBDIRS'     => [ 'lib' ],
);


