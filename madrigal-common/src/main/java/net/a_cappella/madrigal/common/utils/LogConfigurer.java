package net.a_cappella.madrigal.common.utils;

import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.springframework.jmx.export.annotation.*;

/**
 * MBean which allows clients to change or retrieve the logging level for a Log4j Logger at runtime.
 */
@ManagedResource(objectName=LogConfigurer.MBEAN_NAME, description="Change Log4j Logging levels")
public class LogConfigurer {
	public static final String MBEAN_NAME = "log4j.mbeans:name=LogConfigurer";

	@ManagedOperation(description = "Returns the Logger LEVEL for the given logger name")
	@ManagedOperationParameters({ @ManagedOperationParameter(description = "The Logger Name", name = "loggerName") })
	public String getLoggerLevel(String loggerName) {
		Logger logger = Logger.getLogger(loggerName);
		Level loggerLevel = logger.getEffectiveLevel();
		return loggerLevel == null ? "The logger "+loggerName+" has no level" : loggerLevel.toString();
	}

	@ManagedOperation(description = "Set Logger Level")
	@ManagedOperationParameters({
		@ManagedOperationParameter(description = "The Logger Name", name = "loggerName"),
		@ManagedOperationParameter(description = "The Level to which the Logger must be set", name = "loggerLevel") })
	public void setLoggerLevel(String loggerName, String loggerLevel) {
		Logger thisLogger = Logger.getLogger(this.getClass());
		thisLogger.setLevel(Level.INFO);
		Logger logger = Logger.getLogger(loggerName);
		logger.setLevel(Level.toLevel(loggerLevel, Level.INFO));
		thisLogger.info("Set logger "+loggerName+" to level "+logger.getLevel());
	}

	@ManagedAttribute(description = "The Level to which the Root Logger must be set")
	public void setRootLoggerLevel(String rootLoggerLevel) {
		Logger thisLogger = Logger.getLogger(this.getClass());
		Logger.getRootLogger().setLevel(Level.toLevel(rootLoggerLevel, Level.INFO));
		thisLogger.info("Set root logger "+Logger.getRootLogger().getName()+" to level "+Logger.getRootLogger().getLevel());
	}

	@ManagedAttribute(description= "Returns the Root Logger LEVEL")
	public String getRootLoggerLevel() {
		Level rootLevel =  Logger.getRootLogger().getLevel();
		return rootLevel == null ? "Null" : rootLevel.toString();
	}
}
