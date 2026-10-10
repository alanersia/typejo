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

struct ValidationIssue:
    var code: String
    var path: String
    var message: String

    def __init__(out self, code: String, message: String):
        self.code = code
        self.path = ""
        self.message = message

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
    var result_input: PrimitiveValue
    var success: Bool
    var result_issues: List[ValidationIssue]

    def __init__(out self, mut input: PrimitiveValue):
        self.result_input = input.copy()
        self.success = True
        self.result_issues = List[ValidationIssue]()

    def __init__(out self, mut input: PrimitiveValue, var issue: ValidationIssue):
        self.result_input = input.copy()
        self.success = False
        self.result_issues = List[ValidationIssue]()
        self.result_issues.append(issue^)

    def is_ok(self) -> Bool:
        return self.success

    def value(mut self) -> Self.T:
        return self.result_input[Self.T].copy()

    def issues(ref self) -> List[ValidationIssue]:
        var copies = List[ValidationIssue]()
        for i in range(len(self.result_issues)):
            var issue = ValidationIssue(
                self.result_issues[i].code.copy(),
                self.result_issues[i].message.copy(),
            )
            issue.path = self.result_issues[i].path.copy()
            copies.append(issue^)
        return copies^
