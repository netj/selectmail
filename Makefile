VERSION=1.2 (2007-04-03)

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

$(BINDIR)/% $(EXEDIR)/%: $(SRC)/%.hs $(TMP)/
	ghc -Wall -O2 -hidir "$(TMP)" -odir "$(TMP)" -o "$@" "$<"

$(BINDIR)/% $(EXEDIR)/%: $(SRC)/%.pl
	mkdir -p "`dirname "$@"`"
	install -m 555 "$<" "$@"

$(BINDIR)/% $(EXEDIR)/%: $(SRC)/%.sh
	mkdir -p "`dirname "$@"`"
	-chmod +w "$@"
	sed -e 's#$$EXEDIR#'"$(EXEDIR:$(OBJ)/%=../%)"'#g' \
	    -e 's#$$VERSION#'"$(VERSION)"'#g' \
	    <"$<" >"$@"
	chmod a=rx "$@"

$(DATADIR)/%: $(SRC)/%
	mkdir -p "`dirname "$@"`"
	install -m 444 "$<" "$@"


# specific rules
$(BINDIR)/learnmail \
$(BINDIR)/forgetmail \
$(BINDIR)/studymail: $(BINDIR)/classmail
	ln -sf classmail "$@"
