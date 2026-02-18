import QtQuick
import QtTest

import "../../config/ConfigMerge.js" as Merge

TestCase {
    name: "ConfigMerge"

    function test_mergeNestedObjects() {
        const defaults = {
            appearance: {
                font: {
                    family: "Roboto",
                    size: 13
                }
            },
            bar: {
                size: {
                    thickness: 40,
                    margin: 10
                }
            }
        };
        const overrides = {
            appearance: {
                font: {
                    size: 15
                }
            },
            bar: {
                size: {
                    margin: 14
                }
            }
        };

        const merged = Merge.mergeWithDefaults(defaults, overrides);
        compare(merged.appearance.font.family, "Roboto");
        compare(merged.appearance.font.size, 15);
        compare(merged.bar.size.thickness, 40);
        compare(merged.bar.size.margin, 14);
    }

    function test_overridePrimitiveReplacesObject() {
        const defaults = { motion: { shortDuration: 120 } };
        const overrides = { motion: false };

        const merged = Merge.mergeWithDefaults(defaults, overrides);
        compare(merged.motion, false);
    }
}
