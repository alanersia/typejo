from std.testing import assert_equal, assert_false, assert_true, TestSuite
from std.memory import bitcast
from typejo import Constraints, PrimitiveValue, validate

def test_valid_primitives() raises:
    var text = PrimitiveValue(String("Typejo"))
    var integer = PrimitiveValue(Int(42))
    var boolean = PrimitiveValue(Bool(True))
    var half = PrimitiveValue(Float16(1.5))
    var single = PrimitiveValue(Float32(1.5))
    var double = PrimitiveValue(Float64(1.5))
    var brain = PrimitiveValue(BFloat16(1.5))
    var fp4 = PrimitiveValue(Float4_e2m1fn(1.5))
    var fp8a = PrimitiveValue(Float8_e4m3fn(1.5))
    var fp8b = PrimitiveValue(Float8_e4m3fnuz(1.5))
    var fp8c = PrimitiveValue(Float8_e5m2(1.5))
    var fp8d = PrimitiveValue(Float8_e5m2fnuz(1.5))
    var fp8e = PrimitiveValue(Float8_e8m0fnu(1.0))
    assert_true(validate[String](text).is_ok())
    assert_true(validate[Int](integer).is_ok())
    assert_true(validate[Bool](boolean).is_ok())
    assert_true(validate[Float16](half).is_ok())
    assert_true(validate[Float32](single).is_ok())
    assert_true(validate[Float64](double).is_ok())
    assert_true(validate[BFloat16](brain).is_ok())
    assert_true(validate[Float4_e2m1fn](fp4).is_ok())
    assert_true(validate[Float8_e4m3fn](fp8a).is_ok())
    assert_true(validate[Float8_e4m3fnuz](fp8b).is_ok())
    assert_true(validate[Float8_e5m2](fp8c).is_ok())
    assert_true(validate[Float8_e5m2fnuz](fp8d).is_ok())
    assert_true(validate[Float8_e8m0fnu](fp8e).is_ok())

def test_mismatches_are_strict() raises:
    var boolean = PrimitiveValue(Bool(True))
    var integer = PrimitiveValue(Int(1))
    var result = validate[Int](boolean)
    assert_false(result.is_ok())
    assert_equal(result.issues()[0].code, "type_mismatch")
    assert_equal(result.issues()[0].path, "")
    assert_false(validate[Bool](integer).is_ok())

def test_integer_inclusive_bounds() raises:
    var at_min = PrimitiveValue(Int(3))
    var at_max = PrimitiveValue(Int(7))
    var below = PrimitiveValue(Int(2))
    var above = PrimitiveValue(Int(8))
    var bounds = Constraints(minimum=3, maximum=7)
    assert_true(validate[Int](at_min, bounds).is_ok())
    assert_true(validate[Int](at_max, bounds).is_ok())
    var low_result = validate[Int](below, bounds)
    assert_equal(low_result.issues()[0].code, "below_minimum")
    var high_result = validate[Int](above, bounds)
    assert_equal(high_result.issues()[0].code, "above_maximum")

def test_float_inclusive_bounds() raises:
    var low = PrimitiveValue(Float64(1.25))
    var high = PrimitiveValue(Float64(2.5))
    var bounds = Constraints(minimum=Float64(1.25), maximum=Float64(2.5))
    assert_true(validate[Float64](low, bounds).is_ok())
    assert_true(validate[Float64](high, bounds).is_ok())
    var max_only = Constraints(maximum=2.5)
    assert_equal(validate[Float64](high, max_only).is_ok(), True)

def test_string_codepoint_length() raises:
    var input = PrimitiveValue(String("café"))
    var exact = Constraints(min_length=4, max_length=4)
    assert_true(validate[String](input, exact).is_ok())
    var too_short = Constraints(min_length=5)
    var result = validate[String](input, too_short)
    assert_equal(result.issues()[0].code, "too_short")

def test_non_finite_float() raises:
    var input = PrimitiveValue(Float64(FloatLiteral.nan))
    var result = validate[Float64](input)
    assert_false(result.is_ok())
    assert_equal(result.issues()[0].code, "non_finite")
    var half = PrimitiveValue(Float16(FloatLiteral.nan))
    assert_equal(validate[Float16](half).issues()[0].code, "non_finite")

def test_invalid_constraints() raises:
    var input = PrimitiveValue(Int(4))
    var reversed = Constraints(minimum=7, maximum=3)
    var result = validate[Int](input, reversed)
    assert_equal(result.issues()[0].code, "invalid_constraints")
    var text = PrimitiveValue(String("x"))
    var negative_length = Constraints(min_length=-1)
    assert_equal(validate[String](text, negative_length).issues()[0].code, "invalid_constraints")
    var float_input = PrimitiveValue(Float64(4.0))
    var reversed_float = Constraints(minimum=Float64(5.0), maximum=Float64(2.0))
    assert_equal(validate[Float64](float_input, reversed_float).issues()[0].code, "invalid_constraints")

def test_result_and_issue_order_are_stable() raises:
    var input = PrimitiveValue(Int(1))
    var bounds = Constraints(minimum=3)
    var first = validate[Int](input, bounds)
    var second = validate[Int](input, bounds)
    assert_false(first.is_ok())
    assert_equal(len(first.issues()), 1)
    assert_equal(first.issues()[0].code, second.issues()[0].code)
    assert_equal(first.issues()[0].message, second.issues()[0].message)

def test_value_or_returns_value_or_fallback_and_keeps_issues() raises:
    var valid_input = PrimitiveValue(Int(7))
    var valid = validate[Int](valid_input)
    assert_equal(valid.value_or(0), 7)

    var invalid_input = PrimitiveValue(Int(-1))
    var minimum = Constraints(minimum=0)
    var invalid = validate[Int](invalid_input, minimum)
    assert_equal(invalid.value_or(0), 0)
    assert_equal(invalid.issues()[0].code, "below_minimum")

def test_float4_constraints_and_nan() raises:
    var input = PrimitiveValue(Float4_e2m1fn(1.0))
    var bounds = Constraints(minimum=Float64(1.5))
    assert_equal(validate[Float4_e2m1fn](input, bounds).issues()[0].code, "below_minimum")
    var nan_lanes = bitcast[.float4_e2m1fn, 2](UInt8(7))
    var nan = PrimitiveValue(nan_lanes[0])
    assert_equal(validate[Float4_e2m1fn](nan).issues()[0].code, "non_finite")

def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
