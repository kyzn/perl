#!/usr/bin/perl -w

#
# Generate the reentr.c and reentr.h,
# and optionally also the relevant metaconfig units (-U option).
# 

use strict;
use Getopt::Std;
my %opts;
getopts('U', \%opts);

my %map = (
	   V => "void",
	   A => "char*",	# as an input argument
	   B => "char*",	# as an output argument 
	   C => "const char*",	# as a read-only input argument
	   I => "int",
	   L => "long",
	   W => "size_t",
	   H => "FILE**",
	   E => "int*",
	  );

# (See the definitions after __DATA__.)
# In func|inc|type|... a "S" means "type*", and a "R" means "type**".
# (The "types" are often structs, such as "struct passwd".)
#
# After the prototypes one can have |X=...|Y=... to define more types.
# A commonly used extra type is to define D to be equal to "type_data",
# for example "struct_hostent_data to" go with "struct hostent".
#
# Example #1: I_XSBWR means int  func_r(X, type, char*, size_t, type**)
# Example #2: S_SBIE  means type func_r(type, char*, int, int*)
# Example #3: S_CBI   means type func_r(const char*, char*, int)


die "reentr.h: $!" unless open(H, ">reentr.h");
select H;
print <<EOF;
/*
 *    reentr.h
 *
 *    Copyright (c) 1997-2002, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 *  !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!!
 *  This file is built by reentrl.pl from data in reentr.pl.
 */

#ifndef REENTR_H
#define REENTR_H 

#ifdef USE_REENTRANT_API
 
/* Deprecations: some platforms have the said reentrant interfaces
 * but they are declared obsolete and are not to be used.  Often this
 * means that the platform has threadsafed the interfaces (hopefully).
 * All this is OS version dependent, so we are of course fooling ourselves.
 * If you know of more deprecations on some platforms, please add your own. */

#ifdef __hpux
#   undef HAS_CRYPT_R
#   undef HAS_DRAND48_R
#   undef HAS_ENDGRENT_R
#   undef HAS_ENDPWENT_R
#   undef HAS_GETGRENT_R
#   undef HAS_GETPWENT_R
#   undef HAS_SETLOCALE_R
#   undef HAS_SRAND48_R
#   undef HAS_STRERROR_R
#   define NETDB_R_OBSOLETE
#endif

#if defined(__osf__) && defined(__alpha) /* Tru64 aka Digital UNIX */
#   undef HAS_CRYPT_R
#   undef HAS_STRERROR_R
#   define NETDB_R_OBSOLETE
#endif

#ifdef NETDB_R_OBSOLETE
#   undef HAS_ENDHOSTENT_R
#   undef HAS_ENDNETENT_R
#   undef HAS_ENDPROTOENT_R
#   undef HAS_ENDSERVENT_R
#   undef HAS_GETHOSTBYADDR_R
#   undef HAS_GETHOSTBYNAME_R
#   undef HAS_GETHOSTENT_R
#   undef HAS_GETNETBYADDR_R
#   undef HAS_GETNETBYNAME_R
#   undef HAS_GETNETENT_R
#   undef HAS_GETPROTOBYNAME_R
#   undef HAS_GETPROTOBYNUMBER_R
#   undef HAS_GETPROTOENT_R
#   undef HAS_GETSERVBYNAME_R
#   undef HAS_GETSERVBYPORT_R
#   undef HAS_GETSERVENT_R
#   undef HAS_SETHOSTENT_R
#   undef HAS_SETNETENT_R
#   undef HAS_SETPROTOENT_R
#   undef HAS_SETSERVENT_R
#endif

#ifdef I_PWD
#   include <pwd.h>
#endif
#ifdef I_GRP
#   include <grp.h>
#endif
#ifdef I_NETDB
#   include <netdb.h>
#endif
#ifdef I_STDLIB
#   include <stdlib.h>	/* drand48_data */
#endif
#ifdef I_CRYPT
#   ifdef I_CRYPT
#       include <crypt.h>
#   endif
#endif
#ifdef HAS_GETSPNAM_R
#   ifdef I_SHADOW
#       include <shadow.h>
#   endif
#endif

EOF

my %seenh;
my %seena;
my @seenf;
my %seenp;
my %seent;
my %seens;
my %seend;
my %seenu;

