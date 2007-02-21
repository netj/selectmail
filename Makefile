SRC=src
OBJ?=obj
TMP?=tmp
BINDIR=$(OBJ)/bin
EXEDIR=$(OBJ)/bin/selectmail
OBJDIRS=$(BINDIR) $(EXEDIR) $(TMP)
TARGETS=\
	$(BINDIR)/classmail		\
	$(BINDIR)/learnmail		\
	$(BINDIR)/forgetmail		\
	$(BINDIR)/studymail		\
	$(EXEDIR)/class-naive-bayesian	\
	$(EXEDIR)/tokenize		\
	$(EXEDIR)/tokenize1		\
	$(EXEDIR)/counts		\
	

.PHONY: all clean

all: $(TARGETS)

$(OBJDIRS):
	mkdir -p "$@"

$(BINDIR)/%: $(SRC)/% $(BINDIR)
	install -m a=rx "$<" "$@"
$(EXEDIR)/%: $(SRC)/% $(EXEDIR)
	install -m a=rx "$<" "$@"

$(BINDIR)/classmail: $(SRC)/classmail $(BINDIR)
	sed -e 's#$$EXEDIR#'"$(EXEDIR:$(OBJ)/%=../%)"'#g' <"$<" >"$@"
	chmod a=rx "$@"

$(BINDIR)/learnmail \
$(BINDIR)/forgetmail \
$(BINDIR)/studymail: $(BINDIR)/classmail
	ln -sf classmail "$@"

$(EXEDIR)/class-%: $(SRC)/class-%.hs $(EXEDIR) $(TMP)
	ghc -Wall -O2 -hidir "$(TMP)" -odir "$(TMP)" -o "$@" "$<"

$(EXEDIR)/class-%: $(SRC)/class-%.pl $(EXEDIR)
	install -m 555 "$<" "$@"

clean:
	rm -rf "$(OBJ)"
