/* simple_pdf's print library, macOS: printing an existing PDF through PDFKit (1v-c).
   Built by `make -C Clib/macos' into simple_pdf_print_appkit.o, which simple_pdf_print.ecf
   links on macOS. Strings are UTF-8. Every call is made on the main (GUI) thread. */
#ifndef SIMPLE_PDF_PRINT_APPKIT_H
#define SIMPLE_PDF_PRINT_APPKIT_H

/* Outcomes, as PDF_PRINT_PLATFORM_API's: 1 printed (handed to the print queue), 0 cancelled,
   -1 failed (spp_last_error says why), -2 no printer (no panel was shown). */
int spp_has_printer(void);
double spp_default_paper_width(void);
double spp_default_paper_height(void);
int spp_print_file(const char *a_path, const char *a_title, void *a_parent);
int spp_print_file_to(const char *a_path, const char *an_out_path);
const char *spp_last_error(void);

/* For the tests only: the pages PDFKit sees in `a_path'; and the share (0 to 1) of pixels of
   PDFKit's page `a_page' (from 1) at 72 dpi that differ by more than 64 of 255, in any color,
   from the PNG at `a_png' (poppler's rendering); -1 when either cannot be read or the sizes
   differ. */
int spp_test_page_count(const char *a_path);
double spp_test_pixels_off(const char *a_path, int a_page, const char *a_png);

#endif
