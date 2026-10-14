import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Carousel: UP/DOWN scroll through the dice, START picks one.
class PickerView extends WatchUi.View {

    var index as Number;

    function initialize(startIndex as Number) {
        View.initialize();
        index = startIndex;
    }

    function step(delta as Number) as Void {
        var n = Dice.count();
        index = (index + delta + n) % n;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;
        var n = Dice.count();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        Dice.draw(dc, index, cx, cy, w * 26 / 100, 0.0, Dice.name(index), Graphics.FONT_MEDIUM);

        // Neighbours above and below, with arrows.
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var just = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.drawText(cx, h * 15 / 100, Graphics.FONT_XTINY, Dice.name((index + n - 1) % n), just);
        dc.drawText(cx, h * 85 / 100, Graphics.FONT_XTINY, Dice.name((index + 1) % n), just);
        var ay = h * 6 / 100;
        dc.fillPolygon([[cx - 7, ay + 4], [cx + 7, ay + 4], [cx, ay - 4]]);
        ay = h - ay;
        dc.fillPolygon([[cx - 7, ay - 4], [cx + 7, ay - 4], [cx, ay + 4]]);

        // Position dots along the left edge, beside the UP/DOWN buttons.
        for (var i = 0; i < n; i++) {
            var p = Dice.pt(cx.toFloat(), cy.toFloat(), (w / 2 - 10).toFloat(), 270.0 - (i - (n - 1) / 2.0) * 7.0);
            if (i == index) {
                dc.setColor(Dice.FILL[i], Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(p[0], p[1], 4);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(p[0], p[1], 2);
            }
        }

        Dice.startHint(dc, Dice.FILL[index]);
    }
}

class PickerDelegate extends WatchUi.BehaviorDelegate {

    var view as PickerView;

    function initialize(v as PickerView) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onNextPage() as Boolean {
        view.step(1);
        return true;
    }

    function onPreviousPage() as Boolean {
        view.step(-1);
        return true;
    }

    function onSelect() as Boolean {
        Application.Storage.setValue("die", view.index);
        var roll = new RollView(view.index);
        WatchUi.pushView(roll, new RollDelegate(roll), WatchUi.SLIDE_LEFT);
        return true;
    }
}
