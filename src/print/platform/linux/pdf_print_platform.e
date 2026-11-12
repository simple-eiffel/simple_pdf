note
	description: "[
		Printing an existing PDF on Linux (1v-c): GtkPrintOperation with the system dialog,
		each page drawn by Poppler's own poppler_page_render_for_printing, each sheet at the PDF
		page's size and orientation. The test seam is the operation's EXPORT action to a file.
		The C is Clib/linux/simple_pdf_print_gtk.h (the system's gtk4 and poppler-glib).
	]"

class
	PDF_PRINT_PLATFORM

inherit
	PDF_PRINT_PLATFORM_API

create
	make

feature {NONE} -- Initialization

	make
			-- A printer for existing PDFs.
		do
		end

feature -- Status

	has_printer: BOOLEAN
			-- Does GTK see a printer queue (CUPS, local or discovered)? Its virtual "Print to
			-- File" does not count.
		do
			Result := c_printer_count > 0
		end

feature -- Paper

	default_paper_width: REAL_64
			-- GTK's default paper width, in points (Letter's when GTK cannot start).
		do
			Result := default_paper.width
		end

	default_paper_height: REAL_64
			-- GTK's default paper height, in points (Letter's when GTK cannot start).
		do
			Result := default_paper.height
		end

feature -- Printing

	print_file (a_pdf_path, a_title: READABLE_STRING_GENERAL; a_parent: POINTER)
			-- GTK's print dialog over `a_parent' (a GtkWindow), then the pages chosen.
		do
			if not has_printer then
				set_outcome (Outcome_no_printer, "")
			else
				run (a_pdf_path, a_title, a_parent, "")
			end
		end

	print_file_to (a_pdf_path, a_out_path: READABLE_STRING_GENERAL)
			-- The test seam: GtkPrintOperation's export to `a_out_path', no dialog, no printer.
		do
			run (a_pdf_path, "simple_pdf print", default_pointer, a_out_path)
			if last_outcome = Outcome_printed and then not (create {RAW_FILE}.make_with_name (a_out_path)).exists then
				set_outcome (Outcome_failed, {STRING_32} "The export wrote no file at " + a_out_path.to_string_32 + ".")
			elseif last_outcome = Outcome_cancelled then
				set_outcome (Outcome_failed, "The export was cancelled.")
			end
		end

feature -- Pages, for a print preview

	pdf_page_count (a_pdf_path: READABLE_STRING_GENERAL): INTEGER
			-- How many pages (Poppler's pdftotext).
		do
			Result := pages.page_count (a_pdf_path)
		end

	page_size (a_pdf_path: READABLE_STRING_GENERAL; a_page: INTEGER): TUPLE [width, height: REAL_64]
			-- Page `a_page''s size in points (Poppler's pdftocairo).
		do
			Result := pages.page_size (a_pdf_path, a_page)
		end

	page_image (a_pdf_path: READABLE_STRING_GENERAL; a_page: INTEGER; a_scale: REAL_64): detachable CAIRO_SURFACE
			-- Page `a_page' drawn by Poppler's pdftocairo.
		do
			Result := pages.page_image (a_pdf_path, a_page, a_scale)
		end

	pages: PDF_POPPLER_PAGES
			-- The pages drawn by the system's pdftocairo (poppler-utils).
		once ("OBJECT")
			create Result.make ({STRING_32} "/usr/bin/pdftocairo")
		end

feature {NONE} -- Implementation

	run (a_pdf_path, a_title: READABLE_STRING_GENERAL; a_parent: POINTER; a_out: READABLE_STRING_GENERAL)
			-- Print `a_pdf_path' (to `a_out' when it is not empty) and set the outcome.
		local
			l_path, l_title, l_out: C_STRING
			l_message: MANAGED_POINTER
			l_answer: INTEGER
			l_text: STRING_32
		do
			create l_path.make ({UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_pdf_path.to_string_32))
			create l_title.make ({UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_title.to_string_32))
			create l_out.make ({UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_out.to_string_32))
			create l_message.make (Message_capacity)
			l_answer := c_print (l_path.item, l_title.item, a_parent, l_out.item, l_message.item, Message_capacity)
			if l_answer = 1 then
				set_outcome (Outcome_printed, "")
			elseif l_answer = 0 then
				set_outcome (Outcome_cancelled, "")
			else
				l_text := {UTF_CONVERTER}.utf_8_string_8_to_string_32 ((create {C_STRING}.make_by_pointer (l_message.item)).string)
				if l_text.is_empty then
					l_text := "The print operation failed."
				end
				set_outcome (Outcome_failed, l_text)
			end
		end

	default_paper: TUPLE [width, height: REAL_64]
			-- GTK's default paper, in points.
		local
			l_size: MANAGED_POINTER
		do
			create l_size.make (16)
			if c_default_paper (l_size.item, l_size.item + 8) = 1 and then l_size.read_real_64 (0) > 0.0 and then l_size.read_real_64 (8) > 0.0 then
				Result := [l_size.read_real_64 (0), l_size.read_real_64 (8)]
			else
				Result := [612.0, 792.0]
			end
		end

	Message_capacity: INTEGER = 1024
			-- Bytes for a failure's message.

	c_printer_count: INTEGER
		external "C inline use %"simple_pdf_print_gtk.h%""
		alias "return spp_printer_count();"
		end

	c_default_paper (a_width, a_height: POINTER): INTEGER
		external "C inline use %"simple_pdf_print_gtk.h%""
		alias "return spp_default_paper((double *) $a_width, (double *) $a_height);"
		end

	c_print (a_path, a_title, a_parent, a_out, a_message: POINTER; a_capacity: INTEGER): INTEGER
		external "C inline use %"simple_pdf_print_gtk.h%""
		alias "return spp_print((const char *) $a_path, (const char *) $a_title, (void *) $a_parent, (const char *) $a_out, (char *) $a_message, $a_capacity);"
		end

end
