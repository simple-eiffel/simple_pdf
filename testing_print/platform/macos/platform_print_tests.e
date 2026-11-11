note
	description: "[
		macOS tests for printing an existing PDF: PDFKit draws the same pages as Poppler (the
		condition on the Mac's deviation, BUILD_STANDARDS section 10), and the printer check
		agrees with the system's own list. The shared tests are in PRINT_TESTS.
	]"
	testing: "covers"

class
	PLATFORM_PRINT_TESTS

inherit
	PRINT_TESTS

feature -- Running

	run_all (a_run: PROCEDURE [PROCEDURE, STRING])
			-- Run this platform's tests through `a_run'.
		do
			a_run.call (agent test_pdfkit_and_poppler_draw_the_same_pages, "pdfkit_and_poppler_draw_the_same_pages")
			a_run.call (agent test_has_printer_matches_the_system_list, "has_printer_matches_the_system_list")
			a_run.call (agent test_the_text_survives_printing, "the_text_survives_printing")
		end

feature -- Tests

	test_the_text_survives_printing
			-- PDFKit's print path keeps the text layer: the printed job reads back with both
			-- pages' text (the shared check, for the platforms whose path keeps text).
		do
			assert_text_survives_printing
		end

	test_pdfkit_and_poppler_draw_the_same_pages
			-- The two-page test PDF has the same page count in PDFKit as in Poppler, and PDFKit's
			-- page 1 at 72 dpi has fewer than 0.1% of its pixels more than 64 of 255 off Poppler's
			-- page 1 (pdftoppm). Against Poppler's page 2 it has more: a wrong page is caught.
		local
			l_in, l_prefix, l_one, l_two: STRING
			l_reader: SIMPLE_PDF_READER
			l_same, l_wrong: REAL_64
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			l_in := temp_path ("simple_pdf_print_same.pdf")
			l_prefix := temp_path ("simple_pdf_print_same")
			l_one := l_prefix + "-1.png"
			l_two := l_prefix + "-2.png"
			delete_if_there (l_one)
			delete_if_there (l_two)
			write_two_pages (l_in)
			create l_reader.make
			assert ("Poppler's pdftotext is there", l_reader.is_available)
			assert ("the same page count: PDFKit " + c_page_count (l_in).out + ", Poppler " + l_reader.page_count (l_in).out,
				c_page_count (l_in) = 2 and l_reader.page_count (l_in) = 2)
			assert ("Poppler's pdftoppm is there", attached pdftoppm as al_tool)
			if attached pdftoppm as al_tool then
				l_env.system (al_tool + " -r 72 -png '" + l_in + "' '" + l_prefix + "'")
				assert ("pdftoppm drew both pages: " + l_env.return_code.out,
					l_env.return_code = 0 and (create {RAW_FILE}.make_with_name (l_one)).exists and (create {RAW_FILE}.make_with_name (l_two)).exists)
				l_same := pixels_off (l_in, 1, l_one)
				l_wrong := pixels_off (l_in, 1, l_two)
				print ("    PDFKit page 1 against Poppler page 1: " + (l_same * 100.0).out + "%% of pixels off by more than 64; against page 2: "
					+ (l_wrong * 100.0).out + "%%%N")
				assert ("page 1 compared", l_same >= 0.0)
				assert ("the same page: under 0.1%% of pixels off", l_same < 0.001)
				assert ("a wrong page is caught: over 0.1%%", l_wrong > 0.001)
			end
			delete_if_there (l_in)
			delete_if_there (l_one)
			delete_if_there (l_two)
		end

	test_has_printer_matches_the_system_list
			-- `has_printer' agrees with the system's list of destinations (lpstat -e: one line per
			-- printer queue, nothing when there is none).
		local
			l_printer: SIMPLE_PDF_PRINTER
			l_list: STRING
			l_file: PLAIN_TEXT_FILE
			l_has_lines: BOOLEAN
		do
			l_list := temp_path ("simple_pdf_print_lpstat.txt")
			delete_if_there (l_list)
			(create {EXECUTION_ENVIRONMENT}).system ("/usr/bin/lpstat -e > '" + l_list + "' 2>/dev/null")
			create l_file.make_with_name (l_list)
			if l_file.exists then
				l_file.open_read
				l_file.read_line
				l_has_lines := not l_file.end_of_file and then not l_file.last_string.is_empty
				l_file.close
			end
			create l_printer.make
			print ("    lpstat lists a destination: " + l_has_lines.out + "; has_printer: " + l_printer.has_printer.out + "%N")
			assert ("has_printer agrees with lpstat", l_printer.has_printer = l_has_lines)
			delete_if_there (l_list)
		end

feature {NONE} -- Implementation

	pdftoppm: detachable STRING
			-- Poppler's pdftoppm, from Homebrew.
		do
			across <<"/opt/homebrew/bin/pdftoppm", "/usr/local/bin/pdftoppm">> as ic until Result /= Void loop
				if (create {RAW_FILE}.make_with_name (ic)).exists then
					Result := ic
				end
			end
		end

	pixels_off (a_pdf: STRING; a_page: INTEGER; a_png: STRING): REAL_64
			-- The share of PDFKit's page `a_page' pixels more than 64 of 255 off the PNG `a_png'.
		local
			l_pdf, l_png: C_STRING
		do
			create l_pdf.make (a_pdf)
			create l_png.make (a_png)
			Result := c_pixels_off (l_pdf.item, a_page, l_png.item)
		end

	c_page_count (a_pdf: STRING): INTEGER
			-- The pages PDFKit sees in `a_pdf'.
		local
			l_pdf: C_STRING
		do
			create l_pdf.make (a_pdf)
			Result := c_test_page_count (l_pdf.item)
		end

	c_test_page_count (a_path: POINTER): INTEGER
		external "C inline use %"simple_pdf_print_appkit.h%""
		alias "return spp_test_page_count((const char *) $a_path);"
		end

	c_pixels_off (a_path: POINTER; a_page: INTEGER; a_png: POINTER): REAL_64
		external "C inline use %"simple_pdf_print_appkit.h%""
		alias "return spp_test_pixels_off((const char *) $a_path, $a_page, (const char *) $a_png);"
		end

end
