from std.collections import List, Optional
from std.memory import bitcast
from std.utils.numerics import isfinite
from .types import (
    Constraints,
    ExtraFields,
    InputValue,
    INPUT_ARRAY,
    INPUT_OBJECT,
    INPUT_NULL,
    INPUT_PRIMITIVE,
    PrimitiveValue,
    TypejoModel,
    UnknownFieldPolicy,
    ValidationIssue,
    ValidationResult,
)
from .json_numbers import exact_json_int, json_number_end

def validate[T: Copyable & Deinitable](
    mut input: PrimitiveValue,
    mut constraints: Constraints,
) -> ValidationResult[T]:
    if not input.isa[T]():
        return ValidationResult[T](ValidationIssue("type_mismatch", "Input does not match requested type."))

    if input.isa[String]():
        var value = input[String]
        var length = value.count_codepoints()
        if constraints.minimum or constraints.maximum:
            return ValidationResult[T](ValidationIssue("invalid_constraints", "Numeric bounds cannot be used for String."))
        if constraints.min_length and constraints.min_length.value() < 0 or constraints.max_length and constraints.max_length.value() < 0:
            return ValidationResult[T](ValidationIssue("invalid_constraints", "String length bounds must be non-negative."))
        if constraints.min_length and constraints.max_length and constraints.min_length.value() > constraints.max_length.value():
            return ValidationResult[T](ValidationIssue("invalid_constraints", "String length constraints are invalid."))
        if constraints.min_length and length < constraints.min_length.value():
            return ValidationResult[T](ValidationIssue("too_short", "String is shorter than the minimum length."))
        if constraints.max_length and length > constraints.max_length.value():
            return ValidationResult[T](ValidationIssue("too_long", "String is longer than the maximum length."))
    elif input.isa[Int]():
        var value = input[Int]
        if constraints.min_length or constraints.max_length:
            return ValidationResult[T](ValidationIssue("invalid_constraints", "Integer constraints must use integer numeric bounds."))
        if constraints.minimum and not constraints.minimum.value().isa[Int]() or constraints.maximum and not constraints.maximum.value().isa[Int]():
            return ValidationResult[T](ValidationIssue("invalid_constraints", "Integer constraints must use integer numeric bounds."))
        if constraints.minimum and constraints.maximum and constraints.minimum.value()[Int] > constraints.maximum.value()[Int]:
            return ValidationResult[T](ValidationIssue("invalid_constraints", "Numeric minimum exceeds maximum."))
        if constraints.minimum and value < constraints.minimum.value()[Int]:
            return ValidationResult[T](ValidationIssue("below_minimum", "Number is below the minimum."))
        if constraints.maximum and value > constraints.maximum.value()[Int]:
            return ValidationResult[T](ValidationIssue("above_maximum", "Number is above the maximum."))
    elif input.isa[Bool]():
        if constraints.minimum or constraints.maximum or constraints.min_length or constraints.max_length:
            return ValidationResult[T](ValidationIssue("invalid_constraints", "Bool does not accept constraints."))
    else:
        var number: Float64 = 0.0
        if input.isa[Float4_e2m1fn]():
            # Decode the four-bit format because Mojo 1.1 has no CPU conversion for it.
            var paired = input[Float4_e2m1fn].join(input[Float4_e2m1fn])
            var bits = Int(bitcast[.uint8, 1](paired)[0]) & 15
            if bits & 7 == 7:
                return ValidationResult[T](ValidationIssue("non_finite", "Number must be finite."))
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
            return ValidationResult[T](ValidationIssue("invalid_constraints", "Floating-point bounds must use Float64."))
        if (constraints.minimum and not constraints.minimum.value().isa[Float64]()) or (constraints.maximum and not constraints.maximum.value().isa[Float64]()):
            return ValidationResult[T](ValidationIssue("invalid_constraints", "Floating-point bounds must use Float64."))
        if constraints.minimum and not isfinite(constraints.minimum.value()[Float64]) or constraints.maximum and not isfinite(constraints.maximum.value()[Float64]):
            return ValidationResult[T](ValidationIssue("invalid_constraints", "Floating-point bounds must be finite."))
        if constraints.minimum and constraints.maximum and constraints.minimum.value()[Float64] > constraints.maximum.value()[Float64]:
            return ValidationResult[T](ValidationIssue("invalid_constraints", "Numeric minimum exceeds maximum."))
        if not isfinite(number):
            return ValidationResult[T](ValidationIssue("non_finite", "Number must be finite."))
        if constraints.minimum and number < constraints.minimum.value()[Float64]:
            return ValidationResult[T](ValidationIssue("below_minimum", "Number is below the minimum."))
        if constraints.maximum and number > constraints.maximum.value()[Float64]:
            return ValidationResult[T](ValidationIssue("above_maximum", "Number is above the maximum."))

    return ValidationResult[T](input[T].copy())

