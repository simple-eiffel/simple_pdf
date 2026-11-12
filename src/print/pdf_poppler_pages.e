note
	description: "[
		A PDF's pages as images, for a print preview, through Poppler's own pdftocairo (the
		Poppler that prints on Windows and Linux): one page rendered to a PNG in the temporary
		files folder, loaded as an image surface the caller owns, the file removed. Sizes come
		from a rendering at 72 dots per inch (one pixel to the point); the page count from
		SIMPLE_PDF_READER (pdftotext). Used by the Windows and Linux PDF_PRINT_PLATFORM; macOS
		draws its pages with PDFKit.
	]"

class
	PDF_POPPLER_PAGES

create
	make

feature {NONE} -- Initialization

	make (a_helper: READABLE_STRING_GENERAL)
			-- Pages drawn by the pdftocairo at `a_helper'.
		require
			helper_named: not a_helper.is_empty
		do
			create helper.make_from_string_general (a_helper)
		ensure
			helper_set: helper.same_string_general (a_helper)
		end

feature -- Access

	helper: STRING_32
			-- The pdftocairo used.

	page_count (a_pdf_path: READABLE_STRING_GENERAL): INTEGER
			-- How many pages; 0 when the PDF cannot be read.
		local
			l_reader: SIMPLE_PDF_READER
			l_path: STRING_8
		do
			l_path := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_pdf_path.to_string_32)
			create l_reader.make
			if l_reader.is_available and then (create {RAW_FILE}.make_with_name (l_path)).exists then
				Result := l_reader.page_count (l_path)
			end
		ensure
			not_negative: Result >= 0
		end

	page_size (a_pdf_path: READABLE_STRING_GENERAL; a_page: INTEGER): TUPLE [width, height: REAL_64]
			-- Page `a_page''s size in points; [0, 0] when it cannot be drawn.
		require
			page_from_one: a_page >= 1
		do
			if attached page_image (a_pdf_path, a_page, 1.0) as al_image then
				Result := [al_image.width.to_double, al_image.height.to_double]
				al_image.destroy
			else
				Result := [0.0, 0.0]
			end
		ensure
			not_negative: Result.width >= 0.0 and Result.height >= 0.0
		end

	page_image (a_pdf_path: READABLE_STRING_GENERAL; a_page: INTEGER; a_scale: REAL_64): detachable CAIRO_SURFACE
			-- Page `a_page' at `a_scale' pixels to the point, on white; Void when it cannot be drawn.
		require
			page_from_one: a_page >= 1
			scale_positive: a_scale > 0.0
		local
			l_process: SIMPLE_PROCESS
			l_base, l_png: STRING_32
			l_image: CAIRO_SURFACE
		do
			l_base := new_base
			l_png := l_base + {STRING_32} ".png"
			create l_process.make
			l_process.run (quoted (helper) + {STRING_32} " -png -r " + (72.0 * a_scale).rounded.max (1).out + " -f " + a_page.out
				+ " -l " + a_page.out + " -singlefile " + quoted (a_pdf_path) + " " + quoted (l_base))
			if (create {RAW_FILE}.make_with_name (l_png)).exists then
				create l_image.make_from_png (l_png)
				if l_image.is_valid then
					Result := l_image
				else
					l_image.destroy
				end
				(create {RAW_FILE}.make_with_name (l_png)).delete
			end
		end

feature {NONE} -- Implementation

	new_base: STRING_32
			-- A new file name, without extension, in the temporary files folder.
		local
			l_env: EXECUTION_ENVIRONMENT
			l_folder: STRING_32
		do
			create l_env
			if attached l_env.item ("TEMP") as al_t then
				l_folder := al_t
			elseif attached l_env.item ("TMPDIR") as al_t then
				l_folder := al_t
			else
				l_folder := {STRING_32} "/tmp"
			end
			counter.put (counter.item + 1)
			Result := l_folder + {STRING_32} "/simple_pdf_page_" + l_env.current_working_path.name.hash_code.out
				+ "_" + counter.item.out
		end

	counter: CELL [INTEGER]
			-- Numbers the temporary files.
		once
			create Result.put (0)
		end

	quoted (a_argument: READABLE_STRING_GENERAL): STRING_32
			-- `a_argument' as one argument by the Windows rules, which SIMPLE_PROCESS splits by on
			-- every platform: in double quotes; a double quote escaped; backslashes doubled where a
			-- double quote follows.
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
		end

end
