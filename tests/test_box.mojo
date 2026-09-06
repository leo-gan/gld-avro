from std.collections import Optional
from std.testing import TestSuite, assert_equal, assert_true

from runtime.box import Box


def test_box_int() raises:
    var b = Box(Int64(7))
    assert_equal(b[], Int64(7))
    var c = b.copy()
    assert_equal(c[], Int64(7))


def test_optional_box_none() raises:
    var n = Optional[Box[Int64]](None)
    assert_true(not n)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
