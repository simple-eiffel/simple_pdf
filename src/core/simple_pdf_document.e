note
	description: "Represents a generated PDF document with its binary content"
	author: "Your Organization"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_PDF_DOCUMENT

create
	make,
	make_from_file,
	make_failed

feature {NONE} -- Initialization

	make (a_content: MANAGED_POINTER; a_size: INTEGER)
			-- Create document from binary content
		require
			size_positive: a_size > 0
		do
			content := a_content
			content_size := a_size
			is_valid := True
		ensure
			content_set: content = a_content
			size_set: content_size = a_size
			is_valid: is_valid
		end

	make_from_file (a_path: STRING)
			-- Create document by reading existing PDF file
		require
			path_not_empty: not a_path.is_empty
		local
			l_file: RAW_FILE
			l_content: MANAGED_POINTER
		do
			create l_file.make_with_name (a_path)
			if l_file.exists then
				l_file.open_read
				content_size := l_file.count
				create l_content.make (content_size)
				l_file.read_to_managed_pointer (l_content, 0, content_size)
				l_file.close
				content := l_content
				is_valid := True
				source_path := a_path
			else
				is_valid := False
				error_message := "File not found: " + a_path
			end
		end

	make_failed (a_error: STRING)
			-- Create failed document with error message
		require
			error_not_empty: not a_error.is_empty
		do
			is_valid := False
			error_message := a_error
		ensure
			not_valid: not is_valid
			error_set: error_message /= Void
		end

feature -- Access

	content: detachable MANAGED_POINTER
			-- Binary PDF content

	content_size: INTEGER
			-- Size of content in bytes

	source_path: detachable STRING
			-- Original file path if loaded from file

	error_message: detachable STRING
			-- Error message if generation failed

feature -- Status

	is_valid: BOOLEAN
			-- Was the PDF generated successfully?

	has_content: BOOLEAN
			-- Does document have binary content?
		do
			Result := content /= Void and content_size > 0
		end

feature -- Output

	save_to_file (a_path: STRING): BOOLEAN
			-- Save PDF to file, returns True on success
		require
			path_not_empty: not a_path.is_empty
			is_valid: is_valid
			has_content: has_content
		local
			l_file: RAW_FILE
		do
			if attached content as l_content then
				create l_file.make_with_name (a_path)
				l_file.open_write
				l_file.put_managed_pointer (l_content, 0, content_size)
				l_file.close
				Result := True
			end
		rescue
			Result := False
		end

	as_base64: STRING
			-- Return PDF content as Base64 encoded string
		require
			is_valid: is_valid
			has_content: has_content
		local
			l_base64: SIMPLE_BASE64
		do
			create l_base64.make
			if attached content as l_content then
				Result := l_base64.encode (pointer_to_string (l_content.item, content_size))
			else
				Result := ""
			end
		end

feature {NONE} -- Implementation

	pointer_to_string (a_ptr: POINTER; a_size: INTEGER): STRING
			-- Convert pointer content to string
		local
			i: INTEGER
			l_mp: MANAGED_POINTER
		do
			create Result.make (a_size)
			create l_mp.share_from_pointer (a_ptr, a_size)
			from i := 0 until i >= a_size loop
				Result.append_character (l_mp.read_natural_8 (i).to_character_8)
				i := i + 1
			end
		end

end
