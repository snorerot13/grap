Summary: grap, a grapher for groff
Name: grap
Version: 0.8a
Release: 0
Copyright: BSD with no commercial reproduction
Group: Applications/Publishing
Source: http://www.lunabase.org/~faber/Vault/software/grap/grap-0.8a.tar.gz
Patch1: grap-redhat-linux.patch

%description
This is grap, an implementation of Kernigan and Bentley's grap
language for typesetting graphs.  I got sick of groff not having a
version of grap, so I built one.


%prep
%setup
%patch1

%build
make -f GNUmakefile

%install
make install

%files
%doc README
/usr/bin/grap
/usr/local/man/man1/grap.1
/usr/share/grap/examples
/usr/share/grap/grap.defines
