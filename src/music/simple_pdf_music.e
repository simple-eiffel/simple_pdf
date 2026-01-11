note
	description: "[
		SIMPLE_PDF_MUSIC - Native PDF music notation renderer.

		Renders sheet music directly to PDF using Cairo and SMuFL fonts.
		No external dependencies like LilyPond required.

		Requires:
		- Bravura font installed or embedded (SMuFL-compliant)
		- simple_cairo library

		Usage:
			local
				music: SIMPLE_PDF_MUSIC
			do
				create music.make ("output.pdf")
				music.set_title ("My Score")
				music.set_composer ("Composer Name")

				-- Draw a staff
				music.draw_staff (50, 100, 500, 5)

				-- Draw treble clef
				music.draw_clef (60, 100, music.Clef_treble)

				-- Draw notes
				music.draw_note (150, 100, music.Note_quarter, 67)  -- G4

				music.finish
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_PDF_MUSIC

create
	make, make_with_size

feature {NONE} -- Initialization

	make (a_filename: STRING)
			-- Create A4 portrait music PDF.
		require
			filename_not_empty: not a_filename.is_empty
		do
			create glyphs
			create pdf_surface.make_a4 (a_filename)
			surface := pdf_surface.as_surface
			create context.make (surface)
			initialize_defaults
		end

	make_with_size (a_filename: STRING; a_width, a_height: REAL_64)
			-- Create music PDF with custom dimensions (in points).
		require
			filename_not_empty: not a_filename.is_empty
			valid_width: a_width > 0
			valid_height: a_height > 0
		do
			create glyphs
			create pdf_surface.make (a_filename, a_width, a_height)
			surface := pdf_surface.as_surface
			create context.make (surface)
			initialize_defaults
		end

	initialize_defaults
			-- Set up default rendering parameters.
		do
			staff_height := 40.0
			staff_line_thickness := 0.8
			stem_thickness := 1.0
			music_font_size := staff_height  -- 1 staff height = 1 em in SMuFL
			music_font := "Bravura"
			text_font := "Times New Roman"
			text_font_size := 12.0

			-- Black for music notation
			context.set_color_rgb (0.0, 0.0, 0.0).do_nothing

			-- Set up music font
			context.select_font (music_font, 0, 0)
			       .set_font_size (music_font_size).do_nothing
		end

feature -- Access

	pdf_surface: CAIRO_PDF_SURFACE
			-- PDF surface

	surface: CAIRO_SURFACE
			-- Cairo surface wrapper

	context: CAIRO_CONTEXT
			-- Drawing context

	glyphs: SMUFL_GLYPHS
			-- SMuFL glyph definitions

feature -- Configuration

	staff_height: REAL_64
			-- Height of one staff (5 lines) in points.
			-- Standard is 7mm = ~20 points for print.

	staff_line_thickness: REAL_64
			-- Thickness of staff lines in points.

	stem_thickness: REAL_64
			-- Thickness of note stems in points.

	music_font_size: REAL_64
			-- Size of music font in points.

	music_font: STRING
			-- Name of SMuFL-compliant music font.

	text_font: STRING
			-- Name of text font for titles, lyrics, etc.

	text_font_size: REAL_64
			-- Size of text font in points.

feature -- Settings

	set_staff_height (a_height: REAL_64)
			-- Set staff height and update dependent sizes.
		require
			positive: a_height > 0
		do
			staff_height := a_height
			music_font_size := a_height
			context.set_font_size (music_font_size).do_nothing
		ensure
			height_set: staff_height = a_height
		end

	set_music_font (a_font: STRING)
			-- Set music font (must be SMuFL-compliant).
		require
			not_empty: not a_font.is_empty
		do
			music_font := a_font
			context.select_font (music_font, 0, 0).do_nothing
		ensure
			font_set: music_font.same_string (a_font)
		end

feature -- Metadata

	set_title (a_title: STRING)
			-- Set PDF document title.
		do
			pdf_surface.set_title (a_title)
		end

	set_author (a_author: STRING)
			-- Set PDF document author.
		do
			pdf_surface.set_author (a_author)
		end

	set_composer (a_composer: STRING)
			-- Alias for set_author for music context.
		do
			pdf_surface.set_author (a_composer)
		end

