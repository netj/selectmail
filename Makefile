VERSION=1.1 (2007-02-22)

SRC=src
OBJ?=obj
TMP?=tmp
BINDIR=$(OBJ)/bin
EXEDIR=$(OBJ)/bin/selectmail
DATADIR=$(OBJ)/bin/selectmail
OBJDIRS=$(BINDIR) $(EXEDIR) $(DATADIR) $(TMP)
TARGETS=\
	$(BINDIR)/classmail		\
	$(BINDIR)/learnmail		\
	$(BINDIR)/forgetmail		\
	$(BINDIR)/studymail		\
	$(BINDIR)/keepmail		\
	$(EXEDIR)/common		\
	$(EXEDIR)/class-naive-bayesian	\
	$(EXEDIR)/tokenize		\
	$(EXEDIR)/tokenize1		\
	$(EXEDIR)/counts		\
	$(DATADIR)/config		\
	

.PHONY: all clean

all: $(TARGETS)

clean:
	rm -rf "$(OBJ)"

# dirs
%/:
	mkdir -p "$@"

# general rules
$(BINDIR)/% $(EXEDIR)/%: $(SRC)/%
	mkdir -p "`dirname "$@"`"
	install -m a=rx "$<" "$@"

$(BINDIR)/% $(EXEDIR)/%: $(SRC)/%.sh
	mkdir -p "`dirname "$@"`"
	-chmod +w "$@"
	sed -e 's#$$EXEDIR#'"$(EXEDIR:$(OBJ)/%=../%)"'#g' \
	    -e 's#$$VERSION#'"$(VERSION)"'#g' \
	    <"$<" >"$@"
	chmod a=rx "$@"

$(BINDIR)/% $(EXEDIR)/%: $(SRC)/%.pl
	mkdir -p "`dirname "$@"`"
	install -m 555 "$<" "$@"

$(DATADIR)/%: $(SRC)/%
	mkdir -p "`dirname "$@"`"
	install -m 444 "$<" "$@"

$(BINDIR)/% $(EXEDIR)/%: $(SRC)/%.hs $(TMP)/
	ghc -Wall -O2 -hidir "$(TMP)" -odir "$(TMP)" -o "$@" "$<"


# specific rules
$(BINDIR)/learnmail \
$(BINDIR)/forgetmail \
$(BINDIR)/studymail: $(BINDIR)/classmail
	ln -sf classmail "$@"
