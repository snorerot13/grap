Summary: grap, a grapher for groff
Name: grap
Version: 0.91a
Release: 0
Copyright: BSD
Group: Applications/Publishing
Source: http://www.lunabase.org/~faber/Vault/software/grap/grap-0.91a.tar.gz
Patch1: grap-redhat-linux.patch

%description
This is grap, an implementation of Kernigan and Bentley's grap
language for typesetting graphs.  I got sick of groff not having a
version of grap, so I built one.


%prep
%setup

%build
./configure --prefix=/usr

%install
make install


%files
%doc README
%doc COPYRIGHT
%doc CHANGES
/usr/bin/grap
/usr/man/man1/grap.1
/usr/share/grap/examples
/usr/share/grap/grap.defines
/usr/share/grap/README
/usr/share/grap/COPYRIGHT
/usr/share/grap/CHANGES
