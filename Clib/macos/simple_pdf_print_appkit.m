/* simple_pdf's print library, macOS (1v-c): an existing PDF printed through PDFKit's own
   print operation and the native print panel, as a sheet on the parent window. This is
   simple_gui's former sga_print_pdf, moved here unchanged in what it does (Larry: "no need to
   re-invent the wheel"); around it: the printer check, the save-to-file test seam, the
   default paper, and reasons for failures.
   cc -fobjc-arc -c simple_pdf_print_appkit.m (see the Makefile) */
#import <Cocoa/Cocoa.h>
#import <PDFKit/PDFKit.h>
#include <cups/cups.h>
#include <string.h>
#include "simple_pdf_print_appkit.h"

static char s_error[1024];
static void spp_fail(NSString *a_reason) { strlcpy(s_error, [a_reason UTF8String] ?: "printing failed", sizeof s_error); }
const char *spp_last_error(void) { return s_error; }

static NSString *spp_string(const char *s) { return s ? [NSString stringWithUTF8String:s] ?: @"" : @""; }

/* A console program (a test) has no application yet: make it, as AppKit's printing needs one. */
static void spp_application(void)
{
	if (!NSApp) [NSApplication sharedApplication];
}

/* A printer the print panel can print to: a queue added on this Mac, or a printer the
   system has found on the network (the panel offers those and adds one when it is chosen),
   which is CUPS's list of destinations, as `lpstat -e' shows it. */
int spp_has_printer(void)
{
	spp_application();
	if ([[NSPrinter printerNames] count] > 0) return 1;
	cups_dest_t *l_dests = NULL;
	int n = cupsGetDests2(CUPS_HTTP_DEFAULT, &l_dests);
	cupsFreeDests(n, l_dests);
	return n > 0;
}

/* The system's default paper, in points; Letter when it says nothing. */
static NSSize spp_default_paper(void)
{
	spp_application();
	NSSize z = [[NSPrintInfo sharedPrintInfo] paperSize];
	return z.width > 0 && z.height > 0 ? z : NSMakeSize(612, 792);
}
double spp_default_paper_width(void) { return spp_default_paper().width; }
double spp_default_paper_height(void) { return spp_default_paper().height; }

/* The PDF at `a_path', or nil with the reason set. */
static PDFDocument *spp_document(const char *a_path)
{
	NSString *p = spp_string(a_path);
	PDFDocument *d = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:p]];
	if (!d) { spp_fail([NSString stringWithFormat:@"PDFKit could not open %@ as a PDF", p]); return nil; }
	if ([d pageCount] == 0) { spp_fail([NSString stringWithFormat:@"%@ has no pages", p]); return nil; }
	return d;
}

/* The print info for `d': no margins, and the paper following the first page's size and
   shape (the pages are already laid out). */
static NSPrintInfo *spp_print_info(PDFDocument *d)
{
	NSPrintInfo *i = [[NSPrintInfo sharedPrintInfo] copy];
	[i setTopMargin:0]; [i setBottomMargin:0]; [i setLeftMargin:0]; [i setRightMargin:0];
	NSRect b = [[d pageAtIndex:0] boundsForBox:kPDFDisplayBoxMediaBox];
	if (NSWidth(b) > 0 && NSHeight(b) > 0) {
		[i setPaperSize:b.size];
		[i setOrientation:NSWidth(b) > NSHeight(b) ? NSPaperOrientationLandscape : NSPaperOrientationPortrait];
	}
	return i;
}

/* The sheet's end: whether the user printed. */
static int s_print_result;
@interface SPPPrintEnd : NSObject
@end
@implementation SPPPrintEnd
- (void)printOperationDidRun:(NSPrintOperation *)op success:(BOOL)ok contextInfo:(void *)c
{
	(void)op; (void)c;
	s_print_result = ok ? 1 : 0;
	[NSApp stopModal];
}
@end

