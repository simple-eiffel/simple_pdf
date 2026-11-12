note
	description: "[
		Tests for printing an existing PDF (1v-c), the same on every platform: no printer, no
		person, no dialog. `print_file_to' runs each platform's real print path to a file
		(Windows: pdftocairo to the Microsoft Print to PDF printer; Linux: GtkPrintOperation's
		export; macOS: PDFKit's save job), and the result is read back with pdftotext.
	]"
	testing: "covers"

class
	PRINT_TESTS

inherit
	TEST_SET_BASE

feature -- Outcomes

	test_outcomes_are_four_and_distinct
			-- The four outcomes, the same values on every platform.
		local
			l_printer: SIMPLE_PDF_PRINTER
		do
			create l_printer.make
			assert ("printed is 1", l_printer.Outcome_printed = 1)
			assert ("cancelled is 0", l_printer.Outcome_cancelled = 0)
			assert ("failed is -1", l_printer.Outcome_failed = -1)
			assert ("no printer is -2", l_printer.Outcome_no_printer = -2)
			assert ("nothing else is an outcome", not l_printer.is_outcome (2) and not l_printer.is_outcome (-3))
		end

	test_default_paper_is_a_real_size
			-- The system's default paper, in points (Letter is 612 x 792, A4 595 x 842).
		local
			l_printer: SIMPLE_PDF_PRINTER
		do
			create l_printer.make
			print ("    default paper: " + l_printer.default_paper_width.out + " x " + l_printer.default_paper_height.out
				+ " points; has a printer: " + l_printer.has_printer.out + "%N")
			assert ("at least 3 inches wide", l_printer.default_paper_width >= 216.0)
			assert ("at least 3 inches tall", l_printer.default_paper_height >= 216.0)
		end

feature -- Printing to a file

	test_print_file_to_keeps_the_pages_and_their_ink
			-- A two-page PDF printed to a file through the platform's print path keeps its two pages,
			-- and each printed page carries about the ink of the original page, rendered the same way.
			-- (Ink, not text: Windows' print path draws text as shapes, so the job has no text layer;
			-- the text check is a platform test where text survives.)
		local
			l_printer: SIMPLE_PDF_PRINTER
			l_reader: SIMPLE_PDF_READER
			l_in, l_out: STRING
			l_page, l_before, l_after: INTEGER
		do
			l_in := temp_path ("simple_pdf_print_in.pdf")
			l_out := temp_path ("simple_pdf_print_out.pdf")
			delete_if_there (l_out)
			write_two_pages (l_in)
			create l_reader.make
			assert ("pdftotext is there to read the result", l_reader.is_available)
			assert ("the input has two pages", l_reader.page_count (l_in) = 2)
			create l_printer.make
			l_printer.print_file_to (l_in, l_out)
			assert ("printed: " + l_printer.last_outcome.out + " " + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_printer.last_error),
				l_printer.last_outcome = l_printer.Outcome_printed)
			assert ("the job has two pages: " + l_reader.page_count (l_out).out, l_reader.page_count (l_out) = 2)
			from l_page := 1 until l_page > 2 loop
				l_before := page_ink (l_in, l_page)
				l_after := page_ink (l_out, l_page)
				assert ("page " + l_page.out + " of the original has ink: " + l_before.out, l_before > 50)
				assert ("page " + l_page.out + " printed with about its ink: " + l_after.out + " against " + l_before.out,
					l_after * 2 >= l_before and l_after <= l_before * 2)
				l_page := l_page + 1
			end
			delete_if_there (l_in)
			delete_if_there (l_out)
		end

	test_pages_for_a_preview
			-- A print preview's parts: the page count, a page's size in points, and a page drawn
			-- as an image at the scale asked (1.0: one pixel to the point), with ink on it.
		local
			l_printer: SIMPLE_PDF_PRINTER
			l_in: STRING
			l_size: TUPLE [width, height: REAL_64]
		do
			l_in := temp_path ("simple_pdf_preview_in.pdf")
			write_two_pages (l_in)
			create l_printer.make
			assert ("two pages: " + l_printer.pdf_page_count (l_in).out, l_printer.pdf_page_count (l_in) = 2)
			l_size := l_printer.page_size (l_in, 1)
			assert ("Letter in points: " + l_size.width.out + " x " + l_size.height.out,
				(l_size.width - 612.0).abs <= 1.0 and (l_size.height - 792.0).abs <= 1.0)
			if attached l_printer.page_image (l_in, 1, 1.0) as al_image then
				assert ("the image is the page: " + al_image.width.out + " x " + al_image.height.out,
					(al_image.width - 612).abs <= 1 and (al_image.height - 792).abs <= 1)
				al_image.destroy
			else
				assert ("page 1 drawn", False)
			end
			assert ("page 2 has ink: " + page_ink (l_in, 2).out, page_ink (l_in, 2) > 50)
			assert ("no page 3", l_printer.page_image (l_in, 3, 1.0) = Void)
			delete_if_there (l_in)
		end

	test_a_broken_pdf_fails_with_a_reason
			-- A file that is not a PDF fails, with a reason, and never raises.
		local
			l_printer: SIMPLE_PDF_PRINTER
			l_in, l_out: STRING
			l_file: PLAIN_TEXT_FILE
		do
			l_in := temp_path ("simple_pdf_print_broken.pdf")
			l_out := temp_path ("simple_pdf_print_broken_out.pdf")
			create l_file.make_create_read_write (l_in)
			l_file.put_string ("This is not a PDF.%N")
			l_file.close
			create l_printer.make
			l_printer.print_file_to (l_in, l_out)
			assert ("failed", l_printer.last_outcome = l_printer.Outcome_failed)
			assert ("with a reason", not l_printer.last_error.is_empty)
			print ("    reason: " + l_printer.last_error.to_string_8 + "%N")
			delete_if_there (l_in)
			delete_if_there (l_out)
		end

feature -- Helpers, shared with each platform's tests

	assert_text_survives_printing
			-- Where the print path keeps a text layer (Linux, macOS), a two-page PDF printed to a file
			-- reads back with both pages' text.
		local
			l_printer: SIMPLE_PDF_PRINTER
			l_reader: SIMPLE_PDF_READER
			l_in, l_out, l_text: STRING
		do
			l_in := temp_path ("simple_pdf_print_text_in.pdf")
			l_out := temp_path ("simple_pdf_print_text_out.pdf")
			delete_if_there (l_out)
			write_two_pages (l_in)
			create l_printer.make
			l_printer.print_file_to (l_in, l_out)
			assert ("printed", l_printer.last_outcome = l_printer.Outcome_printed)
			create l_reader.make
			l_text := l_reader.extract_text (l_out)
			assert ("page one's text survives: [" + l_text + "]", l_text.has_substring ("First page of the print test"))
			assert ("page two's text survives", l_text.has_substring ("Second page of the print test"))
			delete_if_there (l_in)
			delete_if_there (l_out)
		end

	page_ink (a_pdf: STRING; a_page: INTEGER): INTEGER
			-- Dark pixels on page `a_page' of `a_pdf', rendered at 40 dots per inch by Poppler's
			-- pdftocairo (the same renderer for the original and the printed job).
		local
			l_process: SIMPLE_PROCESS
			l_base: STRING
			l_image: CAIRO_SURFACE
			l_pixels: MANAGED_POINTER
			x, y: INTEGER
			l_pixel: NATURAL_32
		do
			l_base := temp_path ("simple_pdf_print_ink")
			delete_if_there (l_base + ".png")
			create l_process.make
			l_process.run ("%"" + pdftocairo_path + "%" -png -r 40 -f " + a_page.out + " -l " + a_page.out + " -singlefile %"" + a_pdf + "%" %"" + l_base + "%"")
			assert ("pdftocairo rendered page " + a_page.out + " of " + a_pdf, (create {RAW_FILE}.make_with_name (l_base + ".png")).exists)
			create l_image.make_from_png (l_base + ".png")
			l_image.flush.do_nothing
			create l_pixels.share_from_pointer (l_image.data, l_image.stride * l_image.height)
			from y := 0 until y >= l_image.height loop
				from x := 0 until x >= l_image.width loop
					l_pixel := l_pixels.read_natural_32 (y * l_image.stride + x * 4)
					if ((l_pixel |>> 16) & 0xFF) + ((l_pixel |>> 8) & 0xFF) + (l_pixel & 0xFF) < 384 then
						Result := Result + 1
					end
					x := x + 1
				end
				y := y + 1
			end
			l_image.destroy
			delete_if_there (l_base + ".png")
		end

	pdftocairo_path: STRING
			-- Poppler's pdftocairo: simple_pdf's bin/ on Windows, the system's elsewhere.
		do
			if {PLATFORM}.is_windows then
				Result := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 ((create {EXECUTION_ENVIRONMENT}).current_working_path.name.to_string_32) + "/bin/pdftocairo.exe"
			elseif (create {RAW_FILE}.make_with_name ("/opt/homebrew/bin/pdftocairo")).exists then
				Result := "/opt/homebrew/bin/pdftocairo"
			elseif (create {RAW_FILE}.make_with_name ("/usr/local/bin/pdftocairo")).exists then
				Result := "/usr/local/bin/pdftocairo"
			else
				Result := "/usr/bin/pdftocairo"
			end
		end

	write_two_pages (a_path: STRING)
			-- A two-page Letter PDF at `a_path', drawn with cairo, one line of text on each page.
		local
			l_surface: CAIRO_PDF_SURFACE
			l_context: CAIRO_CONTEXT
		do
			create l_surface.make (a_path, 612.0, 792.0)
			assert ("a PDF surface", l_surface.is_valid)
			create l_context.make (l_surface.as_surface)
			l_context.select_font ("sans-serif", l_context.Slant_normal, l_context.Weight_normal).set_font_size (20.0).do_nothing
			l_context.move_to (72.0, 144.0).show_text ("First page of the print test").do_nothing
			l_context.show_page
			l_context.move_to (72.0, 144.0).show_text ("Second page of the print test").do_nothing
			l_context.show_page
			assert ("cairo kept both pages: " + l_context.status.out, l_context.status = 0)
			l_context.destroy
			l_surface.destroy
		end

	temp_path (a_name: STRING): STRING
			-- `a_name' in the temporary files folder.
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			if attached l_env.item ("TEMP") as al_t then
				Result := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (al_t)
			elseif attached l_env.item ("TMPDIR") as al_t then
				Result := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (al_t)
			else
				Result := "/tmp"
			end
			Result := Result + "/" + a_name
		end

	delete_if_there (a_path: STRING)
			-- Remove the file at `a_path' if there is one.
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_path)
			if l_file.exists then
				l_file.delete
			end
		end

end
