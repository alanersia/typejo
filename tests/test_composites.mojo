from std.collections import List, Optional
from std.testing import assert_equal, assert_false, assert_true, TestSuite
from typejo import (
    Constraints,
    ExtraFields,
    InputValue,
    INPUT_ARRAY,
    INPUT_OBJECT,
    PrimitiveValue,
    TypejoModel,
    UnknownFieldPolicy,
    ValidationIssue,
    ValidationResult,
    collect_extras,
    validate_field,
    validate_model,
    validate_model_array,
    validate_optional_field,
    validate_primitive_array,
)

@fieldwise_init
struct Address(TypejoModel):
    var city: String
    var zip: Int
    var extras: ExtraFields

    @staticmethod
    def supports_extras() -> Bool:
        return True

    @staticmethod
    def from_input(
        ref input: InputValue, node: Int, unknown_fields: UnknownFieldPolicy
    ) -> ValidationResult[Self]:
        var issues = List[ValidationIssue]()
        var city_rules = Constraints(min_length=2)
        var city_result = validate_field[String](input, node, "city", city_rules)
        var city = String("")
        if city_result.is_ok():
            city = city_result.value()
        else:
            var city_issues = city_result.issues()
            issues.extend(city_issues^)

        var zip_rules = Constraints(minimum=1)
        var zip_result = validate_field[Int](input, node, "zip", zip_rules)
        var zip = 0
        if zip_result.is_ok():
            zip = zip_result.value()
        else:
            var zip_issues = zip_result.issues()
            issues.extend(zip_issues^)

        if len(issues) > 0:
            return ValidationResult[Self](issues^)
        var extras = empty_extras(input)
        if unknown_fields.mode == 2:
            extras = collect_extras[Self](input, node)
        return ValidationResult[Self](Address(city^, zip, extras^))

def empty_extras(ref input: InputValue) -> ExtraFields:
    var source = input.copy()
    var nodes = List[Int]()
    return ExtraFields(source^, nodes^)

@fieldwise_init
struct Profile(TypejoModel):
    var name: String
    var age: Int
    var nickname: Optional[String]
    var tags: List[String]
    var address: Address
    var peers: List[Address]
    var extras: ExtraFields

    @staticmethod
    def supports_extras() -> Bool:
        return True

    @staticmethod
    def from_input(
        ref input: InputValue, node: Int, unknown_fields: UnknownFieldPolicy
    ) -> ValidationResult[Self]:
        var issues = List[ValidationIssue]()
        var name_rules = Constraints(min_length=2)
        var name_result = validate_field[String](input, node, "name", name_rules)
        var name = String("")
        if name_result.is_ok():
            name = name_result.value()
        else:
            var field_issues = name_result.issues()
            issues.extend(field_issues^)

        var age_default_value = PrimitiveValue(Int(18))
        var age_default = Optional[PrimitiveValue](age_default_value)
        var age_rules = Constraints(minimum=0)
        var age_result = validate_field[Int](input, node, "age", age_rules, age_default)
        var age = 18
        if age_result.is_ok():
            age = age_result.value()
        else:
            var field_issues = age_result.issues()
            issues.extend(field_issues^)

        var nickname_rules = Constraints(min_length=1)
        var nickname_result = validate_optional_field[String](
            input, node, "nickname", nickname_rules, nullable=True
        )
        var nickname: Optional[String] = None
        if nickname_result.is_ok():
            nickname = nickname_result.value()
        else:
            var field_issues = nickname_result.issues()
            issues.extend(field_issues^)

        var tags_node = input.find_field(node, "tags")
        var tags = List[String]()
        if tags_node:
            var tags_rules = Constraints(min_length=1, max_length=3)
            var tags_result = validate_primitive_array[String](
                input, tags_node.value(), tags_rules
            )
            if tags_result.is_ok():
                tags = tags_result.value()
            else:
                tags_result.prepend_field("tags")
                var field_issues = tags_result.issues()
                issues.extend(field_issues^)
        else:
            var issue = ValidationIssue("missing_required", "Required field is missing.")
            issue.add_field("tags")
            issues.append(issue^)

        var address_node = input.find_field(node, "address")
        var address = Address("", 0, empty_extras(input))
        if address_node:
            var address_result = validate_model[Address](
                input, address_node.value(), unknown_fields
            )
            if address_result.is_ok():
                address = address_result.value()
            else:
                address_result.prepend_field("address")
                var field_issues = address_result.issues()
                issues.extend(field_issues^)
        else:
            var issue = ValidationIssue("missing_required", "Required field is missing.")
            issue.add_field("address")
            issues.append(issue^)

        var peers_node = input.find_field(node, "peers")
        var peers = List[Address]()
        if peers_node:
            var peers_rules = Constraints(max_length=2)
            var peers_result = validate_model_array[Address](
                input, peers_node.value(), unknown_fields, peers_rules
            )
            if peers_result.is_ok():
                peers = peers_result.value()
            else:
                peers_result.prepend_field("peers")
                var field_issues = peers_result.issues()
                issues.extend(field_issues^)
        else:
            var issue = ValidationIssue("missing_required", "Required field is missing.")
            issue.add_field("peers")
            issues.append(issue^)

        var extras = empty_extras(input)
        if unknown_fields.mode == 2:
            extras = collect_extras[Self](input, node)
        if len(issues) > 0:
            return ValidationResult[Self](issues^)
        return ValidationResult[Self](
            Profile(name^, age, nickname^, tags^, address^, peers^, extras^)
        )

