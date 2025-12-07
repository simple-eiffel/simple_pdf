note
	description: "PDF engine using wkhtmltopdf (Qt WebKit based)"
	author: "Your Organization"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_PDF_WKHTMLTOPDF

inherit
	SIMPLE_PDF_ENGINE

create
	make,
	make_with_path

feature {NONE} -- Initialization

	make
			-- Create engine using wkhtmltopdf from bin folder or PATH
		do
			detect_executable
		end

	make_with_path (a_path: STRING)
			-- Create engine with explicit path to wkhtmltopdf.exe
		require
			path_not_empty: not a_path.is_empty
		do
			executable_path := a_path
		ensure
			path_set: executable_path = a_path
		end

feature -- Access

	name: STRING = "wkhtmltopdf"

	executable_path: detachable STRING
			-- Path to wkhtmltopdf.exe

feature -- Status

	is_available: BOOLEAN
			-- Is wkhtmltopdf available?
		local
			l_file: RAW_FILE
		do
			if attached executable_path as l_path then
				create l_file.make_with_name (l_path)
				Result := l_file.exists
			end
		end

feature -- Conversion

	render_html (a_html: STRING): SIMPLE_PDF_DOCUMENT
			-- Convert HTML string to PDF
		local
			l_temp_html: STRING
			l_temp_pdf: STRING
			l_file: PLAIN_TEXT_FILE
			l_uuid: UUID_GENERATOR
		do
			create l_uuid
			l_temp_html := temp_directory + "/simple_pdf_" + l_uuid.generate_uuid.out + ".html"
			l_temp_pdf := temp_directory + "/simple_pdf_" + l_uuid.generate_uuid.out + ".pdf"

			-- Write HTML to temp file
			create l_file.make_create_read_write (l_temp_html)
			l_file.put_string (a_html)
			l_file.close

			-- Convert
			Result := render_file (l_temp_html)

			-- Cleanup temp HTML (PDF is loaded into document)
			create l_file.make_with_name (l_temp_html)
			if l_file.exists then
				l_file.delete
			end
		end

	render_file (a_path: STRING): SIMPLE_PDF_DOCUMENT
			-- Convert HTML file to PDF
		local
			l_temp_pdf: STRING
			l_uuid: UUID_GENERATOR
			l_args: ARRAYED_LIST [STRING]
			l_output: STRING
		do
			create l_uuid
			l_temp_pdf := temp_directory + "/simple_pdf_" + l_uuid.generate_uuid.out + ".pdf"

			create l_args.make (20)
			add_settings_args (l_args)
			l_args.extend (a_path)
			l_args.extend (l_temp_pdf)

			l_output := execute_wkhtmltopdf (l_args)

			if (create {RAW_FILE}.make_with_name (l_temp_pdf)).exists then
				create Result.make_from_file (l_temp_pdf)
				-- Cleanup temp PDF after loading
				(create {RAW_FILE}.make_with_name (l_temp_pdf)).delete
			else
				create Result.make_failed ("wkhtmltopdf failed: " + l_output)
			end
		end

	render_url (a_url: STRING): SIMPLE_PDF_DOCUMENT
			-- Convert URL to PDF
		local
			l_temp_pdf: STRING
			l_uuid: UUID_GENERATOR
			l_args: ARRAYED_LIST [STRING]
			l_output: STRING
		do
			create l_uuid
			l_temp_pdf := temp_directory + "/simple_pdf_" + l_uuid.generate_uuid.out + ".pdf"

			create l_args.make (20)
			add_settings_args (l_args)
			l_args.extend (a_url)
			l_args.extend (l_temp_pdf)

			l_output := execute_wkhtmltopdf (l_args)

			if (create {RAW_FILE}.make_with_name (l_temp_pdf)).exists then
				create Result.make_from_file (l_temp_pdf)
				-- Cleanup temp PDF after loading
				(create {RAW_FILE}.make_with_name (l_temp_pdf)).delete
			else
				create Result.make_failed ("wkhtmltopdf failed: " + l_output)
			end
		end

