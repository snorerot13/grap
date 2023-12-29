# -*-rpm-spec-*-
%define version 1.46

Summary: grap, typesets graphs for groff
Name: grap
Version: %{version}
Release: 1
License: BSD
Group: Applications/Publishing
Source0: ./grap-%{version}.tar.gz

%description
This is grap, an implementation of Kernighan and Bentley\'s grap
language for typesetting graphs. 


%prep
%setup -q

%build
./configure --prefix=%{buildroot}%{_prefix} --mandir=%{buildroot}%{_prefix}/share/man
make

%install
make install


%files
%doc README
%doc COPYRIGHT
%doc CHANGES
%dir %{_prefix}/share/grap/
%dir %{_prefix}/share/examples/grap/
%dir %{_prefix}/share/doc/grap/
%{_prefix}/bin/grap
%{_prefix}/share/man/man1/grap.1.gz
%{_prefix}/share/doc/grap/grap.man
%{_prefix}/share/examples/grap/400mpairs.d
%{_prefix}/share/examples/grap/400mtimes.d
%{_prefix}/share/examples/grap/400wpairs.d
%{_prefix}/share/examples/grap/Makefile
%{_prefix}/share/examples/grap/army.d
%{_prefix}/share/examples/grap/boyhts.d
%{_prefix}/share/examples/grap/cy_fatal.d
%{_prefix}/share/examples/grap/example.ms
%{_prefix}/share/examples/grap/internet.d
%{_prefix}/share/examples/grap/prof2.d
%{_prefix}/share/examples/grap/result.SQ_MESH.Fail1.S3.R0.Global.Random1500.succ.result
%{_prefix}/share/examples/grap/result.SQ_MESH.Fail1.S3.R0.Hybrid.Random1500.succ.result
%{_prefix}/share/examples/grap/result.SQ_MESH.Fail1.S3.R0.Local.Random1500.succ.result
%{_prefix}/share/examples/grap/states.d
%{_prefix}/share/examples/grap/states2.d
%{_prefix}/share/examples/grap/states3.d
%{_prefix}/share/examples/grap/usapop.d
%{_prefix}/share/grap/grap.defines
%{_prefix}/share/grap/grap.tex.defines
