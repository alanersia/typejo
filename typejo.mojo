from std.collections import List, Optional
from std.utils.numerics import isfinite
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

    def __init__(out self, minimum: Int, maximum: Int = Int.MAX):
        self.minimum = NumberBound(minimum)
        self.maximum = NumberBound(maximum)
        self.min_length = None
        self.max_length = None

    def __init__(out self, *, maximum: Int):
        self.minimum = None
        self.maximum = NumberBound(maximum)
        self.min_length = None
        self.max_length = None

    def __init__(out self, minimum: Float64, maximum: Float64 = Float64.MAX):
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

def validate[T: Copyable & Deinitable](
    mut input: PrimitiveValue,
    mut constraints: Constraints,
) -> ValidationResult[T]:
    if not input.isa[T]():
        return ValidationResult[T](input, ValidationIssue("type_mismatch", "Input does not match requested type."))

    if input.isa[String]():
        var value = input[String]
        var length = value.count_codepoints()
        if constraints.minimum or constraints.maximum:
            return ValidationResult[T](input, ValidationIssue("invalid_constraints", "Numeric bounds cannot be used for String."))
        if constraints.min_length and constraints.min_length.value() < 0 or constraints.max_length and constraints.max_length.value() < 0:
            return ValidationResult[T](input, ValidationIssue("invalid_constraints", "String length bounds must be non-negative."))
        if constraints.min_length and constraints.max_length and constraints.min_length.value() > constraints.max_length.value():
            return ValidationResult[T](input, ValidationIssue("invalid_constraints", "String length constraints are invalid."))
        if constraints.min_length and length < constraints.min_length.value():
            return ValidationResult[T](input, ValidationIssue("too_short", "String is shorter than the minimum length."))
        if constraints.max_length and length > constraints.max_length.value():
            return ValidationResult[T](input, ValidationIssue("too_long", "String is longer than the maximum length."))
    elif input.isa[Int]():
        var value = input[Int]
        if constraints.min_length or constraints.max_length:
            return ValidationResult[T](input, ValidationIssue("invalid_constraints", "Integer constraints must use integer numeric bounds."))
        if constraints.minimum and not constraints.minimum.value().isa[Int]() or constraints.maximum and not constraints.maximum.value().isa[Int]():
            return ValidationResult[T](input, ValidationIssue("invalid_constraints", "Integer constraints must use integer numeric bounds."))
        if constraints.minimum and constraints.maximum and constraints.minimum.value()[Int] > constraints.maximum.value()[Int]:
            return ValidationResult[T](input, ValidationIssue("invalid_constraints", "Numeric minimum exceeds maximum."))
        if constraints.minimum and value < constraints.minimum.value()[Int]:
            return ValidationResult[T](input, ValidationIssue("below_minimum", "Number is below the minimum."))
        if constraints.maximum and value > constraints.maximum.value()[Int]:
            return ValidationResult[T](input, ValidationIssue("above_maximum", "Number is above the maximum."))
    elif input.isa[Bool]():
        if constraints.minimum or constraints.maximum or constraints.min_length or constraints.max_length:
            return ValidationResult[T](input, ValidationIssue("invalid_constraints", "Bool does not accept constraints."))
    else:
        # shortcut: Float4 cannot be compared or widened on Mojo 1.1 CPU, upgrade when the compiler exposes CPU scalar operations.
        if input.isa[Float4_e2m1fn]():
            return ValidationResult[T](input, ValidationIssue("unsupported_type", "Float4_e2m1fn cannot be validated on the Mojo 1.1 CPU runtime."))
        var number: Float64 = 0.0
        if input.isa[Float16]():
            number = Float64(input[Float16])
        elif input.isa[Float32]():
            number = Float64(input[Float32])
        elif input.isa[Float64]():
            number = input[Float64]
        elif input.isa[BFloat16]():
            number = Float64(input[BFloat16])
        elif input.isa[Float8_e4m3fn]():
            number = Float64(input[Float8_e4m3fn])
        elif input.isa[Float8_e4m3fnuz]():
            number = Float64(input[Float8_e4m3fnuz])
        elif input.isa[Float8_e5m2]():
            number = Float64(input[Float8_e5m2])
        elif input.isa[Float8_e5m2fnuz]():
            number = Float64(input[Float8_e5m2fnuz])
        elif input.isa[Float8_e8m0fnu]():
            number = Float64(input[Float8_e8m0fnu])
        if constraints.min_length or constraints.max_length:
            return ValidationResult[T](input, ValidationIssue("invalid_constraints", "Floating-point bounds must use Float64."))
        if (constraints.minimum and not constraints.minimum.value().isa[Float64]()) or (constraints.maximum and not constraints.maximum.value().isa[Float64]()):
            return ValidationResult[T](input, ValidationIssue("invalid_constraints", "Floating-point bounds must use Float64."))
        if constraints.minimum and not isfinite(constraints.minimum.value()[Float64]) or constraints.maximum and not isfinite(constraints.maximum.value()[Float64]):
            return ValidationResult[T](input, ValidationIssue("invalid_constraints", "Floating-point bounds must be finite."))
        if constraints.minimum and constraints.maximum and constraints.minimum.value()[Float64] > constraints.maximum.value()[Float64]:
            return ValidationResult[T](input, ValidationIssue("invalid_constraints", "Numeric minimum exceeds maximum."))
        if not isfinite(number):
            return ValidationResult[T](input, ValidationIssue("non_finite", "Number must be finite."))
        if constraints.minimum and number < constraints.minimum.value()[Float64]:
            return ValidationResult[T](input, ValidationIssue("below_minimum", "Number is below the minimum."))
        if constraints.maximum and number > constraints.maximum.value()[Float64]:
            return ValidationResult[T](input, ValidationIssue("above_maximum", "Number is above the maximum."))

    return ValidationResult[T](input)

def validate[T: Copyable & Deinitable](mut input: PrimitiveValue) -> ValidationResult[T]:
    var constraints = Constraints()
    return validate[T](input, constraints)