feature -- Staff Drawing

	draw_staff (a_x, a_y, a_width: REAL_64; a_lines: INTEGER)
			-- Draw a staff at position with specified width.
			-- a_y is the position of the middle line.
		require
			valid_lines: a_lines >= 1 and a_lines <= 6
			valid_width: a_width > 0
		local
			l_space, l_y: REAL_64
			i: INTEGER
		do
			l_space := staff_space
			context.set_line_width (staff_line_thickness).do_nothing

			from i := 0 until i >= a_lines loop
				l_y := a_y + (i - (a_lines - 1) // 2) * l_space
				context.draw_line (a_x, l_y, a_x + a_width, l_y).do_nothing
				i := i + 1
			end
		end

	draw_ledger_line (a_x, a_y, a_width: REAL_64)
			-- Draw a single ledger line at position.
		do
			context.set_line_width (staff_line_thickness)
			       .draw_line (a_x, a_y, a_x + a_width, a_y).do_nothing
		end

feature -- Clef Drawing

	draw_clef (a_x, a_y: REAL_64; a_clef_type: INTEGER)
			-- Draw clef at position. a_y is the staff middle line.
		require
			valid_clef: a_clef_type >= Clef_treble and a_clef_type <= Clef_percussion
		local
			l_glyph: NATURAL_32
			l_y_offset: REAL_64
		do
			context.select_font (music_font, 0, 0)
			       .set_font_size (music_font_size).do_nothing

			inspect a_clef_type
			when Clef_treble then
				l_glyph := glyphs.Clef_g
				l_y_offset := staff_space  -- G clef sits on G line (second from bottom)
			when Clef_bass then
				l_glyph := glyphs.Clef_f
				l_y_offset := -staff_space  -- F clef sits on F line (second from top)
			when Clef_alto then
				l_glyph := glyphs.Clef_c
				l_y_offset := 0  -- C clef centered on middle line
			when Clef_tenor then
				l_glyph := glyphs.Clef_c
				l_y_offset := -staff_space  -- Tenor clef on fourth line
			when Clef_percussion then
				l_glyph := glyphs.Clef_percussion
				l_y_offset := 0
			else
				l_glyph := glyphs.Clef_g
				l_y_offset := staff_space
			end

			context.move_to (a_x, a_y + l_y_offset)
			       .show_text (glyphs.glyph_string (l_glyph)).do_nothing
		end

feature -- Note Drawing

	draw_note (a_x, a_y: REAL_64; a_duration: INTEGER; a_midi_pitch: INTEGER)
			-- Draw a note. a_y is staff middle line, pitch determines vertical offset.
		require
			valid_duration: a_duration >= Note_whole and a_duration <= Note_128th
		local
			l_notehead: NATURAL_32
			l_pitch_y: REAL_64
			l_stem_up: BOOLEAN
		do
			context.select_font (music_font, 0, 0)
			       .set_font_size (music_font_size).do_nothing

			-- Calculate vertical position from MIDI pitch (60 = middle C)
			l_pitch_y := pitch_to_y (a_y, a_midi_pitch)

			-- Determine stem direction (up if below middle line)
			l_stem_up := l_pitch_y > a_y

			-- Select notehead glyph based on duration
			inspect a_duration
			when Note_double_whole then
				l_notehead := glyphs.Notehead_double_whole
			when Note_whole then
				l_notehead := glyphs.Notehead_whole
			when Note_half then
				l_notehead := glyphs.Notehead_half
			else
				l_notehead := glyphs.Notehead_black
			end

			-- Draw notehead
			context.move_to (a_x, l_pitch_y)
			       .show_text (glyphs.glyph_string (l_notehead)).do_nothing

			-- Draw stem (for notes shorter than whole)
			if a_duration > Note_whole then
				draw_stem (a_x, l_pitch_y, l_stem_up)
			end

			-- Draw flags (for notes shorter than quarter)
			if a_duration >= Note_8th then
				draw_flag (a_x, l_pitch_y, a_duration, l_stem_up)
			end
		end

	draw_rest (a_x, a_y: REAL_64; a_duration: INTEGER)
			-- Draw a rest. a_y is staff middle line.
		require
			valid_duration: a_duration >= Note_whole and a_duration <= Note_128th
		local
			l_glyph: NATURAL_32
		do
			context.select_font (music_font, 0, 0)
			       .set_font_size (music_font_size).do_nothing

			inspect a_duration
			when Note_double_whole then
				l_glyph := glyphs.Rest_double_whole
			when Note_whole then
				l_glyph := glyphs.Rest_whole
			when Note_half then
				l_glyph := glyphs.Rest_half
			when Note_quarter then
				l_glyph := glyphs.Rest_quarter
			when Note_8th then
				l_glyph := glyphs.Rest_8th
			when Note_16th then
				l_glyph := glyphs.Rest_16th
			when Note_32nd then
				l_glyph := glyphs.Rest_32nd
			when Note_64th then
				l_glyph := glyphs.Rest_64th
			when Note_128th then
				l_glyph := glyphs.Rest_128th
			else
				l_glyph := glyphs.Rest_quarter
			end

			context.move_to (a_x, a_y)
			       .show_text (glyphs.glyph_string (l_glyph)).do_nothing
		end

feature -- Accidental Drawing

	draw_accidental (a_x, a_y: REAL_64; a_accidental: INTEGER)
			-- Draw accidental at position.
		require
			valid_accidental: a_accidental >= Accidental_flat and a_accidental <= Accidental_double_flat
		local
			l_glyph: NATURAL_32
		do
			context.select_font (music_font, 0, 0)
			       .set_font_size (music_font_size).do_nothing

			inspect a_accidental
			when Accidental_flat then
				l_glyph := glyphs.Accidental_flat
			when Accidental_natural then
				l_glyph := glyphs.Accidental_natural
			when Accidental_sharp then
				l_glyph := glyphs.Accidental_sharp
			when Accidental_double_sharp then
				l_glyph := glyphs.Accidental_double_sharp
			when Accidental_double_flat then
				l_glyph := glyphs.Accidental_double_flat
			else
				l_glyph := glyphs.Accidental_natural
			end

			context.move_to (a_x, a_y)
			       .show_text (glyphs.glyph_string (l_glyph)).do_nothing
		end

feature -- Time Signature Drawing

	draw_time_signature (a_x, a_y: REAL_64; a_numerator, a_denominator: INTEGER)
			-- Draw time signature at position.
		local
			l_space: REAL_64
		do
			context.select_font (music_font, 0, 0)
			       .set_font_size (music_font_size).do_nothing

			l_space := staff_space

			-- Draw numerator (top)
			context.move_to (a_x, a_y - l_space)
			       .show_text (time_sig_string (a_numerator)).do_nothing

			-- Draw denominator (bottom)
			context.move_to (a_x, a_y + l_space)
			       .show_text (time_sig_string (a_denominator)).do_nothing
		end

	draw_common_time (a_x, a_y: REAL_64)
			-- Draw common time signature (C).
		do
			context.select_font (music_font, 0, 0)
			       .set_font_size (music_font_size)
			       .move_to (a_x, a_y)
			       .show_text (glyphs.glyph_string (glyphs.Time_sig_common)).do_nothing
		end

	draw_cut_time (a_x, a_y: REAL_64)
			-- Draw cut time signature (alla breve).
		do
			context.select_font (music_font, 0, 0)
			       .set_font_size (music_font_size)
			       .move_to (a_x, a_y)
			       .show_text (glyphs.glyph_string (glyphs.Time_sig_cut)).do_nothing
		end

feature -- Barline Drawing

	draw_barline (a_x, a_y_top, a_y_bottom: REAL_64)
			-- Draw single barline.
		do
			context.set_line_width (staff_line_thickness)
			       .draw_line (a_x, a_y_top, a_x, a_y_bottom).do_nothing
		end

	draw_double_barline (a_x, a_y_top, a_y_bottom: REAL_64)
			-- Draw double barline.
		local
			l_gap: REAL_64
		do
			l_gap := staff_space * 0.3
			context.set_line_width (staff_line_thickness)
			       .draw_line (a_x, a_y_top, a_x, a_y_bottom)
			       .draw_line (a_x + l_gap, a_y_top, a_x + l_gap, a_y_bottom).do_nothing
		end

	draw_final_barline (a_x, a_y_top, a_y_bottom: REAL_64)
			-- Draw final barline (thin-thick).
		local
			l_gap, l_thick: REAL_64
		do
			l_gap := staff_space * 0.3
			l_thick := staff_space * 0.4
			context.set_line_width (staff_line_thickness)
			       .draw_line (a_x, a_y_top, a_x, a_y_bottom).do_nothing
			context.set_line_width (l_thick)
			       .draw_line (a_x + l_gap + l_thick / 2, a_y_top, a_x + l_gap + l_thick / 2, a_y_bottom).do_nothing
		end

feature -- Text Drawing

	draw_title (a_x, a_y: REAL_64; a_title: STRING)
			-- Draw title text.
		do
			context.select_font (text_font, 0, 1)  -- bold
			       .set_font_size (24)
			       .move_to (a_x, a_y)
			       .show_text (a_title).do_nothing
		end

	draw_composer (a_x, a_y: REAL_64; a_composer: STRING)
			-- Draw composer text.
		do
			context.select_font (text_font, 1, 0)  -- italic
			       .set_font_size (14)
			       .move_to (a_x, a_y)
			       .show_text (a_composer).do_nothing
		end

	draw_text (a_x, a_y: REAL_64; a_text: STRING)
			-- Draw generic text.
		do
			context.select_font (text_font, 0, 0)
			       .set_font_size (text_font_size)
			       .move_to (a_x, a_y)
			       .show_text (a_text).do_nothing
		end

feature -- Page Management

	new_page
			-- Start a new page.
		do
			pdf_surface.show_page (context)
		end

	finish
			-- Finalize and close the PDF.
		do
			context.destroy
			surface.destroy
			pdf_surface.destroy
		end

feature -- Duration Constants

	Note_double_whole: INTEGER = 0
	Note_whole: INTEGER = 1
	Note_half: INTEGER = 2
	Note_quarter: INTEGER = 3
	Note_8th: INTEGER = 4
	Note_16th: INTEGER = 5
	Note_32nd: INTEGER = 6
	Note_64th: INTEGER = 7
	Note_128th: INTEGER = 8

feature -- Clef Constants

	Clef_treble: INTEGER = 0
	Clef_bass: INTEGER = 1
	Clef_alto: INTEGER = 2
	Clef_tenor: INTEGER = 3
	Clef_percussion: INTEGER = 4

feature -- Accidental Constants

	Accidental_flat: INTEGER = 0
	Accidental_natural: INTEGER = 1
	Accidental_sharp: INTEGER = 2
	Accidental_double_sharp: INTEGER = 3
	Accidental_double_flat: INTEGER = 4

feature {NONE} -- Implementation

	staff_space: REAL_64
			-- Distance between staff lines.
		do
			Result := staff_height / 4.0
		end

	pitch_to_y (a_staff_y: REAL_64; a_midi_pitch: INTEGER): REAL_64
			-- Convert MIDI pitch to Y coordinate.
			-- Middle C (60) = middle line in alto clef, ledger below treble.
		local
			l_steps: INTEGER
		do
			-- Each step is half a staff space
			-- MIDI 60 = C4, B4 (71) = middle line in treble clef
			l_steps := 71 - a_midi_pitch  -- Distance from B4
			Result := a_staff_y + (l_steps * staff_space / 2.0)
		end

	draw_stem (a_x, a_y: REAL_64; a_up: BOOLEAN)
			-- Draw note stem.
		local
			l_stem_length, l_x, l_y1, l_y2: REAL_64
		do
			l_stem_length := staff_space * 3.5
			l_x := a_x + (if a_up then staff_space * 0.6 else 0.0 end)

			if a_up then
				l_y1 := a_y
				l_y2 := a_y - l_stem_length
			else
				l_y1 := a_y
				l_y2 := a_y + l_stem_length
			end

			context.set_line_width (stem_thickness)
			       .draw_line (l_x, l_y1, l_x, l_y2).do_nothing
		end

	draw_flag (a_x, a_y: REAL_64; a_duration: INTEGER; a_up: BOOLEAN)
			-- Draw note flag(s).
		local
			l_glyph: NATURAL_32
			l_stem_length: REAL_64
		do
			l_stem_length := staff_space * 3.5

			inspect a_duration
			when Note_8th then
				l_glyph := if a_up then glyphs.Flag_8th_up else glyphs.Flag_8th_down end
			when Note_16th then
				l_glyph := if a_up then glyphs.Flag_16th_up else glyphs.Flag_16th_down end
			when Note_32nd then
				l_glyph := if a_up then glyphs.Flag_32nd_up else glyphs.Flag_32nd_down end
			when Note_64th then
				l_glyph := if a_up then glyphs.Flag_64th_up else glyphs.Flag_64th_down end
			when Note_128th then
				l_glyph := if a_up then glyphs.Flag_128th_up else glyphs.Flag_128th_down end
			else
				l_glyph := glyphs.Flag_8th_up
			end

			context.select_font (music_font, 0, 0)
			       .set_font_size (music_font_size).do_nothing

			if a_up then
				context.move_to (a_x + staff_space * 0.6, a_y - l_stem_length).do_nothing
			else
				context.move_to (a_x, a_y + l_stem_length).do_nothing
			end

			context.show_text (glyphs.glyph_string (l_glyph)).do_nothing
		end

	time_sig_string (a_number: INTEGER): STRING_32
			-- Build time signature string from number.
		local
			l_n: INTEGER
		do
			create Result.make (3)
			if a_number >= 10 then
				l_n := a_number // 10
				Result.append (glyphs.glyph_string (glyphs.time_sig_digit (l_n)))
			end
			l_n := a_number \\ 10
			Result.append (glyphs.glyph_string (glyphs.time_sig_digit (l_n)))
		end

invariant
	surface_valid: surface /= Void
	context_valid: context /= Void
	glyphs_valid: glyphs /= Void

end
