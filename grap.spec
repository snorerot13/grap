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
%{prefix}/share/grap/examples/400mpairs.d
%{prefix}/share/grap/examples/400mtimes.d
%{prefix}/share/grap/examples/400wpairs.d
%{prefix}/share/grap/examples/Makefile
%{prefix}/share/grap/examples/army.d
%{prefix}/share/grap/examples/boyhts.d
%{prefix}/share/grap/examples/example.ms
%{prefix}/share/grap/examples/internet.d
%{prefix}/share/grap/examples/prof2.d
%{prefix}/share/grap/examples/states.d
%{prefix}/share/grap/examples/states2.d
%{prefix}/share/grap/examples/states3.d
%{prefix}/share/grap/examples/usapop.d
%{prefix}/share/grap/examples/result.SQ_MESH.Fail1.S3.R0.Global.Random1500.succ.result
%{prefix}/share/grap/examples/result.SQ_MESH.Fail1.S3.R0.Local.Random1500.succ.result
%{prefix}/share/grap/examples/result.SQ_MESH.Fail1.S3.R0.Hybrid.Random1500.succ.result
%{prefix}/share/grap/grap.defines
%{prefix}/share/grap/README
%{prefix}/share/grap/COPYRIGHT
%{prefix}/share/grap/CHANGES
