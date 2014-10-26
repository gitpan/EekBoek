%define modname EekBoek
%define modversion 0.21_03

Name: %modname
Version: %modversion
Release: 1
Source: http://www.squirrel.nl/eekboek/dl/%{name}-%{version}.tar.gz
BuildArch: noarch
Provides: perl(EB) %modname = %version
URL: http://www.squirrel.nl/eekboek/
BuildRoot: %{_tmppath}/rpm-buildroot-%{name}-%{version}-%{release}
Prefix: %{_prefix}

Summary: Accounting software for small and medium-size businesses
License: Artistic
Group: Applications/Productivity

%description
EekBoek is a accounting package for small and medium-size businesses.
Unlike other accounting software, EekBoek has both a command-line
interface (CLI) and a graphical user-interface (GUI). Furthermore,
it has a complete Perl API to create your own custom applications.
EekBoek is designed for the dutch/european market and currently
available in dutch only.

%prep
%setup -q

%build
perl Makefile.PL
make all test

%install
rm -rf $RPM_BUILD_ROOT
make DESTDIR=$RPM_BUILD_ROOT install

rm -f ${RPM_BUILD_ROOT}%{_libdir}/perl*/*/*/perllocal.pod

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc CHANGES README INSTALL QUICKSTART example doc/html TODO

%{_bindir}/ebshell
%{_libdir}/perl5/site_perl/*/EB
%{_libdir}/perl5/site_perl/*/EekBoek.pm
%{_libdir}/perl5/site_perl/*/EB.pm
%{_libdir}/perl5/site_perl/*/*/auto/eekboek
%{_mandir}/man3/*

%changelog
* Thu Dec 08 2005 Johan Vromans <jvromans@squirrel.nl> 0.20
- Include doc/html.
* Tue Nov 22 2005 Johan Vromans <jvromans@squirrel.nl> 0.19
- More.
* Sun Nov 20 2005 Jos Vos <jos@xos.nl> 0.17-XOS.0beta1
- Initial version.
