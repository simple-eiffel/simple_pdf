note
	description: "[
		Linux tests for printing an existing PDF: the text survives (GTK's export keeps a text
		layer), and has_printer agrees with CUPS's own list. The shared tests are in PRINT_TESTS.
	]"
	testing: "covers"

class
	PLATFORM_PRINT_TESTS

inherit
	PRINT_TESTS

feature -- Running

	run_all (a_run: PROCEDURE [PROCEDURE, STRING])
			-- Run this platform's tests through `a_run'.
		do
			a_run.call (agent test_the_text_survives_printing, "the_text_survives_printing")
			a_run.call (agent test_has_printer_matches_cups, "has_printer_matches_cups")
		end

feature -- Tests

	test_the_text_survives_printing
			-- Both pages' text reads back from the exported job.
		do
			assert_text_survives_printing
		end

	test_has_printer_matches_cups
			-- `has_printer' says whether CUPS lists a destination (`lpstat -e'); with no CUPS
			-- client installed there are none.
		local
			l_printer: SIMPLE_PDF_PRINTER
			l_process: SIMPLE_PROCESS
			l_cups: BOOLEAN
		do
			if (create {RAW_FILE}.make_with_name ("/usr/bin/lpstat")).exists then
				create l_process.make
				l_process.run ("/usr/bin/lpstat -e")
				l_cups := attached l_process.last_output as al_out and then not al_out.is_empty
			end
			create l_printer.make
			print ("    has a printer: " + l_printer.has_printer.out + "; CUPS lists one: " + l_cups.out + "%N")
			assert ("has_printer agrees with CUPS", l_printer.has_printer = l_cups)
		end

end
