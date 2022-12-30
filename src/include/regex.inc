; Super simple regex written in rgbasm
; This is only for *extremely simple* parsing.
; It is not a complete regex implementation.

; Supported features:
; - character matching
; - '.'
; - captures

def MATCH_MODE_NONE equ 0
def MATCH_MODE_MATCH equ 1
def MATCH_MODE_DONT equ 2
def MATCH_MODE_ANY equ 3

macro _match ; char
	if capturing
		redef {capture{d:active_capture}} equs strcat("{{capture{d:active_capture}}}", \1)
	endc
endm

macro popchars ; s, nb
	redef \1 equs strsub("{\1}", 1 + (\2))
endm

macro regex ; rx, s, [captures]
	def _source_rx equs \1
	def _rx equs \1
	def _source_s equs \2
	def _s equs \2
	def captures = _NARG - 2

	shift 2
	for i, captures
		redef capture{d:i} equs "\1"
		redef \1 equs ""
		shift 1
	endr

	def capturing = 0
	def active_capture = 0

	rept strlen("{_rx}")
		; A loop may exhaust multiple characters, so check again here.
		if strlen("{_rx}") == 0
			break
		endc

		def match_mode = MATCH_MODE_NONE
		redef matchables equs ""
		redef next_char equs strsub("{_rx}", 1, 1)

		if !strcmp("{next_char}", ".")
			def match_mode = MATCH_MODE_ANY
		elif !strcmp("{next_char}", "(")
			def capturing = 1
		elif !strcmp("{next_char}", ")")
			def active_capture += 1
			def capturing = 0
		elif !strcmp("{next_char}", "\\")
			popchars _rx, 1
			redef matchables equs strsub("{_rx}", 1, 1)
			def match_mode = MATCH_MODE_MATCH
		elif !strcmp("{next_char}", "[")
			popchars _rx, 1
			if strsub("{_rx}", 1, 1) == "^"
				def match_mode = MATCH_MODE_DONT
			else
				def match_mode = MATCH_MODE_MATCH
			endc

			rept strlen("{_rx}")
				redef next_char equs strsub("{_rx}", 1, 1)
				if !strcmp("{next_char}", "]")
					break
				endc
				popchars _rx, 1
				redef matchables equs strcat("{matchables}", "{next_char}")
			endr
		else
			redef matchables equs "{next_char}"
			def match_mode = MATCH_MODE_MATCH
		endc

		if match_mode
			def passed = 0
			redef next_match equs strsub("{_s}", 1, 1)
			
			if match_mode == MATCH_MODE_ANY \
				|| match_mode == MATCH_MODE_MATCH && strin("{matchables}", "{next_match}") \
				|| match_mode == MATCH_MODE_DONT && !strin("{matchables}", "{next_match}")
				_match "{next_match}"
				def passed = 1
			endc

			if !passed
				warn "regex /{_source_rx}/ does not match \"{_source_s}\" (at /{_rx}/ : \"{_s}\") (expected one of: {matchables})"
			endc

			popchars _s, 1
		endc

		popchars _rx, 1
	endr

	if strlen("{_s}")
		warn "regex /{_source_rx}/ does not match \"{_source_s}\" (exhausted regex)"
	endc

	purge _rx, _s, _source_rx, _source_s, captures, next_char, match_mode
endm