while (<DATA>) {
    next if /^\s+$/;
    chomp;
    my ($f, $h, $t, @p) = split(/\s*\|\s*/, $_, -1);
    my $u;
    ($f, $u) = split(' ', $f);
    $seenu{$f} = defined $u ? length $u : 0;
    my $F = uc $f;
    push @seenf, $f;
    my %m = %map;
    if ($t) {
	$m{S} = "$t*";
	$m{R} = "$t**";
    }
    if (@p) {
	while ($p[-1] =~ /=/) {
	    my ($k, $v) = ($p[-1] =~ /^([A-Za-z])\s*=\s*(.*)/);
	    $m{$k} = $v;
	    pop @p;
	}
    }
    if ($opts{U} && open(U, ">d_${f}_r.U"))  {
	select U;
    }
    my $prereqh = $h eq 'stdio' ? '' : "i_$h"; # There's no i_stdio.
    print <<EOF if $opts{U};
?RCS: \$Id: d_${f}_r.U,v $
?RCS:
?RCS: Copyright (c) 2002 Jarkko Hietaniemi
?RCS:
?RCS: You may distribute under the terms of either the GNU General Public
?RCS: License or the Artistic License, as specified in the README file.
?RCS:
?RCS: Generated by the reentr.pl from the Perl 5.8 distribution.
?RCS:
?MAKE:d_${f}_r ${f}_r_proto: Inlibc Protochk Hasproto i_systypes $prereqh usethreads
?MAKE:	-pick add \$@ %<
?S:d_${f}_r:
?S:	This variable conditionally defines the HAS_${F}_R symbol,
?S:	which indicates to the C program that the ${f}_r()
?S:	routine is available.
?S:.
?S:${f}_r_proto:
?S:	This variable encodes the prototype of ${f}_r.
?S:.
?C:HAS_${F}_R:
?C:	This symbol, if defined, indicates that the ${f}_r routine
?C:	is available to ${f} re-entrantly.
?C:.
?C:${F}_R_PROTO:
?C:	This symbol encodes the prototype of ${f}_r.
?C:.
?H:#\$d_${f}_r HAS_${F}_R	   /**/
?H:#define ${F}_R_PROTO \$${f}_r_proto	   /**/
?H:.
?T:try hdrs d_${f}_r_proto
?LINT:set d_${f}_r
?LINT:set ${f}_r_proto
: see if ${f}_r exists
set ${f}_r d_${f}_r
eval \$inlibc
case "\$d_${f}_r" in
"\$define")
	hdrs="\$i_systypes sys/types.h define stdio.h \$i_${h} $h.h"
	case "$h" in
	time)
		hdrs="\$hdrs \$i_systime sys/time.h"
		;;
	esac
	case "\$d_${f}_r_proto:\$usethreads" in
	":define")	d_${f}_r_proto=define
		set d_${f}_r_proto ${f}_r \$hdrs
		eval \$hasproto ;;
	*)	;;
	esac
	case "\$d_${f}_r_proto" in
	define)
EOF
	for my $p (@p) {
	    my ($r, $a) = ($p =~ /^(.)_(.+)/);
	    my $v = join(", ", map { $m{$_} } split '', $a);
	    if ($opts{U}) {
		print <<EOF ;
	case "\$${f}_r_proto" in
	''|0) try='$m{$r} ${f}_r($v);'
	./protochk "extern \$try" \$hdrs && ${f}_r_proto=$p ;;
	esac
EOF
            }
	    $seenh{$f}->{$p}++;
	    push @{$seena{$f}}, $p;
	    $seenp{$p}++;
	    $seent{$f} = $t;
	    $seens{$f} = $m{S};
	    $seend{$f} = $m{D};
	}
	if ($opts{U}) {
	    print <<EOF;
	case "\$${f}_r_proto" in
	''|0)	d_${f}_r=undef
 	        ${f}_r_proto=0
		echo "Disabling ${f}_r, cannot determine prototype." >&4 ;;
	* )	case "\$${f}_r_proto" in
		REENTRANT_PROTO*) ;;
		*) ${f}_r_proto="REENTRANT_PROTO_\$${f}_r_proto" ;;
		esac
		echo "Prototype: \$try" ;;
	esac
	;;
	*)	case "\$usethreads" in
		define) echo "${f}_r has no prototype, not using it." >&4 ;;
		esac
		d_${f}_r=undef
		${f}_r_proto=0
		;;
	esac
	;;
