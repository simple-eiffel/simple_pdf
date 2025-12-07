note
	description: "[
		Simple PDF generation library.

		Provides HTML-to-PDF conversion using multiple rendering engines:
		- wkhtmltopdf (default) - Qt WebKit based, good compatibility
		- Chrome - Headless Chrome/Edge, best CSS support

		Example usage:
			create pdf.make
			doc := pdf.from_html ("<h1>Hello World</h1>")
			doc.save_to_file ("output.pdf")

		With explicit engine:
			create pdf.make_with_engine (create {SIMPLE_PDF_CHROME})
			doc := pdf.from_url ("https://example.com")

		With settings:
			create pdf.make
			pdf.set_page_size ("Letter")
			pdf.set_orientation ("Landscape")
			pdf.set_margins ("1in")
			doc := pdf.from_html (report_html)

		Fluent API:
			create pdf.make
			doc := pdf.page ("Letter").landscape.margin_all ("1in").from_html (report_html)
	]"
	author: "Your Organization"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_PDF

create
	make,
	make_with_engine

feature {NONE} -- Initialization

	make
			-- Create with default engine (wkhtmltopdf)
		local
			l_engine: SIMPLE_PDF_WKHTMLTOPDF
		do
			create l_engine.make
			engine := l_engine
		end

	make_with_engine (a_engine: SIMPLE_PDF_ENGINE)
			-- Create with specified rendering engine
		require
			engine_attached: a_engine /= Void
		do
			engine := a_engine
		ensure
			engine_set: engine = a_engine
		end

feature -- Access

	engine: SIMPLE_PDF_ENGINE
			-- Current rendering engine

feature -- Status

	is_available: BOOLEAN
			-- Is the current engine available?
		do
			Result := engine.is_available
		end

	last_error: detachable STRING
			-- Last error message from engine
		do
			Result := engine.last_error
		end

feature -- Conversion

	from_html (a_html: STRING): SIMPLE_PDF_DOCUMENT
			-- Convert HTML string to PDF
		require
			html_not_empty: not a_html.is_empty
			engine_available: is_available
		do
			Result := engine.render_html (a_html)
		end

	from_file (a_path: STRING): SIMPLE_PDF_DOCUMENT
			-- Convert HTML file to PDF
		require
			path_not_empty: not a_path.is_empty
			file_exists: (create {RAW_FILE}.make_with_name (a_path)).exists
			engine_available: is_available
		do
			Result := engine.render_file (a_path)
		end

	from_url (a_url: STRING): SIMPLE_PDF_DOCUMENT
			-- Convert URL to PDF
		require
			url_not_empty: not a_url.is_empty
			engine_available: is_available
		do
			Result := engine.render_url (a_url)
		end

feature -- Settings (delegated to engine)

	page_size: STRING
			-- Current page size
		do
			Result := engine.page_size
		end

	set_page_size (a_size: STRING)
			-- Set page size (e.g., "A4", "Letter", "Legal")
		require
			size_not_empty: not a_size.is_empty
		do
			engine.set_page_size (a_size)
		end

	orientation: STRING
			-- Current orientation
		do
			Result := engine.orientation
		end

	set_orientation (a_orientation: STRING)
			-- Set page orientation ("Portrait" or "Landscape")
		require
			valid_orientation: a_orientation.same_string ("Portrait") or a_orientation.same_string ("Landscape")
		do
			engine.set_orientation (a_orientation)
		end

	set_margins (a_margin: STRING)
			-- Set all margins to same value (e.g., "10mm", "1in")
		do
			engine.set_margins (a_margin)
		end

	set_margin_top (a_margin: STRING)
		do
			engine.set_margin_top (a_margin)
		end

	set_margin_bottom (a_margin: STRING)
		do
			engine.set_margin_bottom (a_margin)
		end

	set_margin_left (a_margin: STRING)
		do
			engine.set_margin_left (a_margin)
		end

	set_margin_right (a_margin: STRING)
		do
			engine.set_margin_right (a_margin)
		end

feature -- Engine switching

	use_wkhtmltopdf
			-- Switch to wkhtmltopdf engine
		do
			create {SIMPLE_PDF_WKHTMLTOPDF} engine.make
		end

	use_chrome
			-- Switch to Chrome engine
		do
			create {SIMPLE_PDF_CHROME} engine.make
		end

feature -- Fluent API

	page (a_size: STRING): like Current
			-- Set page size and return self for chaining
		require
			size_not_empty: not a_size.is_empty
		do
			set_page_size (a_size)
			Result := Current
		end

	portrait: like Current
			-- Set portrait orientation and return self for chaining
		do
			set_orientation ("Portrait")
			Result := Current
		end

	landscape: like Current
			-- Set landscape orientation and return self for chaining
		do
			set_orientation ("Landscape")
			Result := Current
		end

	margin_all (a_margin: STRING): like Current
			-- Set all margins and return self for chaining
		do
			set_margins (a_margin)
			Result := Current
		end

	margin_top (a_margin: STRING): like Current
			-- Set top margin and return self for chaining
		do
			set_margin_top (a_margin)
			Result := Current
		end

	margin_bottom (a_margin: STRING): like Current
			-- Set bottom margin and return self for chaining
		do
			set_margin_bottom (a_margin)
			Result := Current
		end

	margin_left (a_margin: STRING): like Current
			-- Set left margin and return self for chaining
		do
			set_margin_left (a_margin)
			Result := Current
		end

	margin_right (a_margin: STRING): like Current
			-- Set right margin and return self for chaining
		do
			set_margin_right (a_margin)
			Result := Current
		end

	margins (a_top, a_bottom, a_left, a_right: STRING): like Current
			-- Set individual margins and return self for chaining
		do
			set_margin_top (a_top)
			set_margin_bottom (a_bottom)
			set_margin_left (a_left)
			set_margin_right (a_right)
			Result := Current
		end

	with_wkhtmltopdf: like Current
			-- Switch to wkhtmltopdf engine and return self for chaining
		do
			use_wkhtmltopdf
			Result := Current
		end

	with_chrome: like Current
			-- Switch to Chrome engine and return self for chaining
		do
			use_chrome
			Result := Current
		end

end
