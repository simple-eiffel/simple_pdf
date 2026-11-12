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

feature -- Pages, for a preview

	pdf_page_count (a_pdf_path: READABLE_STRING_GENERAL): INTEGER
			-- How many pages PDFKit reads in the PDF; 0 when it cannot be read.
		local
			l_path: C_STRING
		do
			create l_path.make (utf_8 (a_pdf_path))
			Result := c_page_count (l_path.item).max (0)
		end

	page_size (a_pdf_path: READABLE_STRING_GENERAL; a_page: INTEGER): TUPLE [width, height: REAL_64]
			-- Page `a_page''s media box in points (PDFKit); [0, 0] when it cannot be read.
		local
			l_path: C_STRING
			l_size: MANAGED_POINTER
		do
			create l_path.make (utf_8 (a_pdf_path))
			create l_size.make (16)
			c_page_size (l_path.item, a_page, l_size.item, l_size.item + 8)
			Result := [l_size.read_real_64 (0).max (0.0), l_size.read_real_64 (8).max (0.0)]
		end

	page_image (a_pdf_path: READABLE_STRING_GENERAL; a_page: INTEGER; a_scale: REAL_64): detachable CAIRO_SURFACE
			-- Page `a_page' drawn by PDFKit on white, `a_scale' pixels to the point; Void when it
			-- cannot be drawn. Handed to cairo as a PNG, as the other platforms do.
		local
			l_path, l_png: C_STRING
			l_file: STRING_32
			l_image: CAIRO_SURFACE
		do
			l_file := temporary_png
			create l_path.make (utf_8 (a_pdf_path))
			create l_png.make (utf_8 (l_file))
			if c_page_png (l_path.item, a_page, a_scale, l_png.item) /= 0 then
				create l_image.make_from_png (l_file)
				if l_image.is_valid then
					Result := l_image
				else
					l_image.destroy
				end
			end
			if (create {RAW_FILE}.make_with_name (l_file)).exists then
				(create {RAW_FILE}.make_with_name (l_file)).delete
			end
		end

feature {NONE} -- Implementation

	temporary_png: STRING_32
			-- A new PNG file name in the temporary files folder.
		local
			l_env: EXECUTION_ENVIRONMENT
			l_folder: STRING_32
		do
			create l_env
			if attached l_env.item ("TMPDIR") as al_t then
				l_folder := al_t
			else
				l_folder := {STRING_32} "/tmp"
			end
			if not l_folder.is_empty and then l_folder [l_folder.count] /= '/' then
				l_folder.append_character ('/')
			end
			png_counter.put (png_counter.item + 1)
			Result := l_folder + {STRING_32} "simple_pdf_page_" + c_process_id.out + "_" + png_counter.item.out + {STRING_32} ".png"
		end

	png_counter: CELL [INTEGER]
			-- Numbers the temporary pictures.
		once
			create Result.put (0)
		end

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

	c_page_count (a_path: POINTER): INTEGER
		external "C inline use %"simple_pdf_print_appkit.h%""
		alias "return spp_pdf_page_count((const char *) $a_path);"
		end

	c_page_size (a_path: POINTER; a_page: INTEGER; a_width, a_height: POINTER)
		external "C inline use %"simple_pdf_print_appkit.h%""
		alias "spp_page_size((const char *) $a_path, $a_page, (double *) $a_width, (double *) $a_height);"
		end

	c_page_png (a_path: POINTER; a_page: INTEGER; a_scale: REAL_64; a_png: POINTER): INTEGER
		external "C inline use %"simple_pdf_print_appkit.h%""
		alias "return spp_page_png((const char *) $a_path, $a_page, $a_scale, (const char *) $a_png);"
		end

	c_process_id: INTEGER
		external "C inline use <unistd.h>"
		alias "return (EIF_INTEGER) getpid();"
		end

	c_last_error: POINTER
		external "C inline use %"simple_pdf_print_appkit.h%""
		alias "return (EIF_POINTER) spp_last_error();"
		end

end
