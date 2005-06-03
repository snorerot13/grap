Summary: grap, typesets graphs for groff
Name: grap
Version: 1.36
Release: 1
Copyright: BSD
Group: Applications/Publishing
Source: grap-1.35.tar.gz

%description
This is grap, an implementation of Kernigan and Bentley\'s grap
language for typesetting graphs. 


%prep
%setup

%build
./configure --prefix=/usr/ --mandir=/usr/share/man
make 

%install
make install


%files
%defattr(-, root, root)

%doc README
%doc COPYRIGHT
%doc CHANGES

/usr/bin/grap
/usr/share/man/man1/grap.1
/usr/share/grap/
/usr/share/doc/grap/
