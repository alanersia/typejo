from std.collections import List, Optional
from std.testing import assert_equal, assert_false, assert_true, TestSuite
from typejo import (
    Constraints,
    ExtraFields,
    InputValue,
    INPUT_ARRAY,
    INPUT_NULL,
    JsonOptions,
    TypejoModel,
    UnknownFieldPolicy,
    ValidationIssue,
    ValidationResult,
    collect_extras,
    parse_json,
    validate_field,
    validate_model,
    validate_optional_field,
    validate_primitive_array,
    validate_json,
)

@fieldwise_init
struct JsonAddress(TypejoModel):
    var city: String
    var zip: Int
    var extras: ExtraFields

    @staticmethod
    def supports_extras() -> Bool:
        return True

    @staticmethod
    def from_input(ref input: InputValue, node: Int, unknown_fields: UnknownFieldPolicy) -> ValidationResult[Self]:
        var issues = List[ValidationIssue]()
        var rules = Constraints(min_length=2)
        var city_result = validate_field[String](input, node, "city", rules)
        var city = city_result.value_or(String(""))
        if not city_result.is_ok():
            issues.extend(city_result.issues())
        var zip_rules = Constraints(minimum=1)
        var zip_result = validate_field[Int](input, node, "zip", zip_rules)
        var zip = zip_result.value_or(0)
        if not zip_result.is_ok():
            issues.extend(zip_result.issues())
        if len(issues) > 0:
            return ValidationResult[Self](issues^)
        var extras = _empty_extras(input)
        if unknown_fields.mode == 2:
            extras = collect_extras[Self](input, node)
        return ValidationResult[Self](JsonAddress(city^, zip, extras^))

def _empty_extras(ref input: InputValue) -> ExtraFields:
    var source = input.copy()
    var nodes = List[Int]()
    return ExtraFields(source^, nodes^)

@fieldwise_init
struct JsonUser(TypejoModel):
    var age: Int
    var score: Float64
    var nickname: Optional[String]
    var tags: List[String]
    var address: JsonAddress
    var extras: ExtraFields

    @staticmethod
    def supports_extras() -> Bool:
        return True

    @staticmethod
    def from_input(ref input: InputValue, node: Int, unknown_fields: UnknownFieldPolicy) -> ValidationResult[Self]:
        var issues = List[ValidationIssue]()
        var no_rules = Constraints()
        var age_result = validate_field[Int](input, node, "age", no_rules)
        var age = age_result.value_or(0)
        if not age_result.is_ok():
            issues.extend(age_result.issues())
        var score_result = validate_field[Float64](input, node, "score", no_rules)
        var score = score_result.value_or(0.0)
        if not score_result.is_ok():
            issues.extend(score_result.issues())
        var nickname_rules = Constraints(min_length=1)
        var nickname_result = validate_optional_field[String](
            input, node, "nickname", nickname_rules, nullable=True
        )
        var nickname = nickname_result.value_or(None)
        if not nickname_result.is_ok():
            issues.extend(nickname_result.issues())

        var tags_node = input.find_field(node, "tags")
        var tags = List[String]()
        if tags_node:
            var tag_rules = Constraints(max_length=3)
            var tags_result = validate_primitive_array[String](input, tags_node.value(), tag_rules)
            tags = tags_result.value_or(List[String]())
            if not tags_result.is_ok():
                tags_result.prepend_field("tags")
                issues.extend(tags_result.issues())
        else:
            var issue = ValidationIssue("missing_required", "Required field is missing.")
            issue.add_field("tags")
            issues.append(issue^)

        var address_node = input.find_field(node, "address")
        var address = JsonAddress("", 0, _empty_extras(input))
        if address_node:
            var address_result = validate_model[JsonAddress](input, address_node.value(), unknown_fields)
            address = address_result.value_or(JsonAddress("", 0, _empty_extras(input)))
            if not address_result.is_ok():
                address_result.prepend_field("address")
                issues.extend(address_result.issues())
        else:
            var issue = ValidationIssue("missing_required", "Required field is missing.")
            issue.add_field("address")
            issues.append(issue^)

        var extras_source = input.copy()
        var no_extras = List[Int]()
        var extras = ExtraFields(extras_source^, no_extras^)
        if unknown_fields.mode == 2:
            extras = collect_extras[Self](input, node)
        if len(issues) > 0:
            return ValidationResult[Self](issues^)
        return ValidationResult[Self](JsonUser(age, score, nickname^, tags^, address^, extras^))

