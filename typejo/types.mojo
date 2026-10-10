from std.collections import List, Optional
from std.utils import Variant

comptime PrimitiveValue = Variant[
    String,
    Int,
    Bool,
    Float16,
    Float32,
    Float64,
    BFloat16,
    Float4_e2m1fn,
    Float8_e4m3fn,
    Float8_e4m3fnuz,
    Float8_e5m2,
    Float8_e5m2fnuz,
    Float8_e8m0fnu,
]

comptime NumberBound = Variant[Int, Float64]
comptime ValidationPathSegment = Variant[String, Int]

comptime INPUT_NULL = 0
comptime INPUT_PRIMITIVE = 1
comptime INPUT_OBJECT = 2
comptime INPUT_ARRAY = 3

struct InputNode(Copyable):
    var parent: Int
    var key: String
    var kind: Int
    var primitive: Optional[PrimitiveValue]
    var json_number: Optional[String]

    def __init__(out self, parent: Int, key: String, kind: Int):
        self.parent = parent
        self.key = key
        self.kind = kind
        self.primitive = None
        self.json_number = None

    def __init__(out self, parent: Int, key: String, primitive: PrimitiveValue):
        self.parent = parent
        self.key = key
        self.kind = INPUT_PRIMITIVE
        self.primitive = Optional[PrimitiveValue](primitive.copy())
        self.json_number = None

struct InputValue(Copyable):
    var nodes: List[InputNode]
    var is_json: Bool
    var coerce_numeric_strings: Bool

    def __init__(out self):
        self.nodes = List[InputNode]()
        var root = InputNode(-1, "", INPUT_OBJECT)
        self.nodes.append(root^)
        self.is_json = False
        self.coerce_numeric_strings = False

    def __init__(out self, root_kind: Int):
        self.nodes = List[InputNode]()
        var root = InputNode(-1, "", root_kind)
        self.nodes.append(root^)
        self.is_json = True
        self.coerce_numeric_strings = False

    def __init__(out self, root_value: PrimitiveValue):
        self.nodes = List[InputNode]()
        var root = InputNode(-1, "", root_value)
        self.nodes.append(root^)
        self.is_json = True
        self.coerce_numeric_strings = False

    def root(self) -> Int:
        return 0

    def node_count(ref self) -> Int:
        return len(self.nodes)

    def is_well_formed(ref self) -> Bool:
        if len(self.nodes) == 0 or self.nodes[0].parent != -1 or self.nodes[0].key != "":
            return False
        if self.nodes[0].kind < INPUT_NULL or self.nodes[0].kind > INPUT_ARRAY:
            return False
        if self.nodes[0].kind == INPUT_PRIMITIVE and not self.nodes[0].primitive:
            return False
        if self.nodes[0].kind != INPUT_PRIMITIVE and self.nodes[0].primitive:
            return False
        for index in range(1, len(self.nodes)):
            var parent = self.nodes[index].parent
            if parent < 0 or parent >= index:
                return False
            if self.nodes[parent].kind == INPUT_OBJECT:
                if self.nodes[index].key == "":
                    return False
                for previous in range(1, index):
                    if self.nodes[previous].parent == parent and self.nodes[previous].key == self.nodes[index].key:
                        return False
            elif self.nodes[parent].kind == INPUT_ARRAY:
                if self.nodes[index].key != "":
                    return False
            else:
                return False
            if self.nodes[index].kind < INPUT_NULL or self.nodes[index].kind > INPUT_ARRAY:
                return False
            if self.nodes[index].kind == INPUT_PRIMITIVE and not self.nodes[index].primitive:
                return False
            if self.nodes[index].kind != INPUT_PRIMITIVE and self.nodes[index].primitive:
                return False
        return True

    def add_object(mut self, parent: Int, key: String) -> Int:
        var node = InputNode(parent, key, INPUT_OBJECT)
        self.nodes.append(node^)
        return len(self.nodes) - 1

    def add_array(mut self, parent: Int, key: String) -> Int:
        var node = InputNode(parent, key, INPUT_ARRAY)
        self.nodes.append(node^)
        return len(self.nodes) - 1

    def add_null(mut self, parent: Int, key: String) -> Int:
        var node = InputNode(parent, key, INPUT_NULL)
        self.nodes.append(node^)
        return len(self.nodes) - 1

    def add_primitive(mut self, parent: Int, key: String, value: PrimitiveValue) -> Int:
        var node = InputNode(parent, key, value)
        self.nodes.append(node^)
        return len(self.nodes) - 1

    def add_json_number(mut self, parent: Int, key: String, value: PrimitiveValue, source: String) -> Int:
        var node = InputNode(parent, key, value)
        node.json_number = Optional[String](source)
        self.nodes.append(node^)
        return len(self.nodes) - 1

    def add_json_number_item(mut self, parent: Int, value: PrimitiveValue, source: String) -> Int:
        return self.add_json_number(parent, "", value, source)

    def add_object_item(mut self, parent: Int) -> Int:
        return self.add_object(parent, "")

    def add_array_item(mut self, parent: Int) -> Int:
        return self.add_array(parent, "")

    def add_null_item(mut self, parent: Int) -> Int:
        return self.add_null(parent, "")

    def add_primitive_item(mut self, parent: Int, value: PrimitiveValue) -> Int:
        return self.add_primitive(parent, "", value)

    def kind(ref self, node: Int) -> Int:
        return self.nodes[node].kind

    def key(ref self, node: Int) -> String:
        return self.nodes[node].key.copy()

    def primitive(ref self, node: Int) -> PrimitiveValue:
        return self.nodes[node].primitive.value().copy()

    def find_field(ref self, parent: Int, key: String) -> Optional[Int]:
        for index in range(1, len(self.nodes)):
            if self.nodes[index].parent == parent and self.nodes[index].key == key:
                return Optional[Int](index)
        return None

    def child_count(ref self, parent: Int) -> Int:
        var count = 0
        for index in range(1, len(self.nodes)):
            if self.nodes[index].parent == parent:
                count += 1
        return count

    def child_at(ref self, parent: Int, ordinal: Int) -> Optional[Int]:
        var current = 0
        for index in range(1, len(self.nodes)):
            if self.nodes[index].parent == parent:
                if current == ordinal:
                    return Optional[Int](index)
                current += 1
        return None

    def has_field(ref self, parent: Int, key: String) -> Bool:
        return self.find_field(parent, key).has_value()

    def json_number(ref self, node: Int) -> Optional[String]:
        return self.nodes[node].json_number.copy()

    def permits_numeric_string_coercion(ref self) -> Bool:
        return self.coerce_numeric_strings

