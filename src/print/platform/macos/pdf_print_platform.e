note
	description: "[
		Printing an existing PDF on macOS (1v-c): PDFKit's own print operation and the native
		print panel, as a sheet on the parent NSWindow (app-modal with no parent). The test seam
		is the same operation with no panel, the job saved to a file (the panel's own "Save as
		PDF"), which needs no printer. The Objective-C is Clib/macos/simple_pdf_print_appkit.m,
		built by `make -C Clib/macos'.
		Why PDFKit and not Poppler on the Mac (BUILD_STANDARDS section 10; Larry, 2026-11-11):
		the Mac uses its own system PDF library as Linux uses its own, and Poppler would add about
		twenty libraries to every program that prints, for no visible difference; a test in
		PLATFORM_PRINT_TESTS proves the pages are the same.
	]"

class
	PDF_PRINT_PLATFORM

inherit
	PDF_PRINT_PLATFORM_API

create
	make

feature {NONE} -- Initialization

	make
			-- A printer for this platform; nothing printed yet.
		do
		end

feature -- Status

	has_printer: BOOLEAN
			-- Does the system have a printer the panel can print to? A queue added on this Mac,
			-- or one CUPS has found on the network (the panel offers those): CUPS's destinations.
		do
			Result := c_has_printer /= 0
		end

feature -- Paper

	default_paper_width: REAL_64
			-- The system's default paper width, in points (NSPrintInfo's paper size).
		do
			Result := c_default_paper_width
			if Result <= 0.0 then
				Result := 612.0
			end
		end

	default_paper_height: REAL_64
			-- The system's default paper height, in points.
		do
			Result := c_default_paper_height
			if Result <= 0.0 then
				Result := 792.0
			end
		end

feature -- Printing

	print_file (a_pdf_path, a_title: READABLE_STRING_GENERAL; a_parent: POINTER)
			-- PDFKit's print panel over the PDF, as a sheet on `a_parent' (an NSWindow) or
			-- app-modal; with no printer, no panel.
		local
			l_path, l_title: C_STRING
		do
			create l_path.make (utf_8 (a_pdf_path))
			create l_title.make (utf_8 (a_title))
			take (c_print_file (l_path.item, l_title.item, a_parent))
		end

	print_file_to (a_pdf_path, a_out_path: READABLE_STRING_GENERAL)
			-- The same PDFKit operation with no panel, the job saved to `a_out_path' as a PDF.
		local
			l_path, l_out: C_STRING
		do
			create l_path.make (utf_8 (a_pdf_path))
			create l_out.make (utf_8 (a_out_path))
			take (c_print_file_to (l_path.item, l_out.item))
		end

feature {NONE} -- Implementation

	take (a_result: INTEGER)
			-- Record the outcome the C side answered, with its reason when it failed.
		local
			l_reason: STRING_32
		do
			if is_outcome (a_result) then
				if a_result = Outcome_failed then
					l_reason := {UTF_CONVERTER}.utf_8_string_8_to_string_32 ((create {C_STRING}.make_by_pointer (c_last_error)).string)
					if l_reason.is_empty then
						l_reason := {STRING_32} "printing failed"
					end
					set_outcome (Outcome_failed, l_reason)
				else
					set_outcome (a_result, "")
				end
			else
				set_outcome (Outcome_failed, {STRING_32} "an unknown outcome from the print path: " + a_result.out)
			end
		end

	utf_8 (a_text: READABLE_STRING_GENERAL): STRING_8
			-- `a_text' as UTF-8 bytes.
		do
			Result := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_text)
		end

feature {NONE} -- C (Clib/macos/simple_pdf_print_appkit.m)

	c_has_printer: INTEGER
		external "C inline use %"simple_pdf_print_appkit.h%""
		alias "return spp_has_printer();"
		end

	c_default_paper_width: REAL_64
		external "C inline use %"simple_pdf_print_appkit.h%""
		alias "return spp_default_paper_width();"
		end

	c_default_paper_height: REAL_64
		external "C inline use %"simple_pdf_print_appkit.h%""
		alias "return spp_default_paper_height();"
		end

	c_print_file (a_path, a_title, a_parent: POINTER): INTEGER
		external "C inline use %"simple_pdf_print_appkit.h%""
		alias "return spp_print_file((const char *) $a_path, (const char *) $a_title, (void *) $a_parent);"
		end

	c_print_file_to (a_path, a_out: POINTER): INTEGER
		external "C inline use %"simple_pdf_print_appkit.h%""
		alias "return spp_print_file_to((const char *) $a_path, (const char *) $a_out);"
		end

	c_last_error: POINTER
		external "C inline use %"simple_pdf_print_appkit.h%""
		alias "return (EIF_POINTER) spp_last_error();"
		end

end
