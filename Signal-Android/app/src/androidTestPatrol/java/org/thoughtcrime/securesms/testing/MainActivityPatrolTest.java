package org.thoughtcrime.securesms.testing;

import androidx.test.platform.app.InstrumentationRegistry;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;
import org.thoughtcrime.securesms.ApplicationContext;
import org.thoughtcrime.securesms.MainActivity;
import pl.leancode.patrol.PatrolJUnitRunner;

@RunWith(Parameterized.class)
public class MainActivityPatrolTest {
  @Parameters(name = "{0}")
  public static Object[] testCases() {
    PatrolJUnitRunner instrumentation = (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();

    instrumentation.setUp(MainActivity.class);
    ApplicationContext.startPatrolDartIfNeeded();
    instrumentation.waitForPatrolAppService();
    return instrumentation.listDartTests();
  }

  private final String dartTestName;

  public MainActivityPatrolTest(String dartTestName) {
    this.dartTestName = dartTestName;
  }

  @Test
  public void runDartTest() {
    PatrolJUnitRunner instrumentation = (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
    instrumentation.runDartTest(dartTestName);
  }
}
