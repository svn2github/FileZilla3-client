#! /bin/sh

while test $# != 0; do
  case $1 in 
  -[cC])
    no_check=1
    ;;
  -[hH]|-help|--help)
    echo "Usage: $0 [-c] "
    echo "-c        Do not check if the required tools are available."
    echo "-h --help This message"
    exit
    ;;
  *)
    echo "$0: Unknown option $1"
    $0 --help
    exit 1
  esac
  shift
done

echo -e " --- FileZilla 3 autogen script ---\n"
echo -e "\033[1mHINT:\033[0m If this script fails, please download a recent source tarball from \033[1mhttp://filezilla-project.org/nightly.php\033[0m\n"

failedAclocal()
{
  echo -e "\n\033[1;31m*** Failed to execute aclocal\033[0m"
  echo "" 
  echo '    If you get errors about undefined symbols, make sure'
  echo '    that the corresponding .m4 file is in your aclocal search'
  echo '    directory.'
  echo '    Especially if you get an error about undefined'
  echo '    AC_PROG_LIBTOOL, search for a .m4 file with libtool in'
  echo '    its name and copy the file to the directory,'
  echo -e '    \033[1maclocal --print-ac-dir\033[0m prints.'

  exit 1
}

echo -n "1. Cleaning previous files... "

rm -rf  configure config.log aclocal.m4 \
  config.status config autom4te.cache libtool
find . -name "Makefile.in" | xargs rm -f
find . -name "Makefile" | xargs rm -f
echo done

findsuffix()
{
  # If a program could not be found using or was of a wrong version, try
  # the program name with the version number as suffix

  local name
  name="$PACKAGE$MAJOR$MINOR"
  if $name --version < /dev/null > /dev/null 2>&1; then
    PACKAGE=$name
    return 0
  fi
  name="$PACKAGE-$MAJOR$MINOR"
  if $name --version < /dev/null > /dev/null 2>&1; then
    PACKAGE=$name
    return 0
  fi
  name="${PACKAGE}-${MAJOR}.${MINOR}"
  if $name --version < /dev/null > /dev/null 2>&1; then
    PACKAGE=$name
    return 0
  fi

  return 1
}

version_check()
{
  local USESUFFIX=""
  if [ "$1" = "usesuffix" ]; then
    USESUFFIX=true
    shift 1
  fi

  PACKAGE=$1
  PACKAGENAME=$1
  MAJOR=$2
  MINOR=$3
  MICRO=$4
  SILENT=$5

  VERSION=$MAJOR

  if [ ! -z "$MINOR" ]; then VERSION=$VERSION.$MINOR; else MINOR=0; fi
  if [ ! -z "$MICRO" ]; then VERSION=$VERSION.$MICRO; else MICRO=0; fi
  
  if [ x$SILENT != x2 ]; then
    if [ ! -z $VERSION ]; then
      echo -n "Checking for $PACKAGE >= $VERSION ... "
    else
      echo -n "Checking for $PACKAGE ... "
    fi
  fi

  if [ -z "$USESUFFIX" ]; then
    ($PACKAGE --version) < /dev/null > /dev/null 2>&1 ||
    {
      if [ -z "$VERSION" ]; then
        VERSION="1.2.3"
      else
        # Retry again, append a suffix if needed
        version_check usesuffix $PACKAGE $MAJOR $MINOR $MICRO 2
        return
      fi
      echo -e "\033[1;31mnot found\033[0m\n"
      echo -e "\033[1m$PACKAGENAME\033[0m could not be found. On some systems \033[1m$PACKAGENAME\033[0m might be installed but"
      echo -e "has a suffix with the version number, for example \033[1m$PACKAGEMA;E-$VERSION\033[0m."
      echo -e "If that is the case, create a symlink to \033[1m$PACKAGENAME\033[0m."
      exit 1
    }
  else
    findsuffix ||
    {
      echo -e "\033[1;31mnot found\033[0m\n"
      echo -e "\033[1m$PACKAGENAME\033[0m could not be found. On some systems \033[1m$PACKAGENAME\033[0m might be installed but"
      echo -e "has a suffix with the version number, for example \033[1m$PACKAGENAME-$VERSION\033[0m."
      echo -e "If that is the case, create a symlink to \033[1m$PACKAGE\033[0m."
      exit 1
    }
  fi

  # the following line is carefully crafted sed magic
  pkg_version=`$PACKAGE --version|head -n 1|sed 's/([^)]*)//g;s/^[a-zA-Z\.\ \-]*//;s/ .*$//'`
  pkg_major=`echo $pkg_version | cut -d. -f1`
  pkg_minor=`echo $pkg_version | sed s/[-,a-z,A-Z].*// | cut -d. -f2`
  pkg_micro=`echo $pkg_version | sed s/[-,a-z,A-Z].*// | cut -d. -f3`
  [ -z "$pkg_minor" ] && pkg_minor=0
  [ -z "$pkg_micro" ] && pkg_micro=0

  WRONG=
  if [ -z "$MAJOR" ]; then
    echo "found $pkg_version, ok."
    return 0
  fi
  
  # start checking the version
  if [ "$pkg_major" -lt "$MAJOR" ]; then
    WRONG=1
  elif [ "$pkg_major" -eq "$MAJOR" ]; then
    if [ "$pkg_minor" -lt "$MINOR" ]; then
      WRONG=1
    elif [ "$pkg_minor" -eq "$MINOR" -a "$pkg_micro" -lt "$MICRO" ]; then
      WRONG=1
    fi
  fi

  if [ ! -z "$WRONG" ]; then
    # Retry again, append a suffix if needed
    if [ -z "$USESUFFIX" ]; then
      version_check usesuffix $PACKAGE $MAJOR $MINOR $MICRO 2
      return
    fi
    if [ x$SILENT = x1 ]; then
      return 2;
    fi
    echo -e "\033[1mfound $pkg_version, not ok !\033[0m"
    echo "You must have $PACKAGENAME $VERSION or greater to generate the configure script."
    echo -e "If \033[1m$PACKAGENAME\033[0m is a symlink, make sure it points to the correct version."
    echo -e "Please update your installation or get a recent source tarball from \033[1mhttp://filezilla-project.org/nightly.php\033[0m"
    exit 2
  else
    echo "found $pkg_version, ok."
    return 0
  fi
}

