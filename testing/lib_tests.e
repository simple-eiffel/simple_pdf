note
	description: "Unit tests for simple_pdf library"
	author: "Your Organization"
	date: "$Date$"
	revision: "$Revision$"
	testing: "covers"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Tests

	test_engine_detection
			-- Test that engine detection works
		local
			l_engines: SIMPLE_PDF_ENGINES
		do
			create l_engines
			-- Should not crash
			assert ("report_not_empty", not l_engines.report.is_empty)
		end

	test_wkhtmltopdf_engine_creation
			-- Test wkhtmltopdf engine creation
		local
			l_engine: SIMPLE_PDF_WKHTMLTOPDF
		do
			create l_engine.make
			assert ("name_is_wkhtmltopdf", l_engine.name.same_string ("wkhtmltopdf"))
		end

	test_chrome_engine_creation
			-- Test Chrome engine creation
		local
			l_engine: SIMPLE_PDF_CHROME
		do
			create l_engine.make
			assert ("name_is_chrome", l_engine.name.same_string ("Chrome"))
		end

	test_simple_pdf_creation
			-- Test main API class creation
		local
			l_pdf: SIMPLE_PDF
		do
			create l_pdf.make
			assert ("engine_attached", l_pdf.engine /= Void)
			assert ("default_page_size_a4", l_pdf.page_size.same_string ("A4"))
		end

	test_document_failed_creation
			-- Test failed document creation
		local
			l_doc: SIMPLE_PDF_DOCUMENT
		do
			create l_doc.make_failed ("Test error")
			assert ("is_not_valid", not l_doc.is_valid)
			assert ("has_error", attached l_doc.error_message)
		end

	test_reader_creation
			-- Test PDF reader creation
		local
			l_reader: SIMPLE_PDF_READER
		do
			create l_reader.make
			-- Should not crash - reader may or may not find pdftotext
		end

feature -- Shared DLL set (BUILD_STANDARDS section 9)

	test_bin_mirrors_the_owners_cairo_set
			-- bin/ carries copies of DLLs simple_cairo owns (cairo 1.18.0 and the six it loads)
			-- because the helper programs here (pdftotext.exe, poppler) load DLLs from their own
			-- folder. One version per DLL name across simple_* (Larry, 2026-11-11: "the SAME
			-- version"): every DLL in bin/ that the owner's runtime/windows/ also holds must be
			-- byte-identical to the owner's. The mirror goes when staging lands (simple_pdf#1).
		note
			testing: "covers/bin"
		local
			l_root, l_owner, l_bin, l_name: STRING
			l_dir: DIRECTORY
			l_hash: SIMPLE_HASH
			l_mine, l_theirs: detachable STRING
			l_checked: INTEGER
		do
			if {PLATFORM}.is_windows then
				l_root := simple_eiffel_root
				l_owner := l_root + "/simple_cairo/runtime/windows"
				l_bin := l_root + "/simple_pdf/bin"
				create l_dir.make (l_owner)
				assert ("the owner's set is there: " + l_owner, l_dir.exists)
				create l_hash.make
				across l_dir.entries as ic loop
					l_name := ic.utf_8_name
					if l_name.as_lower.ends_with (".dll") and then (create {RAW_FILE}.make_with_name (l_bin + "/" + l_name)).exists then
						l_checked := l_checked + 1
						l_mine := l_hash.sha256_file (l_bin + "/" + l_name)
						l_theirs := l_hash.sha256_file (l_owner + "/" + l_name)
						assert ("bin/" + l_name + " differs from its owner's copy, simple_cairo/runtime/windows/" + l_name
							+ " (owner: simple_cairo): bin " + hash_text (l_mine) + ", owner " + hash_text (l_theirs),
							attached l_mine as al_m and then attached l_theirs as al_t and then al_m.same_string (al_t))
					end
				end
				assert ("bin/ mirrors some of the owner's set: " + l_checked.out + " checked", l_checked > 0)
			end
		end

	test_cairo_text_reads_back_through_the_helper
			-- Text drawn into a PDF by this process's cairo (1.18.0 on Windows) reads back through
			-- pdftotext: the helper starts with the DLLs it finds and parses cairo 1.18's PDF 1.7
			-- object streams.
		note
			testing: "covers/{SIMPLE_PDF_READER}.extract_text"
		local
			l_surface: CAIRO_PDF_SURFACE
			l_context: CAIRO_CONTEXT
			l_reader: SIMPLE_PDF_READER
			l_path, l_text: STRING
			l_file: RAW_FILE
		do
			create l_reader.make
			if l_reader.is_available then
				l_path := temp_folder + "/simple_pdf_cairo_round_trip.pdf"
				create l_surface.make (l_path, 612.0, 792.0)
				assert ("a PDF surface", l_surface.is_valid)
				create l_context.make (l_surface.as_surface)
				l_context.select_font ("sans-serif", l_context.Slant_normal, l_context.Weight_normal).set_font_size (24.0).do_nothing
				l_context.move_to (72.0, 144.0).show_text ("Mirror round trip").do_nothing
				l_context.show_page
				assert ("cairo kept the page: " + l_context.status.out, l_context.status = 0)
				l_context.destroy
				l_surface.destroy
				l_text := l_reader.extract_text (l_path)
				assert ("the text reads back through " + hash_text (l_reader.executable_path) + ": [" + l_text + "] " + hash_text (l_reader.last_error),
					l_text.has_substring ("Mirror round trip"))
				create l_file.make_with_name (l_path)
				if l_file.exists then
					l_file.delete
				end
			else
				assert ("pdftotext ships in bin/ on Windows", not {PLATFORM}.is_windows)
				print ("    (no pdftotext on this machine: round trip not run)%N")
			end
		end

feature {NONE} -- Shared DLL set helpers

	simple_eiffel_root: STRING
			-- $SIMPLE_EIFFEL, which every simple_* build sets.
		do
			if attached (create {EXECUTION_ENVIRONMENT}).item ("SIMPLE_EIFFEL") as al_root then
				Result := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (al_root)
			else
				Result := ""
			end
			assert ("SIMPLE_EIFFEL is set", not Result.is_empty)
		end

	temp_folder: STRING
			-- The temporary files folder.
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
		end

	hash_text (a_text: detachable STRING): STRING
			-- `a_text', or "(none)".
		do
			if attached a_text as al_t then
				Result := al_t
			else
				Result := "(none)"
			end
		end

end
