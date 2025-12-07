note
	description: "Deferred class defining the interface for PDF rendering engines"
	author: "Your Organization"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SIMPLE_PDF_ENGINE

feature -- Access

	name: STRING
			-- Human-readable name of this engine
		deferred
		ensure
			result_not_empty: not Result.is_empty
		end

	is_available: BOOLEAN
			-- Is this engine available on the current system?
		deferred
		end

	last_error: detachable STRING
			-- Last error message, if any

feature -- Conversion

	render_html (a_html: STRING): SIMPLE_PDF_DOCUMENT
			-- Convert HTML string to PDF
		require
			engine_available: is_available
			html_not_empty: not a_html.is_empty
		deferred
		end

	render_file (a_path: STRING): SIMPLE_PDF_DOCUMENT
			-- Convert HTML file to PDF
		require
			engine_available: is_available
			path_not_empty: not a_path.is_empty
			file_exists: (create {RAW_FILE}.make_with_name (a_path)).exists
		deferred
		end

	render_url (a_url: STRING): SIMPLE_PDF_DOCUMENT
			-- Convert URL to PDF
		require
			engine_available: is_available
			url_not_empty: not a_url.is_empty
		deferred
		end

feature -- Settings

	page_size: STRING assign set_page_size
			-- Page size (e.g., "A4", "Letter")
		attribute
			Result := "A4"
		end

	orientation: STRING assign set_orientation
			-- Page orientation ("Portrait" or "Landscape")
		attribute
			Result := "Portrait"
		end

	margin_top: STRING assign set_margin_top
			-- Top margin (e.g., "10mm", "1in")
		attribute
			Result := "10mm"
		end

	margin_bottom: STRING assign set_margin_bottom
			-- Bottom margin
		attribute
			Result := "10mm"
		end

	margin_left: STRING assign set_margin_left
			-- Left margin
		attribute
			Result := "10mm"
		end

	margin_right: STRING assign set_margin_right
			-- Right margin
		attribute
			Result := "10mm"
		end

feature -- Settings modification

	set_page_size (a_size: STRING)
			-- Set page size
		require
			size_not_empty: not a_size.is_empty
		do
			page_size := a_size
		ensure
			page_size_set: page_size = a_size
		end

	set_orientation (a_orientation: STRING)
			-- Set page orientation
		require
			valid_orientation: a_orientation.same_string ("Portrait") or a_orientation.same_string ("Landscape")
		do
			orientation := a_orientation
		ensure
			orientation_set: orientation = a_orientation
		end

	set_margin_top (a_margin: STRING)
		do
			margin_top := a_margin
		end

	set_margin_bottom (a_margin: STRING)
		do
			margin_bottom := a_margin
		end

	set_margin_left (a_margin: STRING)
		do
			margin_left := a_margin
		end

	set_margin_right (a_margin: STRING)
		do
			margin_right := a_margin
		end

	set_margins (a_margin: STRING)
			-- Set all margins to the same value
		do
			margin_top := a_margin
			margin_bottom := a_margin
			margin_left := a_margin
			margin_right := a_margin
		end

feature {NONE} -- Implementation

	set_last_error (a_error: detachable STRING)
			-- Set last error message
		do
			last_error := a_error
		end

end
