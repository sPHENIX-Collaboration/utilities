AUTOMAKE_OPTIONS = foreign 

INCLUDES = -I$(includedir) -I$(OFFLINE_MAIN)/include -I`root-config --incdir`

bin_PROGRAMS = jprof

jprof_SOURCES = \
  bfd.cpp \
  coff.cpp \
  elf.cpp \
  leaky.cpp \
  strset.cpp \
  intcnt.cpp

jprof_LDADD = \
  -L$(libdir) \
  -L$(OFFLINE_MAIN)/lib \
  -lboost_regex \
  -lbfd \
  -liberty \
  -ldl

lib_LTLIBRARIES = libjprof.la

libjprof_la_SOURCES = libmalloc.cpp prof.C profDict.C

include_HEADERS = jprof.h prof.h	

EXTRA_DIST = README.html

noinst_HEADERS = leaky.h strset.h libmalloc.h intcnt.h config.h profLinkDef.h

profDict.C: prof.h profLinkDef.h
	rootcint -f $@ -c $(DEFS) $(INCLUDES) $^

clean-local:
	rm -f *Dict*








