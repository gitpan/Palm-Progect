#!/bin/sh

mkdir -p docs

pod2html bin/progconv                             >  docs/progconv.html
pod2html lib/Palm/Progect/Converter/CSV.pm        >  docs/Progect-Converter-CSV.html
pod2html lib/Palm/Progect/Converter/Text.pm       >  docs/Progect-Converter-Text.html
pod2html lib/Palm/Progect/Converter.pm            >  docs/Progect-Converter.html
pod2html lib/Palm/Progect/Date.pm                 >  docs/Progect-Date.html
pod2html lib/Palm/Progect/Prefs.pm                >  docs/Progect-Prefs.html
pod2html lib/Palm/Progect/Record.pm               >  docs/Progect-Record.html
pod2html lib/Palm/Progect/VersionDelegator.pm     >  docs/Progect-VersionDelegator.html
pod2html lib/Palm/Progect.pm                      >  docs/Progect.html