*)	${f}_r_proto=0
	;;
esac

EOF
	close(U);		    
    }
}

close DATA;

select H;

{
    my $i = 1;
    for my $p (sort keys %seenp) {
	print "#define REENTRANT_PROTO_${p}	${i}\n";
	$i++;
    }
}

sub ifprotomatch {
    my $F = shift;
    join " || ", map { "${F}_R_PROTO == REENTRANT_PROTO_$_" } @_;
}

my @struct;
my @size;
my @init;
my @free;
my @wrap;
my @define;

sub pushssif {
    push @struct, @_;
    push @size, @_;
    push @init, @_;
    push @free, @_;
}

sub pushinitfree {
    my $f = shift;
    push @init, <<EOF;
	New(31338, PL_reentrant_buffer->_${f}_buffer, PL_reentrant_buffer->_${f}_size, char);
EOF
    push @free, <<EOF;
	Safefree(PL_reentrant_buffer->_${f}_buffer);
EOF
}

sub define {
    my ($n, $p, @F) = @_;
    my @H;
    my $H = uc $F[0];
    push @define, <<EOF;
/* The @F using \L$n? */

EOF
    for my $f (@F) {
	my $F = uc $f;
	my $h = "${F}_R_HAS_$n";
	push @H, $h;
	my @h = grep { /$p/ } @{$seena{$f}};
	if (@h) {
	    push @define, "#if defined(HAS_${F}_R) && (" . join(" || ", map { "${F}_R_PROTO == REENTRANT_PROTO_$_" } @h) . ")\n";

	    push @define, <<EOF;
#   define $h
#else
#   undef  $h
#endif
EOF
        }
    }
    push @define, <<EOF;

/* Any of the @F using \L$n? */

EOF
    push @define, "#if (" . join(" || ", map { "defined($_)" } @H) . ")\n";
    push @define, <<EOF;
#   define USE_${H}_$n
#else
#   undef  USE_${H}_$n
#endif

EOF
}

define('BUFFER',  'B',
       qw(getgrent getgrgid getgrnam));

define('PTR',  'R',
       qw(getgrent getgrgid getgrnam));
define('PTR',  'R',
       qw(getpwent getpwnam getpwuid));
define('PTR',  'R',
       qw(getspent getspnam));

define('FPTR', 'H',
       qw(getgrent getgrgid getgrnam));
define('FPTR', 'H',
       qw(getpwent getpwnam getpwuid));

define('BUFFER',  'B',
       qw(getpwent getpwgid getpwnam));

define('PTR', 'R',
       qw(gethostent gethostbyaddr gethostbyname));
define('PTR', 'R',
       qw(getnetent getnetbyaddr getnetbyname));
define('PTR', 'R',
       qw(getprotoent getprotobyname getprotobynumber));
define('PTR', 'R',
       qw(getservent getservbyname getservbyport));

define('BUFFER', 'B',
       qw(gethostent gethostbyaddr gethostbyname));
define('BUFFER', 'B',
       qw(getnetent getnetbyaddr getnetbyname));
define('BUFFER', 'B',
       qw(getprotoent getprotobyname getprotobynumber));
define('BUFFER', 'B',
       qw(getservent getservbyname getservbyport));

define('ERRNO', 'E',
       qw(gethostent gethostbyaddr gethostbyname));
define('ERRNO', 'E',
       qw(getnetent getnetbyaddr getnetbyname));