struct UnknownFieldPolicy:
    var mode: Int

    def __init__(out self, mode: Int):
        self.mode = mode

    @staticmethod
    def reject() -> Self:
        return Self(0)

    @staticmethod
    def ignore() -> Self:
        return Self(1)

    @staticmethod
    def preserve() -> Self:
        return Self(2)

struct ExtraFields(Copyable):
    var source: InputValue
    var nodes: List[Int]

    def __init__(out self, var source: InputValue, var nodes: List[Int]):
        self.source = source^
        self.nodes = nodes^

    def count(ref self) -> Int:
        return len(self.nodes)

    def key(ref self, index: Int) -> String:
        return self.source.key(self.nodes[index])

    def kind(ref self, index: Int) -> Int:
        return self.source.kind(self.nodes[index])

    def primitive(ref self, index: Int) -> PrimitiveValue:
        return self.source.primitive(self.nodes[index])

    def node(ref self, index: Int) -> Int:
        return self.nodes[index]

    def input(ref self) -> InputValue:
        return self.source.copy()

struct ValidationIssue:
    var code: String
    var path: String
    var message: String
    var path_segments: List[ValidationPathSegment]
    var source_offset: Int
    var source_line: Int
    var source_column: Int

    def __init__(out self, code: String, message: String):
        self.code = code
        self.path = ""
        self.message = message
        self.path_segments = List[ValidationPathSegment]()
        self.source_offset = -1
        self.source_line = -1
        self.source_column = -1

    def set_source_location(mut self, offset: Int, line: Int, column: Int):
        self.source_offset = offset
        self.source_line = line
        self.source_column = column

    def add_field(mut self, field: String):
        if self.path:
            self.path = self.path + "." + field
        else:
            self.path = field.copy()
        self.path_segments.append(ValidationPathSegment(field.copy()))

    def add_index(mut self, index: Int):
        self.path = self.path + "[" + String(index) + "]"
        self.path_segments.append(ValidationPathSegment(index))

    def prepend_field(mut self, field: String):
        if len(self.path_segments) > 0 and self.path_segments[0].isa[Int]():
            self.path = field + self.path
        elif self.path:
            self.path = field + "." + self.path
        else:
            self.path = field.copy()
        self.path_segments.insert(0, ValidationPathSegment(field.copy()))

    def prepend_index(mut self, index: Int):
        var prefix = "[" + String(index) + "]"
        var separator = "."
        if len(self.path_segments) > 0 and self.path_segments[0].isa[Int]():
            separator = ""
        self.path = prefix + (separator + self.path if self.path else "")
        self.path_segments.insert(0, ValidationPathSegment(index))

    def replace_code(mut self, code: String):
        self.code = code.copy()

