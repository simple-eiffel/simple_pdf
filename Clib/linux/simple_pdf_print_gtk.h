/* simple_pdf_print_gtk.h - printing an existing PDF on Linux (1v-c, 2026-11-11).

   GtkPrintOperation with the system dialog; each page is drawn by Poppler's own
   poppler_page_render_for_printing into the operation's cairo context, and each
   sheet takes the PDF page's own size and orientation (request-page-setup), as
   Windows' pdftocairo -origpagesizes does. The test seam is the operation's
   EXPORT action to a PDF file: the same drawing, no dialog, no printer.

   Header-only, static functions, no state kept between calls: everything a run
   needs lives on its stack (the poppler document rides on the operation). */

#ifndef SIMPLE_PDF_PRINT_GTK_H
#define SIMPLE_PDF_PRINT_GTK_H

#include <string.h>
#include <gtk/gtk.h>
#include <gtk/gtkunixprint.h> /* GtkPrinter, gtk_enumerate_printers */
#include <poppler.h>

/* Make GTK usable from a console program too; 1 when it is. */
static int spp_gtk_ready(void)
{
    return gtk_init_check() ? 1 : 0;
}

/* Copy `a_text' into `a_out' (capacity `a_cap' bytes, terminated). */
static void spp_set_message(char* a_out, int a_cap, const char* a_text)
{
    if (a_out && a_cap > 0) {
        strncpy(a_out, a_text ? a_text : "", (size_t) (a_cap - 1));
        a_out[a_cap - 1] = 0;
    }
}

static gboolean spp_count_printer(GtkPrinter* a_printer, gpointer a_count)
{
    /* GTK's "Print to File" is always there and is not a queue: it does not count. */
    if (!gtk_printer_is_virtual(a_printer)) {
        (*(int*) a_count)++;
    }
    return FALSE; /* keep enumerating */
}

/* How many printer queues GTK sees (CUPS, local and discovered), leaving out the
   virtual print-to-file printer; -1 when GTK cannot start. */
static int spp_printer_count(void)
{
    int l_count = 0;
    if (!spp_gtk_ready()) return -1;
    gtk_enumerate_printers(spp_count_printer, &l_count, NULL, TRUE);
    return l_count;
}

/* The default paper's size in points into a_w, a_h; 0 when GTK cannot start. */
static int spp_default_paper(double* a_w, double* a_h)
{
    GtkPaperSize* l_size;
    if (!spp_gtk_ready()) return 0;
    l_size = gtk_paper_size_new(NULL);
    *a_w = gtk_paper_size_get_width(l_size, GTK_UNIT_POINTS);
    *a_h = gtk_paper_size_get_height(l_size, GTK_UNIT_POINTS);
    gtk_paper_size_free(l_size);
    return 1;
}

static void spp_page_setup(GtkPrintOperation* a_op, GtkPrintContext* a_context, int a_page, GtkPageSetup* a_setup, gpointer a_doc)
{
    PopplerPage* l_page = poppler_document_get_page((PopplerDocument*) a_doc, a_page);
    double l_w = 0, l_h = 0;
    GtkPaperSize* l_size;
    (void) a_op; (void) a_context;
    if (!l_page) return;
    poppler_page_get_size(l_page, &l_w, &l_h);
    g_object_unref(l_page);
    if (l_w <= 0 || l_h <= 0) return;
    if (l_w > l_h) {
        l_size = gtk_paper_size_new_custom("simple_pdf_page", "PDF page", l_h, l_w, GTK_UNIT_POINTS);
        gtk_page_setup_set_orientation(a_setup, GTK_PAGE_ORIENTATION_LANDSCAPE);
    } else {
        l_size = gtk_paper_size_new_custom("simple_pdf_page", "PDF page", l_w, l_h, GTK_UNIT_POINTS);
        gtk_page_setup_set_orientation(a_setup, GTK_PAGE_ORIENTATION_PORTRAIT);
    }
    gtk_page_setup_set_paper_size(a_setup, l_size);
    gtk_paper_size_free(l_size);
}

static void spp_draw_page(GtkPrintOperation* a_op, GtkPrintContext* a_context, int a_page, gpointer a_doc)
{
    PopplerPage* l_page = poppler_document_get_page((PopplerDocument*) a_doc, a_page);
    cairo_t* l_cr = gtk_print_context_get_cairo_context(a_context);
    (void) a_op;
    if (!l_page) return;
    poppler_page_render_for_printing(l_page, l_cr);
    g_object_unref(l_page);
}

/* Print the PDF at `a_path' (a file path, UTF-8). With `a_out' non-null and not
   empty: export to that PDF file with no dialog (the test seam); else the system
   dialog over `a_parent' (a GtkWindow, or null). The job is named `a_title'.
   Answers 1 printed, 0 cancelled, -1 failed (the reason in `a_message'). */
static int spp_print(const char* a_path, const char* a_title, void* a_parent, const char* a_out, char* a_message, int a_cap)
{
    GError* l_error = NULL;
    gchar* l_uri;
    PopplerDocument* l_doc;
    GtkPrintOperation* l_op;
    GtkPrintOperationResult l_result;
    GtkPrintOperationAction l_action;
    int l_answer = -1;

    spp_set_message(a_message, a_cap, "");
    if (!spp_gtk_ready()) {
        spp_set_message(a_message, a_cap, "GTK could not start (no display).");
        return -1;
    }
    l_uri = g_filename_to_uri(a_path, NULL, &l_error);
    if (!l_uri) {
        spp_set_message(a_message, a_cap, l_error ? l_error->message : "The PDF's path could not be made a URI.");
        if (l_error) g_error_free(l_error);
        return -1;
    }
    l_doc = poppler_document_new_from_file(l_uri, NULL, &l_error);
    g_free(l_uri);
    if (!l_doc) {
        spp_set_message(a_message, a_cap, l_error ? l_error->message : "Poppler could not open the PDF.");
        if (l_error) g_error_free(l_error);
        return -1;
    }
    l_op = gtk_print_operation_new();
    gtk_print_operation_set_n_pages(l_op, poppler_document_get_n_pages(l_doc));
    gtk_print_operation_set_job_name(l_op, a_title);
    gtk_print_operation_set_use_full_page(l_op, TRUE);
    gtk_print_operation_set_unit(l_op, GTK_UNIT_POINTS);
    g_signal_connect(l_op, "request-page-setup", G_CALLBACK(spp_page_setup), l_doc);
    g_signal_connect(l_op, "draw-page", G_CALLBACK(spp_draw_page), l_doc);
    if (a_out && a_out[0]) {
        gtk_print_operation_set_export_filename(l_op, a_out);
        l_action = GTK_PRINT_OPERATION_ACTION_EXPORT;
    } else {
        l_action = GTK_PRINT_OPERATION_ACTION_PRINT_DIALOG;
    }
    l_result = gtk_print_operation_run(l_op, l_action, a_parent ? GTK_WINDOW(a_parent) : NULL, &l_error);
    if (l_result == GTK_PRINT_OPERATION_RESULT_APPLY || l_result == GTK_PRINT_OPERATION_RESULT_IN_PROGRESS) {
        l_answer = 1;
    } else if (l_result == GTK_PRINT_OPERATION_RESULT_CANCEL) {
        l_answer = 0;
    } else {
        spp_set_message(a_message, a_cap, l_error ? l_error->message : "The print operation failed.");
        l_answer = -1;
    }
    if (l_error) g_error_free(l_error);
    g_object_unref(l_op);
    g_object_unref(l_doc);
    return l_answer;
}

#endif /* SIMPLE_PDF_PRINT_GTK_H */
