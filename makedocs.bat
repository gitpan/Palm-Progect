@echo off

md docs

set pod2html=perl -S pod2html.bat

%pod2html% bin\progconv                             >  docs\progconv.html
if errorlevel 1 set pod2html=perl -S pod2html.pl

%pod2html% bin\progconv                             >  docs\progconv.html
%pod2html% lib\Palm\Progect\Converter\CSV.pm        >  docs\Progect-Converter-CSV.html
%pod2html% lib\Palm\Progect\Converter\Text.pm       >  docs\Progect-Converter-Text.html
%pod2html% lib\Palm\Progect\Converter.pm            >  docs\Progect-Converter.html
%pod2html% lib\Palm\Progect\Date.pm                 >  docs\Progect-Date.html
%pod2html% lib\Palm\Progect\Prefs.pm                >  docs\Progect-Prefs.html
%pod2html% lib\Palm\Progect\Record.pm               >  docs\Progect-Record.html
%pod2html% lib\Palm\Progect\VersionDelegator.pm     >  docs\Progect-VersionDelegator.html
%pod2html% lib\Palm\Progect.pm                      >  docs\Progect.html
