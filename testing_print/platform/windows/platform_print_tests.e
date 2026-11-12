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
			a_run.call (agent test_a_file_printer_asks_us_and_never_hangs, "a_file_printer_asks_us_and_never_hangs")
			a_run.call (agent test_a_helper_dies_with_the_program, "a_helper_dies_with_the_program")
			a_run.call (agent test_the_print_wait_is_modal, "the_print_wait_is_modal")
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
			assert ("the name came through intact: " + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_printer.last_error_detail),
				l_printer.last_error_detail.has_substring (l_name))
			assert ("the person reads a sentence, not the helper", not l_printer.last_error.has_substring ("pdftocairo"))
			delete_if_there (l_in)
		end

	test_a_file_printer_asks_us_and_never_hangs
			-- 2026-11-11 (Larry's copy hung): a printer that writes a file (Microsoft Print to PDF)
			-- is asked where by us, not by its own prompt, which stood unseen while the program
			-- waited. The tests answer the question; the job finishes in seconds and writes there.
		local
			l_printer: SIMPLE_PDF_PRINTER
			l_in, l_out: STRING
			l_started: DATE_TIME
		do
			create l_printer.make
			assert ("Microsoft Print to PDF writes files", l_printer.printer_writes_files ("Microsoft Print to PDF"))
			l_in := temp_path ("simple_pdf_file_printer_in.pdf")
			l_out := temp_path ("simple_pdf_file_printer_out.pdf")
			delete_if_there (l_out)
			write_two_pages (l_in)
			l_printer.set_test_file_answer (l_out)
			create l_started.make_now
			l_printer.print_chosen (l_in, "File printer test", default_pointer, "Microsoft Print to PDF", True, 1, 2, 2, 1, True, 0, 0)
			l_printer.set_test_file_answer (Void)
			assert ("printed: " + l_printer.last_outcome.out + " " + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_printer.last_error_detail),
				l_printer.last_outcome = l_printer.Outcome_printed)
			assert ("in seconds, not after a timeout", (create {DATE_TIME}.make_now).relative_duration (l_started).seconds_count < 120)
			assert ("written where we said", (create {RAW_FILE}.make_with_name (l_out)).exists)
			delete_if_there (l_in)
			delete_if_there (l_out)
		end

	test_a_helper_dies_with_the_program
			-- A print helper is started the way `run_helper' starts it and joins this program's
			-- kill-on-close job (simple_process's `ends_with_owner'), so a killed program never
			-- leaves one waiting on a prompt (Larry's force-close left pdftocairo behind).
		local
			l_printer: SIMPLE_PDF_PRINTER
			l_child: SIMPLE_PIPED_PROCESS
		do
			create l_printer.make
			l_child := l_printer.new_helper_process
			l_child.start_in_directory ("ping -n 3 127.0.0.1", Void)
			assert ("a child started", l_child.is_started)
			assert ("in a kill-on-close job", l_printer.is_in_job (l_child.process_id))
			l_child.wait_for_exit (10000)
			l_child.close
		end

	test_the_print_wait_is_modal
			-- While the print helper runs, our windows are disabled: a click posted to one is
			-- dropped, a close request is held and handed back once the helper ends, and the
			-- window is enabled again (EIF-GROUP, 2026-11-11). The window is off every screen.
		local
			l_printer: SIMPLE_PDF_PRINTER
			l_child: SIMPLE_PIPED_PROCESS
			l_window: POINTER
		do
			create l_printer.make
			l_window := c_test_window
			assert ("a test window", l_window /= default_pointer)
			c_test_post_click_and_close (l_window)
			l_child := l_printer.new_helper_process
			l_child.start_in_directory ("ping -n 2 127.0.0.1", Void)
			assert ("a child started", l_child.is_started)
			l_printer.modal_wait (l_child, 20_000)
			assert ("the child ended", l_child.has_exited)
			l_child.close
			assert ("enabled again", c_test_enabled (l_window) = 1)
			assert ("the click was dropped", c_test_clicks (l_window) = 0)
			assert ("the close was held, not handled during the wait", c_test_closes (l_window) = 0)
			c_test_drain
			assert ("the close was handed back after", c_test_closes (l_window) = 1)
			assert ("still no click", c_test_clicks (l_window) = 0)
			c_test_destroy (l_window)
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


feature {NONE} -- Test windows

	c_test_window: POINTER
		external "C inline use %"simple_pdf_print_win.h%""
		alias "return (EIF_POINTER) spp_test_window ();"
		end

	c_test_post_click_and_close (a_window: POINTER)
		external "C inline use %"simple_pdf_print_win.h%""
		alias "spp_test_post_click_and_close ((HWND) $a_window);"
		end

	c_test_clicks (a_window: POINTER): INTEGER
		external "C inline use %"simple_pdf_print_win.h%""
		alias "return spp_test_clicks ((HWND) $a_window);"
		end

	c_test_closes (a_window: POINTER): INTEGER
		external "C inline use %"simple_pdf_print_win.h%""
		alias "return spp_test_closes ((HWND) $a_window);"
		end

	c_test_enabled (a_window: POINTER): INTEGER
		external "C inline use %"simple_pdf_print_win.h%""
		alias "return spp_test_enabled ((HWND) $a_window);"
		end

	c_test_drain
		external "C inline use %"simple_pdf_print_win.h%""
		alias "spp_test_drain ();"
		end

	c_test_destroy (a_window: POINTER)
		external "C inline use %"simple_pdf_print_win.h%""
		alias "DestroyWindow ((HWND) $a_window);"
		end

end
