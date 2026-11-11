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

	test_print_file_to_keeps_the_pages_and_text
			-- A two-page PDF printed to a file through the platform's print path keeps its two pages
			-- and its text.
		local
			l_printer: SIMPLE_PDF_PRINTER
			l_reader: SIMPLE_PDF_READER
			l_in, l_out: STRING
			l_text: STRING
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
			assert ("printed: " + l_printer.last_outcome.out + " " + l_printer.last_error.to_string_8,
				l_printer.last_outcome = l_printer.Outcome_printed)
			assert ("the job has two pages: " + l_reader.page_count (l_out).out, l_reader.page_count (l_out) = 2)
			l_text := l_reader.extract_text (l_out)
			assert ("page one's text survives: [" + l_text + "]", l_text.has_substring ("First page of the print test"))
			assert ("page two's text survives", l_text.has_substring ("Second page of the print test"))
			delete_if_there (l_in)
			delete_if_there (l_out)
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