def make_profile_input(mut input: InputValue):
    var root = input.root()
    var name = PrimitiveValue(String("Mira"))
    var tags = input.add_array(root, "tags")
    var first_tag = PrimitiveValue(String("mojo"))
    var city = PrimitiveValue(String("Jakarta"))
    var zip = PrimitiveValue(Int(10110))
    var peer_city = PrimitiveValue(String("Bandung"))
    var peer_zip = PrimitiveValue(Int(40111))
    _ = input.add_primitive(root, "name", name)
    _ = input.add_primitive_item(tags, first_tag)
    var address = input.add_object(root, "address")
    _ = input.add_primitive(address, "city", city)
    _ = input.add_primitive(address, "zip", zip)
    var peers = input.add_array(root, "peers")
    var peer = input.add_object_item(peers)
    _ = input.add_primitive(peer, "city", peer_city)
    _ = input.add_primitive(peer, "zip", peer_zip)

def test_valid_model_defaults_optional_and_nested_values() raises:
    var input = InputValue()
    make_profile_input(input)
    var result = validate_model[Profile](input)
    assert_true(result.is_ok())
    var profile = result.value()
    assert_equal(profile.name, "Mira")
    assert_equal(profile.age, 18)
    if profile.nickname:
        assert_true(False)
    else:
        assert_true(True)
    assert_equal(len(profile.tags), 1)
    assert_equal(profile.address.city, "Jakarta")
    assert_equal(len(profile.peers), 1)

def test_missing_required_null_and_nullable_are_distinct() raises:
    var input = InputValue()
    var rules = Constraints()
    var missing = validate_field[Int](input, input.root(), "age", rules)
    assert_equal(missing.issues()[0].code, "missing_required")

    _ = input.add_null(input.root(), "age")
    var null_value = validate_field[Int](input, input.root(), "age", rules)
    assert_equal(null_value.issues()[0].code, "null_not_allowed")
    var nullable = validate_optional_field[String](
        input, input.root(), "age", rules, nullable=True
    )
    assert_true(nullable.is_ok())
    var nullable_value = nullable.value()
    if nullable_value:
        assert_true(False)
    else:
        assert_true(True)

    var default_value = PrimitiveValue(Int(21))
    var default = Optional[PrimitiveValue](default_value)
    var null_with_default = validate_field[Int](
        input, input.root(), "age", rules, default
    )
    assert_equal(null_with_default.issues()[0].code, "null_not_allowed")

def test_invalid_default_is_reported() raises:
    var input = InputValue()
    var rules = Constraints(minimum=1)
    var invalid_default_value = PrimitiveValue(String("not an int"))
    var invalid_default = Optional[PrimitiveValue](invalid_default_value)
    var result = validate_field[Int](
        input, input.root(), "age", rules, invalid_default
    )
    assert_equal(result.issues()[0].code, "invalid_default")
    assert_equal(result.issues()[0].path, "age")

def test_collection_boundaries_and_item_paths() raises:
    var input = InputValue()
    var root = input.root()
    var empty = input.add_array(root, "empty")
    var empty_rules = Constraints(min_length=1)
    var too_few = validate_primitive_array[String](input, empty, empty_rules)
    assert_equal(too_few.issues()[0].code, "too_few_items")

    var boundary = input.add_array(root, "boundary")
    var boundary_first = PrimitiveValue(String("one"))
    var boundary_second = PrimitiveValue(String("two"))
    _ = input.add_primitive_item(boundary, boundary_first)
    _ = input.add_primitive_item(boundary, boundary_second)
    var boundary_rules = Constraints(min_length=1, max_length=2)
    assert_true(validate_primitive_array[String](input, boundary, boundary_rules).is_ok())

    var tags = input.add_array(root, "tags")
    var first = PrimitiveValue(String("ok"))
    var second = PrimitiveValue(Int(9))
    _ = input.add_primitive_item(tags, first)
    _ = input.add_primitive_item(tags, second)
    var rules = Constraints(min_length=1, max_length=2)
    var invalid_item = validate_primitive_array[String](input, tags, rules)
    assert_equal(invalid_item.issues()[0].code, "type_mismatch")
    assert_equal(invalid_item.issues()[0].path, "[1]")

    _ = input.add_primitive_item(tags, first)
    var too_many = validate_primitive_array[String](input, tags, rules)
    assert_equal(too_many.issues()[0].code, "too_many_items")