def validate[T: Copyable & Deinitable](mut input: PrimitiveValue) -> ValidationResult[T]:
    var constraints = Constraints()
    return validate[T](input, constraints)

def _validate_json_number[T: Copyable & Deinitable](
    source: String,
    mut constraints: Constraints,
) -> ValidationResult[T]:
    if json_number_end(source) < 0:
        return ValidationResult[T](ValidationIssue("type_mismatch", "Value is not a JSON number."))
    if T == Int:
        var exact = exact_json_int(source)
        if not exact:
            return ValidationResult[T](ValidationIssue("numeric_out_of_range", "JSON number must be an exact, representable integer."))
        var primitive = PrimitiveValue(exact.value())
        return validate[T](primitive, constraints)
    var number: Float64
    try:
        number = Float64(source)
    except:
        return ValidationResult[T](ValidationIssue("numeric_out_of_range", "JSON number is outside the supported range."))
    if not isfinite(number):
        return ValidationResult[T](ValidationIssue("non_finite", "Number must be finite."))
    comptime if T == Float64:
        var primitive = PrimitiveValue(number)
        return validate[T](primitive, constraints)
    elif T == Float32:
        var primitive = PrimitiveValue(Float32(number))
        return validate[T](primitive, constraints)
    elif T == Float16:
        var primitive = PrimitiveValue(Float16(number))
        return validate[T](primitive, constraints)
    elif T == BFloat16:
        var primitive = PrimitiveValue(BFloat16(number))
        return validate[T](primitive, constraints)
    elif T == Float4_e2m1fn:
        var primitive = PrimitiveValue(Float4_e2m1fn(number))
        return validate[T](primitive, constraints)
    elif T == Float8_e4m3fn:
        var primitive = PrimitiveValue(Float8_e4m3fn(number))
        return validate[T](primitive, constraints)
    elif T == Float8_e4m3fnuz:
        var primitive = PrimitiveValue(Float8_e4m3fnuz(number))
        return validate[T](primitive, constraints)
    elif T == Float8_e5m2:
        var primitive = PrimitiveValue(Float8_e5m2(number))
        return validate[T](primitive, constraints)
    elif T == Float8_e5m2fnuz:
        var primitive = PrimitiveValue(Float8_e5m2fnuz(number))
        return validate[T](primitive, constraints)
    elif T == Float8_e8m0fnu:
        var primitive = PrimitiveValue(Float8_e8m0fnu(number))
        return validate[T](primitive, constraints)
    else:
        return ValidationResult[T](ValidationIssue("type_mismatch", "JSON numbers require a numeric model field."))

def _validate_input_primitive[T: Copyable & Deinitable](
    ref input: InputValue,
    node: Int,
    mut constraints: Constraints,
) -> ValidationResult[T]:
    var json_number = input.json_number(node)
    if json_number:
        return _validate_json_number[T](json_number.value(), constraints)
    var primitive = input.primitive(node)
    if input.permits_numeric_string_coercion() and primitive.isa[String]() and (T == Int or T == Float64):
        var source = primitive[String]
        return _validate_json_number[T](source, constraints)
    return validate[T](primitive, constraints)

def _is_model_field[T: TypejoModel](field_name: String) -> Bool:
    comptime names = reflect[T].field_names()
    var found = False
    comptime for index in range(reflect[T].field_count()):
        if field_name == String(materialize[names[index]]()):
            found = True
    return found

def collect_extras[T: TypejoModel](ref input: InputValue, node: Int) -> ExtraFields:
    var extra_nodes = List[Int]()
    for ordinal in range(input.child_count(node)):
        var child = input.child_at(node, ordinal).value()
        if not _is_model_field[T](input.key(child)):
            extra_nodes.append(child)
    var source = input.copy()
    return ExtraFields(source^, extra_nodes^)

