from std.collections import List, Optional
from .types import (
    INPUT_ARRAY,
    INPUT_NULL,
    INPUT_OBJECT,
    InputValue,
    JsonOptions,
    PrimitiveValue,
    ValidationIssue,
    ValidationResult,
)
from .validation import validate_model
from .types import TypejoModel, UnknownFieldPolicy
from .json_numbers import _digit, exact_json_int

struct _JSONParser:
    var source: String
    var options: JsonOptions
    var input: InputValue
    var position: Int
    var line: Int
    var column: Int
    var previous_cr: Bool
    var error: Optional[ValidationIssue]

    def __init__(out self, source: String, options: JsonOptions):
        self.source = source
        self.options = options.copy()
        self.input = InputValue()
        self.position = 0
        self.line = 1
        self.column = 1
        self.previous_cr = False
        self.error = None

    def _current(ref self) -> Int:
        if self.position >= self.source.byte_length():
            return -1
        return ord(self.source[byte=self.position])

    def _advance(mut self) -> Int:
        var code = self._current()
        if code < 0:
            return code
        var character = self.source[byte=self.position]
        self.position += character.byte_length()
        if code == 13:
            self.line += 1
            self.column = 1
            self.previous_cr = True
        elif code == 10:
            if not self.previous_cr:
                self.line += 1
            self.column = 1
            self.previous_cr = False
        else:
            self.column += 1
            self.previous_cr = False
        return code

    def _fail(mut self, code: String, message: String):
        if not self.error:
            var issue = ValidationIssue(code, message)
            issue.set_source_location(self.position, self.line, self.column)
            self.error = Optional[ValidationIssue](issue^)

    def _error_result(mut self) -> ValidationResult[InputValue]:
        var issue = ValidationIssue(self.error.value().code.copy(), self.error.value().message.copy())
        issue.set_source_location(
            self.error.value().source_offset,
            self.error.value().source_line,
            self.error.value().source_column,
        )
        return ValidationResult[InputValue](issue^)

    def _skip_space(mut self):
        while self._current() == 32 or self._current() == 9 or self._current() == 10 or self._current() == 13:
            _ = self._advance()

    def _parse_string(mut self) -> String:
        var result = String("")
        if self._current() != 34:
            self._fail("json_syntax_error", "Expected a JSON string.")
            return result
        _ = self._advance()
        while self._current() >= 0:
            var code = self._current()
            if code == 34:
                _ = self._advance()
                return result^
            if code < 32:
                self._fail("json_syntax_error", "Unescaped control character in JSON string.")
                return result^
            if code == 92:
                _ = self._advance()
                var escape = self._current()
                if escape == 34 or escape == 47 or escape == 92:
                    result += chr(escape)
                    _ = self._advance()
                elif escape == 98:
                    result += chr(8)
                    _ = self._advance()
                elif escape == 102:
                    result += chr(12)
                    _ = self._advance()
                elif escape == 110:
                    result += chr(10)
                    _ = self._advance()
                elif escape == 114:
                    result += chr(13)
                    _ = self._advance()
                elif escape == 116:
                    result += chr(9)
                    _ = self._advance()
                elif escape == 117:
                    _ = self._advance()
                    var first = self._hex4()
                    if self.error:
                        return result^
                    var scalar = first
                    if first >= 55296 and first <= 56319:
                        if self._current() != 92:
                            self._fail("json_syntax_error", "High surrogate must be followed by a low surrogate.")
                            return result^
                        _ = self._advance()
                        if self._current() != 117:
                            self._fail("json_syntax_error", "High surrogate must be followed by a low surrogate.")
                            return result^
                        _ = self._advance()
                        var second = self._hex4()
                        if self.error:
                            return result^
                        if second < 56320 or second > 57343:
                            self._fail("json_syntax_error", "Invalid low surrogate in JSON string.")
                            return result^
                        scalar = 65536 + (first - 55296) * 1024 + second - 56320
                    elif first >= 56320 and first <= 57343:
                        self._fail("json_syntax_error", "Unpaired low surrogate in JSON string.")
                        return result^
                    result += chr(scalar)
                else:
                    self._fail("json_syntax_error", "Invalid escape sequence in JSON string.")
                    return result^
            else:
                var start = self.position
                _ = self._advance()
                result += String(self.source[byte=start:self.position])
        self._fail("json_syntax_error", "Unterminated JSON string.")
        return result^

    def _hex4(mut self) -> Int:
        var value = 0
        for _ in range(4):
            var code = self._current()
            var digit = -1
            if code >= 48 and code <= 57:
                digit = code - 48
            elif code >= 65 and code <= 70:
                digit = code - 55
            elif code >= 97 and code <= 102:
                digit = code - 87
            if digit < 0:
                self._fail("json_syntax_error", "Invalid Unicode escape in JSON string.")
                return 0
            value = value * 16 + digit
            _ = self._advance()
        return value

    def _number_token(mut self) -> String:
        var start = self.position
        if self._current() == 45:
            _ = self._advance()
        if self._current() == 48:
            _ = self._advance()
            if _digit(self._current()):
                self._fail("json_syntax_error", "Leading zeros are not allowed in JSON numbers.")
                return String("")
        elif _digit(self._current()):
            while _digit(self._current()):
                _ = self._advance()
        else:
            self._fail("json_syntax_error", "Invalid JSON number.")
            return String("")
        if self._current() == 46:
            _ = self._advance()
            if not _digit(self._current()):
                self._fail("json_syntax_error", "A decimal point must be followed by a digit.")
                return String("")
            while _digit(self._current()):
                _ = self._advance()
        if self._current() == 69 or self._current() == 101:
            _ = self._advance()
            if self._current() == 43 or self._current() == 45:
                _ = self._advance()
            if not _digit(self._current()):
                self._fail("json_syntax_error", "An exponent must contain at least one digit.")
                return String("")
            while _digit(self._current()):
                _ = self._advance()
        return String(self.source[byte=start:self.position])

    def _primitive(mut self, parent: Int, key: String) -> Bool:
        var code = self._current()
        if code == 34:
            var value = self._parse_string()
            if self.error:
                return False
            _ = self.input.add_primitive(parent, key, PrimitiveValue(value^))
            return True
        if code == 116 or code == 102 or code == 110:
            var literal = String("true") if code == 116 else String("false") if code == 102 else String("null")
            for index in range(literal.byte_length()):
                if self._current() != ord(literal[byte=index]):
                    self._fail("json_syntax_error", "Invalid JSON literal.")
                    return False
                _ = self._advance()
            if literal == "null":
                _ = self.input.add_null(parent, key)
            else:
                _ = self.input.add_primitive(parent, key, PrimitiveValue(literal == "true"))
            return True
        if code == 45 or _digit(code):
            var token = self._number_token()
            if self.error:
                return False
            var exact = exact_json_int(token)
            var primitive: PrimitiveValue
            if exact:
                primitive = PrimitiveValue(exact.value())
            else:
                var number: Float64
                try:
                    number = Float64(token)
                except:
                    number = Float64(0.0)
                primitive = PrimitiveValue(number)
            _ = self.input.add_json_number(parent, key, primitive, token^)
            return True
        self._fail("json_syntax_error", "Expected a JSON value.")
        return False

    def _parse_value(mut self, parent: Int, key: String, depth: Int) -> Bool:
        self._skip_space()
        if self.error:
            return False
        if self._current() == 123:
            if depth > self.options.max_depth:
                self._fail("json_limit_exceeded", "Maximum JSON nesting depth exceeded.")
                return False
            var node = self.input.add_object(parent, key)
            return self._parse_object(node, depth)
        if self._current() == 91:
            if depth > self.options.max_depth:
                self._fail("json_limit_exceeded", "Maximum JSON nesting depth exceeded.")
                return False
            var node = self.input.add_array(parent, key)
            return self._parse_array(node, depth)
        return self._primitive(parent, key)

    def _parse_object(mut self, node: Int, depth: Int) -> Bool:
        _ = self._advance()
        self._skip_space()
        if self._current() == 125:
            _ = self._advance()
            return True
        var count = 0
        while not self.error:
            if self._current() != 34:
                self._fail("json_syntax_error", "Expected a quoted object key.")
                return False
            var key = self._parse_string()
            if self.error:
                return False
            if self.input.find_field(node, key):
                self._fail("json_duplicate_key", "Duplicate object member names are not supported.")
                return False
            self._skip_space()
            if self._current() != 58:
                self._fail("json_syntax_error", "Expected ':' after object key.")
                return False
            _ = self._advance()
            count += 1
            if count > self.options.max_collection_items:
                self._fail("json_limit_exceeded", "Maximum object member count exceeded.")
                return False
            if not self._parse_value(node, key^, depth + 1):
                return False
            self._skip_space()
            if self._current() == 125:
                _ = self._advance()
                return True
            if self._current() != 44:
                self._fail("json_syntax_error", "Expected ',' or '}' after object member.")
                return False
            _ = self._advance()
            self._skip_space()
        return False

    def _parse_array(mut self, node: Int, depth: Int) -> Bool:
        _ = self._advance()
        self._skip_space()
        if self._current() == 93:
            _ = self._advance()
            return True
        var count = 0
        while not self.error:
            count += 1
            if count > self.options.max_collection_items:
                self._fail("json_limit_exceeded", "Maximum array item count exceeded.")
                return False
            if not self._parse_value(node, "", depth + 1):
                return False
            self._skip_space()
            if self._current() == 93:
                _ = self._advance()
                return True
            if self._current() != 44:
                self._fail("json_syntax_error", "Expected ',' or ']' after array item.")
                return False
            _ = self._advance()
            self._skip_space()
        return False

    def parse(mut self) -> ValidationResult[InputValue]:
        if self.options.max_input_bytes < 0 or self.options.max_depth < 0 or self.options.max_collection_items < 0 or self.options.max_issues < 1:
            return ValidationResult[InputValue](ValidationIssue("invalid_json_options", "JSON limits must be non-negative and max_issues must be positive."))
        if self.source.byte_length() > self.options.max_input_bytes:
            var issue = ValidationIssue("json_limit_exceeded", "Maximum JSON input size exceeded.")
            issue.set_source_location(0, 1, 1)
            return ValidationResult[InputValue](issue^)
        self._skip_space()
        var root_kind = self._current()
        if root_kind == 123:
            self.input = InputValue(INPUT_OBJECT)
            if not self._parse_object(0, 0):
                return self._error_result()
        elif root_kind == 91:
            self.input = InputValue(INPUT_ARRAY)
            if not self._parse_array(0, 0):
                return self._error_result()
        elif root_kind == 34:
            var value = self._parse_string()
            if self.error:
                return self._error_result()
            self.input = InputValue(PrimitiveValue(value^))
        elif root_kind == 110:
            if not self._primitive_root_literal("null"):
                return self._error_result()
            self.input = InputValue(INPUT_NULL)
        elif root_kind == 116 or root_kind == 102:
            var literal = String("true") if root_kind == 116 else String("false")
            if not self._primitive_root_literal(literal):
                return self._error_result()
            self.input = InputValue(PrimitiveValue(literal == "true"))
        elif root_kind == 45 or _digit(root_kind):
            var token = self._number_token()
            if self.error:
                return self._error_result()
            var exact = exact_json_int(token)
            if exact:
                self.input = InputValue(PrimitiveValue(exact.value()))
            else:
                var number: Float64
                try:
                    number = Float64(token)
                except:
                    number = Float64(0.0)
                self.input = InputValue(PrimitiveValue(number))
            self.input.nodes[0].json_number = Optional[String](token^)
        else:
            self._fail("json_syntax_error", "Expected a JSON value.")
            return self._error_result()
        self.input.is_json = True
        self.input.coerce_numeric_strings = self.options.coerce_numeric_strings
        self._skip_space()
        if self._current() >= 0:
            self._fail("json_syntax_error", "Unexpected content after JSON value.")
            return self._error_result()
        if not self.input.is_well_formed():
            return ValidationResult[InputValue](ValidationIssue("invalid_input", "Parsed JSON tree is malformed."))
        return ValidationResult[InputValue](self.input.copy())

    def _primitive_root_literal(mut self, literal: String) -> Bool:
        for index in range(literal.byte_length()):
            if self._current() != ord(literal[byte=index]):
                self._fail("json_syntax_error", "Invalid JSON literal.")
                return False
            _ = self._advance()
        return True

def parse_json(source: String, options: JsonOptions = JsonOptions()) -> ValidationResult[InputValue]:
    var parser = _JSONParser(source, options)
    return parser.parse()

def validate_json[T: TypejoModel](
    source: String,
    options: JsonOptions = JsonOptions(),
    unknown_fields: UnknownFieldPolicy = UnknownFieldPolicy.reject(),
) -> ValidationResult[T]:
    var parsed = parse_json(source, options)
    if not parsed.is_ok():
        return ValidationResult[T](parsed.issues())
    var input = parsed.value()
    var result = validate_model[T](input, input.root(), unknown_fields)
    if result.is_ok():
        return result^
    var issues = result.issues()
    if len(issues) > options.max_issues:
        var limited = List[ValidationIssue]()
        for index in range(options.max_issues - 1):
            var issue = ValidationIssue(issues[index].code.copy(), issues[index].message.copy())
            issue.path = issues[index].path.copy()
            for segment in range(len(issues[index].path_segments)):
                issue.path_segments.append(issues[index].path_segments[segment].copy())
            limited.append(issue^)
        limited.append(ValidationIssue("too_many_issues", "Maximum validation issue count exceeded."))
        return ValidationResult[T](limited^)
    return result^
