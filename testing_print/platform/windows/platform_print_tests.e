note
	description: "[
		Windows tests for printing an existing PDF: the helper program's arguments, and the
		printer list. The shared tests are in PRINT_TESTS.
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
			a_run.call (agent test_a_hostile_printer_name_reaches_the_helper_intact, "a_hostile_printer_name_reaches_the_helper_intact")
			a_run.call (agent test_has_printer_matches_the_system_list, "has_printer_matches_the_system_list")
		end

feature -- Tests

	test_a_hostile_printer_name_reaches_the_helper_intact
			-- pdftocairo gets its arguments as a list encoded by the Windows rules, never a shell
			-- string. A printer that does not exist, named with spaces, double quotes, a backslash
			-- before a quote, a comma and an accented letter, fails, and pdftocairo's own message
			-- quotes the name back exactly.
		local
			l_printer: SIMPLE_PDF_PRINTER
			l_in: STRING
			l_name: STRING_32
		do
			l_in := temp_path ("simple_pdf_print_name.pdf")
			write_two_pages (l_in)
			l_name := {STRING_32} "Simple %"PDF%" t%/233/st, printer \%" end"
			create l_printer.make
			l_printer.print_file_to_printer (l_in, l_name, temp_path ("simple_pdf_print_name_out.pdf"))
			assert ("failed", l_printer.last_outcome = l_printer.Outcome_failed)
			assert ("the name came through intact: " + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_printer.last_error),
				l_printer.last_error.has_substring (l_name))
			delete_if_there (l_in)
		end

	test_has_printer_matches_the_system_list
			-- `has_printer' says whether SHELL_PRINTER lists any printer. On Windows a printer that
			-- writes files (Microsoft Print to PDF) is a real, removable print queue the user can
			-- print through, so it counts; GTK's always-present "Print to File" is not a queue.
		local
			l_printer: SIMPLE_PDF_PRINTER
			l_list: SHELL_PRINTER
		do
			create l_printer.make
			create l_list.make
			assert ("has_printer agrees with the system's list", l_printer.has_printer = not l_list.printer_names.is_empty)
		end

end
