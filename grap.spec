Summary: grap, a grapher for groff
Name: grap
Version: 1.01
Release: 1
Copyright: BSD
Group: Applications/Publishing
Source: http://www.lunabase.org/~faber/Vault/software/grap/grap-0.95b.tar.gz

%description
This is grap, an implementation of Kernigan and Bentley's grap
language for typesetting graphs.  I got sick of groff not having a
version of grap, so I built one.


%prep
%setup

%build
MYCFLAGS="$RPM_OPT_FLAGS"

CFLAGS="$MYCFLAGS" ./configure --prefix=%prefix

%install
rm -rf $RPM_BUILD_ROOT
make prefix=$RPM_BUILD_ROOT%{prefix} install


%files
%defattr(-, root, root)

%doc README
%doc COPYRIGHT
%doc CHANGES

%{prefix}/bin/grap
%{prefix}/man/man1/grap.1
%{prefix}/share/grap/examples
%{prefix}/share/grap/grap.defines
%{prefix}/share/grap/README
%{prefix}/share/grap/COPYRIGHT
%{prefix}/share/grap/CHANGES
