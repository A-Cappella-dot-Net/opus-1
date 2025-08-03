package net.a_cappella.cembalo.cukes;

import org.junit.platform.suite.api.ConfigurationParameter;
import org.junit.platform.suite.api.IncludeEngines;
import org.junit.platform.suite.api.SelectClasspathResource;
import org.junit.platform.suite.api.Suite;

import static io.cucumber.junit.platform.engine.Constants.*;

@Suite
@IncludeEngines("cucumber")
@SelectClasspathResource("src/test/resources/cukes")
@ConfigurationParameter(key = FEATURES_PROPERTY_NAME, value = "src/test/resources/cukes")
@ConfigurationParameter(key = PLUGIN_PROPERTY_NAME, value = "pretty, html:target/cucumber-reports/cucumber.html")
@ConfigurationParameter(key = GLUE_PROPERTY_NAME, value = "net/a_cappella/cembalo/cukes")
public class RunCukesTest {
}