def validate_model[T: TypejoModel](
    ref input: InputValue,
    node: Int = 0,
    unknown_fields: UnknownFieldPolicy = UnknownFieldPolicy.reject(),
) -> ValidationResult[T]:
    if not input.is_well_formed():
        return ValidationResult[T](
            ValidationIssue("invalid_input", "Input value tree is malformed.")
        )
    if node < 0 or node >= input.node_count() or input.kind(node) != INPUT_OBJECT:
        return ValidationResult[T](
            ValidationIssue("type_mismatch", "Model input must be an object.")
        )

    if unknown_fields.mode < 0 or unknown_fields.mode > 2:
        return ValidationResult[T](
            ValidationIssue("invalid_policy", "Unknown-field policy is invalid.")
        )

    if unknown_fields.mode == 2 and not T.supports_extras():
        return ValidationResult[T](
            ValidationIssue("invalid_model", "Model does not declare typed extra fields.")
        )

    var result = T.from_input(input, node, unknown_fields)
    if unknown_fields.mode != 0:
        return result^

    var issues = result.issues()
    for ordinal in range(input.child_count(node)):
        var child = input.child_at(node, ordinal).value()
        var key = input.key(child)
        if not _is_model_field[T](key):
            var issue = ValidationIssue("unknown_field", "Field is not declared by model.")
            issue.add_field(key)
            issues.append(issue^)
    if len(issues) > 0:
        return ValidationResult[T](issues^)
    return result^

def validate_field[T: Copyable & Deinitable](
    ref input: InputValue,
    node: Int,
    field: String,
    mut constraints: Constraints,
    default: Optional[PrimitiveValue] = None,
) -> ValidationResult[T]:
    if not input.is_well_formed():
        return ValidationResult[T](
            ValidationIssue("invalid_input", "Input value tree is malformed.")
        )
    if node < 0 or node >= input.node_count() or input.kind(node) != INPUT_OBJECT:
        return ValidationResult[T](
            ValidationIssue("type_mismatch", "Field parent must be an object.")
        )
    var child = input.find_field(node, field)
    if not child:
        if default:
            var default_value = default.value().copy()
            var result = validate[T](default_value, constraints)
            if not result.is_ok():
                result.replace_issue_code("invalid_default")
            result.add_field(field.copy())
            return result^
        var issue = ValidationIssue("missing_required", "Required field is missing.")
        issue.add_field(field.copy())
        return ValidationResult[T](issue^)

    var child_node = child.value()
    if input.kind(child_node) == INPUT_NULL:
        var issue = ValidationIssue("null_not_allowed", "Null is not allowed for this field.")
        issue.add_field(field.copy())
        return ValidationResult[T](issue^)
    if input.kind(child_node) != INPUT_PRIMITIVE:
        var issue = ValidationIssue("type_mismatch", "Field must contain a primitive value.")
        issue.add_field(field.copy())
        return ValidationResult[T](issue^)

    var result = _validate_input_primitive[T](input, child_node, constraints)
    result.add_field(field.copy())
    return result^

def validate_optional_field[T: Copyable & Deinitable](
    ref input: InputValue,
    node: Int,
    field: String,
    mut constraints: Constraints,
    *,
    required: Bool = False,
    nullable: Bool = False,
    default: Optional[PrimitiveValue] = None,
) -> ValidationResult[Optional[T]]:
    if not input.is_well_formed():
        return ValidationResult[Optional[T]](
            ValidationIssue("invalid_input", "Input value tree is malformed.")
        )
    if node < 0 or node >= input.node_count() or input.kind(node) != INPUT_OBJECT:
        return ValidationResult[Optional[T]](
            ValidationIssue("type_mismatch", "Field parent must be an object.")
        )
    var child = input.find_field(node, field)
    if not child:
        if default:
            var default_value = default.value().copy()
            var checked = validate[T](default_value, constraints)
            if not checked.is_ok():
                checked.replace_issue_code("invalid_default")
                checked.add_field(field.copy())
                var issues = checked.issues()
                return ValidationResult[Optional[T]](issues^)
            var present = Optional[T](checked.value())
            return ValidationResult[Optional[T]](present^)
        if required:
            var issue = ValidationIssue("missing_required", "Required field is missing.")
            issue.add_field(field.copy())
            return ValidationResult[Optional[T]](issue^)
        var absent: Optional[T] = None
        return ValidationResult[Optional[T]](absent^)

    var child_node = child.value()
    if input.kind(child_node) == INPUT_NULL:
        if nullable:
            var absent: Optional[T] = None
            return ValidationResult[Optional[T]](absent^)
        var issue = ValidationIssue("null_not_allowed", "Null is not allowed for this field.")
        issue.add_field(field.copy())
        return ValidationResult[Optional[T]](issue^)
    if input.kind(child_node) != INPUT_PRIMITIVE:
        var issue = ValidationIssue("type_mismatch", "Field must contain a primitive value.")
        issue.add_field(field.copy())
        return ValidationResult[Optional[T]](issue^)

    var checked = _validate_input_primitive[T](input, child_node, constraints)
    if not checked.is_ok():
        checked.add_field(field.copy())
        var issues = checked.issues()
        return ValidationResult[Optional[T]](issues^)
    var present = Optional[T](checked.value())
    return ValidationResult[Optional[T]](present^)

