note
	description: "PDF engine using Chrome/Chromium headless mode (best CSS support)"
	author: "Your Organization"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_PDF_CHROME

inherit
	SIMPLE_PDF_ENGINE

create
	make,
	make_with_path

feature {NONE} -- Initialization

	make
			-- Create engine using Chrome from common locations or PATH
		do
			detect_executable
		end

	make_with_path (a_path: STRING)
			-- Create engine with explicit path to chrome.exe
		require
			path_not_empty: not a_path.is_empty
		do
			executable_path := a_path
		ensure
			path_set: executable_path = a_path
		end

feature -- Access

	name: STRING = "Chrome"

	executable_path: detachable STRING
			-- Path to chrome.exe

feature -- Status

	is_available: BOOLEAN
			-- Is Chrome available?
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
			l_file: PLAIN_TEXT_FILE
			l_uuid: SIMPLE_UUID
		do
			create l_uuid.make
			l_temp_html := temp_directory + "/simple_pdf_" + l_uuid.new_v4_string + ".html"

			-- Write HTML to temp file
			create l_file.make_create_read_write (l_temp_html)
			l_file.put_string (a_html)
			l_file.close

			-- Convert via file
			Result := render_file (l_temp_html)

			-- Cleanup temp HTML
			create l_file.make_with_name (l_temp_html)
			if l_file.exists then
				l_file.delete
			end
		end

	render_file (a_path: STRING): SIMPLE_PDF_DOCUMENT
			-- Convert HTML file to PDF
		local
			l_file_url: STRING
		do
			-- Chrome needs file:// URL for local files
			l_file_url := "file:///" + a_path
			l_file_url.replace_substring_all ("\", "/")
			Result := render_url (l_file_url)
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
			add_chrome_args (l_args, a_url, l_temp_pdf)

			l_output := execute_chrome (l_args)

			if (create {RAW_FILE}.make_with_name (l_temp_pdf)).exists then
				create Result.make_from_file (l_temp_pdf)
				-- Cleanup temp PDF after loading
				(create {RAW_FILE}.make_with_name (l_temp_pdf)).delete
			else
				create Result.make_failed ("Chrome PDF generation failed: " + l_output)
			end
		end

feature {NONE} -- Implementation

	detect_executable
			-- Detect Chrome executable location (cross-platform)
		local
			l_file: RAW_FILE
			l_candidates: ARRAYED_LIST [STRING]
			l_path: STRING
		do
			create l_candidates.make (15)

			if {PLATFORM}.is_windows then
				-- Windows Chrome/Edge locations
				l_candidates.extend ("C:/Program Files/Google/Chrome/Application/chrome.exe")
				l_candidates.extend ("C:/Program Files (x86)/Google/Chrome/Application/chrome.exe")
				l_candidates.extend ("C:/Users/" + user_name + "/AppData/Local/Google/Chrome/Application/chrome.exe")
				l_candidates.extend ("C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe")
				l_candidates.extend ("C:/Program Files/Microsoft/Edge/Application/msedge.exe")
			else
				-- Linux Chrome/Chromium locations
				l_candidates.extend ("/usr/bin/google-chrome")
				l_candidates.extend ("/usr/bin/google-chrome-stable")
				l_candidates.extend ("/usr/bin/chromium")
				l_candidates.extend ("/usr/bin/chromium-browser")
				l_candidates.extend ("/snap/bin/chromium")
				l_candidates.extend ("/usr/local/bin/chrome")
				-- macOS Chrome locations
				l_candidates.extend ("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")
				l_candidates.extend ("/Applications/Chromium.app/Contents/MacOS/Chromium")
				l_candidates.extend ("/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge")
			end

			from l_candidates.start until l_candidates.after or executable_path /= Void loop
				l_path := l_candidates.item
				create l_file.make_with_name (l_path)
				if l_file.exists then
					executable_path := l_path
				end
				l_candidates.forth
			end
		end

	user_name: STRING
			-- Current user name (cross-platform)
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			if {PLATFORM}.is_windows then
				if attached l_env.item ("USERNAME") as l_user then
					Result := l_user.to_string_8
				else
					Result := "User"
				end
			else
				-- Linux/macOS: USER env var
				if attached l_env.item ("USER") as l_user then
					Result := l_user.to_string_8
				else
					Result := "user"
				end
			end
		end

	execute_chrome (a_args: LIST [STRING]): STRING
			-- Execute Chrome with given arguments, return output
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
					Result := "Failed to execute Chrome"
				end
			end
		end

	add_chrome_args (a_args: LIST [STRING]; a_url, a_output: STRING)
			-- Add Chrome headless arguments for PDF generation
		do
			a_args.extend ("--headless")
			a_args.extend ("--disable-gpu")
			a_args.extend ("--no-sandbox")
			a_args.extend ("--disable-software-rasterizer")

			-- PDF output
			a_args.extend ("--print-to-pdf=" + a_output)

			-- Page settings
			a_args.extend ("--print-to-pdf-no-header")

			-- Paper size (Chrome uses inches)
			if page_size.same_string ("A4") then
				a_args.extend ("--paper-width=8.27")
				a_args.extend ("--paper-height=11.69")
			elseif page_size.same_string ("Letter") then
				a_args.extend ("--paper-width=8.5")
				a_args.extend ("--paper-height=11")
			end

			-- Landscape
			if orientation.same_string ("Landscape") then
				a_args.extend ("--landscape")
			end

			-- Margins (convert mm to inches approximately)
			a_args.extend ("--margin-top=" + margin_to_inches (margin_top))
			a_args.extend ("--margin-bottom=" + margin_to_inches (margin_bottom))
			a_args.extend ("--margin-left=" + margin_to_inches (margin_left))
			a_args.extend ("--margin-right=" + margin_to_inches (margin_right))

			-- The URL to print
			a_args.extend (a_url)
		end

	margin_to_inches (a_margin: STRING): STRING
			-- Convert margin string (e.g., "10mm") to inches for Chrome
		local
			l_value: REAL_64
		do
			if a_margin.has_substring ("mm") then
				l_value := a_margin.substring (1, a_margin.count - 2).to_real_64 / 25.4
			elseif a_margin.has_substring ("in") then
				l_value := a_margin.substring (1, a_margin.count - 2).to_real_64
			elseif a_margin.has_substring ("cm") then
				l_value := a_margin.substring (1, a_margin.count - 2).to_real_64 / 2.54
			else
				-- Assume pixels, convert roughly
				l_value := a_margin.to_real_64 / 96.0
			end
			Result := l_value.out
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
