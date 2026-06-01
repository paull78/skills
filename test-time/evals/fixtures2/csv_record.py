def parse_record(line):
    """Parse a single CSV record into its list of field strings.

    Rules:
      - Fields are separated by commas.
      - A field may be wrapped in double quotes. Inside a quoted field a
        comma is a literal character (not a separator), and a doubled quote
        ("") represents one literal double-quote character.
      - The surrounding quotes are not part of the returned value.

    Example:
      parse_record('a,"b,c",d')  -> ['a', 'b,c', 'd']
    """
    fields = []
    cur = []
    i = 0
    n = len(line)
    while i < n:
        c = line[i]
        if c == '"':
            i += 1
            while i < n and line[i] != '"':
                cur.append(line[i])
                i += 1
            i += 1  # skip the closing quote
        elif c == ',':
            fields.append("".join(cur))
            cur = []
            i += 1
        else:
            cur.append(c)
            i += 1
    fields.append("".join(cur))
    return fields