for my $f (@seenf) {
    my $F = uc $f;
    my $ifdef = "#ifdef HAS_${F}_R\n";
    my $endif = "#endif /* HAS_${F}_R */\n";
    if (exists $seena{$f}) {
	my @p = @{$seena{$f}};
	if ($f =~ /^(asctime|ctime|getlogin|setlocale|strerror|ttyname)$/) {
	    pushssif $ifdef;
	    push @struct, <<EOF;
	char*	_${f}_buffer;
	size_t	_${f}_size;
EOF
	    push @size, <<EOF;
	PL_reentrant_buffer->_${f}_size = 256; /* Make something up. */
EOF
	    pushinitfree $f;
	    pushssif $endif;
	}
        elsif ($f =~ /^(crypt)$/) {
	    pushssif $ifdef;
	    push @struct, <<EOF;
#if CRYPT_R_PROTO == REENTRANT_PROTO_B_CCD
	$seend{$f} _${f}_data;
#else
	$seent{$f} _${f}_struct;
#endif
EOF
    	    push @init, <<EOF;
#ifdef __GLIBC__
	PL_reentrant_buffer->_${f}_struct.initialized = 0;
#endif
EOF
	    pushssif $endif;
	}
        elsif ($f =~ /^(drand48|gmtime|localtime|random)$/) {
	    pushssif $ifdef;
	    push @struct, <<EOF;
	$seent{$f} _${f}_struct;
EOF
	    if ($1 eq 'drand48') {
	        push @struct, <<EOF;
	double	_${f}_double;
EOF
	    }
	    pushssif $endif;
	}
        elsif ($f =~ /^(getgrnam|getpwnam|getspnam)$/) {
	    pushssif $ifdef;
	    my $g = $f;
	    $g =~ s/nam/ent/g;
	    my $G = uc $g;
	    push @struct, <<EOF;
	$seent{$f}	_${g}_struct;
	char*	_${g}_buffer;
	size_t	_${g}_size;
EOF
            push @struct, <<EOF;
#   ifdef USE_${G}_PTR
	$seent{$f}*	_${g}_ptr;
#   endif
EOF
    	    if ($g eq 'getspent') {
		push @size, <<EOF;
	PL_reentrant_buffer->_${g}_size = 1024;
EOF
	    } else {
	        push @struct, <<EOF;
#   ifdef USE_${G}_FPTR
	FILE*	_${g}_fptr;
#   endif
EOF
		    push @init, <<EOF;
#   ifdef USE_${G}_FPTR
	PL_reentrant_buffer->_${g}_fptr = NULL;
#   endif
EOF
		my $sc = $g eq 'getgrent' ?
		    '_SC_GETGR_R_SIZE_MAX' : '_SC_GETPW_R_SIZE_MAX';
		push @size, <<EOF;
#   if defined(HAS_SYSCONF) && defined($sc) && !defined(__GLIBC__)
	PL_reentrant_buffer->_${g}_size = sysconf($sc);
#   else
#       if defined(__osf__) && defined(__alpha) && defined(SIABUFSIZ)
	PL_reentrant_buffer->_${g}_size = SIABUFSIZ;
#       else
#           ifdef __sgi
	PL_reentrant_buffer->_${g}_size = BUFSIZ;
#           else
	PL_reentrant_buffer->_${g}_size = 256;
#           endif
#       endif
#   endif 
EOF
            }
	    pushinitfree $g;
	    pushssif $endif;
	}
        elsif ($f =~ /^(gethostbyname|getnetbyname|getservbyname|getprotobyname)$/) {
	    pushssif $ifdef;
	    my $g = $f;
	    $g =~ s/byname/ent/;
	    my $G = uc $g;
	    my $D = ifprotomatch($F, grep {/D/} @p);
	    my $d = $seend{$f};
	    push @struct, <<EOF;
	$seent{$f}	_${g}_struct;
#   if $D
	$d	_${g}_data;
#   else
	char*	_${g}_buffer;
	size_t	_${g}_size;
#   endif
#   ifdef USE_${G}_PTR
	$seent{$f}*	_${g}_ptr;
#   endif
EOF
    	    push @struct, <<EOF;
#   ifdef USE_${G}_ERRNO
	int	_${g}_errno;
#   endif 
EOF
	    push @size, <<EOF;
#if   !($D)
	PL_reentrant_buffer->_${g}_size = 2048; /* Any better ideas? */
#endif
EOF
	    push @init, <<EOF;
#if   !($D)
	New(31338, PL_reentrant_buffer->_${g}_buffer, PL_reentrant_buffer->_${g}_size, char);
#endif
EOF
	    push @free, <<EOF;
#if   !($D)
	Safefree(PL_reentrant_buffer->_${g}_buffer);
#endif
EOF
	    pushssif $endif;
	}
        elsif ($f =~ /^(readdir|readdir64)$/) {
	    pushssif $ifdef;
	    my $R = ifprotomatch($F, grep {/R/} @p);
	    push @struct, <<EOF;
	$seent{$f}*	_${f}_struct;
	size_t	_${f}_size;
#   if $R
	$seent{$f}*	_${f}_ptr;
#   endif
EOF
	    push @size, <<EOF;
	/* This is the size Solaris recommends.
	 * (though we go static, should use pathconf() instead) */
	PL_reentrant_buffer->_${f}_size = sizeof($seent{$f}) + MAXPATHLEN + 1;
EOF
    	    push @init, <<EOF;
	PL_reentrant_buffer->_${f}_struct = ($seent{$f}*)safemalloc(PL_reentrant_buffer->_${f}_size);
EOF
	    push @free, <<EOF;
	Safefree(PL_reentrant_buffer->_${f}_struct);
EOF
	    pushssif $endif;
	}

	push @wrap, $ifdef;

# Doesn't implement the buffer growth loop for glibc gethostby*().
	push @wrap, <<EOF;
#   undef $f
EOF
        my @v = 'a'..'z';
        my $v = join(", ", @v[0..$seenu{$f}-1]);
	for my $p (@p) {
	    my ($r, $a) = split '_', $p;
	    my $test = $r eq 'I' ? ' == 0' : '';
	    my $true  = 1;
	    my $g = $f;
	    if ($g =~ /^(?:get|set|end)(pw|gr|host|net|proto|serv|sp)/) {
		$g = "get$1ent";
	    } elsif ($g eq 'srand48') {
		$g = "drand48";
	    }
	    my $b = $a;
	    my $w = '';
	    substr($b, 0, $seenu{$f}) = '';
	    if ($b =~ /R/) {
		$true = "PL_reentrant_buffer->_${g}_ptr";
	    } elsif ($b =~ /T/ && $f eq 'drand48') {
		$true = "PL_reentrant_buffer->_${g}_double";
	    } elsif ($b =~ /S/) {
		if ($f =~ /^readdir/) {
		    $true = "PL_reentrant_buffer->_${g}_struct";
		} else {
		    $true = "&PL_reentrant_buffer->_${g}_struct";
		}
	    } elsif ($b =~ /B/) {
		$true = "PL_reentrant_buffer->_${g}_buffer";
	    }
	    if (length $b) {
		$w = join ", ",
		         map {
			     $_ eq 'R' ?
				 "&PL_reentrant_buffer->_${g}_ptr" :
			     $_ eq 'E' ?
				 "&PL_reentrant_buffer->_${g}_errno" :
			     $_ eq 'B' ?
				 "PL_reentrant_buffer->_${g}_buffer" :
			     $_ =~ /^[WI]$/ ?
				 "PL_reentrant_buffer->_${g}_size" :
			     $_ eq 'H' ?
				 "&PL_reentrant_buffer->_${g}_fptr" :
			     $_ eq 'D' ?
				 "&PL_reentrant_buffer->_${g}_data" :
			     $_ eq 'S' ?
				 ($f =~ /^readdir/ ?
				  "PL_reentrant_buffer->_${g}_struct" :
				  "&PL_reentrant_buffer->_${g}_struct" ) :
			     $_ eq 'T' && $f eq 'drand48' ?
				 "&PL_reentrant_buffer->_${g}_double" :
				 $_
			 } split '', $b;
		$w = ", $w" if length $v;
	    }
	    my $call = "${f}_r($v$w)";
	    $call = "((errno = $call))" if $r eq 'I';
	    push @wrap, <<EOF;
#   if !defined($f) && ${F}_R_PROTO == REENTRANT_PROTO_$p
EOF
	    if ($r eq 'V' || $r eq 'B') {
	        push @wrap, <<EOF;
#       define $f($v) $call
EOF
	    } else {
		if ($f =~ /^get/) {
		    my $rv = $v ? ", $v" : "";
		    push @wrap, <<EOF;
#       define $f($v) ($call$test ? $true : (errno == ERANGE ? Perl_reentrant_retry("$f"$rv) : 0))
EOF
		} else {
		    push @wrap, <<EOF;
#       define $f($v) ($call$test ? $true : 0)
EOF
		}
	    }
	    push @wrap, <<EOF;
#   endif
EOF
	}

	push @wrap, $endif, "\n";
    }
}

