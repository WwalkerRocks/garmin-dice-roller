import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Rolls the chosen die. START rolls (again and again), BACK returns to the picker.
class RollView extends WatchUi.View {

    const TUMBLE_TICKS = 12;
    const TICK_MS = 60;
    const HISTORY_SIZE = 5;

    var index as Number;
    var sides as Number;
    var shown as Number = 0;          // 0 = not rolled yet
    var result as Number = 0;
    var rolls as Number = 0;
    var history as Array<Number> = [] as Array<Number>;   // newest first
    var ticks as Number = 0;
    var tilt as Float = 0.0;
    var timer as Timer.Timer = new Timer.Timer();

    function initialize(i as Number) {
        View.initialize();
        index = i;
        sides = Dice.SIDES[i];
    }

    function roll() as Void {
        if (ticks > 0) {
            return;
        }
        if (result > 0) {
            history = [result].addAll(history) as Array<Number>;
            if (history.size() > HISTORY_SIZE) {
                history = history.slice(0, HISTORY_SIZE);
            }
        }
        result = Dice.roll(sides);
        ticks = TUMBLE_TICKS;
        tumble();
        timer.start(method(:onTick), TICK_MS, true);
    }

    function onTick() as Void {
        ticks -= 1;
        if (ticks <= 0) {
            finish();
        } else {
            tumble();
        }
        WatchUi.requestUpdate();
    }

    // Random face and a tilt that settles as the die slows down.
    function tumble() as Void {
        shown = Dice.roll(sides);
        var amp = 30.0 * ticks / TUMBLE_TICKS;
        tilt = (Math.rand() % 201 - 100) * amp / 100.0;
    }

    function finish() as Void {
        timer.stop();
        ticks = 0;
        tilt = 0.0;
        shown = result;
        rolls += 1;
        if (Attention has :vibrate && System.getDeviceSettings().vibrateOn) {
            Attention.vibrate([new Attention.VibeProfile(50, 80)]);
        }
    }

    function onHide() as Void {
        if (ticks > 0) {
            finish();
        }
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var just = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 13 / 100, Graphics.FONT_SMALL, Dice.name(index), just);

        // Number fonts only contain digits, so the "?" placeholder needs a text font.
        if (shown > 0) {
            Dice.draw(dc, index, cx, h * 48 / 100, w * 25 / 100, tilt, shown.toString(), Graphics.FONT_NUMBER_MEDIUM);
        } else {
            Dice.draw(dc, index, cx, h * 48 / 100, w * 25 / 100, tilt, "?", Graphics.FONT_LARGE);
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        if (rolls == 0 && ticks == 0) {
            dc.drawText(cx, h * 82 / 100, Graphics.FONT_XTINY, "START to roll", just);
        } else {
            var prev = "";
            for (var i = 0; i < history.size(); i++) {
                prev += (i == 0 ? "" : "  ") + history[i];
            }
            if (prev.length() > 0) {
                dc.drawText(cx, h * 80 / 100, Graphics.FONT_XTINY, prev, just);
            }
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 90 / 100, Graphics.FONT_XTINY, "#" + rolls, just);
        }

        Dice.startHint(dc, Dice.FILL[index]);
    }
}

class RollDelegate extends WatchUi.BehaviorDelegate {

    var view as RollView;

    function initialize(v as RollView) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onSelect() as Boolean {
        view.roll();
        return true;
    }
}