def test_parse_json_values_and_unicode_escapes() raises:
    var parsed = parse_json("{\"text\":\"café \\uD83D\\uDE42\\n\",\"n\":1.00,\"items\":[true,null,-3e1]}")
    assert_true(parsed.is_ok())
    var input = parsed.value()
    assert_true(input.is_well_formed())
    var text_node = input.find_field(input.root(), "text").value()
    assert_equal(input.primitive(text_node)[String], "café 🙂\n")
    var number_node = input.find_field(input.root(), "n").value()
    assert_true(input.primitive(number_node).isa[Int]())
    assert_equal(input.json_number(number_node).value(), "1.00")
    var items = input.find_field(input.root(), "items").value()
    assert_equal(input.kind(items), INPUT_ARRAY)
    assert_equal(input.child_count(items), 3)
    assert_equal(input.kind(input.child_at(items, 1).value()), INPUT_NULL)

    var root_string = parse_json("\"text\"")
    assert_true(root_string.is_ok())
    assert_equal(root_string.value().primitive(0)[String], "text")
    var root_null = parse_json("null")
    assert_true(root_null.is_ok())
    assert_equal(root_null.value().kind(0), INPUT_NULL)
    var root_array = parse_json("[1,2]")
    assert_true(root_array.is_ok())
    assert_equal(root_array.value().kind(0), INPUT_ARRAY)

def test_parse_json_rejects_malformed_tokens_with_location() raises:
    var invalid = parse_json("{\n  \"x\": ]}")
    assert_false(invalid.is_ok())
    assert_equal(invalid.issues()[0].code, "json_syntax_error")
    assert_equal(invalid.issues()[0].source_line, 2)
    assert_equal(invalid.issues()[0].source_column, 8)

    var malformed = List[String]()
    malformed.append("")
    malformed.append("[1,]")
    malformed.append("{\"x\":1,}")
    malformed.append("\"\\q\"")
    malformed.append("\"\\uD800\"")
    malformed.append("01")
    malformed.append("1.")
    malformed.append("1e+")
    malformed.append("true false")
    malformed.append("{\"x\":1,\"x\":2}")
    for source in malformed:
        assert_false(parse_json(source).is_ok())

def test_json_limits_and_options() raises:
    var byte_limit = JsonOptions()
    byte_limit.max_input_bytes = 2
    assert_equal(parse_json("null", byte_limit).issues()[0].code, "json_limit_exceeded")

    var depth_limit = JsonOptions()
    depth_limit.max_depth = 0
    assert_equal(parse_json("{\"nested\":{}}", depth_limit).issues()[0].code, "json_limit_exceeded")

    var item_limit = JsonOptions()
    item_limit.max_collection_items = 1
    assert_equal(parse_json("[1,2]", item_limit).issues()[0].code, "json_limit_exceeded")
    assert_true(parse_json("[1,2]", JsonOptions()).is_ok())

    var invalid_options = JsonOptions()
    invalid_options.max_issues = 0
    assert_equal(parse_json("null", invalid_options).issues()[0].code, "invalid_json_options")