feature {NONE} -- Implementation

	detect_executable
			-- Detect wkhtmltopdf.exe location
		local
			l_file: RAW_FILE
			l_candidates: ARRAYED_LIST [STRING]
			l_path: STRING
			l_env: EXECUTION_ENVIRONMENT
			l_cwd: STRING
		do
			create l_env
			l_cwd := l_env.current_working_path.name.to_string_8

			-- Check common locations
			create l_candidates.make (4)
			l_candidates.extend ("bin/wkhtmltopdf.exe")
			l_candidates.extend ("wkhtmltopdf.exe")
			l_candidates.extend ("C:/Program Files/wkhtmltopdf/bin/wkhtmltopdf.exe")
			l_candidates.extend ("C:/Program Files (x86)/wkhtmltopdf/bin/wkhtmltopdf.exe")

			from l_candidates.start until l_candidates.after or executable_path /= Void loop
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

			-- Fallback: check PATH using 'where' command
			if executable_path = Void then
				executable_path := find_in_path ("wkhtmltopdf.exe")
			end
		end

	find_in_path (a_name: STRING): detachable STRING
			-- Find executable in system PATH
		local
			l_process: PROCESS
			l_factory: PROCESS_FACTORY
			l_buffer: SPECIAL [NATURAL_8]
			l_result: STRING
		do
			create l_factory
			l_process := l_factory.process_launcher ("cmd", <<"/c", "where", a_name>>, Void)
			l_process.set_hidden (True)
			l_process.redirect_output_to_stream
			l_process.launch
			if l_process.launched then
				create l_buffer.make_filled (0, 1024)
				from
				until
					l_process.has_output_stream_closed
				loop
					l_process.read_output_to_special (l_buffer)
				end
				l_process.wait_for_exit
				create l_result.make_from_c_substring ($l_buffer, 1, l_buffer.count)
				l_result.prune_all ('%R')
				l_result.prune_all ('%N')
				if not l_result.is_empty and then not l_result.has_substring ("INFO:") then
					Result := l_result
				end
			end
		end

	execute_wkhtmltopdf (a_args: LIST [STRING]): STRING
			-- Execute wkhtmltopdf with given arguments, return output
		local
			l_process: PROCESS
			l_factory: PROCESS_FACTORY
			l_buffer: SPECIAL [NATURAL_8]
			l_args: ARRAY [STRING]
			i: INTEGER
		do
			create Result.make_empty

			if attached executable_path as l_exe then
				-- Convert list to array
				create l_args.make_filled ("", 1, a_args.count)
				i := 1
				from a_args.start until a_args.after loop
					l_args [i] := a_args.item
					i := i + 1
					a_args.forth
				end

				create l_factory
				l_process := l_factory.process_launcher (l_exe, l_args, Void)
				l_process.set_hidden (True)
				l_process.redirect_output_to_stream
				l_process.redirect_error_to_same_as_output
				l_process.launch

				if l_process.launched then
					create l_buffer.make_filled (0, 4096)
					from
					until
						l_process.has_output_stream_closed
					loop
						l_process.read_output_to_special (l_buffer)
					end
					l_process.wait_for_exit
					create Result.make_from_c_substring ($l_buffer, 1, l_buffer.count)
				else
					Result := "Failed to launch wkhtmltopdf"
				end
			end
		end

	add_settings_args (a_args: LIST [STRING])
			-- Add current settings as command line arguments
		do
			a_args.extend ("--page-size")
			a_args.extend (page_size)

			if orientation.same_string ("Landscape") then
				a_args.extend ("--orientation")
				a_args.extend ("Landscape")
			end

			a_args.extend ("--margin-top")
			a_args.extend (margin_top)

			a_args.extend ("--margin-bottom")
			a_args.extend (margin_bottom)

			a_args.extend ("--margin-left")
			a_args.extend (margin_left)

			a_args.extend ("--margin-right")
			a_args.extend (margin_right)

			-- Quiet mode to reduce output noise
			a_args.extend ("--quiet")
		end

	temp_directory: STRING
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