local $" = '';

print <<EOF;

/* Defines for indicating which special features are supported. */

@define
typedef struct {
@struct
} REENTR;

/* The wrappers. */

@wrap
#endif /* USE_REENTRANT_API */
 
#endif

EOF

close(H);

die "reentr.c: $!" unless open(C, ">reentr.c");
select C;
print <<EOF;
/*
 *    reentr.c
 *
 *    Copyright (c) 1997-2002, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 *  !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!!
 *  This file is built by reentrl.pl from data in reentr.pl.
 *
 * "Saruman," I said, standing away from him, "only one hand at a time can
 *  wield the One, and you know that well, so do not trouble to say we!"
 *
 */

#include "EXTERN.h"
#define PERL_IN_REENTR_C
#include "perl.h"
#include "reentr.h"

void
Perl_reentrant_size(pTHX) {
#ifdef USE_REENTRANT_API
@size
#endif /* USE_REENTRANT_API */
}

void
Perl_reentrant_init(pTHX) {
#ifdef USE_REENTRANT_API
	New(31337, PL_reentrant_buffer, 1, REENTR);
	Perl_reentrant_size(aTHX);
@init
#endif /* USE_REENTRANT_API */
}

void
Perl_reentrant_free(pTHX) {
#ifdef USE_REENTRANT_API
@free
	Safefree(PL_reentrant_buffer);
#endif /* USE_REENTRANT_API */
}