def test_validate_json_numbers_nested_models_and_policy() raises:
    var source = "{\"age\":1.00,\"score\":2,\"nickname\":null,\"tags\":[\"mojo\"],\"address\":{\"city\":\"Jakarta\",\"zip\":123}}"
    var result = validate_json[JsonUser](source)
    assert_true(result.is_ok())
    var user = result.value()
    assert_equal(user.age, 1)
    assert_equal(user.score, 2.0)
    assert_equal(user.address.city, "Jakarta")
    assert_equal(user.address.zip, 123)
    assert_equal(len(user.tags), 1)
    assert_false(user.nickname)

    var numeric_strings = JsonOptions()
    numeric_strings.coerce_numeric_strings = True
    var coerced = validate_json[JsonUser]("{\"age\":\"42\",\"score\":\"2.5\",\"tags\":[],\"address\":{\"city\":\"Rome\",\"zip\":\"8\"}}", numeric_strings)
    assert_true(coerced.is_ok())
    assert_equal(coerced.value().age, 42)
    assert_equal(coerced.value().score, 2.5)
    assert_equal(coerced.value().address.zip, 8)

    var max_int = validate_json[JsonUser]("{\"age\":9223372036854775807,\"score\":9007199254740993,\"tags\":[],\"address\":{\"city\":\"Rome\",\"zip\":8}}")
    assert_true(max_int.is_ok())
    assert_equal(max_int.value().age, 9223372036854775807)
    assert_equal(max_int.value().score, Float64(9007199254740992))
    var int_overflow = validate_json[JsonUser]("{\"age\":9223372036854775808,\"score\":2,\"tags\":[],\"address\":{\"city\":\"Rome\",\"zip\":8}}")
    assert_equal(int_overflow.issues()[0].code, "numeric_out_of_range")
    var fractional_int = validate_json[JsonUser]("{\"age\":1.01,\"score\":2,\"tags\":[],\"address\":{\"city\":\"Rome\",\"zip\":8}}")
    assert_equal(fractional_int.issues()[0].code, "numeric_out_of_range")
    var float_overflow = validate_json[JsonUser]("{\"age\":1,\"score\":1e999,\"tags\":[],\"address\":{\"city\":\"Rome\",\"zip\":8}}")
    assert_false(float_overflow.is_ok())

    var invalid_coercion = validate_json[JsonUser]("{\"age\":\"true\",\"score\":2,\"tags\":[],\"address\":{\"city\":\"Rome\",\"zip\":8}}", numeric_strings)
    assert_false(invalid_coercion.is_ok())
    assert_equal(invalid_coercion.issues()[0].code, "type_mismatch")

def test_validate_json_preserves_parse_errors_and_caps_issues() raises:
    var parse_error = validate_json[JsonUser]("{bad}")
    assert_false(parse_error.is_ok())
    assert_equal(parse_error.issues()[0].code, "json_syntax_error")
    assert_true(parse_error.issues()[0].source_line > 0)

    var one_issue = JsonOptions()
    one_issue.max_issues = 1
    var invalid = validate_json[JsonUser]("{\"age\":\"x\",\"score\":\"y\",\"tags\":[],\"address\":{\"city\":\"x\",\"zip\":0}}", one_issue)
    assert_false(invalid.is_ok())
    assert_equal(len(invalid.issues()), 1)
    assert_equal(invalid.issues()[0].code, "too_many_issues")

def test_unknown_field_policy_applies_to_json_models() raises:
    var source = "{\"age\":5,\"score\":1,\"tags\":[],\"address\":{\"city\":\"Lima\",\"zip\":9},\"theme\":\"dark\"}"
    var rejected = validate_json[JsonUser](source)
    assert_equal(rejected.issues()[0].code, "unknown_field")
    var ignore = validate_json[JsonUser](source, JsonOptions(), UnknownFieldPolicy.ignore())
    assert_true(ignore.is_ok())
    var preserve = validate_json[JsonUser](source, JsonOptions(), UnknownFieldPolicy.preserve())
    assert_true(preserve.is_ok())
    assert_equal(preserve.value().extras.count(), 1)
    assert_equal(preserve.value().extras.key(0), "theme")

def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