checkTools()
{
  N=$1

  if [ ! -z "$no_check" ]; then
    echo "$N. Checking required tools... skipped"
    automake="automake"
    aclocal="aclocal"
    autoeader="autoheader"
    autoconf="autoconf"
    libtoolize="libtoolize"
    return 0
  fi

  echo "$N. Checking required tools... "

  echo -n "$N.1 "; version_check automake 1 8 0 1
  if [ x$? = x2 ]; then
    WANT_AUTOMAKE=1.8
    export WANT_AUTOMAKE
    version_check automake 1 8 0 2
  fi
  automake="$PACKAGE"

  echo -n "$N.2 "; version_check aclocal; aclocal=$PACKAGE
  echo -n "$N.3 "; version_check autoheader; autoheader=$PACKAGE
  echo -n "$N.4 "; version_check autoconf 2 5; autoconf=$PACKAGE
  echo -n "$N.5 "; version_check libtoolize 1 4; libtoolize=$PACKAGE
}

checkTools 2

echo "3. Creating configure and friends... "
if [ ! -e config ]
then
  mkdir config
fi

echo "3.1 Running aclocal... "
$aclocal -I . || failedAclocal

echo "3.2 Running autoheader... "
$autoheader

echo "3.3 Runnig libtoolize... "
$libtoolize --automake -c -f

echo "3.4 Running autoconf... "
$autoconf

echo "3.5 Runing automake... "
$automake -a -c

echo -n "4. Checking generate files... "
if test ! -f configure || test ! -f config/ltmain.sh || test ! -f Makefile.in; then
  echo -e "\033[1;31mfailed"
  echo -e "\nError: Unable to generate all required files!\033[0m\n"
  echo "Please make sure you have you have autoconf 2.5, automake 1.7, libtool 1.5,"
  echo "autoheader and aclocal installed."
  echo -e "If you don't have access to these tools, please get a recent source tarball from \033[1mhttp://filezilla-project.org/nightly.php\033[0m instead."
  echo "script which will download the generated files, just remember to call it from"
  echo "time to time, it will only download if some files have been changed"

  exit 1
fi
echo done
echo -e "\nScript completed successfully."
echo -e "Now run \033[1m./configure\033[0m, see \033[1m./configure --help\033[0m for more information"

