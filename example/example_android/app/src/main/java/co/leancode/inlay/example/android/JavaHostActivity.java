package co.leancode.inlay.example.android;

import android.os.Bundle;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import co.leancode.example_module.javagen.ConfirmActionDialog;
import co.leancode.example_module.javagen.CounterPage;
import co.leancode.example_module.javagen.GreetingPage;
import co.leancode.example_module.javagen.GreetingStyle;
import co.leancode.inlay.InlayNavigator;
import kotlin.Unit;

/**
 * The navigation calls of {@link MainActivity}, written in Java against the
 * Java output of inlay_gen (the {@code java:} section of {@code inlay.yaml}).
 *
 * <p>Shows how a Java host consumes inlay's Kotlin API: the navigator is
 * {@code InlayNavigator.INSTANCE}, and result callbacks are Kotlin
 * {@code Function1} lambdas that return {@code Unit.INSTANCE}. The generated
 * route classes are plain final classes with a constructor, getters and the
 * same {@code FlutterRoute} / {@code FlutterRouteWithResult} contracts as the
 * Kotlin ones, so the typed {@code onResult} overloads deliver already-decoded
 * values ({@code Long}, {@code Boolean}).
 */
public class JavaHostActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_java_host);
        setTitle("Java host");

        findViewById(R.id.btnJavaGreeting).setOnClickListener(v ->
                InlayNavigator.INSTANCE.push(this, new GreetingPage("Java", GreetingStyle.formal)));

        findViewById(R.id.btnJavaCounter).setOnClickListener(v ->
                // Native -> Flutter -> typed result back (count: Long, or null when dismissed).
                InlayNavigator.INSTANCE.push(this, new CounterPage(null), count -> {
                    showResult("Counter", count == null ? "dismissed" : count.toString());
                    return Unit.INSTANCE;
                }));

        findViewById(R.id.btnJavaConfirmDialog).setOnClickListener(v ->
                // Native -> Flutter dialog -> typed result back (confirmed: Boolean).
                InlayNavigator.INSTANCE.presentDialog(
                        this,
                        new ConfirmActionDialog("delete", "Are you sure?"),
                        confirmed -> {
                            showResult("Confirm dialog", confirmed == null ? "dismissed" : confirmed.toString());
                            return Unit.INSTANCE;
                        }));
    }

    private void showResult(String label, String value) {
        new AlertDialog.Builder(this)
                .setTitle(label + " returned")
                .setMessage(value)
                .setPositiveButton("OK", null)
                .show();
    }
}
