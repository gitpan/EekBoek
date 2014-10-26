# -*- rpm-spec -*-

# Package name, mixed case (EekBoek)
%define pkgname EekBoek
# Package name, lowcase (eekboek)
%define lcname eekboek
# Package version
%define pkgversion 1.04
# Suffix (-unstable, or empty)
%define pkgsuffix 

################ Build Options ################
%define gui 0
%{?_with_gui:    %{expand: %%define gui 1}}
%{?_without_gui: %{expand: %%define gui 0}}

%define dbtests 0
%{?_with_dbtests:    %{expand: %%define dbtests 1}}
%{?_without_dbtests: %{expand: %%define dbtests 0}}
################ End Build Options ################

Name: %pkgname
Version: %pkgversion
Release: 1
Source: http://www.eekboek.nl/dl/%{pkgname}-%{version}.tar.gz
BuildArch: noarch
URL: http://www.eekboek.nl
BuildRoot: %{_tmppath}/rpm-buildroot-%{pkgname}-%{version}-%{release}
Prefix: %{_prefix}
Vendor: Squirrel Consultancy
Packager: Johan Vromans <jvromans@squirrel.nl>

AutoReqProv: 0

Requires: perl >= 5.8
Requires: perl(Archive::Zip)
Requires: perl(Term::ReadLine)
Requires: perl(DBI) >= 1.40
Requires: %{name}-db

BuildRequires: perl >= 5.8
BuildRequires: perl(DBI)

Provides: %{pkgname} = %{version}

Summary: Bookkeeping software for small and medium-size businesses
License: Artistic
Group: Applications/Productivity

%description
EekBoek is a bookkeeping package for small and medium-size businesses.
Unlike other accounting software, EekBoek has both a command-line
interface (CLI) and a graphical user-interface (GUI, currently under
development). Furthermore, it has a complete Perl API to create your
own custom applications. EekBoek is designed for the Dutch/European
market and currently available in Dutch only. An English translation
is in the works (help appreciated).

%package db-postgresql
Summary: PostgreSQL database driver for %{pkgname}.
Group: Applications/Productivity
AutoReqProv: 0
Requires: %{name} = %{version}
Requires: perl-DBD-Pg >= 1.41
Provides: %{name}-db

%description db-postgresql
EekBoek can make use of several database systems for its storage.
This package contains the PostgreSQL database driver for %{name}.
You need to install at least one of the available database packages.

%package db-sqlite
Summary: SQLite database driver for %{pkgname}.
Group: Applications/Productivity
AutoReqProv: 0
Requires: %{name} = %{version}
Requires: perl-DBD-SQLite >= 1.12
Provides: %{name}-db

%description db-sqlite
EekBoek can make use of several database systems for its storage.
This package contains the SQLite database driver for %{name}.
You need to install at least one of the available database packages.

%if %{gui}
%package gui
Summary: GUI extension for %{pkgname}.
Group: Applications/Productivity
AutoReqProv: 0
Requires: %{name} = %{version}
Requires: perl-Wx >= 0.74

%description gui
The wxWidgets-based GUI extension for %{name}.
%endif

%prep
%setup -q -n %{pkgname}-%{pkgversion}

%build
%{__perl} Build.PL
%{__perl} Build
%if %{dbtests}
%{__perl} Build test
%else
%{__perl} Build test --skipdbtests
%endif
%if %{gui}
%{__install} -m 0755 script/ebgui blib/script/ebgui
%endif

mv blib/lib/EB/examples .
( cd examples;
  mv ../eekboek-mode.el .;
  zip -q ../blib/lib/EB/schema/sampledb.ebz *.eb schema.dat )

%install

%define ebconf  %{_sysconfdir}/%{lcname}
%define ebshare %{_datadir}/%{pkgname}-%{version}

%{__rm} -rf $RPM_BUILD_ROOT

%{__mkdir_p} ${RPM_BUILD_ROOT}%{ebconf}
%{__install} -m 0644 examples/%{lcname}.conf ${RPM_BUILD_ROOT}%{ebconf}/%{lcname}.conf

%{__mkdir_p} ${RPM_BUILD_ROOT}%{ebshare}/lib

find blib/lib -type d -printf "mkdir ${RPM_BUILD_ROOT}%{ebshare}/lib/%%P\n" | sh -x
find blib/lib ! -type d -printf "%{__install} -m 0444 %p ${RPM_BUILD_ROOT}%{ebshare}/lib/%%P\n" | sh -x

%{__mkdir_p} ${RPM_BUILD_ROOT}%{_bindir}

echo "#!%{__perl}" > ${RPM_BUILD_ROOT}%{_bindir}/ebshell

