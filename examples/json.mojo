from std.collections import List, Optional
from typejo import (
    Constraints,
    InputValue,
    JsonOptions,
    TypejoModel,
    UnknownFieldPolicy,
    ValidationIssue,
    ValidationResult,
    validate_field,
    validate_json,
    validate_optional_field,
)

@fieldwise_init
struct Signup(TypejoModel):
    var username: String
    var age: Int
    var nickname: Optional[String]

    @staticmethod
    def supports_extras() -> Bool:
        return False

    @staticmethod
    def from_input(
        ref input: InputValue, node: Int, unknown_fields: UnknownFieldPolicy
    ) -> ValidationResult[Self]:
        var issues = List[ValidationIssue]()
        var username_rules = Constraints(min_length=3)
        var username_result = validate_field[String](
            input, node, "username", username_rules
        )
        var username = username_result.value_or(String(""))
        if not username_result.is_ok():
            issues.extend(username_result.issues())

        var age_rules = Constraints(minimum=0)
        var age_result = validate_field[Int](input, node, "age", age_rules)
        var age = age_result.value_or(0)
        if not age_result.is_ok():
            issues.extend(age_result.issues())

        var nickname_rules = Constraints(min_length=1)
        var nickname_result = validate_optional_field[String](
            input, node, "nickname", nickname_rules, nullable=True
        )
        var nickname = nickname_result.value_or(None)
        if not nickname_result.is_ok():
            issues.extend(nickname_result.issues())

        if len(issues) > 0:
            return ValidationResult[Self](issues^)
        return ValidationResult[Self](Signup(username^, age, nickname^))

def main():
    var options = JsonOptions()
    options.coerce_numeric_strings = True

    var source = """{"username":"mira.dev","age":"18","nickname":null}"""
    var result = validate_json[Signup](source, options)
    if result.is_ok():
        var signup = result.value()
        print("Valid signup:", signup.username, "age:", signup.age)
    else:
        print("Invalid signup:")
        for issue in result.issues():
            print("-", issue.code, issue.path, issue.message)

    var invalid = validate_json[Signup]("""{"username":"Jo","age":-2}""", options)
    if invalid.is_ok():
        print("Valid signup:", invalid.value().username)
    else:
        print("Rejected JSON model:")
        for issue in invalid.issues():
            print("-", issue.code, issue.path, issue.message)
