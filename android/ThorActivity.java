package ch.lafleurstudio.toimemetusais;

import android.content.Context;
import android.hardware.display.DisplayManager;
import android.os.Build;
import android.os.Bundle;
import android.os.SystemClock;
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
    // Lid: when the screen went away (pause, or our display off); 0 = here
    private long awaySince = 0;
    private static final long LID_MIN_MS = 500;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (Build.VERSION.SDK_INT < 17) return;
        displays = (DisplayManager) getSystemService(Context.DISPLAY_SERVICE);
        listener = new DisplayManager.DisplayListener() {
            @Override public void onDisplayAdded(int id) { showTimer(); }
            @Override public void onDisplayRemoved(int id) { showTimer(); }
            @Override public void onDisplayChanged(int id) {
                if (id != myDisplayId()) return;
                if (Build.VERSION.SDK_INT >= 20) {
                    if (getWindowManager().getDefaultDisplay().getState() == Display.STATE_OFF) away();
                    else back();
                }
            }
        };
        displays.registerDisplayListener(listener, null);
    }

    private int myDisplayId() {
        return getWindowManager().getDefaultDisplay().getDisplayId();
    }

    // Closing the lid turns the screen off (the game pauses); reopening it
    // brings it back = next word, like the RG SP. The game cannot time this
    // itself, so the screen-off time is measured here and sent as "lid".
    private void away() {
        if (awaySince == 0) awaySince = SystemClock.elapsedRealtime();
    }

    private void back() {
        if (awaySince == 0) return;
        long ms = SystemClock.elapsedRealtime() - awaySince;
        awaySince = 0;
        if (ms >= LID_MIN_MS) TimerPresentation.send(TimerPresentation.bridgeDir(this), "lid");
    }

    @Override
    protected void onPause() {
        away();
        super.onPause();
    }

    @Override
    public void onResume() {
        super.onResume();
        back();
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
        int mine = myDisplayId();
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
