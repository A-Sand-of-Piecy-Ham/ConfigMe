# Called by kitty for every paste, because kitty.conf lists `filter` in
# paste_actions.
#
# Text copied in a Windows application reaches WSL with CRLF line endings.
# kitty's built-in replace-dangerous-control-codes does not touch a bare
# carriage return -- it is not considered dangerous -- so every pasted line
# arrived with a trailing ^M. In a shell that produces a command not found for
# a name with an invisible character on the end; in an editor it is visible
# junk.
#
# replace-newline is NOT the option for this: it strips newlines entirely and
# would join the pasted lines into one.


def filter_paste(text: str) -> str:
    # Normalise CRLF and lone CR to LF. Order matters: handling CRLF first
    # keeps a Windows line ending from becoming two newlines.
    return text.replace("\r\n", "\n").replace("\r", "\n")
