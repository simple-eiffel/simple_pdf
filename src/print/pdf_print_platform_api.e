note
	description: "[
		Printing an existing PDF (1v-c, port-coordination docs/SIMPLE_GUI_SPEC.md): through each
		platform's own printing and its system dialog, or through the same path to a file with no
		dialog (the test seam). Larry, 2026-11-11: "Anything that reads, draws or prints an
		existing PDF lives in simple_pdf", and "no need to re-invent the wheel".

		One effective class per platform, PDF_PRINT_PLATFORM, in src/print/platform/<name>/:
		  windows - simple_shell's print dialog (owned by the parent window), then Poppler's own
		            pdftocairo.exe -print, from simple_pdf's bin/;
		  linux   - GtkPrintOperation with the system dialog, drawing poppler-glib's pages;
		  macos   - PDFKit's printOperationForPrintInfo: with the native panel, as a sheet.

		The four outcomes are the same on every platform. "Printed" means the job was handed to
		the system's print queue. "No printer" is decided before any dialog: with no printer,
		`print_file' shows nothing. Every call returns with `last_outcome' set, and is made on
		the GUI thread.
	]"

deferred class
	PDF_PRINT_PLATFORM_API

feature -- Outcomes

	Outcome_printed: INTEGER = 1
			-- The job was handed to the system's print queue.

	Outcome_cancelled: INTEGER = 0
			-- The user cancelled the dialog.

	Outcome_failed: INTEGER = -1
			-- Printing failed; `last_error' says why.

	Outcome_no_printer: INTEGER = -2
			-- The system has no printer; no dialog was shown.

	is_outcome (a_value: INTEGER): BOOLEAN
			-- Is `a_value' one of the four outcomes?
		do
			Result := a_value >= Outcome_no_printer and a_value <= Outcome_printed
		ensure
			definition: Result = (a_value >= Outcome_no_printer and a_value <= Outcome_printed)
		end

feature -- Access

	last_outcome: INTEGER
			-- The outcome of the last `print_file' or `print_file_to'.

	last_error: STRING_32
			-- Why the last call failed; empty unless it failed.
		attribute
			create Result.make_empty
		end

	last_error_detail: STRING_32
			-- For the program's log, not the person: the helper's own words (exit code, messages)
			-- behind `last_error'; may be empty.
		attribute
			create Result.make_empty
		end

feature -- Status

	has_printer: BOOLEAN
			-- Does the system have a printer queue? (GTK's "Print to File", which is always there
			-- and is not a queue, does not count; Windows' Microsoft Print to PDF is a queue and does.)
		deferred
		end

feature -- Paper

	default_paper_width: REAL_64
			-- The system's default paper width, in points (Letter's 612 when the system says none).
		deferred
		ensure
			positive: Result > 0.0
		end

	default_paper_height: REAL_64
			-- The system's default paper height, in points (Letter's 792 when the system says none).
		deferred
		ensure
			positive: Result > 0.0
		end

feature -- Printing

	print_file (a_pdf_path, a_title: READABLE_STRING_GENERAL; a_parent: POINTER)
			-- The system's print dialog over the PDF at `a_pdf_path', owned by `a_parent' (an HWND,
			-- a GtkWindow or an NSWindow; default_pointer for none); then the pages the user chose
			-- are printed. `a_title' names the job. With no printer, no dialog shows.
		require
			path_not_empty: not a_pdf_path.is_empty
			pdf_exists: (create {RAW_FILE}.make_with_name (a_pdf_path)).exists
			title_not_empty: not a_title.is_empty
		deferred
		ensure
			known_outcome: is_outcome (last_outcome)
			failure_explained: last_outcome = Outcome_failed implies not last_error.is_empty
			error_only_on_failure: last_outcome /= Outcome_failed implies last_error.is_empty
		end

	print_file_to (a_pdf_path, a_out_path: READABLE_STRING_GENERAL)
			-- The test seam: the same platform print path with no dialog, no printer and no person,
			-- the job written to `a_out_path' as a PDF.
		require
			path_not_empty: not a_pdf_path.is_empty
			pdf_exists: (create {RAW_FILE}.make_with_name (a_pdf_path)).exists
			out_not_empty: not a_out_path.is_empty
			distinct: not a_out_path.same_string (a_pdf_path)
		deferred
		ensure
			printed_or_failed: last_outcome = Outcome_printed or last_outcome = Outcome_failed
			written_when_printed: last_outcome = Outcome_printed implies (create {RAW_FILE}.make_with_name (a_out_path)).exists
			failure_explained: last_outcome = Outcome_failed implies not last_error.is_empty
			error_only_on_failure: last_outcome = Outcome_printed implies last_error.is_empty
		end

feature -- Pages, for a print preview

	pdf_page_count (a_pdf_path: READABLE_STRING_GENERAL): INTEGER
			-- How many pages the PDF at `a_pdf_path' has; 0 when it cannot be read.
		require
			path_not_empty: not a_pdf_path.is_empty
		deferred
		ensure
			not_negative: Result >= 0
		end

	page_size (a_pdf_path: READABLE_STRING_GENERAL; a_page: INTEGER): TUPLE [width, height: REAL_64]
			-- Page `a_page''s size in points; [0, 0] when it cannot be read.
		require
			path_not_empty: not a_pdf_path.is_empty
			page_from_one: a_page >= 1
		deferred
		ensure
			not_negative: Result.width >= 0.0 and Result.height >= 0.0
		end

	page_image (a_pdf_path: READABLE_STRING_GENERAL; a_page: INTEGER; a_scale: REAL_64): detachable CAIRO_SURFACE
			-- Page `a_page' drawn as an image, `a_scale' pixels to the point (1.0: 72 dots per inch),
			-- on white; Void when it cannot be drawn. The caller owns the surface (`destroy' it).
			-- Windows and Linux: Poppler (pdftocairo); macOS: PDFKit, the library that prints there.
		require
			path_not_empty: not a_pdf_path.is_empty
			page_from_one: a_page >= 1
			scale_positive: a_scale > 0.0
		deferred
		end

feature {NONE} -- Outcome

	set_outcome (a_outcome: INTEGER; a_error: READABLE_STRING_GENERAL)
			-- Record `a_outcome', with `a_error' when it is a failure.
		require
			known_outcome: is_outcome (a_outcome)
			failure_explained: a_outcome = Outcome_failed implies not a_error.is_empty
			error_only_on_failure: a_outcome /= Outcome_failed implies a_error.is_empty
		do
			last_outcome := a_outcome
			create last_error.make_from_string_general (a_error)
			create last_error_detail.make_empty
		ensure
			outcome_set: last_outcome = a_outcome
			error_set: last_error.same_string_general (a_error)
		end

	set_detail (a_detail: READABLE_STRING_GENERAL)
			-- Record `a_detail' behind the last failure.
		do
			create last_error_detail.make_from_string_general (a_detail)
		ensure
			set: last_error_detail.same_string_general (a_detail)
		end

invariant
	known_outcome: is_outcome (last_outcome)

end