void*
Perl_reentrant_retry(const char *f, ...)
{
    dTHX;
    void *retptr = NULL;
#ifdef USE_REENTRANT_API
    void *p0, *p1;
    size_t asize;
    int anint;
    va_list ap;

    va_start(ap, f);

#define REENTRANTHALFMAXSIZE 32768 /* The maximum may end up twice this. */

    switch (PL_op->op_type) {
#ifdef USE_GETHOSTENT_BUFFER
    case OP_GHBYADDR:
    case OP_GHBYNAME:
    case OP_GHOSTENT:
	{
	    if (PL_reentrant_buffer->_gethostent_size <= REENTRANTHALFMAXSIZE) {
		PL_reentrant_buffer->_gethostent_size *= 2;
		Renew(PL_reentrant_buffer->_gethostent_buffer,
		      PL_reentrant_buffer->_gethostent_size, char);
		switch (PL_op->op_type) {
	        case OP_GHBYADDR:
		    p0    = va_arg(ap, void *);
		    asize = va_arg(ap, size_t);
		    anint  = va_arg(ap, int);
		    retptr = gethostbyaddr(p0, asize, anint); break;
	        case OP_GHBYNAME:
		    p0 = va_arg(ap, void *);
		    retptr = gethostbyname(p0); break;
	        case OP_GHOSTENT:
		    retptr = gethostent(); break;
	        default:
		    break;
	        }
	    }
	}
	break;
#endif
#ifdef USE_GETGRENT_BUFFER
    case OP_GGRNAM:
    case OP_GGRGID:
    case OP_GGRENT:
	{
	    if (PL_reentrant_buffer->_getgrent_size <= REENTRANTHALFMAXSIZE) {
		Gid_t gid;
		PL_reentrant_buffer->_getgrent_size *= 2;
		Renew(PL_reentrant_buffer->_getgrent_buffer,
		      PL_reentrant_buffer->_getgrent_size, char);
		switch (PL_op->op_type) {
	        case OP_GGRNAM:
		    p0 = va_arg(ap, void *);
		    retptr = getgrnam(p0); break;
	        case OP_GGRGID:
		    gid = va_arg(ap, Gid_t);
		    retptr = getgrgid(gid); break;
	        case OP_GGRENT:
		    retptr = getgrent(); break;
	        default:
		    break;
	        }
	    }
	}
	break;
#endif
#ifdef USE_GETNETENT_BUFFER
    case OP_GNBYADDR:
    case OP_GNBYNAME:
    case OP_GNETENT:
	{
	    if (PL_reentrant_buffer->_getnetent_size <= REENTRANTHALFMAXSIZE) {
		Netdb_net_t net;
		PL_reentrant_buffer->_getnetent_size *= 2;
		Renew(PL_reentrant_buffer->_getnetent_buffer,
		      PL_reentrant_buffer->_getnetent_size, char);
		switch (PL_op->op_type) {
	        case OP_GNBYADDR:
		    net = va_arg(ap, Netdb_net_t);
		    anint = va_arg(ap, int);
		    retptr = getnetbyaddr(net, anint); break;
	        case OP_GNBYNAME:
		    p0 = va_arg(ap, void *);
		    retptr = getnetbyname(p0); break;
	        case OP_GNETENT:
		    retptr = getnetent(); break;
	        default:
		    break;
	        }
	    }
	}
	break;
#endif
#ifdef USE_GETPWENT_BUFFER
    case OP_GPWNAM:
    case OP_GPWUID:
    case OP_GPWENT:
	{
	    if (PL_reentrant_buffer->_getpwent_size <= REENTRANTHALFMAXSIZE) {
		Uid_t uid;
		PL_reentrant_buffer->_getpwent_size *= 2;
		Renew(PL_reentrant_buffer->_getpwent_buffer,
		      PL_reentrant_buffer->_getpwent_size, char);
		switch (PL_op->op_type) {
	        case OP_GPWNAM:
		    p0 = va_arg(ap, void *);
		    retptr = getpwnam(p0); break;
	        case OP_GPWUID:
		    uid = va_arg(ap, Uid_t);
		    retptr = getpwuid(uid); break;
	        case OP_GPWENT:
		    retptr = getpwent(); break;
	        default:
		    break;
	        }
	    }
	}
	break;
#endif
#ifdef USE_GETPROTOENT_BUFFER
    case OP_GPBYNAME:
    case OP_GPBYNUMBER:
    case OP_GPROTOENT:
	{
	    if (PL_reentrant_buffer->_getprotoent_size <= REENTRANTHALFMAXSIZE) {
		PL_reentrant_buffer->_getprotoent_size *= 2;
		Renew(PL_reentrant_buffer->_getprotoent_buffer,
		      PL_reentrant_buffer->_getprotoent_size, char);
		switch (PL_op->op_type) {
	        case OP_GPBYNAME:
		    p0 = va_arg(ap, void *);
		    retptr = getprotobyname(p0); break;
	        case OP_GPBYNUMBER:
		    anint = va_arg(ap, int);
		    retptr = getprotobynumber(anint); break;
	        case OP_GPROTOENT:
		    retptr = getprotoent(); break;
	        default:
		    break;
	        }
	    }
	}
	break;
#endif
#ifdef USE_GETSERVENT_BUFFER
    case OP_GSBYNAME:
    case OP_GSBYPORT:
    case OP_GSERVENT:
	{
	    if (PL_reentrant_buffer->_getservent_size <= REENTRANTHALFMAXSIZE) {
		PL_reentrant_buffer->_getservent_size *= 2;
		Renew(PL_reentrant_buffer->_getservent_buffer,
		      PL_reentrant_buffer->_getservent_size, char);
		switch (PL_op->op_type) {
	        case OP_GSBYNAME:
		    p0 = va_arg(ap, void *);
		    p1 = va_arg(ap, void *);
		    retptr = getservbyname(p0, p1); break;
	        case OP_GSBYPORT:
		    anint = va_arg(ap, int);
		    p0 = va_arg(ap, void *);
		    retptr = getservbyport(anint, p0); break;
	        case OP_GSERVENT:
		    retptr = getservent(); break;
	        default:
		    break;
	        }
	    }
	}
	break;
#endif
    default:
	/* Not known how to retry, so just fail. */
	break;
    }

    va_end(ap);
#endif
    return retptr;
}

