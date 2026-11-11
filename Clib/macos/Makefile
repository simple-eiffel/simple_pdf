# simple_pdf's print library on macOS: make (from this folder) builds the object
# simple_pdf_print.ecf links on macintosh.
CFLAGS = -O2 -g -fobjc-arc -Wall

simple_pdf_print_appkit.o: simple_pdf_print_appkit.m simple_pdf_print_appkit.h
	$(CC) $(CFLAGS) -c simple_pdf_print_appkit.m -o simple_pdf_print_appkit.o

clean:
	rm -f simple_pdf_print_appkit.o