int spp_print_file(const char *a_path, const char *a_title, void *a_parent)
{
	s_error[0] = 0;
	spp_application();
	if (!spp_has_printer()) return -2;   /* no printer: no panel */
	PDFDocument *d = spp_document(a_path);
	if (!d) return -1;
	NSPrintOperation *op = [d printOperationForPrintInfo:spp_print_info(d) scalingMode:kPDFPrintPageScaleDownToFit autoRotate:YES];
	if (!op) { spp_fail(@"PDFKit made no print operation for the PDF"); return -1; }
	NSString *l_title = spp_string(a_title);
	if ([l_title length]) [op setJobTitle:l_title];
	[op setShowsPrintPanel:YES];
	[op setShowsProgressPanel:YES];
	[[op printPanel] setOptions:NSPrintPanelShowsCopies | NSPrintPanelShowsPageRange | NSPrintPanelShowsPaperSize
		| NSPrintPanelShowsOrientation | NSPrintPanelShowsScaling | NSPrintPanelShowsPreview];
	id w = (__bridge id)a_parent;
	if (w && ![w isKindOfClass:[NSWindow class]]) w = nil;
	s_print_result = 0;
	if (w && [w isVisible] && ![w attachedSheet]) {
		static SPPPrintEnd *s_end;
		if (!s_end) s_end = [[SPPPrintEnd alloc] init];
		[op runOperationModalForWindow:w delegate:s_end didRunSelector:@selector(printOperationDidRun:success:contextInfo:) contextInfo:NULL];
		/* wait in AppKit's own modal loop (the parent and its sheet) until the sheet ends */
		[NSApp runModalForWindow:w];
	}
	else s_print_result = [op runOperation] ? 1 : 0;
	return s_print_result;
}

/* ---------------------------------------------------------------- for the tests only */

int spp_test_page_count(const char *a_path)
{
	PDFDocument *d = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:spp_string(a_path)]];
	return d ? (int)[d pageCount] : -1;
}

double spp_test_pixels_off(const char *a_path, int a_page, const char *a_png)
{
	spp_application();
	PDFDocument *d = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:spp_string(a_path)]];
	NSBitmapImageRep *b = [NSBitmapImageRep imageRepWithData:[NSData dataWithContentsOfFile:spp_string(a_png)]];
	if (!d || !b || a_page < 1 || a_page > (int)[d pageCount]) return -1;
	PDFPage *p = [d pageAtIndex:(NSUInteger)a_page - 1];
	NSRect r = [p boundsForBox:kPDFDisplayBoxMediaBox];
	NSInteger w = (NSInteger)NSWidth(r), h = (NSInteger)NSHeight(r);
	if (w != [b pixelsWide] || h != [b pixelsHigh]) return -1;
	NSBitmapImageRep *a = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:w pixelsHigh:h bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
	CGContextRef cg = [[NSGraphicsContext graphicsContextWithBitmapImageRep:a] CGContext];
	CGContextSetRGBFillColor(cg, 1, 1, 1, 1);
	CGContextFillRect(cg, CGRectMake(0, 0, w, h));
	[p drawWithBox:kPDFDisplayBoxMediaBox toContext:cg];
	long l_off = 0;
	for (NSInteger y = 0; y < h; y++) for (NSInteger x = 0; x < w; x++) {
		NSUInteger pa[4], pb[4];
		[a getPixel:pa atX:x y:y];
		[b getPixel:pb atX:x y:y];
		int l_most = 0;
		for (int k = 0; k < 3; k++) { int l_d = abs((int)pa[k] - (int)pb[k]); if (l_d > l_most) l_most = l_d; }
		if (l_most > 64) l_off++;
	}
	return (double)l_off / (double)(w * h);
}

/* The test seam: the same operation with no panel, the job saved to `an_out_path' as a PDF
   (the panel's own "Save as PDF"); it needs no printer. */
int spp_print_file_to(const char *a_path, const char *an_out_path)
{
	s_error[0] = 0;
	spp_application();
	PDFDocument *d = spp_document(a_path);
	if (!d) return -1;
	NSPrintInfo *i = spp_print_info(d);
	NSString *l_out = spp_string(an_out_path);
	[i setJobDisposition:NSPrintSaveJob];
	[[i dictionary] setObject:[NSURL fileURLWithPath:l_out] forKey:NSPrintJobSavingURL];
	NSPrintOperation *op = [d printOperationForPrintInfo:i scalingMode:kPDFPrintPageScaleDownToFit autoRotate:YES];
	if (!op) { spp_fail(@"PDFKit made no print operation for the PDF"); return -1; }
	[op setShowsPrintPanel:NO];
	[op setShowsProgressPanel:NO];
	if (![op runOperation]) { spp_fail([NSString stringWithFormat:@"the print operation did not save %@", l_out]); return -1; }
	if (![[NSFileManager defaultManager] fileExistsAtPath:l_out]) { spp_fail([NSString stringWithFormat:@"the print operation reported success but wrote no %@", l_out]); return -1; }
	return 1;
}
