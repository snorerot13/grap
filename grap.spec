Summary: grap, typesets graphs for groff
Name: grap
Version: 1.05
Release: 1
Copyright: BSD
Group: Applications/Publishing
Source: http://www.lunabase.org/~faber/Vault/software/grap/grap-1.05.tar.gz

%description
This is grap, an implementation of Kernigan and Bentley\'s grap
language for typesetting graphs.  I got sick of groff not having a
version of grap, so I built one.


%prep
%setup

%build
./configure --prefix=/usr/local
make depend
make 

%install
make install


%files
%defattr(-, root, root)

%doc README
%doc COPYRIGHT
%doc CHANGES

/usr/local/bin/grap
/usr/local/man/man1/grap.1
/usr/local/share/grap/
