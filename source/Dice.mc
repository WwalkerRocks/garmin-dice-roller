import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

// Dice definitions plus top-down drawing of each die.
// Shapes are true top-down silhouettes of the physical dice:
//   d2  coin                  -> circle
//   d3  rounded prism         -> rounded (Reuleaux) triangle
//   d4  tetrahedron, tip up   -> triangle with 3 faces
//   d6  cube, face up         -> square
//   d8  octahedron, tip up    -> diamond with 4 faces
//   d10 trapezohedron, tip up -> decagon with 5 kite faces
//   d12 dodecahedron, face up -> decagon with centre pentagon
//   d20 icosahedron, face up  -> hexagon with centre triangle
module Dice {

    const SIDES = [2, 3, 4, 6, 8, 10, 12, 20] as Array<Number>;

    // FR945 has a 64-colour MIP display, so stick to 0x00/0x55/0xAA/0xFF channels.
    const FILL = [0xAAAAAA, 0xFF55AA, 0x55FF55, 0xFFFF00, 0xFFAA00, 0x0055FF, 0xAA55FF, 0xFF0000] as Array<Number>;
    const INK  = [0x000000, 0x000000, 0x000000, 0x000000, 0x000000, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF] as Array<Number>;

    // Golden-ratio inner face size for the d12 pentagon and d20 triangle.
    const PHI_INV = 0.618;

    function count() as Number {
        return SIDES.size();
    }

    function name(i as Number) as String {
        return "d" + SIDES[i];
    }

    // Unbiased integer in 1..sides.
    function roll(sides as Number) as Number {
        var limit = 0x7FFFFFFF - (0x7FFFFFFF % sides);
        var v = Math.rand();
        while (v >= limit) {
            v = Math.rand();
        }
        return v % sides + 1;
    }

    // Point at radius r, angle deg measured clockwise from 12 o'clock.
    function pt(cx as Float, cy as Float, r as Float, deg as Float) as Point2D {
        var a = Math.toRadians(deg);
        return [cx + r * Math.sin(a), cy - r * Math.cos(a)];
    }

    function poly(cx as Float, cy as Float, r as Float, n as Number, startDeg as Float) as Array<Point2D> {
        var pts = new Array<Point2D>[n];
        for (var i = 0; i < n; i++) {
            pts[i] = pt(cx, cy, r, startDeg + 360.0 * i / n);
        }
        return pts;
    }

    // Reuleaux triangle: each side is an arc centred on the opposite corner.
    function reuleaux(cx as Float, cy as Float, r as Float, rot as Float) as Array<Point2D> {
        var v = poly(cx, cy, r, 3, rot);
        var steps = 8;
        var pts = [] as Array<Point2D>;
        for (var side = 0; side < 3; side++) {
            var a = v[side];
            var c = v[(side + 2) % 3];
            var s = Math.sqrt((a[0] - c[0]) * (a[0] - c[0]) + (a[1] - c[1]) * (a[1] - c[1]));
            var start = Math.atan2(a[1] - c[1], a[0] - c[0]);
            // Corners are 60 degrees apart as seen from the opposite corner.
            for (var k = 0; k < steps; k++) {
                var t = start + (Math.PI / 3.0) * k / steps;
                pts.add([c[0] + s * Math.cos(t), c[1] + s * Math.sin(t)]);
            }
        }
        return pts;
    }

    function outline(dc as Dc, pts as Array<Point2D>) as Void {
        var n = pts.size();
        for (var i = 0; i < n; i++) {
            line(dc, pts[i], pts[(i + 1) % n]);
        }
    }

    function line(dc as Dc, a as Point2D, b as Point2D) as Void {
        dc.drawLine(a[0], a[1], b[0], b[1]);
    }