EOF

__DATA__
asctime S	|time	|const struct tm|B_SB|B_SBI|I_SB|I_SBI
crypt CC	|crypt	|struct crypt_data|B_CCS|B_CCD|D=CRYPTD*
ctermid	B	|stdio	|		|B_B
ctime S		|time	|const time_t	|B_SB|B_SBI|I_SB|I_SBI
drand48		|stdlib	|struct drand48_data	|I_ST|T=double*
endgrent	|grp	|		|I_H|V_H
endhostent	|netdb	|struct hostent_data	|I_S|V_S
endnetent	|netdb	|struct netent_data	|I_S|V_S
endprotoent	|netdb	|struct protoent_data	|I_S|V_S
endpwent	|pwd	|		|I_H|V_H
endservent	|netdb	|struct servent_data	|I_S|V_S
getgrent	|grp	|struct group	|I_SBWR|I_SBIR|S_SBW|S_SBI|I_SBI|I_SBIH
getgrgid T	|grp	|struct group	|I_TSBWR|I_TSBIR|I_TSBI|S_TSBI|T=gid_t
getgrnam C	|grp	|struct group	|I_CSBWR|I_CSBIR|S_CBI|I_CSBI|S_CSBI
gethostbyaddr CWI	|netdb	|struct hostent	|I_CWISBWRE|S_CWISBWIE|S_CWISBIE|S_TWISBIE|S_CIISBIE|S_CSBIE|S_TSBIE|I_CWISD|I_CIISD|I_CII|D=struct hostent_data*|T=const void*
gethostbyname C	|netdb	|struct hostent	|I_CSBWRE|S_CSBIE|I_CSD|D=struct hostent_data*
gethostent	|netdb	|struct hostent	|I_SBWRE|I_SBIE|S_SBIE|S_SBI|I_SBI|I_SD|D=struct hostent_data*
getlogin	|unistd	|		|I_BW|I_BI|B_BW|B_BI
getnetbyaddr LI	|netdb	|struct netent	|I_UISBWRE|I_LISBI|S_TISBI|S_LISBI|I_TISD|I_LISD|I_IISD|D=struct netent_data*|T=in_addr_t|U=unsigned long
getnetbyname C	|netdb	|struct netent	|I_CSBWRE|I_CSBI|S_CSBI|I_CSD|D=struct netent_data*
getnetent	|netdb	|struct netent	|I_SBWRE|I_SBIE|S_SBIE|S_SBI|I_SBI|I_SD|D=struct netent_data*
getprotobyname C|netdb	|struct protoent|I_CSBWR|S_CSBI|I_CSD|D=struct protoent_data*
getprotobynumber I	|netdb	|struct protoent|I_ISBWR|S_ISBI|I_ISD|D=struct protoent_data*
getprotoent	|netdb	|struct protoent|I_SBWR|I_SBI|S_SBI|I_SD|D=struct protoent_data*
getpwent	|pwd	|struct passwd	|I_SBWR|I_SBIR|S_SBW|S_SBI|I_SBI|I_SBIH
getpwnam C	|pwd	|struct passwd	|I_CSBWR|I_CSBIR|S_CSBI|I_CSBI
getpwuid T	|pwd	|struct passwd	|I_TSBWR|I_TSBIR|I_TSBI|S_TSBI|T=uid_t
getservbyname CC|netdb	|struct servent	|I_CCSBWR|S_CCSBI|I_CCSD|D=struct servent_data*
getservbyport IC|netdb	|struct servent	|I_ICSBWR|S_ICSBI|I_ICSD|D=struct servent_data*
getservent	|netdb	|struct servent	|I_SBWR|I_SBI|S_SBI|I_SD|D=struct servent_data*
getspnam C	|shadow	|struct spwd	|I_CSBWR|S_CSBI
gmtime T	|time	|struct tm	|S_TS|I_TS|T=const time_t*
localtime T	|time	|struct tm	|S_TS|I_TS|T=const time_t*
random		|stdlib	|struct random_data|I_TS|T=int*
readdir T	|dirent	|struct dirent	|I_TSR|I_TS|T=DIR*
readdir64 T	|dirent	|struct dirent64|I_TSR|I_TS|T=DIR*
setgrent	|grp	|		|I_H|V_H
sethostent I	|netdb	|		|I_ID|V_ID|D=struct hostent_data*
setlocale IC	|locale	|		|I_ICBI
setnetent I	|netdb	|		|I_ID|V_ID|D=struct netent_data*
setprotoent I	|netdb	|		|I_ID|V_ID|D=struct protoent_data*
setpwent	|pwd	|		|I_H|V_H
setservent I	|netdb	|		|I_ID|V_ID|D=struct servent_data*
srand48 L	|stdlib	|struct drand48_data	|I_LS
srandom	T	|stdlib	|struct random_data|I_TS|T=unsigned int
strerror I	|string	|		|I_IBW|I_IBI|B_IBW
tmpnam B	|stdio	|		|B_B
ttyname	I	|unistd	|		|I_IBW|I_IBI|B_IBI