def test_nested_model_and_list_paths() raises:
    var bad_input = InputValue()
    var root = bad_input.root()
    var name = PrimitiveValue(String("Mira"))
    var tags = bad_input.add_array(root, "tags")
    var tag = PrimitiveValue(String("mojo"))
    var address = bad_input.add_object(root, "address")
    var city = PrimitiveValue(String("Jakarta"))
    var postal = PrimitiveValue(Int(-2))
    var peers = bad_input.add_array(root, "peers")
    var peer = bad_input.add_object_item(peers)
    var peer_city = PrimitiveValue(String("x"))
    var peer_zip = PrimitiveValue(Int(-3))
    _ = bad_input.add_primitive(root, "name", name)
    _ = bad_input.add_primitive_item(tags, tag)
    _ = bad_input.add_primitive(address, "city", city)
    _ = bad_input.add_primitive(address, "zip", postal)
    _ = bad_input.add_primitive(peer, "city", peer_city)
    _ = bad_input.add_primitive(peer, "zip", peer_zip)
    var bad_result = validate_model[Profile](bad_input)
    assert_false(bad_result.is_ok())
    var issues = bad_result.issues()
    var found_nested = False
    for index in range(len(issues)):
        if issues[index].path == "address.zip":
            found_nested = True
            assert_equal(len(issues[index].path_segments), 2)
            assert_true(issues[index].path_segments[0].isa[String]())
            assert_equal(issues[index].path_segments[0][String], "address")
            assert_equal(issues[index].path_segments[1][String], "zip")
    assert_true(found_nested)
    found_nested = False
    for index in range(len(issues)):
        if issues[index].path == "peers[0].city":
            found_nested = True
            assert_equal(len(issues[index].path_segments), 3)
            assert_equal(issues[index].path_segments[0][String], "peers")
            assert_equal(issues[index].path_segments[1][Int], 0)
            assert_equal(issues[index].path_segments[2][String], "city")
    assert_true(found_nested)

def test_unknown_fields_reject_ignore_and_preserve() raises:
    var input = InputValue()
    make_profile_input(input)
    var theme = PrimitiveValue(String("dark"))
    _ = input.add_primitive(input.root(), "theme", theme)

    var rejected = validate_model[Profile](input)
    assert_false(rejected.is_ok())
    var rejected_issues = rejected.issues()
    var found_unknown = False
    for index in range(len(rejected_issues)):
        if rejected_issues[index].code == "unknown_field" and rejected_issues[index].path == "theme":
            found_unknown = True
    assert_true(found_unknown)

    var ignore = UnknownFieldPolicy.ignore()
    var ignored = validate_model[Profile](input, 0, ignore)
    assert_true(ignored.is_ok())
    assert_equal(ignored.value().extras.count(), 0)

    var preserve = UnknownFieldPolicy.preserve()
    var preserved = validate_model[Profile](input, 0, preserve)
    assert_true(preserved.is_ok())
    assert_equal(preserved.value().extras.count(), 1)
    assert_equal(preserved.value().extras.key(0), "theme")
    assert_true(preserved.value().extras.primitive(0).isa[String]())

    var nested_input = InputValue()
    make_profile_input(nested_input)
    var metadata = nested_input.add_object(nested_input.root(), "metadata")
    var labels = nested_input.add_array(metadata, "labels")
    var label = PrimitiveValue(String("internal"))
    _ = nested_input.add_primitive_item(labels, label)
    var nested_preserved = validate_model[Profile](nested_input, 0, preserve)
    assert_true(nested_preserved.is_ok())
    var preserved_profile = nested_preserved.value()
    var extra = preserved_profile.extras.copy()
    assert_equal(extra.kind(0), INPUT_OBJECT)
    var preserved_input = extra.input()
    var preserved_metadata = extra.node(0)
    var preserved_labels = preserved_input.find_field(preserved_metadata, "labels")
    assert_true(preserved_labels)
    assert_equal(preserved_input.kind(preserved_labels.value()), INPUT_ARRAY)

def test_malformed_input_tree_and_policy_are_safe_errors() raises:
    var duplicate = InputValue()
    var first_city = PrimitiveValue(String("Jakarta"))
    var second_city = PrimitiveValue(String("Bandung"))
    _ = duplicate.add_primitive(duplicate.root(), "city", first_city)
    _ = duplicate.add_primitive(duplicate.root(), "city", second_city)
    var malformed = validate_model[Address](duplicate)
    assert_equal(malformed.issues()[0].code, "invalid_input")
    var direct_rules = Constraints()
    var direct_field = validate_field[Int](
        duplicate, duplicate.root(), "zip", direct_rules
    )
    assert_equal(direct_field.issues()[0].code, "invalid_input")

    var input = InputValue()
    var array_node = input.add_array(input.root(), "items")
    var parent_rules = Constraints()
    var wrong_parent = validate_field[Int](input, array_node, "zip", parent_rules)
    assert_equal(wrong_parent.issues()[0].code, "type_mismatch")
    var invalid_policy = UnknownFieldPolicy(99)
    var policy_result = validate_model[Address](input, 0, invalid_policy)
    assert_equal(policy_result.issues()[0].code, "invalid_policy")

    var array = input.add_array(input.root(), "other_items")
    var rules = Constraints(minimum=0)
    var invalid_collection_rules = validate_primitive_array[String](input, array, rules)
    assert_equal(invalid_collection_rules.issues()[0].code, "invalid_constraints")

def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