    // Draws die i centred at (x, y) with nominal radius r.
    // rot tilts the die (used while tumbling); label is drawn in the centre face.
    function draw(dc as Dc, i as Number, x as Number, y as Number, r as Number,
                  rot as Float, label as String, font as FontType) as Void {
        var cx = x.toFloat();
        var cy = y.toFloat();
        var rf = r.toFloat();
        var fill = FILL[i];
        var ink = INK[i];
        var sides = SIDES[i];
        var centreLines = true;

        dc.setPenWidth(2);

        if (sides == 2) {
            // Coin: a tumble squashes it horizontally like a flip.
            var rad = rf * 0.85;
            var squash = rot == 0.0 ? 1.0 : Math.cos(Math.toRadians(rot * 4.0)).abs();
            if (squash < 0.15) {
                squash = 0.15;
            }
            dc.setColor(fill, Graphics.COLOR_TRANSPARENT);
            dc.fillEllipse(cx, cy, rad * squash, rad);
            dc.setColor(ink, Graphics.COLOR_TRANSPARENT);
            dc.drawEllipse(cx, cy, rad * squash * 0.82, rad * 0.82);
            centreLines = false;
        } else if (sides == 3) {
            dc.setColor(fill, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon(reuleaux(cx, cy + rf * 0.08, rf * 0.92, rot));
            centreLines = false;
        } else if (sides == 4) {
            // Shift down so the triangle looks centred rather than its centroid.
            var c = [cx, cy + rf * 0.2] as Point2D;
            var v = poly(c[0], c[1], rf * 1.12, 3, rot);
            dc.setColor(fill, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon(v);
            dc.setColor(ink, Graphics.COLOR_TRANSPARENT);
            for (var k = 0; k < 3; k++) {
                line(dc, c, v[k]);
            }
        } else if (sides == 6) {
            dc.setColor(fill, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon(poly(cx, cy, rf * 1.05, 4, 45.0 + rot));
            centreLines = false;
        } else if (sides == 8) {
            var v = poly(cx, cy, rf * 1.1, 4, rot);
            dc.setColor(fill, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon(v);
            dc.setColor(ink, Graphics.COLOR_TRANSPARENT);
            line(dc, v[0], v[2]);
            line(dc, v[1], v[3]);
        } else if (sides == 10) {
            var v = poly(cx, cy, rf, 10, rot);
            var c = [cx, cy] as Point2D;
            dc.setColor(fill, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon(v);
            dc.setColor(ink, Graphics.COLOR_TRANSPARENT);
            outline(dc, v);
            for (var k = 0; k < 10; k += 2) {
                line(dc, c, v[k]);
            }
        } else if (sides == 12) {
            var v = poly(cx, cy, rf, 10, rot);
            var inner = poly(cx, cy, rf * PHI_INV, 5, rot);
            dc.setColor(fill, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon(v);
            dc.setColor(ink, Graphics.COLOR_TRANSPARENT);
            outline(dc, v);
            outline(dc, inner);
            for (var k = 0; k < 5; k++) {
                line(dc, inner[k], v[k * 2]);
            }
        } else {
            var v = poly(cx, cy, rf * 1.02, 6, rot);
            var inner = poly(cx, cy, rf * 1.02 * PHI_INV, 3, rot);
            dc.setColor(fill, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon(v);
            dc.setColor(ink, Graphics.COLOR_TRANSPARENT);
            outline(dc, v);
            outline(dc, inner);
            for (var k = 0; k < 3; k++) {
                line(dc, inner[k], v[(k * 2 + 5) % 6]);
                line(dc, inner[k], v[k * 2]);
                line(dc, inner[k], v[k * 2 + 1]);
            }
        }

        // Clear a patch behind the label so edge lines don't run through the digits.
        var dims = dc.getTextDimensions(label, font);
        if (centreLines) {
            var pw = dims[0] + 8;
            var ph = dims[1] * 3 / 4;
            dc.setColor(fill, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x - pw / 2, y - ph / 2, pw, ph, 6);
        }
        dc.setColor(ink, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Small highlight on the bezel next to the START button (2 o'clock).
    function startHint(dc as Dc, colour as Number) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setPenWidth(6);
        dc.setColor(colour, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(w / 2, h / 2, w / 2 - 3, Graphics.ARC_COUNTER_CLOCKWISE, 27, 47);
        dc.setPenWidth(1);
    }
}