sed -s "s;# use lib qw(EekBoekLibrary;use lib qw(%{ebshare}/lib;" \
	< script/ebshell >> ${RPM_BUILD_ROOT}%{_bindir}/ebshell
%{__chmod} 0755 ${RPM_BUILD_ROOT}%{_bindir}/ebshell

cat <<EOD > .files
%defattr(-,root,root)
%doc CHANGES README INSTALL QUICKSTART examples doc/html TODO
%dir %{_sysconfdir}/%{lcname}
%config(noreplace) %{_sysconfdir}/%{lcname}/%{lcname}.conf
%dir %{ebshare}
%{_bindir}/ebshell
%{_mandir}/man1/*
EOD

( cd $RPM_BUILD_ROOT;
  find ./%{ebshare} -type d -printf "%%%%dir %{ebshare}/%%P\n";
  find ./%{ebshare} -type f -printf "%{ebshare}/%%P\\n" | grep -v "lib/EB/DB/.*pm"
) >> .files

%if %{gui}
%{__mkdir_p} ${RPM_BUILD_ROOT}%{ebshare}/script
%{__install} -m 0755 blib/script/ebgui ${RPM_BUILD_ROOT}%{ebshare}/script
%{__mkdir_p} ${RPM_BUILD_ROOT}%{ebshare}/libgui
echo "#!%{__perl}" > ${RPM_BUILD_ROOT}%{_bindir}/ebgui
echo 'my $share = "%{ebshare}";' >> ${RPM_BUILD_ROOT}%{_bindir}/ebgui
echo 'exec $^X "perl", "-Mlib=$share/lib", "-Mlib=$share/libgui", "$share/script/ebgui", @ARGV;' >> ${RPM_BUILD_ROOT}%{_bindir}/ebgui
%{__chmod} 0755 ${RPM_BUILD_ROOT}%{_bindir}/ebgui
%endif

%{__mkdir_p} ${RPM_BUILD_ROOT}%{_mandir}/man1
pod2man blib/script/ebshell > ${RPM_BUILD_ROOT}%{_mandir}/man1/ebshell.1

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files -f .files

%files db-postgresql
%dir %{ebshare}
%dir %{ebshare}/lib
%dir %{ebshare}/lib/EB
%dir %{ebshare}/lib/EB/DB
%{ebshare}/lib/EB/DB/Postgres.pm

%files db-sqlite
%dir %{ebshare}
%dir %{ebshare}/lib
%dir %{ebshare}/lib/EB
%dir %{ebshare}/lib/EB/DB
%{ebshare}/lib/EB/DB/Sqlite.pm

%if %{gui}
%files gui
%defattr(-,root,root)
%{ebshare}/libgui
%dir %{ebshare}/script
%{ebshare}/script/ebgui
%{_bindir}/ebgui
%endif

%post

%changelog
* Sat Jul 19 2008 Johan Vromans <jvromans@squirrel.nl> - 1.03.90
- Remove debian stuff
- Don't use unstable.
* Fri Apr 11 2008 Johan Vromans <jvromans@squirrel.nl> - 1.03.12
- Simplify by setting variables from the .in template
* Sun Apr 01 2007 Johan Vromans <jvromans@squirrel.nl> - 1.03.03
- Exclude some Wx files.
* Sun Nov 05 2006 Johan Vromans <jvromans@squirrel.nl> - 1.03.00
- Move DB drivers to separate package, and adjust req/prov.
* Mon Oct 16 2006 Johan Vromans <jvromans@squirrel.nl> - 1.01.02
- Prepare (but don't use) suffixes to separate production and unstable versions.
* Wed Aug 02 2006 Johan Vromans <jvromans@squirrel.nl> 0.92
- New URL. Add Vendor.
* Fri Jun 09 2006 Johan Vromans <jvromans@squirrel.nl> 0.60
- Remove man3.
* Thu Jun 08 2006 Johan Vromans <jvromans@squirrel.nl> 0.60
- Fix example.
* Mon Jun 05 2006 Johan Vromans <jvromans@squirrel.nl> 0.59
- Better script handling.
* Mon Apr 17 2006 Johan Vromans <jvromans@squirrel.nl> 0.56
- Initial provisions for GUI.
* Wed Apr 12 2006 Johan Vromans <jvromans@squirrel.nl> 0.56
- %config(noreplace) for eekboek.conf.
* Tue Mar 28 2006 Johan Vromans <jvromans@squirrel.nl> 0.52
- Perl Independent Install
* Mon Mar 27 2006 Johan Vromans <jvromans@squirrel.nl> 0.52
- Add "--with dbtests" parameter for rpmbuild.
- Resultant rpm may be signed.
* Sun Mar 19 2006 Johan Vromans <jvromans@squirrel.nl> 0.50
- Switch to Build.PL instead of Makefile.PL.
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
