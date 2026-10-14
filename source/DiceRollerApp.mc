import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class DiceRollerApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        Math.srand(Time.now().value() ^ System.getTimer());
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        // Reopen on the die used last time.
        var start = Application.Storage.getValue("die");
        var index = (start instanceof Number && start >= 0 && start < Dice.count()) ? start : 3;
        var view = new PickerView(index);
        return [view, new PickerDelegate(view)];
    }
}
