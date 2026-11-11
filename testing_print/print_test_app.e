note
	description: "Runs simple_pdf_print's tests: the shared ones, then this platform's (PLATFORM_PRINT_TESTS)."

class
	PRINT_TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run every test; the first argument, when given, runs only the tests whose name has it.
		local
			l_shared: PRINT_TESTS
			l_platform: PLATFORM_PRINT_TESTS
		do
			if (create {ARGUMENTS_32}).argument_count >= 1 then
				only := (create {ARGUMENTS_32}).argument (1).to_string_32
			end
			print ("=== simple_pdf_print tests ===%N")
			create l_shared
			run_test (agent l_shared.test_outcomes_are_four_and_distinct, "outcomes_are_four_and_distinct")
			run_test (agent l_shared.test_default_paper_is_a_real_size, "default_paper_is_a_real_size")
			run_test (agent l_shared.test_print_file_to_keeps_the_pages_and_text, "print_file_to_keeps_the_pages_and_text")
			run_test (agent l_shared.test_a_broken_pdf_fails_with_a_reason, "a_broken_pdf_fails_with_a_reason")
			create l_platform
			l_platform.run_all (agent run_test)
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")
			if failed > 0 then
				print ("TESTS FAILED%N")
			end
		end

feature -- Running

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run `a_test'; any exception fails it, and the reason is printed.
		local
			l_retried: BOOLEAN
		do
			if attached only as al_only and then not a_name.has_substring (al_only.to_string_8) then
					-- Not asked for.
			elseif not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			if attached (create {EXCEPTION_MANAGER}).last_exception as al_exception and then attached al_exception.description as al_text then
				print ("        why: " + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (al_text) + "%N")
			end
			failed := failed + 1
			l_retried := True
			retry
		end

	passed, failed: INTEGER
			-- Counts so far.

	only: detachable STRING_32
			-- Run just the tests whose name contains this.

end