struct Constraints:
    var minimum: Optional[NumberBound]
    var maximum: Optional[NumberBound]
    var min_length: Optional[Int]
    var max_length: Optional[Int]

    def __init__(out self):
        self.minimum = None
        self.maximum = None
        self.min_length = None
        self.max_length = None

    def __init__(out self, minimum: Int):
        self.minimum = NumberBound(minimum)
        self.maximum = None
        self.min_length = None
        self.max_length = None

    def __init__(out self, minimum: Int, maximum: Int):
        self.minimum = NumberBound(minimum)
        self.maximum = NumberBound(maximum)
        self.min_length = None
        self.max_length = None

    def __init__(out self, *, maximum: Int):
        self.minimum = None
        self.maximum = NumberBound(maximum)
        self.min_length = None
        self.max_length = None

    def __init__(out self, minimum: Float64):
        self.minimum = NumberBound(minimum)
        self.maximum = None
        self.min_length = None
        self.max_length = None

    def __init__(out self, minimum: Float64, maximum: Float64):
        self.minimum = NumberBound(minimum)
        self.maximum = NumberBound(maximum)
        self.min_length = None
        self.max_length = None

    def __init__(out self, *, maximum: Float64):
        self.minimum = None
        self.maximum = NumberBound(maximum)
        self.min_length = None
        self.max_length = None

    def __init__(out self, *, min_length: Optional[Int] = None, max_length: Optional[Int] = None):
        self.minimum = None
        self.maximum = None
        self.min_length = min_length
        self.max_length = max_length

struct ValidationResult[T: Copyable & Deinitable]:
    var result_value: Optional[Self.T]
    var success: Bool
    var result_issues: List[ValidationIssue]

    def __init__(out self, var value: Self.T):
        self.result_value = Optional[Self.T](value^)
        self.success = True
        self.result_issues = List[ValidationIssue]()

    def __init__(out self, var issue: ValidationIssue):
        self.result_value = None
        self.success = False
        self.result_issues = List[ValidationIssue]()
        self.result_issues.append(issue^)

    def __init__(out self, var issues: List[ValidationIssue]):
        self.result_value = None
        self.success = False
        self.result_issues = issues^

    def is_ok(self) -> Bool:
        return self.success

    def value(mut self) -> Self.T:
        return self.result_value.value().copy()

    def value_or(mut self, var default: Self.T) -> Self.T:
        if self.success:
            return self.result_value.value().copy()
        return default^

    def issues(ref self) -> List[ValidationIssue]:
        var copies = List[ValidationIssue]()
        for i in range(len(self.result_issues)):
            var issue = ValidationIssue(
                self.result_issues[i].code.copy(),
                self.result_issues[i].message.copy(),
            )
            issue.path = self.result_issues[i].path.copy()
            issue.source_offset = self.result_issues[i].source_offset
            issue.source_line = self.result_issues[i].source_line
            issue.source_column = self.result_issues[i].source_column
            for segment_index in range(len(self.result_issues[i].path_segments)):
                issue.path_segments.append(self.result_issues[i].path_segments[segment_index].copy())
            copies.append(issue^)
        return copies^

    def add_field(mut self, field: String):
        for i in range(len(self.result_issues)):
            self.result_issues[i].add_field(field.copy())

    def add_index(mut self, index: Int):
        for i in range(len(self.result_issues)):
            self.result_issues[i].add_index(index)

    def prepend_field(mut self, field: String):
        for i in range(len(self.result_issues)):
            self.result_issues[i].prepend_field(field.copy())

    def prepend_index(mut self, index: Int):
        for i in range(len(self.result_issues)):
            self.result_issues[i].prepend_index(index)

    def replace_issue_code(mut self, code: String):
        for i in range(len(self.result_issues)):
            self.result_issues[i].replace_code(code)

    def append_issues(mut self, var issues: List[ValidationIssue]):
        self.result_issues.extend(issues^)

@fieldwise_init
struct JsonOptions(Copyable):
    var max_input_bytes: Int
    var max_depth: Int
    var max_collection_items: Int
    var max_issues: Int
    var coerce_numeric_strings: Bool

    def __init__(out self):
        self.max_input_bytes = 1_048_576
        self.max_depth = 128
        self.max_collection_items = 10_000
        self.max_issues = 100
        self.coerce_numeric_strings = False


trait TypejoModel(Copyable, Deinitable):
    @staticmethod
    def supports_extras() -> Bool:
        ...

    @staticmethod
    def from_input(
        ref input: InputValue, node: Int, unknown_fields: UnknownFieldPolicy
    ) -> ValidationResult[Self]:
        ...
