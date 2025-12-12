note
	description: "Unit tests for simple_pdf library"
	author: "Your Organization"
	date: "$Date$"
	revision: "$Revision$"
	testing: "covers"

class
	SIMPLE_PDF_TEST_SET

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

end
