
PP(pp_caller) {
    dSP;
    register I32 cxix = dopoptosub(cxstack_ix);
    register const PERL_CONTEXT *cx;
    register const PERL_CONTEXT *ccstack = cxstack;
    const PERL_SI *top_si = PL_curstackinfo;
    I32 gimme;
    const char *stashname;
    I32 count = 0;

    if (MAXARG)
        count = POPi;

    for (;;) {
        /* we may be in a higher stacklevel, so dig down deeper */
        while (cxix < 0 && top_si->si_type != PERLSI_MAIN) {
            top_si = top_si->si_prev;
            ccstack = top_si->si_cxstack;
            cxix = dopoptosub_at(ccstack, top_si->si_cxix);
        }

        if (cxix < 0) {
            if (GIMME != G_ARRAY) {
                EXTEND(SP, 1);
                RETPUSHUNDEF;
            }

            RETURN;
        }

        /* caller() should not report the automatic calls to &DB::sub */
        if (PL_DBsub && GvCV(PL_DBsub) && cxix >= 0 && ccstack[cxix].blk_sub.cv == GvCV(PL_DBsub))
            count++;

        if (!count--)
            break;

        cxix = dopoptosub_at(ccstack, cxix - 1);
    }

    cx = &ccstack[cxix];
    if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
        const I32 dbcxix = dopoptosub_at(ccstack, cxix - 1);

        /* We expect that ccstack[dbcxix] is CXt_SUB, anyway, the
           field below is defined for any cx. */
        /* caller() should not report the automatic calls to &DB::sub */

        if (PL_DBsub && GvCV(PL_DBsub) && dbcxix >= 0 && ccstack[dbcxix].blk_sub.cv == GvCV(PL_DBsub))
            cx = &ccstack[dbcxix];
    }

    stashname = CopSTASHPV(cx->blk_oldcop);
    if (GIMME != G_ARRAY) {
        EXTEND(SP, 1);

        // PAUL: scalar context, seems to skip the stuff I want

        if (!stashname)
            PUSHs(&PL_sv_undef);

        else {
            dTARGET;
            sv_setpv(TARG, stashname);
            PUSHs(TARG);
        }

        RETURN;
    }

    EXTEND(SP, 10);

    // PAUL: my @foo = caller(2)
    // PAUL: stash == namespace apparently $foo[0]
    if (!stashname) PUSHs(&PL_sv_undef);
    else            PUSHs(sv_2mortal(newSVpv(stashname, 0)));

    PUSHs(sv_2mortal(newSVpv(OutCopFILE(cx->blk_oldcop), 0))); // the filename $foo[1]
    PUSHs(sv_2mortal(newSViv((I32)CopLINE(cx->blk_oldcop)))); // line $foo[2]

    if (!MAXARG)
        RETURN;

    if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
        GV *cvgv = CvGV(ccstack[cxix].blk_sub.cv);

        /* So is ccstack[dbcxix]. */

        // PAUL: this is probably what we're looking for... $foo[3] is the name of the subroutine
        //       $foo[4] is "hasargs:" whether a new @_ was set up for the frame

        if (isGV(cvgv)) {
            SV * const sv = NEWSV(49, 0);
            gv_efullname3(sv, cvgv, Nullch);
            PUSHs(sv_2mortal(sv));
            PUSHs(sv_2mortal(newSViv((I32)cx->blk_sub.hasargs)));
        }

        else {
            PUSHs(sv_2mortal(newSVpvn("(unknown)",9)));
            PUSHs(sv_2mortal(newSViv((I32)cx->blk_sub.hasargs)));
        }

    } else {
        PUSHs(sv_2mortal(newSVpvn("(eval)",6)));
        PUSHs(sv_2mortal(newSViv(0)));
    }

    gimme = (I32)cx->blk_gimme;

    if (gimme == G_VOID) PUSHs(&PL_sv_undef);
    else                 PUSHs(sv_2mortal(newSViv(gimme & G_ARRAY)));

    if (CxTYPE(cx) == CXt_EVAL) {
        if (cx->blk_eval.old_op_type == OP_ENTEREVAL) {
            /* eval STRING */
            PUSHs(cx->blk_eval.cur_text);
            PUSHs(&PL_sv_no);

        } else if (cx->blk_eval.old_namesv) {
            /* require */
            PUSHs(sv_2mortal(newSVsv(cx->blk_eval.old_namesv)));
            PUSHs(&PL_sv_yes);

        } else {
            /* eval BLOCK (try blocks have old_namesv == 0) */
            PUSHs(&PL_sv_undef);
            PUSHs(&PL_sv_undef);
        }

    } else {
        PUSHs(&PL_sv_undef);
        PUSHs(&PL_sv_undef);
    }

    if (CxTYPE(cx) == CXt_SUB && cx->blk_sub.hasargs && CopSTASH_eq(PL_curcop, PL_debstash)) {
        AV * const ary = cx->blk_sub.argarray;
        const int off = AvARRAY(ary) - AvALLOC(ary);

        if (!PL_dbargs) {
            GV* tmpgv;
            PL_dbargs = GvAV(gv_AVadd(tmpgv = gv_fetchpv("DB::args", TRUE, SVt_PVAV)));
            GvMULTI_on(tmpgv);
            AvREAL_off(PL_dbargs);	/* XXX should be REIFY (see av.h) */
        }

        if (AvMAX(PL_dbargs) < AvFILLp(ary) + off)
            av_extend(PL_dbargs, AvFILLp(ary) + off);

        Copy(AvALLOC(ary), AvARRAY(PL_dbargs), AvFILLp(ary) + 1 + off, SV*);
        AvFILLp(PL_dbargs) = AvFILLp(ary) + off;
    }

    /* XXX only hints propagated via op_private are currently
     * visible (others are not easily accessible, since they
     * use the global PL_hints) */
    PUSHs(sv_2mortal(newSViv((I32)cx->blk_oldcop->op_private & HINT_PRIVATE_MASK)));

    // PAUL: you can drop an arbitrary scope in C?
    {
        SV * mask ;
        SV * old_warnings = cx->blk_oldcop->cop_warnings ;

        if  (old_warnings == pWARN_NONE || (old_warnings == pWARN_STD && (PL_dowarn & G_WARN_ON) == 0))
            mask = newSVpvn(WARN_NONEstring, WARNsize) ;

        else if (old_warnings == pWARN_ALL || (old_warnings == pWARN_STD && PL_dowarn & G_WARN_ON)) {
            /* Get the bit mask for $warnings::Bits{all}, because
             * it could have been extended by warnings::register */
            SV **bits_all;
            HV *bits = get_hv("warnings::Bits", FALSE);

            if (bits && (bits_all=hv_fetch(bits, "all", 3, FALSE))) {
                mask = newSVsv(*bits_all);

            } else {
                mask = newSVpvn(WARN_ALLstring, WARNsize) ;
            }

        } else mask = newSVsv(old_warnings);

        PUSHs(sv_2mortal(mask));
    }

    RETURN;
}
