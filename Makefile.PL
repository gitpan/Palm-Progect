use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	        => 'Palm::Progect',
    'VERSION_FROM'	=> 'Progect.pm', # finds $VERSION
    'PREREQ_PM'	    => {
        # 'Palm::PDB'        => '1.19',
        # 'Palm::StdAppInfo' => '1.11',
        # 'Palm::Raw'        => '1.8',
        'Palm::PDB'        => '1',
        'Palm::StdAppInfo' => '1',
        'Palm::Raw'        => '1',
    },
    'EXE_FILES'     => [ 'bin/progconv' ],
);