def _collection_constraint_error(count: Int, mut constraints: Constraints) -> Int:
    if constraints.minimum or constraints.maximum:
        return 1
    if (constraints.min_length and constraints.min_length.value() < 0) or (
        constraints.max_length and constraints.max_length.value() < 0
    ):
        return 2
    if constraints.min_length and constraints.max_length and constraints.min_length.value() > constraints.max_length.value():
        return 3
    if constraints.min_length and count < constraints.min_length.value():
        return 4
    if constraints.max_length and count > constraints.max_length.value():
        return 5
    return 0

def _collection_constraint_issue(code: Int) -> ValidationIssue:
    if code == 4:
        return ValidationIssue("too_few_items", "Collection has fewer items than the minimum length.")
    if code == 5:
        return ValidationIssue("too_many_items", "Collection has more items than the maximum length.")
    if code == 2:
        return ValidationIssue("invalid_constraints", "Collection length bounds must be non-negative.")
    if code == 3:
        return ValidationIssue("invalid_constraints", "Collection minimum length exceeds maximum.")
    return ValidationIssue("invalid_constraints", "Collections do not accept numeric bounds.")

def validate_primitive_array[T: Copyable & Deinitable](
    ref input: InputValue,
    node: Int,
    mut constraints: Constraints,
) -> ValidationResult[List[T]]:
    if not input.is_well_formed():
        return ValidationResult[List[T]](
            ValidationIssue("invalid_input", "Input value tree is malformed.")
        )
    if node < 0 or node >= input.node_count() or input.kind(node) != INPUT_ARRAY:
        return ValidationResult[List[T]](
            ValidationIssue("type_mismatch", "Input must be an array.")
        )
    var count = input.child_count(node)
    var constraint_error = _collection_constraint_error(count, constraints)
    if constraint_error != 0:
        var issue = _collection_constraint_issue(constraint_error)
        return ValidationResult[List[T]](issue^)

    var values = List[T]()
    var issues = List[ValidationIssue]()
    for index in range(count):
        var child = input.child_at(node, index).value()
        if input.kind(child) != INPUT_PRIMITIVE:
            var issue = ValidationIssue("type_mismatch", "Array item must contain a primitive value.")
            issue.add_index(index)
            issues.append(issue^)
            continue
        var no_constraints = Constraints()
        var result = _validate_input_primitive[T](input, child, no_constraints)
        if result.is_ok():
            values.append(result.value())
        else:
            result.add_index(index)
            var item_issues = result.issues()
            issues.extend(item_issues^)
    if len(issues) > 0:
        return ValidationResult[List[T]](issues^)
    return ValidationResult[List[T]](values^)

def validate_model_array[T: TypejoModel](
    ref input: InputValue,
    node: Int,
    unknown_fields: UnknownFieldPolicy,
    mut constraints: Constraints,
) -> ValidationResult[List[T]]:
    if not input.is_well_formed():
        return ValidationResult[List[T]](
            ValidationIssue("invalid_input", "Input value tree is malformed.")
        )
    if node < 0 or node >= input.node_count() or input.kind(node) != INPUT_ARRAY:
        return ValidationResult[List[T]](
            ValidationIssue("type_mismatch", "Input must be an array.")
        )
    var count = input.child_count(node)
    var constraint_error = _collection_constraint_error(count, constraints)
    if constraint_error != 0:
        var issue = _collection_constraint_issue(constraint_error)
        return ValidationResult[List[T]](issue^)

    var values = List[T]()
    var issues = List[ValidationIssue]()
    for index in range(count):
        var child = input.child_at(node, index).value()
        var result = validate_model[T](input, child, unknown_fields)
        if result.is_ok():
            values.append(result.value())
        else:
            result.prepend_index(index)
            var item_issues = result.issues()
            issues.extend(item_issues^)
    if len(issues) > 0:
        return ValidationResult[List[T]](issues^)
    return ValidationResult[List[T]](values^)
