%define modname EekBoek
%define modversion 0.46

Name: %modname
Version: %modversion
Release: 1
Source: http://www.squirrel.nl/eekboek/dl/%{name}-%{version}.tar.gz
BuildArch: noarch
URL: http://www.squirrel.nl/eekboek/
BuildRoot: %{_tmppath}/rpm-buildroot-%{name}-%{version}-%{release}
Prefix: %{_prefix}
BuildRequires: perl(Config::IniFiles)

Summary: Bookkeeping software for small and medium-size businesses
License: Artistic
Group: Applications/Productivity

%description
EekBoek is a bookkeeping package for small and medium-size businesses.
Unlike other accounting software, EekBoek has both a command-line
interface (CLI) and a graphical user-interface (GUI). Furthermore, it
has a complete Perl API to create your own custom applications.
EekBoek is designed for the Dutch/European market and currently
available in Dutch only. An English translation is in the works (help
appreciated).

%prep
%setup -q

%build
perl Makefile.PL
make all
env EB_SKIPDBTESTS=1 make test

%install
rm -rf $RPM_BUILD_ROOT
make DESTDIR=$RPM_BUILD_ROOT install

rm -f ${RPM_BUILD_ROOT}%{_libdir}/perl*/*/*/perllocal.pod
rm -f ${RPM_BUILD_ROOT}%{_libdir}/perl*/*/*/*/auto/eekboek/.packlist

mkdir -p ${RPM_BUILD_ROOT}%{_sysconfdir}/eekboek
install -m 0644 example/eekboek.conf ${RPM_BUILD_ROOT}%{_sysconfdir}/eekboek

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc CHANGES README INSTALL QUICKSTART example doc/html TODO
%dir %{_sysconfdir}/eekboek
%config %{_sysconfdir}/eekboek/eekboek.conf
%{_bindir}/ebshell
%{perl_sitelib}/EB
%{perl_sitelib}/EB.pm
%{perl_sitelib}/EekBoek.pm
%{_mandir}/man1/*
%{_mandir}/man3/*

%changelog
* Mon Jan 30 2006 Johan Vromans <jvromans@squirrel.nl> 0.37
- Add build dep perl(Config::IniFiles).
* Fri Dec 23 2005 Wytze van der Raay <wytze@nlnet.nl> 0.23
- Fixes for x86_64 building problems.
* Wed Dec 12 2005 Johan Vromans <jvromans@squirrel.nl> 0.22
- Change some wordings.
- Add man1.
* Tue Dec 11 2005 Johan Vromans <jvromans@squirrel.nl> 0.21
- Add INSTALL QUICKSTART
* Thu Dec 08 2005 Johan Vromans <jvromans@squirrel.nl> 0.20
- Include doc/html.
* Tue Nov 22 2005 Johan Vromans <jvromans@squirrel.nl> 0.19
- More.
* Sun Nov 20 2005 Jos Vos <jos@xos.nl> 0.17-XOS.0beta1
- Initial version.
