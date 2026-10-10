from typejo import Constraints, PrimitiveValue, validate

def main():
    var username = PrimitiveValue(String("Mira"))
    var username_rules = Constraints(min_length=3, max_length=12)
    var valid = validate[String](username, username_rules)
    if valid.is_ok():
        print("Valid username:", valid.value())
    else:
        for issue in valid.issues():
            print(issue.code, issue.path, issue.message)

    var short_name = PrimitiveValue(String("Jo"))
    var invalid = validate[String](short_name, username_rules)
    if invalid.is_ok():
        print("Valid username:", invalid.value())
    else:
        print("Invalid username:")
        for issue in invalid.issues():
            print("-", issue.code, issue.message)
