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
			a_run.call (agent test_copies_collated_and_not, "copies_collated_and_not")
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

	test_copies_collated_and_not
			-- Two copies of pages 1 to 3: collated, each copy prints the range (2 runs); not
			-- collated, each page prints its copies before the next (6 runs: 1, 1, 2, 2, 3, 3).
		local
			l_printer: SIMPLE_PDF_PRINTER
			l_runs: ARRAYED_LIST [ARRAYED_LIST [STRING_32]]
			l_pages: STRING_32
		do
			create l_printer.make
			l_runs := l_printer.job_runs ("Printer", 1, 3, 2, True, 0, 0, "doc.pdf", True)
			assert ("collated: two runs", l_runs.count = 2)
			assert ("each the whole range", across l_runs as ic all position_of (ic, "-f") > 0 and position_of (ic, "1") > 0 and position_of (ic, "3") > 0 end)
			l_runs := l_printer.job_runs ("Printer", 1, 3, 2, False, 0, 0, "doc.pdf", True)
			assert ("not collated: six runs", l_runs.count = 6)
			create l_pages.make_empty
			across l_runs as ic loop
				l_pages.append (ic [position_of (ic, "-f") + 1])
			end
			assert ("page by page: " + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_pages), l_pages.same_string ({STRING_32} "112233"))
			l_runs := l_printer.job_runs ("Printer", 1, 0, 3, False, 2, 0, "doc.pdf", False)
			assert ("page count unknown: whole copies", l_runs.count = 3 and position_of (l_runs.first, "-f") = 0)
			assert ("duplex long passed on", position_of (l_runs.first, "duplex=long") > 0)
			assert ("the file last", l_runs.first.last.same_string ({STRING_32} "doc.pdf"))
		end

	position_of (a_list: LIST [STRING_32]; a_text: STRING_32): INTEGER
			-- Where `a_text' first is in `a_list', by content (a list's `has' compares identity); 0 when absent.
		do
			across a_list as ic until Result > 0 loop
				if ic.same_string (a_text) then
					Result := @ic.cursor_index
				end
			end
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
