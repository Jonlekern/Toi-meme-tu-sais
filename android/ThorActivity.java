package ch.lafleurstudio.toimemetusais;

import android.content.Context;
import android.hardware.display.DisplayManager;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.Display;

import org.love2d.android.GameActivity;

/**
 * LÖVE's game activity plus a second screen: on a handheld with two displays
 * (AYN Thor), the timer and its settings are shown on the display the game is
 * not on, as a Presentation. The game and that screen talk through small files
 * (see TimerPresentation and src/dual.lua).
 */
public class ThorActivity extends GameActivity {
    private static final String TAG = "ThorActivity";
    private TimerPresentation presentation;
    private DisplayManager displays;
    private DisplayManager.DisplayListener listener;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (Build.VERSION.SDK_INT < 17) return;
        displays = (DisplayManager) getSystemService(Context.DISPLAY_SERVICE);
        listener = new DisplayManager.DisplayListener() {
            @Override public void onDisplayAdded(int id) { showTimer(); }
            @Override public void onDisplayRemoved(int id) { showTimer(); }
            @Override public void onDisplayChanged(int id) { }
        };
        displays.registerDisplayListener(listener, null);
    }

    @Override
    protected void onStart() {
        super.onStart();
        showTimer();
    }

    @Override
    protected void onStop() {
        hideTimer();
        super.onStop();
    }

    @Override
    protected void onDestroy() {
        hideTimer();
        if (Build.VERSION.SDK_INT >= 17 && displays != null && listener != null) {
            displays.unregisterDisplayListener(listener);
        }
        super.onDestroy();
    }

    /** First display other than the one the game is on, or null. */
    private Display otherDisplay() {
        if (Build.VERSION.SDK_INT < 17 || displays == null) return null;
        int mine = getWindowManager().getDefaultDisplay().getDisplayId();
        for (Display d : displays.getDisplays()) {
            if (d.getDisplayId() == mine) continue;
            if (Build.VERSION.SDK_INT >= 20 && d.getState() == Display.STATE_OFF) continue;
            return d;
        }
        return null;
    }

    private void showTimer() {
        if (Build.VERSION.SDK_INT < 17 || isFinishing()) return;
        Display d = otherDisplay();
        if (presentation != null && d != null && presentation.getDisplay().getDisplayId() == d.getDisplayId()) return;
        hideTimer();
        if (d == null) return;
        try {
            TimerPresentation p = new TimerPresentation(this, d);
            p.show();
            presentation = p;
            Log.d(TAG, "timer shown on display " + d.getDisplayId());
        } catch (RuntimeException e) {
            Log.w(TAG, "cannot show the timer on display " + d.getDisplayId(), e);
        }
    }

    private void hideTimer() {
        if (presentation == null) return;
        TimerPresentation p = presentation;
        presentation = null;
        try {
            p.dismiss();
        } catch (RuntimeException e) {
            Log.w(TAG, "dismiss failed", e);
        }
    }
}
