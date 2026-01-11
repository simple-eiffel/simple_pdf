note
	description: "[
		SMUFL_GLYPHS - Standard Music Font Layout glyph code points.

		Contains Unicode code points for all standard music notation symbols
		as defined by SMuFL 1.4 (https://w3c.github.io/smufl/latest/).

		These glyphs are in the Private Use Area (U+E000-U+F8FF) and
		require a SMuFL-compliant font like Bravura.

		Usage:
			local
				glyph: SMUFL_GLYPHS
				treble_clef: STRING_32
			do
				create glyph
				treble_clef := glyph.glyph_string (glyph.Clef_g)
				-- Use treble_clef with Cairo text rendering
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SMUFL_GLYPHS

feature -- Clefs (U+E050-U+E07F)

	Clef_g: NATURAL_32 = 0xE050
			-- G clef (treble clef)

	Clef_g_small: NATURAL_32 = 0xE051
			-- G clef (small staff)

	Clef_g_8va_alta: NATURAL_32 = 0xE053
			-- G clef ottava alta (octave up)

	Clef_g_8va_bassa: NATURAL_32 = 0xE054
			-- G clef ottava bassa (octave down)

	Clef_g_15ma_alta: NATURAL_32 = 0xE055
			-- G clef quindicesima alta (two octaves up)

	Clef_f: NATURAL_32 = 0xE062
			-- F clef (bass clef)

	Clef_f_small: NATURAL_32 = 0xE063
			-- F clef (small staff)

	Clef_f_8va_bassa: NATURAL_32 = 0xE065
			-- F clef ottava bassa (octave down)

	Clef_c: NATURAL_32 = 0xE05C
			-- C clef (alto/tenor clef)

	Clef_percussion: NATURAL_32 = 0xE069
			-- Percussion clef (unpitched)

	Clef_tab: NATURAL_32 = 0xE06D
			-- 6-string tablature clef

feature -- Noteheads (U+E0A0-U+E0FF)

	Notehead_double_whole: NATURAL_32 = 0xE0A0
			-- Double whole note (breve)

	Notehead_whole: NATURAL_32 = 0xE0A2
			-- Whole note (semibreve)

	Notehead_half: NATURAL_32 = 0xE0A3
			-- Half note (minim) - open notehead

	Notehead_black: NATURAL_32 = 0xE0A4
			-- Quarter note and shorter (crotchet+) - filled notehead

	Notehead_x: NATURAL_32 = 0xE0A9
			-- X notehead (muted/dead note)

	Notehead_plus: NATURAL_32 = 0xE0AF
			-- Plus notehead

	Notehead_circle_x: NATURAL_32 = 0xE0B3
			-- Circled X notehead

	Notehead_diamond_white: NATURAL_32 = 0xE0D9
			-- Diamond notehead (white/open)

	Notehead_diamond_black: NATURAL_32 = 0xE0DB
			-- Diamond notehead (filled)

	Notehead_parenthesis_left: NATURAL_32 = 0xE0CE
			-- Parenthesis left for noteheads

	Notehead_parenthesis_right: NATURAL_32 = 0xE0CF
			-- Parenthesis right for noteheads

feature -- Flags (U+E240-U+E25F)

	Flag_8th_up: NATURAL_32 = 0xE240
			-- 8th note (quaver) flag, stem up

	Flag_8th_down: NATURAL_32 = 0xE241
			-- 8th note (quaver) flag, stem down

	Flag_16th_up: NATURAL_32 = 0xE242
			-- 16th note (semiquaver) flag, stem up

	Flag_16th_down: NATURAL_32 = 0xE243
			-- 16th note (semiquaver) flag, stem down

	Flag_32nd_up: NATURAL_32 = 0xE244
			-- 32nd note (demisemiquaver) flag, stem up

	Flag_32nd_down: NATURAL_32 = 0xE245
			-- 32nd note (demisemiquaver) flag, stem down

	Flag_64th_up: NATURAL_32 = 0xE246
			-- 64th note flag, stem up

	Flag_64th_down: NATURAL_32 = 0xE247
			-- 64th note flag, stem down

	Flag_128th_up: NATURAL_32 = 0xE248
			-- 128th note flag, stem up

	Flag_128th_down: NATURAL_32 = 0xE249
			-- 128th note flag, stem down

feature -- Accidentals (U+E260-U+E26F)

	Accidental_flat: NATURAL_32 = 0xE260
			-- Flat

	Accidental_natural: NATURAL_32 = 0xE261
			-- Natural

	Accidental_sharp: NATURAL_32 = 0xE262
			-- Sharp

	Accidental_double_sharp: NATURAL_32 = 0xE263
			-- Double sharp

	Accidental_double_flat: NATURAL_32 = 0xE264
			-- Double flat

	Accidental_triple_sharp: NATURAL_32 = 0xE265
			-- Triple sharp

	Accidental_triple_flat: NATURAL_32 = 0xE266
			-- Triple flat

	Accidental_natural_flat: NATURAL_32 = 0xE267
			-- Natural flat (courtesy)

	Accidental_natural_sharp: NATURAL_32 = 0xE268
			-- Natural sharp (courtesy)

	Accidental_parens_left: NATURAL_32 = 0xE26A
			-- Accidental parenthesis, left

	Accidental_parens_right: NATURAL_32 = 0xE26B
			-- Accidental parenthesis, right

feature -- Time Signatures (U+E080-U+E09F)

	Time_sig_0: NATURAL_32 = 0xE080
	Time_sig_1: NATURAL_32 = 0xE081
	Time_sig_2: NATURAL_32 = 0xE082
	Time_sig_3: NATURAL_32 = 0xE083
	Time_sig_4: NATURAL_32 = 0xE084
	Time_sig_5: NATURAL_32 = 0xE085
	Time_sig_6: NATURAL_32 = 0xE086
	Time_sig_7: NATURAL_32 = 0xE087
	Time_sig_8: NATURAL_32 = 0xE088
	Time_sig_9: NATURAL_32 = 0xE089

	Time_sig_common: NATURAL_32 = 0xE08A
			-- Common time (C)

	Time_sig_cut: NATURAL_32 = 0xE08B
			-- Cut time (alla breve)

feature -- Rests (U+E4E0-U+E4FF)

	Rest_maxima: NATURAL_32 = 0xE4E0
			-- Maxima rest

	Rest_longa: NATURAL_32 = 0xE4E1
			-- Longa rest

	Rest_double_whole: NATURAL_32 = 0xE4E2
			-- Double whole rest (breve)

	Rest_whole: NATURAL_32 = 0xE4E3
			-- Whole rest (semibreve)

	Rest_half: NATURAL_32 = 0xE4E4
			-- Half rest (minim)

	Rest_quarter: NATURAL_32 = 0xE4E5
			-- Quarter rest (crotchet)

	Rest_8th: NATURAL_32 = 0xE4E6
			-- Eighth rest (quaver)

	Rest_16th: NATURAL_32 = 0xE4E7
			-- 16th rest (semiquaver)

	Rest_32nd: NATURAL_32 = 0xE4E8
			-- 32nd rest (demisemiquaver)

	Rest_64th: NATURAL_32 = 0xE4E9
			-- 64th rest

	Rest_128th: NATURAL_32 = 0xE4EA
			-- 128th rest

feature -- Articulations (U+E4A0-U+E4BF)

	Articulation_accent: NATURAL_32 = 0xE4A0
			-- Accent above

	Articulation_staccato: NATURAL_32 = 0xE4A2
			-- Staccato above

	Articulation_tenuto: NATURAL_32 = 0xE4A4
			-- Tenuto above

	Articulation_marcato: NATURAL_32 = 0xE4AC
			-- Marcato above

	Articulation_staccatissimo: NATURAL_32 = 0xE4A8
			-- Staccatissimo above

	Articulation_fermata: NATURAL_32 = 0xE4C0
			-- Fermata above

	Articulation_fermata_below: NATURAL_32 = 0xE4C1
			-- Fermata below

feature -- Dynamics (U+E520-U+E54F)

	Dynamic_piano: NATURAL_32 = 0xE520
			-- Piano (p)

	Dynamic_mezzo: NATURAL_32 = 0xE521
			-- Mezzo (m)

	Dynamic_forte: NATURAL_32 = 0xE522
			-- Forte (f)

	Dynamic_rinforzando: NATURAL_32 = 0xE523
			-- Rinforzando (r)

	Dynamic_sforzando: NATURAL_32 = 0xE524
			-- Sforzando (s)

	Dynamic_z: NATURAL_32 = 0xE525
			-- Z (for sfz, fz)

	Dynamic_niente: NATURAL_32 = 0xE526
			-- Niente (n)

	Dynamic_ppp: NATURAL_32 = 0xE52A
			-- Pianississimo (ppp)

	Dynamic_pp: NATURAL_32 = 0xE52B
			-- Pianissimo (pp)

	Dynamic_mp: NATURAL_32 = 0xE52C
			-- Mezzo-piano (mp)

	Dynamic_mf: NATURAL_32 = 0xE52D
			-- Mezzo-forte (mf)

	Dynamic_pf: NATURAL_32 = 0xE52E
			-- Piano-forte (pf)

	Dynamic_ff: NATURAL_32 = 0xE52F
			-- Fortissimo (ff)

	Dynamic_fff: NATURAL_32 = 0xE530
			-- Fortississimo (fff)

	Dynamic_sfz: NATURAL_32 = 0xE539
			-- Sforzando (sfz)

feature -- Ornaments (U+E560-U+E58F)

	Ornament_trill: NATURAL_32 = 0xE566
			-- Trill

	Ornament_turn: NATURAL_32 = 0xE567
			-- Turn

	Ornament_inverted_turn: NATURAL_32 = 0xE568
			-- Inverted turn

	Ornament_mordent: NATURAL_32 = 0xE56C
			-- Mordent

	Ornament_inverted_mordent: NATURAL_32 = 0xE56D
			-- Inverted mordent (upper mordent)

	Ornament_trill_line: NATURAL_32 = 0xE59E
			-- Trill continuation line

feature -- Repeats (U+E040-U+E04F)

	Repeat_left: NATURAL_32 = 0xE040
			-- Left repeat sign

	Repeat_right: NATURAL_32 = 0xE041
			-- Right repeat sign

	Repeat_left_right: NATURAL_32 = 0xE042
			-- Left/right repeat sign

	Coda: NATURAL_32 = 0xE048
			-- Coda sign

	Segno: NATURAL_32 = 0xE047
			-- Segno sign

	Dal_segno: NATURAL_32 = 0xE045
			-- Dal segno

	Da_capo: NATURAL_32 = 0xE046
			-- Da capo

feature -- Barlines (U+E030-U+E03F)

	Barline_single: NATURAL_32 = 0xE030
			-- Single barline

	Barline_double: NATURAL_32 = 0xE031
			-- Double barline

	Barline_final: NATURAL_32 = 0xE032
			-- Final barline (thin-thick)

	Barline_dashed: NATURAL_32 = 0xE036
			-- Dashed barline

	Barline_dotted: NATURAL_32 = 0xE037
			-- Dotted barline

feature -- Staff (U+E010-U+E02F)

	Staff_5_lines: NATURAL_32 = 0xE014
			-- 5-line staff

	Staff_1_line: NATURAL_32 = 0xE010
			-- 1-line staff

	Ledger_line: NATURAL_32 = 0xE022
			-- Ledger line

	Brace: NATURAL_32 = 0xE000
			-- Brace (for piano/organ)

	Bracket: NATURAL_32 = 0xE002
			-- Bracket (for instrument groups)

feature -- Octave Lines (U+E510-U+E51F)

	Ottava: NATURAL_32 = 0xE510
			-- 8va

	Ottava_bassa: NATURAL_32 = 0xE512
			-- 8vb

	Quindicesima: NATURAL_32 = 0xE514
			-- 15ma

	Quindicesima_bassa: NATURAL_32 = 0xE516
			-- 15mb

feature -- Dots (U+E1E0-U+E1FF)

	Augmentation_dot: NATURAL_32 = 0xE1E7
			-- Augmentation dot

feature -- Beams

	Beam_short: NATURAL_32 = 0xE1F0
			-- Short beam

feature -- Utility

	glyph_string (a_code: NATURAL_32): STRING_32
			-- Convert code point to string for rendering.
		do
			create Result.make (1)
			Result.append_character (a_code.to_character_32)
		ensure
			single_character: Result.count = 1
		end

	glyph_char (a_code: NATURAL_32): CHARACTER_32
			-- Convert code point to character.
		do
			Result := a_code.to_character_32
		end

	time_sig_digit (a_digit: INTEGER): NATURAL_32
			-- Get time signature glyph for digit 0-9.
		require
			valid_digit: a_digit >= 0 and a_digit <= 9
		do
			Result := (Time_sig_0 + a_digit.to_natural_32)
		end

end
