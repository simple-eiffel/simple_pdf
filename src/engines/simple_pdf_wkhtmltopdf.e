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
			l_uuid: SIMPLE_UUID
		do
			create l_uuid.make
			l_temp_html := temp_directory + "/simple_pdf_" + l_uuid.new_v4_string + ".html"
			l_temp_pdf := temp_directory + "/simple_pdf_" + l_uuid.new_v4_string + ".pdf"

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
			l_uuid: SIMPLE_UUID
			l_args: ARRAYED_LIST [STRING]
			l_output: STRING
		do
			create l_uuid.make
			l_temp_pdf := temp_directory + "/simple_pdf_" + l_uuid.new_v4_string + ".pdf"

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
			l_uuid: SIMPLE_UUID
			l_args: ARRAYED_LIST [STRING]
			l_output: STRING
		do
			create l_uuid.make
			l_temp_pdf := temp_directory + "/simple_pdf_" + l_uuid.new_v4_string + ".pdf"

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
			-- Detect wkhtmltopdf location (cross-platform)
		local
			l_file: RAW_FILE
			l_candidates: ARRAYED_LIST [STRING]
			l_path: STRING
			l_env: EXECUTION_ENVIRONMENT
			l_cwd: STRING
		do
			create l_env
			l_cwd := l_env.current_working_path.name.to_string_8

			create l_candidates.make (10)

			if {PLATFORM}.is_windows then
				-- Windows locations
				l_candidates.extend ("bin/wkhtmltopdf.exe")
				l_candidates.extend ("wkhtmltopdf.exe")
				l_candidates.extend ("C:/Program Files/wkhtmltopdf/bin/wkhtmltopdf.exe")
				l_candidates.extend ("C:/Program Files (x86)/wkhtmltopdf/bin/wkhtmltopdf.exe")
			else
				-- Linux/macOS locations
				l_candidates.extend ("/usr/bin/wkhtmltopdf")
				l_candidates.extend ("/usr/local/bin/wkhtmltopdf")
				l_candidates.extend ("/opt/homebrew/bin/wkhtmltopdf")  -- macOS Homebrew ARM
				l_candidates.extend ("/usr/local/opt/wkhtmltopdf/bin/wkhtmltopdf")  -- macOS Homebrew Intel
				l_candidates.extend ("bin/wkhtmltopdf")
				l_candidates.extend ("wkhtmltopdf")
			end

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

			-- Fallback: check PATH
			if executable_path = Void then
				if {PLATFORM}.is_windows then
					executable_path := find_in_path ("wkhtmltopdf.exe")
				else
					executable_path := find_in_path ("wkhtmltopdf")
				end
			end
		end

	find_in_path (a_name: STRING): detachable STRING
			-- Find executable in system PATH (cross-platform)
		local
			l_proc: SIMPLE_PROCESS
			l_result: STRING_32
			l_cmd: STRING
		do
			create l_proc.make
			if {PLATFORM}.is_windows then
				l_cmd := "cmd /c where " + a_name
			else
				l_cmd := "which " + a_name
			end
			l_proc.run (l_cmd)
			if l_proc.was_successful and then attached l_proc.last_output as l_out then
				l_result := l_out.twin
				l_result.prune_all ('%R')
				l_result.prune_all ('%N')
				if not l_result.is_empty and then not l_result.has_substring ({STRING_32} "INFO:") then
					Result := l_result.to_string_8
				end
			end
		end

	execute_wkhtmltopdf (a_args: LIST [STRING]): STRING
			-- Execute wkhtmltopdf with given arguments, return output
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
					Result := "Failed to execute wkhtmltopdf"
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
			-- Get system temp directory (cross-platform)
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			if {PLATFORM}.is_windows then
				if attached l_env.item ("TEMP") as l_temp then
					Result := l_temp.to_string_8
				elseif attached l_env.item ("TMP") as l_tmp then
					Result := l_tmp.to_string_8
				else
					Result := "."
				end
			else
				-- Linux/macOS: TMPDIR or /tmp
				if attached l_env.item ("TMPDIR") as l_tmpdir then
					Result := l_tmpdir.to_string_8
				else
					Result := "/tmp"
				end
			end
		end

end
