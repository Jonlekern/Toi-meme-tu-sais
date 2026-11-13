package ch.lafleurstudio.toimemetusais;

import android.annotation.TargetApi;
import android.app.Presentation;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.graphics.drawable.ColorDrawable;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Display;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.Charset;

/**
 * The bottom screen: time left, Pause / Recommencer and the duration
 * (aucun, 30, 60, 90 s), all usable during play.
 *
 * Talks to the game through files in its save directory (src/dual.lua):
 * reads thor/state.txt, writes one thor/cmd-*.txt file per command.
 */
@TargetApi(17)
public class TimerPresentation extends Presentation {
    // LÖVE save directory: <files>/save/<identity>, identity from conf.lua
    private static final String IDENTITY = "detoimeme";
    private static final Charset UTF8 = Charset.forName("UTF-8");

    public TimerPresentation(Context outer, Display display) {
        super(outer, display);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // never take the focus: buttons and the lid keep going to the game
        Window w = getWindow();
        w.addFlags(WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
            | WindowManager.LayoutParams.FLAG_FULLSCREEN
            | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
            | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
            | WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        // the device theme is light: without this, the strip a system bar
        // leaves (a white line at the edge of the screen) shows its background
        w.setBackgroundDrawable(new ColorDrawable(TimerView.BG));
        w.setLayout(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT);
        if (Build.VERSION.SDK_INT >= 28) {
            w.getAttributes().layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        }
        TimerView v = new TimerView(getContext(), bridgeDir(getContext()));
        v.setBackgroundColor(TimerView.BG);
        setContentView(v);
        if (Build.VERSION.SDK_INT >= 30) {
            w.setDecorFitsSystemWindows(false);
            WindowInsetsController c = w.getInsetsController();
            if (c != null) {
                c.hide(WindowInsets.Type.systemBars());
                c.setSystemBarsBehavior(WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
            }
        }
    }

    /** Folder shared with the game: <files>/save/<identity>/thor */
    static File bridgeDir(Context c) {
        return new File(c.getFilesDir(), "save/" + IDENTITY + "/thor");
    }

    private static long cmdCount = 0;

    /** One command per file, written aside then renamed so the game never reads half of it. */
    static synchronized void send(File dir, String cmd) {
        try {
            if (!dir.isDirectory() && !dir.mkdirs()) return;
            String name = String.format("cmd-%015d-%04d.txt", System.currentTimeMillis(), cmdCount++ % 10000);
            File tmp = new File(dir, "." + name);
            FileOutputStream out = new FileOutputStream(tmp);
            try { out.write((cmd + "\n").getBytes(UTF8)); } finally { out.close(); }
            if (!tmp.renameTo(new File(dir, name))) tmp.delete();
        } catch (IOException ignored) {
        }
    }

    static final class TimerView extends View {
        // logical size of the screen, as on the mockup; scaled to fit
        private static final float W = 620, H = 540;
        static final int BG = 0xFF1A1A1A;
        private static final int PINK = 0xFFF26EF2, TEXT = 0xFFF4F4F4,
            GREY = 0xFF888888, OUTLINE = 0xFF555555;
        private static final int[] TIMERS = { 0, 30, 60, 90 };
        private static final String[] LABELS = { "aucun", "30 s", "60 s", "90 s" };

        private final File dir;
        private final Handler handler = new Handler(Looper.getMainLooper());
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final RectF r = new RectF();
        private Typeface regular, bold, tall;
        private String lastState = "";
        // state from the game
        private boolean playing, paused;
        private int remaining = -1, total = 0, word = 0, timer = 0;
        // logical -> screen
        private float scale = 1, ox = 0, oy = 0;

        private final Runnable poll = new Runnable() {
            @Override public void run() {
                readState();
                handler.postDelayed(this, 100);
            }
        };

        TimerView(Context c, File dir) {
            super(c);
            this.dir = dir;
            regular = font(c, "Calebard-Regular.ttf");
            bold = font(c, "Calebard-Bold.ttf");
            tall = font(c, "Clebard-Tall.ttf");
            setSystemUiVisibility(View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
        }

        private static Typeface font(Context c, String name) {
            try {
                return Typeface.createFromAsset(c.getAssets(), "thor-fonts/" + name);
            } catch (RuntimeException e) {
                return Typeface.DEFAULT;
            }
        }

        @Override protected void onAttachedToWindow() {
            super.onAttachedToWindow();
            send("dual 1");
            handler.post(poll);
        }

        @Override protected void onDetachedFromWindow() {
            handler.removeCallbacks(poll);
            send("dual 0");
            super.onDetachedFromWindow();
        }

        // ---- files ----

        private void readState() {
            File f = new File(dir, "state.txt");
            byte[] buf = new byte[512];
            int n;
            FileInputStream in = null;
            try {
                in = new FileInputStream(f);
                n = in.read(buf);
            } catch (IOException e) {
                return;
            } finally {
                if (in != null) try { in.close(); } catch (IOException ignored) { }
            }
            if (n <= 0) return;
            String s = new String(buf, 0, n, UTF8);
            if (s.equals(lastState) || !s.endsWith("\n")) return; // unchanged, or caught mid-write
            lastState = s;
            for (String line : s.split("\n")) {
                int eq = line.indexOf('=');
                if (eq < 0) continue;
                String k = line.substring(0, eq);
                int v;
                try { v = Integer.parseInt(line.substring(eq + 1).trim()); } catch (NumberFormatException e) { continue; }
                if (k.equals("playing")) playing = v == 1;
                else if (k.equals("remaining")) remaining = v;
                else if (k.equals("total")) total = v;
                else if (k.equals("paused")) paused = v == 1;
                else if (k.equals("word")) word = v;
                else if (k.equals("timer")) timer = v;
            }
            invalidate();
        }

        private void send(String cmd) { TimerPresentation.send(dir, cmd); }

        // ---- layout (logical coordinates, same as the mockup) ----

        private static final float BTN_Y = 300, BTN_H = 70, PAUSE_X = 50, RESTART_X = 320, BTN_W = 250;
        private static final float PILL_Y = 430, PILL_H = 52, PILL_X = 50, PILL_W = 115, PILL_GAP = 20;

        private boolean timerRunning() { return playing && remaining >= 0 && total > 0; }

        @Override protected void onSizeChanged(int w, int h, int ow, int oh) {
            scale = Math.min(w / W, h / H);
            ox = (w - W * scale) / 2;
            oy = (h - H * scale) / 2;
        }

        private void text(Canvas c, String s, Typeface tf, float size, int color, float x, float y, float w, Paint.Align align) {
            paint.setStyle(Paint.Style.FILL);
            paint.setTypeface(tf);
            paint.setTextSize(size);
            paint.setColor(color);
            paint.setTextAlign(align);
            float tx = align == Paint.Align.CENTER ? x + w / 2 : align == Paint.Align.RIGHT ? x + w : x;
            Paint.FontMetrics fm = paint.getFontMetrics();
            c.drawText(s, tx, y - fm.top, paint);
        }

        private void pill(Canvas c, float x, float y, float w, float h, Integer fill, Integer line) {
            r.set(x, y, x + w, y + h);
            if (fill != null) {
                paint.setStyle(Paint.Style.FILL);
                paint.setColor(fill);
                c.drawRoundRect(r, h / 2, h / 2, paint);
            }
            if (line != null) {
                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeWidth(2);
                paint.setColor(line);
                r.inset(1, 1);
                c.drawRoundRect(r, h / 2, h / 2, paint);
            }
        }

        // label centred in a box; shrinks the text if it would not fit
        private void label(Canvas c, String s, Typeface tf, float size, int color, float x, float y, float w, float h) {
            paint.setTypeface(tf);
            paint.setTextSize(size);
            while (size > 10 && paint.measureText(s) > w - 16) { size -= 1; paint.setTextSize(size); }
            Paint.FontMetrics fm = paint.getFontMetrics();
            text(c, s, tf, size, color, x, y + (h - (fm.bottom - fm.top)) / 2, w, Paint.Align.CENTER);
        }

        private static String fmt(int sec) {
            return (sec / 60) + ":" + (sec % 60 < 10 ? "0" : "") + (sec % 60);
        }

        @Override protected void onDraw(Canvas c) {
            c.drawColor(BG);
            c.save();
            c.translate(ox, oy);
            c.scale(scale, scale);
            boolean running = timerRunning();

            text(c, "Chrono", regular, 18, GREY, 30, 24, 0, Paint.Align.LEFT);
            if (playing && word > 0) text(c, "Mot " + word, regular, 18, GREY, 0, 24, W - 30, Paint.Align.RIGHT);

            String big;
            int bigColor;
            if (running) { big = fmt(remaining); bigColor = paused ? GREY : PINK; }
            else if (timer > 0) { big = fmt(timer); bigColor = GREY; }
            else { big = "—"; bigColor = GREY; }
            text(c, big, tall, 150, bigColor, 0, 50, W, Paint.Align.CENTER);

            pill(c, 50, 250, 520, 14, null, OUTLINE);
            if (running) {
                float frac = Math.max(0f, Math.min(1f, remaining / (float) total));
                if (frac > 0) pill(c, 50, 250, Math.max(14, 520 * frac), 14, paused ? GREY : PINK, null);
            }

            int alpha = running ? 255 : 90;
            c.saveLayerAlpha(0, BTN_Y - 4, W, BTN_Y + BTN_H + 4, alpha, Canvas.ALL_SAVE_FLAG);
            pill(c, PAUSE_X, BTN_Y, BTN_W, BTN_H, PINK, null);
            label(c, paused ? "Reprendre" : "Pause", bold, 22, BG, PAUSE_X, BTN_Y, BTN_W, BTN_H);
            pill(c, RESTART_X, BTN_Y, BTN_W, BTN_H, null, OUTLINE);
            label(c, "Recommencer", bold, 22, TEXT, RESTART_X, BTN_Y, BTN_W, BTN_H);
            c.restore();

            text(c, "Durée", regular, 18, GREY, 50, 400, 0, Paint.Align.LEFT);
            for (int i = 0; i < TIMERS.length; i++) {
                float x = PILL_X + i * (PILL_W + PILL_GAP);
                boolean sel = TIMERS[i] == timer;
                pill(c, x, PILL_Y, PILL_W, PILL_H, sel ? Integer.valueOf(PINK) : null, sel ? null : Integer.valueOf(OUTLINE));
                label(c, LABELS[i], regular, 18, sel ? BG : GREY, x, PILL_Y, PILL_W, PILL_H);
            }
            text(c, playing ? "Changer la durée relance le chrono" : "Choisis la durée avant de jouer",
                regular, 14, GREY, 0, 505, W, Paint.Align.CENTER);
            c.restore();
        }

        @Override public boolean onTouchEvent(MotionEvent e) {
            if (e.getActionMasked() != MotionEvent.ACTION_UP) return true;
            float x = (e.getX() - ox) / scale, y = (e.getY() - oy) / scale;
            if (timerRunning() && y >= BTN_Y && y <= BTN_Y + BTN_H) {
                if (x >= PAUSE_X && x <= PAUSE_X + BTN_W) {
                    paused = !paused;
                    send(paused ? "pause" : "resume");
                } else if (x >= RESTART_X && x <= RESTART_X + BTN_W) {
                    paused = false;
                    send("restart");
                }
                invalidate();
                return true;
            }
            if (y >= PILL_Y - 10 && y <= PILL_Y + PILL_H + 10) {
                for (int i = 0; i < TIMERS.length; i++) {
                    float px = PILL_X + i * (PILL_W + PILL_GAP);
                    if (x >= px - PILL_GAP / 2 && x <= px + PILL_W + PILL_GAP / 2) {
                        timer = TIMERS[i];
                        send("timer " + TIMERS[i]);
                        invalidate();
                        return true;
                    }
                }
            }
            return true;
        }
    }
}
