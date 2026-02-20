import QtQuick
import QtTest

import "../../services/parsers/WallpaperParsers.js" as WallpaperParsers

TestCase {
    name: "WallpaperParsers"

    function test_buildMatugenArgs() {
        const dark = WallpaperParsers.buildMatugenArgs("/tmp/a.png", true);
        compare(dark.length, 9);
        compare(dark[0], "matugen");
        compare(dark[1], "image");
        compare(dark[2], "-t");
        compare(dark[3], "scheme-vibrant");
        compare(dark[4], "-m");
        compare(dark[5], "dark");
        compare(dark[6], "/tmp/a.png");
        compare(dark[7], "--source-color-index");
        compare(dark[8], "0");

        const light = WallpaperParsers.buildMatugenArgs("/tmp/a.png", false);
        compare(light[5], "light");
    }

    function test_parseAndSortDiscoveryOutput() {
        const parsed = WallpaperParsers.parseDiscoveryOutput('["/x/b.png", "/x/A.jpg", "/y/a.jpg"]');
        compare(parsed.length, 3);

        const sorted = WallpaperParsers.sortedImagePaths(parsed);
        compare(sorted[0], "/x/A.jpg");
        compare(sorted[1], "/y/a.jpg");
        compare(sorted[2], "/x/b.png");
    }

    function test_indexAndClamp() {
        const paths = ["/a.png", "/b.png"];
        compare(WallpaperParsers.indexForPath(paths, "/b.png"), 1);
        compare(WallpaperParsers.indexForPath(paths, "/c.png"), -1);

        compare(WallpaperParsers.clampIndex(-3, 2), 0);
        compare(WallpaperParsers.clampIndex(9, 2), 1);
        compare(WallpaperParsers.clampIndex(1, 2), 1);
        compare(WallpaperParsers.clampIndex(0, 0), -1);
    }
}
