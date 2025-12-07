note
	description: "Helper class for detecting and selecting PDF engines"
	author: "Your Organization"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_PDF_ENGINES

feature -- Engine creation

	wkhtmltopdf: SIMPLE_PDF_WKHTMLTOPDF
			-- Create wkhtmltopdf engine
		do
			create Result.make
		end

	chrome: SIMPLE_PDF_CHROME
			-- Create Chrome engine
		do
			create Result.make
		end

feature -- Detection

	default_engine: SIMPLE_PDF_ENGINE
			-- Best available engine on this system
			-- Priority: wkhtmltopdf (if bundled), Chrome (if installed)
		do
			if wkhtmltopdf_available then
				Result := wkhtmltopdf
			elseif chrome_available then
				Result := chrome
			else
				-- Return wkhtmltopdf anyway (will fail gracefully)
				Result := wkhtmltopdf
			end
		end

	wkhtmltopdf_available: BOOLEAN
			-- Is wkhtmltopdf available?
		local
			l_engine: SIMPLE_PDF_WKHTMLTOPDF
		do
			create l_engine.make
			Result := l_engine.is_available
		end

	chrome_available: BOOLEAN
			-- Is Chrome/Edge available?
		local
			l_engine: SIMPLE_PDF_CHROME
		do
			create l_engine.make
			Result := l_engine.is_available
		end

	any_available: BOOLEAN
			-- Is any PDF engine available?
		do
			Result := wkhtmltopdf_available or chrome_available
		end

feature -- Information

	available_engines: ARRAYED_LIST [SIMPLE_PDF_ENGINE]
			-- List of all available engines
		do
			create Result.make (2)
			if wkhtmltopdf_available then
				Result.extend (wkhtmltopdf)
			end
			if chrome_available then
				Result.extend (chrome)
			end
		end

	report: STRING
			-- Human-readable report of available engines
		do
			create Result.make_empty
			Result.append ("PDF Engine Availability Report%N")
			Result.append ("=============================%N%N")

			Result.append ("wkhtmltopdf: ")
			if wkhtmltopdf_available then
				Result.append ("AVAILABLE")
				if attached wkhtmltopdf.executable_path as l_path then
					Result.append (" (" + l_path + ")")
				end
			else
				Result.append ("NOT FOUND")
			end
			Result.append ("%N")

			Result.append ("Chrome/Edge: ")
			if chrome_available then
				Result.append ("AVAILABLE")
				if attached chrome.executable_path as l_path then
					Result.append (" (" + l_path + ")")
				end
			else
				Result.append ("NOT FOUND")
			end
			Result.append ("%N%N")

			Result.append ("Default engine: " + default_engine.name + "%N")
		end

end
