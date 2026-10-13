include ../common.mk
LDLIBS = -lm

PROG = fib

all: $(PROG)

$(PROG): callfib.c $(ARCH)/$(PROG).S
	$(CCLD) $(CFLAGS) -o $@ $^ $(LDLIBS)

run: $(PROG)
	$(RUN) ./$(PROG)

clean:
	rm -rf *.o $(PROG) *.dSYM

.PHONY: all run clean
