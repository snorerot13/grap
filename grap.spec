# -*-rpm-spec-*-
%define	prefix   %{_prefix}
%define version 1.43

Summary: grap, typesets graphs for groff
Name: grap
Version: %{version}
Release: 1
License: BSD
Group: Applications/Publishing
Source: http://www.lunabase.org/~faber/Vault/software/grap/grap-%{version}.tar.gz
BuildRoot: /var/tmp/grap-%{version}

%description
This is grap, an implementation of Kernighan and Bentley\'s grap
language for typesetting graphs. 


%prep
%setup

%build
./configure --prefix=%{prefix} --mandir=%{prefix}/share/man
make prefix=$RPM_BUILD_ROOT%{prefix} MANDIR=$RPM_BUILD_ROOT%{prefix}/share/man/man1

%install
make prefix=$RPM_BUILD_ROOT%{prefix} MANDIR=$RPM_BUILD_ROOT%{prefix}/share/man/man1 install


%files
%defattr(-, root, root)

%doc README
%doc COPYRIGHT
%doc CHANGES

%{prefix}/bin/grap
%{prefix}/share/man/man1/grap.1.gz
%{prefix}/share/grap/
%{prefix}/share/examples/grap/
%{prefix}/share/doc/grap/



