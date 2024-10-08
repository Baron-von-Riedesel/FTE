#ifndef __FTEVER_H
#define __FTEVER_H

#define MAKE_VERSION(major,minor,release) ((major<<24L) | (minor << 16L) | release)

#define PROG_FTE      "fte"
#define PROG_CFTE     "cfte"
#define PROGRAM       PROG_FTE
#define EXTRA_VERSION ""
#define VERSION       "0.51" EXTRA_VERSION
#define VERNUM        MAKE_VERSION(0x00, 0x51, 0x0000)
#define COPYRIGHT     "Copyright (c) 1994-1998 Marko Macek\n" \
                      "Copyright (c) 2000-2024 Others"

#endif // __FTEVER_H
