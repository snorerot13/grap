Summary: grap, a grapher for groff
Name: grap
Version: 0.95b
Release: 0
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
/usr/share/grap/examples/400mpairs.d
/usr/share/grap/examples/400mtimes.d
/usr/share/grap/examples/400wpairs.d
/usr/share/grap/examples/Makefile
/usr/share/grap/examples/army.d
/usr/share/grap/examples/boyhts.d
/usr/share/grap/examples/example.ms
/usr/share/grap/examples/internet.d
/usr/share/grap/examples/prof2.d
/usr/share/grap/examples/states.d
/usr/share/grap/examples/states2.d
/usr/share/grap/examples/states3.d
/usr/share/grap/examples/usapop.d
/usr/share/grap/examples/result.SQ_MESH.Fail1.S3.R0.Global.Random1500.succ.result
/usr/share/grap/examples/result.SQ_MESH.Fail1.S3.R0.Local.Random1500.succ.result
/usr/share/grap/examples/result.SQ_MESH.Fail1.S3.R0.Hybrid.Random1500.succ.result
/usr/share/grap/grap.defines
/usr/share/grap/README
/usr/share/grap/COPYRIGHT
/usr/share/grap/CHANGES
