ACLOCAL_AMFLAGS = -I . 

AUTOMAKE_OPTIONS = 1.6

if !LOCALES_ONLY
  MAYBE_SRCDIR = src
  MAYBE_DATADIR = data
if HAS_CPPUNIT
  MAYBE_TESTS = tests
endif
endif

if LOCALES
  MAYBE_LOCALES = locales
endif
SUBDIRS = . $(MAYBE_SRCDIR) $(MAYBE_LOCALES) $(MAYBE_DATADIR) $(MAYBE_TESTS)

dist_noinst_SCRIPTS = autogen.sh

dist_noinst_DATA = filezilla.kdevelop GPL.html

dist_noinst_DATA += docs/iconspecs.htm

docsdir = $(pkgdatadir)/docs

dist_docs_DATA = docs/fzdefaults.xml.example

dist_man1_MANS = docs/filezilla.man \
		 docs/fzputtygen.man \
		 docs/fzsftp.man
dist_man5_MANS = docs/fzdefaults.xml.man

if !LOCALES_ONLY
if MACAPPBUNDLE
clean-local:
	rm -rf FileZilla.app
endif
endif
