note
	description: "[
		PDF text extraction using pdftotext (Poppler).

		Extracts plain text content from PDF files for:
		- Full-text search indexing
		- Content analysis
		- Text mining

		Example usage:
			create reader.make
			if reader.is_available then
				text := reader.extract_text ("document.pdf")
				-- text now contains the PDF's text content
			end
	]"
	author: "Your Organization"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_PDF_READER

create
	make,
	make_with_path

feature {NONE} -- Initialization

	make
			-- Create reader using pdftotext from bin folder or PATH
		do
			detect_executable
		end

	make_with_path (a_path: STRING)
			-- Create reader with explicit path to pdftotext.exe
		require
			path_not_empty: not a_path.is_empty
		do
			executable_path := a_path
		ensure
			path_set: executable_path = a_path
		end

feature -- Access

	executable_path: detachable STRING
			-- Path to pdftotext.exe

	last_error: detachable STRING
			-- Last error message, if any

feature -- Status

	is_available: BOOLEAN
			-- Is pdftotext available?
		local
			l_file: RAW_FILE
		do
			if attached executable_path as l_path then
				create l_file.make_with_name (l_path)
				Result := l_file.exists
			end
		end

feature -- Extraction

	extract_text (a_pdf_path: STRING): STRING
			-- Extract text from PDF file
		require
			path_not_empty: not a_pdf_path.is_empty
			file_exists: (create {RAW_FILE}.make_with_name (a_pdf_path)).exists
			is_available: is_available
		local
			l_temp_txt: STRING
			l_uuid: UUID_GENERATOR
			l_args: ARRAYED_LIST [STRING]
			l_output: STRING
			l_file: PLAIN_TEXT_FILE
			l_raw: RAW_FILE
		do
			create l_uuid
			l_temp_txt := get_temp_directory + "/simple_pdf_" + l_uuid.generate_uuid.out + ".txt"

			create l_args.make (10)
			l_args.extend ("-layout")
			l_args.extend (a_pdf_path)
			l_args.extend (l_temp_txt)

			l_output := execute_pdftotext (l_args)

			create l_raw.make_with_name (l_temp_txt)
			if l_raw.exists then
				create l_file.make_open_read (l_temp_txt)
				l_file.read_stream (l_file.count.max (1))
				Result := l_file.last_string
				l_file.close
				l_raw.delete
				last_error := Void
			else
				Result := ""
				last_error := "pdftotext failed: " + l_output
			end
		end

	extract_text_raw (a_pdf_path: STRING): STRING
			-- Extract text without layout preservation (compact)
		require
			path_not_empty: not a_pdf_path.is_empty
			file_exists: (create {RAW_FILE}.make_with_name (a_pdf_path)).exists
			is_available: is_available
		local
			l_temp_txt: STRING
			l_uuid: UUID_GENERATOR
			l_args: ARRAYED_LIST [STRING]
			l_output: STRING
			l_file: PLAIN_TEXT_FILE
			l_raw: RAW_FILE
		do
			create l_uuid
			l_temp_txt := get_temp_directory + "/simple_pdf_" + l_uuid.generate_uuid.out + ".txt"

			create l_args.make (10)
			l_args.extend ("-raw")
			l_args.extend (a_pdf_path)
			l_args.extend (l_temp_txt)

			l_output := execute_pdftotext (l_args)

			create l_raw.make_with_name (l_temp_txt)
			if l_raw.exists then
				create l_file.make_open_read (l_temp_txt)
				l_file.read_stream (l_file.count.max (1))
				Result := l_file.last_string
				l_file.close
				l_raw.delete
				last_error := Void
			else
				Result := ""
				last_error := "pdftotext failed: " + l_output
			end
		end

	extract_page (a_pdf_path: STRING; a_page: INTEGER): STRING
			-- Extract text from specific page
		require
			path_not_empty: not a_pdf_path.is_empty
			file_exists: (create {RAW_FILE}.make_with_name (a_pdf_path)).exists
			page_positive: a_page > 0
			is_available: is_available
		local
			l_temp_txt: STRING
			l_uuid: UUID_GENERATOR
			l_args: ARRAYED_LIST [STRING]
			l_output: STRING
			l_file: PLAIN_TEXT_FILE
			l_raw: RAW_FILE
		do
			create l_uuid
			l_temp_txt := get_temp_directory + "/simple_pdf_" + l_uuid.generate_uuid.out + ".txt"

			create l_args.make (10)
			l_args.extend ("-f")
			l_args.extend (a_page.out)
			l_args.extend ("-l")
			l_args.extend (a_page.out)
			l_args.extend ("-layout")
			l_args.extend (a_pdf_path)
			l_args.extend (l_temp_txt)

			l_output := execute_pdftotext (l_args)

			create l_raw.make_with_name (l_temp_txt)
			if l_raw.exists then
				create l_file.make_open_read (l_temp_txt)
				l_file.read_stream (l_file.count.max (1))
				Result := l_file.last_string
				l_file.close
				l_raw.delete
				last_error := Void
			else
				Result := ""
				last_error := "pdftotext failed: " + l_output
			end
		end

	extract_pages (a_pdf_path: STRING; a_first, a_last: INTEGER): STRING
			-- Extract text from page range
		require
			path_not_empty: not a_pdf_path.is_empty
			file_exists: (create {RAW_FILE}.make_with_name (a_pdf_path)).exists
			valid_range: a_first > 0 and a_first <= a_last
			is_available: is_available
		local
			l_temp_txt: STRING
			l_uuid: UUID_GENERATOR
			l_args: ARRAYED_LIST [STRING]
			l_output: STRING
			l_file: PLAIN_TEXT_FILE
			l_raw: RAW_FILE
		do
			create l_uuid
			l_temp_txt := get_temp_directory + "/simple_pdf_" + l_uuid.generate_uuid.out + ".txt"

			create l_args.make (10)
			l_args.extend ("-f")
			l_args.extend (a_first.out)
			l_args.extend ("-l")
			l_args.extend (a_last.out)
			l_args.extend ("-layout")
			l_args.extend (a_pdf_path)
			l_args.extend (l_temp_txt)

			l_output := execute_pdftotext (l_args)

			create l_raw.make_with_name (l_temp_txt)
			if l_raw.exists then
				create l_file.make_open_read (l_temp_txt)
				l_file.read_stream (l_file.count.max (1))
				Result := l_file.last_string
				l_file.close
				l_raw.delete
				last_error := Void
			else
				Result := ""
				last_error := "pdftotext failed: " + l_output
			end
		end

