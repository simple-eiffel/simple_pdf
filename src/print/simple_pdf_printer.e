note
	description: "[
		Print an existing PDF (1v-c): `print_file' shows the system's print dialog over it and
		prints what the user chose; `print_file_to' runs the same platform print path to a file,
		with no dialog (the test seam). See PDF_PRINT_PLATFORM_API for the outcomes and what
		each platform uses underneath.
	]"

class
	SIMPLE_PDF_PRINTER

inherit
	PDF_PRINT_PLATFORM

create
	make

end
