# IP-Pakken

## To create an installer

* Download emacs binaries and place in emacs-24.3
    Link: http://ftp.gnu.org/gnu/emacs/windows/
* Download Moscow ML binaries and place in mosml
    Link: http://www.mosml.org
* Download and install Inno Setup (non-unicode version)
    Link: http://www.jrsoftware.org/isinfo.php
* Open the .iss file and select Build > Compile from the menu.

## Tested with

* emacs 24.3, full binary distribution
* Moscow ML 2.10
* InnoSetup 5.5.5 non-unicode

## Gotchas

* If debugging the installer, please do note that it does not write a .emacs if it already exists, nor does the uninstaller remove it.

## License

IP-Pakken - Bundled installer for Emacs, Moscow ML and SML mode used for the former course Introduction to Programming at University of Copenhagen.
Copyright (C) 2016  Sebastian Paaske Tørholm

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
