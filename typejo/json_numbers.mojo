from std.collections import Optional

def _digit(code: Int) -> Bool:
    return code >= 48 and code <= 57

def json_number_end(source: String) -> Int:
    var length = source.byte_length()
    if length == 0:
        return -1
    var position = 0
    if source[byte=position] == "-":
        position += 1
        if position == length:
            return -1
    if source[byte=position] == "0":
        position += 1
        if position < length and _digit(ord(source[byte=position])):
            return -1
    elif _digit(ord(source[byte=position])) and ord(source[byte=position]) != 48:
        while position < length and _digit(ord(source[byte=position])):
            position += 1
    else:
        return -1
    if position < length and source[byte=position] == ".":
        position += 1
        var start = position
        while position < length and _digit(ord(source[byte=position])):
            position += 1
        if position == start:
            return -1
    if position < length and (source[byte=position] == "e" or source[byte=position] == "E"):
        position += 1
        if position < length and (source[byte=position] == "+" or source[byte=position] == "-"):
            position += 1
        var start = position
        while position < length and _digit(ord(source[byte=position])):
            position += 1
        if position == start:
            return -1
    return position if position == length else -1

def exact_json_int(source: String) -> Optional[Int]:
    var length = source.byte_length()
    var position = 0
    var negative = False
    if source[byte=position] == "-":
        negative = True
        position += 1
    var digits = String("")
    var fraction_digits = 0
    while position < length and _digit(ord(source[byte=position])):
        digits += String(source[byte=position])
        position += 1
    if position < length and source[byte=position] == ".":
        position += 1
        while position < length and _digit(ord(source[byte=position])):
            digits += String(source[byte=position])
            fraction_digits += 1
            position += 1
    var exponent = 0
    var exponent_negative = False
    if position < length and (source[byte=position] == "e" or source[byte=position] == "E"):
        position += 1
        if source[byte=position] == "+" or source[byte=position] == "-":
            exponent_negative = source[byte=position] == "-"
            position += 1
        while position < length:
            var digit = ord(source[byte=position]) - 48
            if exponent < length + 20:
                exponent = exponent * 10 + digit
                if exponent > length + 20:
                    exponent = length + 20
            position += 1
    if exponent_negative:
        exponent = -exponent
    var shift = exponent - fraction_digits
    var first = 0
    while first < digits.byte_length() and ord(digits[byte=first]) == 48:
        first += 1
    if first == digits.byte_length():
        return Optional[Int](0)
    var significant_length = digits.byte_length() - first
    if shift < 0:
        var remove_count = -shift
        if remove_count >= significant_length:
            return None
        for index in range(digits.byte_length() - remove_count, digits.byte_length()):
            if ord(digits[byte=index]) != 48:
                return None
        significant_length -= remove_count
        shift = 0
    if significant_length + shift > 19:
        return None
    var normalized = String("-") if negative else String("")
    for index in range(first, first + significant_length):
        normalized += String(digits[byte=index])
    for _ in range(shift):
        normalized += "0"
    try:
        return Optional[Int](Int(normalized))
    except:
        return None
