#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

I32 my_dopoptosub(const PERL_CONTEXT *cxstk, I32 startingblock) {
    I32 i;
    for(i=startingblock; i>=0; i--) {
        const PERL_CONTEXT * const cx = &cxstk[i];

        switch (CxTYPE(cx)) {
            case CXt_EVAL:
            case CXt_SUB:
            case CXt_FORMAT:
            return i;
        }
    }

    return i;
}

MODULE = Object::PreviousObject PACKAGE = Object::PreviousObject

SV*
previous_object_xs()

    PREINIT:
    register I32 cxix = my_dopoptosub(cxstack, cxstack_ix);
    register const PERL_CONTEXT *cx;
    register const PERL_CONTEXT *ccstack = cxstack;
    const PERL_SI *top_si = PL_curstackinfo;
    int count = 1; // this corresponds to the caller(2) from the previous_object_perl 

	CODE:
    RETVAL = newSV(0); // just return undef by default

    for (;;) {
        while (cxix < 0 && top_si->si_type != PERLSI_MAIN) {
            top_si = top_si->si_prev;
            ccstack = top_si->si_cxstack;
            cxix = my_dopoptosub(ccstack, top_si->si_cxix);
        }

        if (cxix < 0)
            break;

        if (!count--)
            break;

        cxix = my_dopoptosub(ccstack, cxix - 1);
    }

    if( cxix >= 0 ) {
        cx = &ccstack[cxix];

        if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
            GV *cvgv = CvGV(cx->blk_sub.cv);

            if (isGV(cvgv)) {
                const char *fname;
                const char *stashname = CopSTASHPV(ccstack[cxix+1].blk_oldcop);
                SV * const subnsv = NEWSV(49, 0);

                gv_efullname3(subnsv, cvgv, Nullch);
                fname = SvPV(subnsv, PL_na);

                warn("\e[1;34mstashname=%s; fname=%s\e[m", stashname, fname);

                // PUSHs(sv_2mortal(sv));
                // PUSHs(sv_2mortal(newSViv((I32)cx->blk_sub.hasargs)));
                RETVAL = subnsv;
            }
        }
    }

    OUTPUT:
    RETVAL
