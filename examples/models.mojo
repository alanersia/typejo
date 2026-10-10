from std.collections import List, Optional
from typejo import (
    Constraints,
    ExtraFields,
    InputValue,
    PrimitiveValue,
    TypejoModel,
    UnknownFieldPolicy,
    ValidationIssue,
    ValidationResult,
    collect_extras,
    validate_field,
    validate_model,
    validate_optional_field,
)

@fieldwise_init
struct User(TypejoModel):
    var username: String
    var age: Int
    var nickname: Optional[String]
    var extras: ExtraFields

    @staticmethod
    def supports_extras() -> Bool:
        return True

    @staticmethod
    def from_input(
        ref input: InputValue, node: Int, unknown_fields: UnknownFieldPolicy
    ) -> ValidationResult[Self]:
        var issues = List[ValidationIssue]()
        var username_rules = Constraints(min_length=3)
        var username_result = validate_field[String](
            input, node, "username", username_rules
        )
        var username = String("")
        if username_result.is_ok():
            username = username_result.value()
        else:
            var field_issues = username_result.issues()
            issues.extend(field_issues^)

        var age_rules = Constraints(minimum=0)
        var age_default_value = PrimitiveValue(Int(18))
        var age_default = Optional[PrimitiveValue](age_default_value)
        var age_result = validate_field[Int](
            input, node, "age", age_rules, age_default
        )
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

        var source = input.copy()
        var no_extras = List[Int]()
        var extras = ExtraFields(source^, no_extras^)
        if unknown_fields.mode == 2:
            extras = collect_extras[Self](input, node)

        if len(issues) > 0:
            return ValidationResult[Self](issues^)
        return ValidationResult[Self](User(username^, age, nickname^, extras^))

def add_string(mut input: InputValue, key: String, value: String):
    var primitive = PrimitiveValue(value)
    _ = input.add_primitive(input.root(), key, primitive)

def main():
    var valid_input = InputValue()
    add_string(valid_input, "username", "mira.dev")
    add_string(valid_input, "team", "platform")

    var preserve_unknown = UnknownFieldPolicy.preserve()
    var valid = validate_model[User](valid_input, 0, preserve_unknown)
    if valid.is_ok():
        var user = valid.value()
        print("Valid user:", user.username, "age:", user.age)
        print("Preserved extra fields:", user.extras.count())
    else:
        for issue in valid.issues():
            print(issue.code, issue.path, issue.message)

    var invalid_input = InputValue()
    add_string(invalid_input, "username", "Jo")
    var bad_age = PrimitiveValue(Int(-1))
    _ = invalid_input.add_primitive(invalid_input.root(), "age", bad_age)

    var invalid = validate_model[User](invalid_input)
    if invalid.is_ok():
        print("Valid user:", invalid.value().username)
    else:
        print("Invalid user:")
        for issue in invalid.issues():
            print("-", issue.code, issue.path, issue.message)
