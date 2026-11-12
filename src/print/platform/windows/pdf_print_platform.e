note
	description: "[
		Printing an existing PDF on Windows (1v-c): simple_shell's print dialog, owned by the
		parent window, then Poppler's own pdftocairo.exe -print, from simple_pdf's bin/ (the same
		Poppler 24.08.0 build as pdftotext.exe), once per copy.

		pdftocairo renders with Poppler onto cairo's Win32 printing surface. Passed on from the
		dialog: the printer, the page range, copies (repeated, collated jobs), duplex, and the
		paper source. Not passed on (named in the spec, said in the guide): the printer's own
		Preferences (color mode, quality and other driver-private choices) and the dialog's paper
		and orientation, because pdftocairo sizes each sheet from the PDF's own page.

		The helper's arguments are encoded by the Windows rules, never through a shell; its run
		has a timeout; its messages (Poppler's tools write UTF-8 on Windows) become `last_error'.

		Poppler's Windows tools turn their command line into UTF-8 and pass the printer name to
		the ANSI printer functions, so a printer named with characters outside ASCII cannot be
		reached through pdftocairo: the run fails with pdftocairo's "not found" (named in the spec).
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
			-- Does Windows list a printer? (Microsoft Print to PDF is a queue and counts.)
		do
			Result := not (create {SHELL_PRINTER}.make).printer_names.is_empty
		end

feature -- Paper

	default_paper_width: REAL_64
			-- The user's locale paper width, in points.
		do
			inspect locale_paper
			when Locale_legal then
				Result := 612.0
			when Locale_a3 then
				Result := 842.0
			when Locale_a4 then
				Result := 595.0
			else
				Result := 612.0
			end
		end

	default_paper_height: REAL_64
			-- The user's locale paper height, in points.
		do
			inspect locale_paper
			when Locale_legal then
				Result := 1008.0
			when Locale_a3 then
				Result := 1191.0
			when Locale_a4 then
				Result := 842.0
			else
				Result := 792.0
			end
		end

feature -- Printing

	print_file (a_pdf_path, a_title: READABLE_STRING_GENERAL; a_parent: POINTER)
			-- simple_shell's print dialog over `a_parent', then pdftocairo once per copy.
		local
			l_dialog: SHELL_PRINT_DIALOG
			l_reader: SIMPLE_PDF_READER
			l_pages, i: INTEGER
			l_first, l_last: INTEGER
			l_folder, l_copy: STRING_32
		do
			if not has_printer then
				set_outcome (Outcome_no_printer, "")
			elseif helper_path = Void then
				fail ("Printing is not set up on this computer.", Missing_helper)
			else
				create l_reader.make
				if l_reader.is_available then
					l_pages := l_reader.page_count (utf_8 (a_pdf_path))
				end
				create l_dialog.make
				l_dialog.show (a_parent, l_pages)
				if l_dialog.last_answer = l_dialog.Answer_cancel then
					set_outcome (Outcome_cancelled, "")
				elseif l_dialog.last_answer = l_dialog.Answer_failed then
					set_outcome (Outcome_failed, "The print dialog could not open (error " + l_dialog.last_error_code.out + ").")
				else
					print_chosen (a_pdf_path, a_title, a_parent, l_dialog.printer_name, l_dialog.is_all_pages, l_dialog.first_page,
						l_dialog.last_page, l_pages, l_dialog.copies, l_dialog.is_collated, l_dialog.duplex, l_dialog.paper_source)
				end
			end
		end

	print_chosen (a_pdf_path, a_title: READABLE_STRING_GENERAL; a_parent: POINTER; a_printer: READABLE_STRING_GENERAL;
			a_all_pages: BOOLEAN; a_first, a_last, a_page_count, a_copies: INTEGER; a_collated: BOOLEAN; a_duplex, a_source: INTEGER)
			-- Print what the dialog chose. A printer that writes a file (Microsoft Print to PDF, the
			-- XPS writer) is asked where by us, with the system's Save dialog owned by `a_parent', and
			-- prints one copy there: the printer's own prompt, from the helper, could stand unseen
			-- behind our windows (Larry's copy hung on it, 2026-11-11).
		require
			printer_named: not a_printer.is_empty
			copies_positive: a_copies >= 1
		local
			l_first, l_last: INTEGER
			l_folder, l_copy: STRING_32
			l_out: detachable STRING_32
			l_dialog: SHELL_FILE_DIALOG
			l_ok: BOOLEAN
			i: INTEGER
		do
			l_ok := True
			if printer_writes_files (a_printer) then
				if attached test_file_answer as al_answer then
					l_out := al_answer
				else
					create l_dialog.make
					l_dialog.choose_save_file (a_parent, a_title, file_printer_filter (a_printer), "", file_name_for (a_title))
					if l_dialog.has_choice then
						l_out := l_dialog.chosen_path
					end
				end
				if l_out = Void then
					set_outcome (Outcome_cancelled, "")
					l_ok := False
				end
			end
			if l_ok then
				if a_all_pages then
					l_first := 1
					l_last := a_page_count
				else
					l_first := a_first
					l_last := a_last
				end
					-- pdftocairo names the job after its input file: print a copy named after the title
				l_folder := new_temp_folder
				l_copy := file_name_for (a_title)
				if not copy_file (a_pdf_path, l_folder + "\" + l_copy) then
					set_outcome (Outcome_failed, {STRING_32} "Could not prepare the job in " + l_folder + ".")
				else
					across
						job_runs (a_printer, l_first, l_last, if l_out /= Void then 1 else a_copies end, a_collated,
							a_duplex, a_source, l_copy, not a_all_pages) as ic
					until
						i > 0 and last_outcome /= Outcome_printed
					loop
						i := i + 1
						if attached l_out as al_out then
							ic.extend (al_out)
						end
						run_helper (ic, l_folder)
					end
				end
				delete_file (l_folder + "\" + l_copy)
				delete_folder (l_folder)
			end
		end

	printer_writes_files (a_printer: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_printer' write a file and ask where (its port PORTPROMPT: or FILE:)?
		local
			l_name: NATIVE_STRING
			l_port: MANAGED_POINTER
			l_text: STRING_32
			i: INTEGER
		do
			create l_name.make (a_printer)
			create l_port.make (512)
			if c_printer_port (l_name.item, l_port.item, 256) = 1 then
				create l_text.make (16)
				from i := 0 until i >= 256 or else l_port.read_natural_16 (i * 2) = 0 loop
					l_text.append_code (l_port.read_natural_16 (i * 2).to_natural_32)
					i := i + 1
				end
				l_text.to_upper
				Result := l_text.same_string ({STRING_32} "PORTPROMPT:") or l_text.same_string ({STRING_32} "FILE:")
			end
		end

	modal_wait (a_process: SIMPLE_PIPED_PROCESS; a_limit_ms: INTEGER)
			-- Wait up to `a_limit_ms' for `a_process' to end, as a modal dialog waits: this
			-- thread's windows disabled, so nothing re-enters (no second Print, no close);
			-- painting and timers kept up, so no window shows "Not responding"; keyboard and
			-- mouse dropped; a close request held and handed back after (2026-11-11, EIF-GROUP).
		require
			started: a_process.is_started
			limit_positive: a_limit_ms > 0
		local
			l_disabled, l_held: MANAGED_POINTER
			l_disabled_count, l_held_count, l_waited: INTEGER
		do
			create l_disabled.make (Window_capacity * Pointer_bytes)
			create l_held.make (Held_capacity * c_held_size)
			l_disabled_count := c_disable_windows (l_disabled.item, Window_capacity)
			from
				l_held_count := c_pump_messages (l_held.item, Held_capacity, 0)
			until
				a_process.has_exited or l_waited >= a_limit_ms
			loop
				a_process.wait_for_exit (Pump_interval_ms)
				l_held_count := c_pump_messages (l_held.item, Held_capacity, l_held_count)
				l_waited := l_waited + Pump_interval_ms
			end
			c_enable_windows (l_disabled.item, l_disabled_count)
			c_repost (l_held.item, l_held_count)
		end

	new_helper_process: SIMPLE_PIPED_PROCESS
			-- A process to run the print helper in: started the ordinary way, so a driver's own
			-- prompt (a PIN, paper out) is not started hidden; no console window; and ended with
			-- this program, however it ends (Larry's force-closed copy left pdftocairo behind).
		do
			create Result.make
			Result.set_show_window (True)
			Result.set_suppresses_console (True)
			Result.set_ends_with_owner (True)
		ensure
			shown: Result.show_window
			no_console: Result.suppresses_console
			ends_with_us: Result.ends_with_owner
			not_started: not Result.is_started
		end

	is_in_job (a_pid: NATURAL_32): BOOLEAN
			-- Is process `a_pid' in a job object?
		do
			Result := c_in_job (a_pid) = 1
		end

	set_test_file_answer (a_path: detachable READABLE_STRING_GENERAL)
			-- Tests: answer the file printer's "save the printout where?" with `a_path' (Void: ask).
		do
			if attached a_path as al_path then
				create test_file_answer.make_from_string_general (al_path)
			else
				test_file_answer := Void
			end
		end

	test_file_answer: detachable STRING_32
			-- The tests' answer to the file printer's question, if set.

	print_file_to (a_pdf_path, a_out_path: READABLE_STRING_GENERAL)
			-- The test seam: pdftocairo to the Microsoft Print to PDF printer, which writes the job
			-- to `a_out_path' (StartDoc's output file) with no dialog.
		do
			print_file_to_printer (a_pdf_path, File_printer, a_out_path)
		end

	print_file_to_printer (a_pdf_path, a_printer, a_out_path: READABLE_STRING_GENERAL)
			-- Windows: pdftocairo to printer `a_printer', the job written to `a_out_path'.
		require
			path_not_empty: not a_pdf_path.is_empty
			pdf_exists: (create {RAW_FILE}.make_with_name (a_pdf_path)).exists
			printer_not_empty: not a_printer.is_empty
			out_not_empty: not a_out_path.is_empty
			distinct: not a_out_path.same_string (a_pdf_path)
		local
			l_args: ARRAYED_LIST [STRING_32]
		do
			delete_file (a_out_path)
			create l_args.make (6)
			l_args.extend ({STRING_32} "-print")
			l_args.extend ({STRING_32} "-printer")
			l_args.extend (a_printer.to_string_32)
			l_args.extend ({STRING_32} "-origpagesizes")
			l_args.extend (a_pdf_path.to_string_32)
			l_args.extend (a_out_path.to_string_32)
			run_helper (l_args, Void)
			if last_outcome = Outcome_printed and then not (create {RAW_FILE}.make_with_name (a_out_path)).exists then
				set_outcome (Outcome_failed, {STRING_32} "The printer " + a_printer.to_string_32 + " wrote no file at " + a_out_path.to_string_32 + ".")
			end
		ensure
			printed_or_failed: last_outcome = Outcome_printed or last_outcome = Outcome_failed
			written_when_printed: last_outcome = Outcome_printed implies (create {RAW_FILE}.make_with_name (a_out_path)).exists
		end

feature -- The helper

	helper_path: detachable STRING_32
			-- pdftocairo.exe: bin\ under the working folder or the working folder (as SIMPLE_PDF_READER
			-- finds pdftotext.exe), then the program's own folder and its bin\ (how a program ships it),
			-- then simple_pdf's bin\ under SIMPLE_EIFFEL (development), then Poppler's install folders;
			-- Void when absent.
		local
			l_env: EXECUTION_ENVIRONMENT
			l_cwd, l_exe_dir: STRING_32
			l_candidates: ARRAYED_LIST [STRING_32]
		once ("OBJECT")
			create l_env
			l_cwd := l_env.current_working_path.name.to_string_32
			create l_candidates.make (8)
			l_candidates.extend (l_cwd + {STRING_32} "\bin\pdftocairo.exe")
			l_candidates.extend (l_cwd + {STRING_32} "\pdftocairo.exe")
			if attached (create {PATH}.make_from_string ((create {ARGUMENTS_32}).command_name)).parent as al_dir then
				l_exe_dir := al_dir.name.to_string_32
				l_candidates.extend (l_exe_dir + {STRING_32} "\pdftocairo.exe")
				l_candidates.extend (l_exe_dir + {STRING_32} "\bin\pdftocairo.exe")
			end
			if attached l_env.item ("SIMPLE_EIFFEL") as al_root then
				l_candidates.extend (al_root + {STRING_32} "\simple_pdf\bin\pdftocairo.exe")
			end
			l_candidates.extend ({STRING_32} "C:\Program Files\poppler\bin\pdftocairo.exe")
			l_candidates.extend ({STRING_32} "C:\Program Files (x86)\poppler\bin\pdftocairo.exe")
			across l_candidates as ic until Result /= Void loop
				if (create {RAW_FILE}.make_with_name (ic)).exists then
					Result := ic
				end
			end
		end

	quoted (a_argument: READABLE_STRING_GENERAL): STRING_32
			-- `a_argument' as one argument by the Windows rules (CommandLineToArgvW and the C
			-- runtime, which SIMPLE_PROCESS's POSIX side follows too): in double quotes; a double
			-- quote escaped with a backslash; backslashes doubled where a double quote follows.
		local
			l_text: STRING_32
			i, k, l_slashes: INTEGER
		do
			l_text := a_argument.to_string_32
			create Result.make (l_text.count + 2)
			Result.append_character ('"')
			from i := 1 until i > l_text.count loop
				if l_text [i] = '\' then
					l_slashes := l_slashes + 1
					Result.append_character ('\')
				elseif l_text [i] = '"' then
					from k := 1 until k > l_slashes loop
						Result.append_character ('\')
						k := k + 1
					end
					Result.append_character ('\')
					Result.append_character ('"')
					l_slashes := 0
				else
					l_slashes := 0
					Result.append_character (l_text [i])
				end
				i := i + 1
			end
			from k := 1 until k > l_slashes loop
				Result.append_character ('\')
				k := k + 1
			end
			Result.append_character ('"')
		ensure
			quoted_both_ends: Result.count >= 2 and Result [1] = '"' and Result [Result.count] = '"'
		end

	Helper_timeout_ms: INTEGER = 3_600_000
			-- How long one print run may take before it is stopped: an hour. pdftocairo reports no
			-- progress to watch, so this bounds only a run that never ends (a printer waiting on an
			-- answer no one can give); a long job on a slow printer stays well inside it.

	Window_capacity: INTEGER = 64
			-- Windows of ours a print run disables at most.

	Held_capacity: INTEGER = 16
			-- Close requests a print run holds at most.

	Pump_interval_ms: INTEGER = 50
			-- How often the wait services the windows.

	Pointer_bytes: INTEGER = 8
			-- Room for one window handle.

	File_printer: STRING_32 = "Microsoft Print to PDF"
			-- The printer the test seam prints to.

	Missing_helper: STRING_32 = "pdftocairo.exe was not found (simple_pdf's bin\ beside the program, or Poppler's install folder)."

feature -- The runs a choice makes

	job_runs (a_printer: READABLE_STRING_GENERAL; a_first, a_last, a_copies: INTEGER; a_collated: BOOLEAN;
			a_duplex, a_source: INTEGER; a_file: READABLE_STRING_GENERAL; a_ranged: BOOLEAN): ARRAYED_LIST [ARRAYED_LIST [STRING_32]]
			-- pdftocairo's argument lists for one print choice, one list per run: pages `a_first' to
			-- `a_last' (`a_ranged': the user chose them; else every page, and `a_last' is the page
			-- count or 0 when it is unknown), `a_copies' copies, collated or not, the dialog's
			-- duplex (SHELL_PRINT_DIALOG's Duplex_*) and paper source (a DMBIN_ value), printing
			-- `a_file'. Collated (or one copy, or an unknown page count): each copy prints the whole
			-- range. Not collated: each page prints all its copies before the next page.
		require
			printer_named: not a_printer.is_empty
			copies_positive: a_copies >= 1
			range_valid: a_ranged implies (1 <= a_first and a_first <= a_last)
			count_known_or_zero: not a_ranged implies (a_first = 1 and a_last >= 0)
			file_named: not a_file.is_empty
		local
			l_page, k: INTEGER
		do
			create Result.make (a_copies)
			if a_collated or a_copies = 1 or else (not a_ranged and a_last = 0) then
				from k := 1 until k > a_copies loop
					Result.extend (run_arguments (a_printer, a_duplex, a_source, a_ranged, a_first, a_last, a_file))
					k := k + 1
				end
			else
				from l_page := a_first until l_page > a_last loop
					from k := 1 until k > a_copies loop
						Result.extend (run_arguments (a_printer, a_duplex, a_source, True, l_page, l_page, a_file))
						k := k + 1
					end
					l_page := l_page + 1
				end
			end
		ensure
			collated_count: (a_collated or a_copies = 1 or (not a_ranged and a_last = 0)) implies Result.count = a_copies
			uncollated_count: not (a_collated or a_copies = 1 or (not a_ranged and a_last = 0)) implies Result.count = a_copies * (a_last - a_first + 1)
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
			-- The pages drawn by the pdftocairo.exe beside the program (`helper_path').
		once ("OBJECT")
			create Result.make (if attached helper_path as al_path then al_path else {STRING_32} "pdftocairo.exe" end)
		end

feature {NONE} -- Running the helper

	run_arguments (a_printer: READABLE_STRING_GENERAL; a_duplex, a_source: INTEGER; a_ranged: BOOLEAN;
			a_first, a_last: INTEGER; a_file: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- One pdftocairo run's arguments.
		local
			l_options: STRING_32
		do
			create Result.make (12)
			Result.extend ({STRING_32} "-print")
			Result.extend ({STRING_32} "-printer")
			Result.extend (a_printer.to_string_32)
			Result.extend ({STRING_32} "-origpagesizes")
			if a_ranged then
				Result.extend ({STRING_32} "-f")
				Result.extend (a_first.out)
				Result.extend ({STRING_32} "-l")
				Result.extend (a_last.out)
			end
			create l_options.make_empty
			inspect a_duplex
			when {SHELL_PRINT_DIALOG}.Duplex_off then
				l_options.append ({STRING_32} "duplex=off")
			when {SHELL_PRINT_DIALOG}.Duplex_long_edge then
				l_options.append ({STRING_32} "duplex=long")
			when {SHELL_PRINT_DIALOG}.Duplex_short_edge then
				l_options.append ({STRING_32} "duplex=short")
			else
			end
			if attached source_name (a_source) as al_source then
				if not l_options.is_empty then
					l_options.append_character (',')
				end
				l_options.append ({STRING_32} "source=" + al_source)
			end
			if not l_options.is_empty then
				Result.extend ({STRING_32} "-printopt")
				Result.extend (l_options)
			end
			Result.extend (a_file.to_string_32)
		end


	run_helper (a_args: LIST [STRING_32]; a_folder: detachable STRING_32)
			-- Run pdftocairo with `a_args' in `a_folder' (Void: the current one); its exit code
			-- sets the outcome: 0 printed, 99 failed, anything else or a timeout failed.
		local
			l_process: SIMPLE_PIPED_PROCESS
			l_command, l_text: STRING_32
		do
			if attached helper_path as al_exe then
				l_command := quoted (al_exe)
				across a_args as ic loop
					l_command.append_character (' ')
					l_command.append (quoted (ic))
				end
				l_process := new_helper_process
				l_process.start_in_directory (l_command, a_folder)
				if not l_process.is_started then
					if attached l_process.last_error as al_why then
						fail ("Printing could not start.", {STRING_32} "pdftocairo did not start: " + al_why)
					else
						fail ("Printing could not start.", "pdftocairo did not start.")
					end
				else
					if l_process.is_input_open then
						l_process.close_input
					end
					modal_wait (l_process, Helper_timeout_ms)
					if l_process.has_exited then
						l_process.await_output_end (2000)
					end
					if not l_process.has_exited then
						l_process.kill
						fail ("The printer did not answer within an hour, so the job was stopped.",
							{STRING_32} "pdftocairo timed out after " + (Helper_timeout_ms // 1000).out + " seconds.")
					else
						l_text := {UTF_CONVERTER}.utf_8_string_8_to_string_32 (l_process.pending_output)
						l_text.adjust
						if l_process.exit_code = 0 then
							set_outcome (Outcome_printed, "")
						else
								-- pdftocairo's exit codes: 1 the PDF could not be opened, 2 the output
								-- file could not be written, 3 printing is not permitted, 99 other
							inspect l_process.exit_code
							when 1 then
								fail ("The document could not be read for printing.", helper_detail (l_process.exit_code, l_text))
							when 2 then
								fail ("The printout could not be written.", helper_detail (l_process.exit_code, l_text))
							when 3 then
								fail ("The document does not allow printing.", helper_detail (l_process.exit_code, l_text))
							else
								fail ("The printer did not finish the job.", helper_detail (l_process.exit_code, l_text))
							end
						end
					end
					l_process.close
				end
			else
				fail ("Printing is not set up on this computer.", Missing_helper)
			end
		end

	fail (a_message, a_detail: READABLE_STRING_GENERAL)
			-- Failed: `a_message' for the person (`last_error'), `a_detail' for us (`last_error_detail').
		require
			message_present: not a_message.is_empty
		do
			set_outcome (Outcome_failed, a_message)
			set_detail (a_detail)
		ensure
			failed: last_outcome = Outcome_failed
		end

	helper_detail (a_code: INTEGER; a_text: READABLE_STRING_32): STRING_32
			-- pdftocairo's exit code and what it wrote.
		do
			Result := {STRING_32} "pdftocairo exit " + a_code.out
			if not a_text.is_empty then
				Result.append ({STRING_32} ": " + a_text)
			end
		end

	source_name (a_bin: INTEGER): detachable STRING_32
			-- pdftocairo's name for paper source `a_bin' (a DMBIN_ value); Void for a driver's own.
		do
			inspect a_bin
			when 1 then Result := "upper"
			when 2 then Result := "lower"
			when 3 then Result := "middle"
			when 4 then Result := "manual"
			when 5 then Result := "envelope"
			when 6 then Result := "envmanual"
			when 7 then Result := "auto"
			when 8 then Result := "tractor"
			when 9 then Result := "smallfmt"
			when 10 then Result := "largefmt"
			when 11 then Result := "largecapacity"
			when 15 then Result := "formsource"
			else
			end
		end

feature {NONE} -- Files

	file_printer_filter (a_printer: READABLE_STRING_GENERAL): STRING_32
			-- What a file printer writes: XPS for an XPS writer, else PDF.
		do
			if a_printer.as_string_32.as_upper.has_substring ({STRING_32} "XPS") then
				Result := {STRING_32} "XPS documents|*.oxps;*.xps"
			else
				Result := {STRING_32} "PDF files|*.pdf"
			end
		end

	new_temp_folder: STRING_32
			-- A new, empty folder under the temporary files folder.
		local
			l_base: STRING_32
			l_dir: DIRECTORY
			n: INTEGER
		do
			if attached (create {EXECUTION_ENVIRONMENT}).item ("TEMP") as al_t then
				l_base := al_t
			else
				l_base := "."
			end
			from
				n := 1
				Result := l_base + {STRING_32} "\simple_pdf_print_" + n.out
			until
				not (create {DIRECTORY}.make (Result)).exists
			loop
				n := n + 1
				Result := l_base + {STRING_32} "\simple_pdf_print_" + n.out
			end
			create l_dir.make (Result)
			l_dir.create_dir
		end

	file_name_for (a_title: READABLE_STRING_GENERAL): STRING_32
			-- `a_title' as a file name ending in .pdf: characters a file name cannot hold become
			-- "_", and at most 100 characters are kept.
		local
			c: CHARACTER_32
			i: INTEGER
			l_title: STRING_32
		do
			l_title := a_title.to_string_32
			create Result.make (l_title.count.min (100) + 4)
			from i := 1 until i > l_title.count or Result.count >= 100 loop
				c := l_title [i]
				if c.code < 32 or else (c.is_character_8 and then ("<>:%"/\|?*").has (c.to_character_8)) then
					Result.append_character ('_')
				else
					Result.append_character (c)
				end
				i := i + 1
			end
			Result.adjust
			if Result.is_empty then
				Result := "Document"
			end
			Result.append ({STRING_32} ".pdf")
		ensure
			a_pdf: Result.ends_with ({STRING_32} ".pdf")
		end

	copy_file (a_from, a_to: READABLE_STRING_GENERAL): BOOLEAN
			-- Copy the file at `a_from' to `a_to'; did it work?
		local
			l_in, l_out: RAW_FILE
			l_retried: BOOLEAN
		do
			if not l_retried then
				create l_in.make_open_read (a_from)
				create l_out.make_open_write (a_to)
				if l_in.count > 0 then
					l_in.read_stream (l_in.count)
					l_out.put_string (l_in.last_string)
				end
				l_in.close
				l_out.close
				Result := True
			end
		rescue
			l_retried := True
			retry
		end

	delete_file (a_path: READABLE_STRING_GENERAL)
			-- Remove the file at `a_path' if there is one.
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_path)
			if l_file.exists then
				l_file.delete
			end
		end

	delete_folder (a_path: READABLE_STRING_GENERAL)
			-- Remove the folder at `a_path' if it is there and empty.
		local
			l_dir: DIRECTORY
		do
			create l_dir.make (a_path)
			if l_dir.exists and then l_dir.is_empty then
				l_dir.delete
			end
		end

	utf_8 (a_text: READABLE_STRING_GENERAL): STRING_8
			-- `a_text' in UTF-8.
		do
			Result := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_text.to_string_32)
		end

feature {NONE} -- Windows

	c_printer_port (a_name, a_out: POINTER; a_cap: INTEGER): INTEGER
		external "C inline use %"simple_pdf_print_win.h%""
		alias "return spp_printer_port ((const wchar_t *) $a_name, (wchar_t *) $a_out, $a_cap);"
		end

	c_in_job (a_pid: NATURAL_32): INTEGER
		external "C inline use %"simple_pdf_print_win.h%""
		alias "return spp_in_job ((DWORD) $a_pid);"
		end

	c_pump_messages (a_held: POINTER; a_cap, a_count: INTEGER): INTEGER
		external "C inline use %"simple_pdf_print_win.h%""
		alias "return spp_pump_messages ((SPP_HELD *) $a_held, $a_cap, $a_count);"
		end

	c_repost (a_held: POINTER; a_count: INTEGER)
		external "C inline use %"simple_pdf_print_win.h%""
		alias "spp_repost ((SPP_HELD *) $a_held, $a_count);"
		end

	c_held_size: INTEGER
		external "C inline use %"simple_pdf_print_win.h%""
		alias "return (EIF_INTEGER) sizeof (SPP_HELD);"
		end

	c_disable_windows (a_out: POINTER; a_cap: INTEGER): INTEGER
		external "C inline use %"simple_pdf_print_win.h%""
		alias "return spp_disable_windows ((HWND *) $a_out, $a_cap);"
		end

	c_enable_windows (a_list: POINTER; a_count: INTEGER)
		external "C inline use %"simple_pdf_print_win.h%""
		alias "spp_enable_windows ((HWND *) $a_list, $a_count);"
		end

	locale_paper: INTEGER
			-- The user's locale paper size (LOCALE_IPAPERSIZE): 1 Letter, 5 Legal, 8 A3, 9 A4.
		external "C inline use <windows.h>"
		alias "[
			DWORD l_value = 0;
			if (GetLocaleInfoW (LOCALE_USER_DEFAULT, LOCALE_IPAPERSIZE | LOCALE_RETURN_NUMBER, (LPWSTR) &l_value, sizeof (l_value) / sizeof (WCHAR)) == 0) return 0;
			return (EIF_INTEGER) l_value;
		]"
		end

	Locale_legal: INTEGER = 5
	Locale_a3: INTEGER = 8
	Locale_a4: INTEGER = 9

end
