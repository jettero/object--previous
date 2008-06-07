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
    int count = 2; // this corresponds to the caller(2) from the previous_object_perl 

	PPCODE:
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

    if( cxix >= 0 )
        cx = &ccstack[cxix];