feature {NONE} -- Implementation

	detect_executable
			-- Detect pdftotext.exe location
		local
			l_file: RAW_FILE
			l_candidates: ARRAYED_LIST [STRING]
			l_path: STRING
			l_env: EXECUTION_ENVIRONMENT
			l_cwd: STRING
		do
			create l_env
			l_cwd := l_env.current_working_path.name.to_string_8

			create l_candidates.make (4)
			l_candidates.extend ("bin/pdftotext.exe")
			l_candidates.extend ("pdftotext.exe")
			l_candidates.extend ("C:/Program Files/poppler/bin/pdftotext.exe")
			l_candidates.extend ("C:/Program Files (x86)/poppler/bin/pdftotext.exe")

			from
				l_candidates.start
			until
				l_candidates.after or executable_path /= Void
			loop
				l_path := l_candidates.item
				create l_file.make_with_name (l_path)
				if l_file.exists then
					-- Convert to absolute path for reliability
					if l_path.starts_with ("C:") or l_path.starts_with ("/") then
						executable_path := l_path
					else
						executable_path := l_cwd + "/" + l_path
					end
				end
				l_candidates.forth
			end

			if executable_path = Void then
				executable_path := find_in_path ("pdftotext.exe")
			end
		end

	find_in_path (a_name: STRING): detachable STRING
			-- Find executable in system PATH
		local
			l_proc: SIMPLE_PROCESS
			l_result: STRING_32
		do
			create l_proc.make
			l_proc.run ("cmd /c where " + a_name)
			if l_proc.was_successful and then attached l_proc.last_output as l_out then
				l_result := l_out.twin
				l_result.prune_all ('%R')
				l_result.prune_all ('%N')
				if not l_result.is_empty and then not l_result.has_substring ({STRING_32} "INFO:") then
					Result := l_result.to_string_8
				end
			end
		end

	execute_pdftotext (a_args: LIST [STRING]): STRING
			-- Execute pdftotext with given arguments, return output
		local
			l_proc: SIMPLE_PROCESS
			l_cmd: STRING
		do
			create Result.make_empty

			if attached executable_path as l_exe then
				-- Build command string with quoted arguments
				create l_cmd.make_from_string ("%"" + l_exe + "%"")
				from a_args.start until a_args.after loop
					l_cmd.append (" %"" + a_args.item + "%"")
					a_args.forth
				end

				create l_proc.make
				l_proc.run (l_cmd)

				if attached l_proc.last_output as l_out then
					Result := l_out.to_string_8
				elseif attached l_proc.last_error as l_err then
					Result := "Error: " + l_err.to_string_8
				else
					Result := "Failed to execute pdftotext"
				end
			end
		end

	get_temp_directory: STRING
			-- Get system temp directory
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			if attached l_env.item ("TEMP") as l_temp then
				Result := l_temp.to_string_8
			elseif attached l_env.item ("TMP") as l_tmp then
				Result := l_tmp.to_string_8
			else
				Result := "."
			end
		end

end
