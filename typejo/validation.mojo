from std.memory import bitcast
from std.utils.numerics import isfinite
from .types import Constraints, PrimitiveValue, ValidationIssue, ValidationResult

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
        var number: Float64 = 0.0
        if input.isa[Float4_e2m1fn]():
            # Decode the four-bit format because Mojo 1.1 has no CPU conversion for it.
            var paired = input[Float4_e2m1fn].join(input[Float4_e2m1fn])
            var bits = Int(bitcast[.uint8, 1](paired)[0]) & 15
            if bits & 7 == 7:
                return ValidationResult[T](input, ValidationIssue("non_finite", "Number must be finite."))
            var magnitude: Float64 = 0.0
            if bits & 7 == 1:
                magnitude = 0.5
            elif bits & 7 == 2:
                magnitude = 1.0
            elif bits & 7 == 3:
                magnitude = 1.5
            elif bits & 7 == 4:
                magnitude = 2.0
            elif bits & 7 == 5:
                magnitude = 3.0
            elif bits & 7 == 6:
                magnitude = 4.0
            number = magnitude if bits & 8 == 0 else -magnitude
        elif input.isa[Float16]():
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
