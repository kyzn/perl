/* -*- buffer-read-only: t -*-
   !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!!
   This file is built by regen/pX.pl.
   Any changes made here will be lost!
 */


/*    perl7.h
 *
 *    Copyright (C) 2020 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#ifndef H_PERL_7
#define H_PERL_7 1

/* this is used by toke.c to setup a Perl7 flavor */
/* #define P7_TOKE_SETUP "use p7;" */

/*
*   GENERATED using lib/feature.pm: FIXME
*/

#define P7_TOKE_SETUP "BEGIN { "\
                      "   ${^WARNING_BITS} = pack( 'H*', '555555555555555555555555150001500101' );"\
                      "   $^H |= 0x1C0206E2;"\
                      "   $^H{feature___SUB__} = 1; $^H{feature_bitwise} = 1; $^H{feature_evalbytes} = 1; $^H{feature_fc} = 1; $^H{feature_myref} = 1; $^H{feature_postderef_qq} = 1; $^H{feature_refaliasing} = 1; $^H{feature_say} = 1; $^H{feature_signatures} = 1; $^H{feature_state} = 1; $^H{feature_switch} = 1; $^H{feature_unieval} = 1;"\
                      "}"

/*

bitwise current_sub declared_refs evalbytes fc postderef_qq refaliasing say signatures state switch unicode_eval
*/

#endif /* Include guard */

/* ex: set ro: */
