package hu.elte.txtuml.api.model;

import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;

import hu.elte.txtuml.api.model.backend.DiagnosticsServiceConnector;
import hu.elte.txtuml.api.model.backend.log.ExecutorLog;
import hu.elte.txtuml.api.model.report.ModelExecutionEventsListener;
import hu.elte.txtuml.api.model.report.RuntimeErrorsListener;
import hu.elte.txtuml.api.model.report.RuntimeWarningsListener;
import hu.elte.txtuml.utils.Logger;

/**
 * The class that manages the model execution.
 * 
 * <p>
 * <b>Represents:</b> no model element
 * <p>
 * <b>Usage:</b>
 * <p>
 * 
 * The model executor starts automatically when this class is accessed from
 * code. To shut it down, call either {@link #shutdown} or {@link #shutdownNow}.
 * <p>
 * See {@link ModelExecutor.Settings} to change settings of the execution.
 * 
 * <p>
 * <b>Java restrictions:</b>
 * <ul>
 * <li><i>Instantiate:</i> disallowed</li>
 * <li><i>Define subtype:</i> disallowed</li>
 * </ul>
 * 
 * <p>
 * <b>Implementation note:</b>
 * <p>
 * Accessed from multiple threads, so must be thread-safe.
 * <p>
 * See the documentation of {@link Model} for an overview on modeling in
 * JtxtUML.
 */
public final class ModelExecutor implements ModelElement {

	/**
	 * The thread on which the model execution will run.
	 */
	private static final ModelExecutorThread thread = new ModelExecutorThread().autoStart();

	/**
	 * The object which prints the runtime log of the executor.
	 */
	private static final ExecutorLog executorLog = new ExecutorLog();

	/**
	 * Sole constructor of <code>ModelExecutor</code>, which is designed to be
	 * an uninstantiatable class.
	 */
	private ModelExecutor() {
	}

	// SETTINGS

	/**
	 * Provides all the global settings of txtUML model execution through its
	 * static methods.
	 * 
	 * <p>
	 * <b>Represents:</b> no model element
	 * <p>
	 * <b>Usage:</b>
	 * <p>
	 * 
	 * Calling its static methods only affect the model execution, they are not
	 * exported.
	 * <p>
	 * Its static methods might be called from anywhere in the model as they are
	 * not harmful to the model execution in any way. However, it is strongly
	 * advised to perform any changes in the settings before the model execution
	 * is started to prevent confusing and unexpected results.
	 * 
	 * <p>
	 * <b>Java restrictions:</b>
	 * <ul>
	 * <li><i>Instantiate:</i> disallowed</li>
	 * <li><i>Define subtype:</i> disallowed</li>
	 * </ul>
	 * 
	 * <p>
	 * See the documentation of {@link Model} for an overview on modeling in
	 * JtxtUML.
	 */
	public static final class Settings implements ModelElement {

		/**
		 * Indicates whether optional dynamic checks should be performed. Is
		 * <code>true</code> by default.
		 */
		private static volatile boolean dynamicChecks = true;

		/**
		 * A lock on {@link Settings#executionTimeMultiplier}.
		 */
		private static final Object LOCK_ON_EXECUTION_TIME_MULTIPLIER = new Object();

		/**
		 * The current execution time multiplier which affects how long
		 * time-related events should take.
		 */
		private static float executionTimeMultiplier = 1f;

		/**
		 * Indicates whether the execution time multiplier can still be changed
		 * or it has already been locked by calling
		 * {@link #lockExecutionTimeMultiplier()}.
		 */
		private static volatile boolean canChangeExecutionTimeMultiplier = true;

		/**
		 * Sole constructor of <code>Settings</code>, which is designed to be an
		 * uninstantiatable class.
		 */
		private Settings() {
		}

		/**
		 * Sets whether executor's non-error log has to be shown. By default, it
		 * is switched off.
		 * <p>
		 * Executor's non-error log consists of short messages reporting about
		 * certain changes in the runtime model, like a model object processing
		 * a signal or using a transition.
		 * 
		 * @param newValue
		 *            whether executor's non-error log has to shown
		 */
		public static void setExecutorLog(boolean newValue) {
			executorLog.setLogEvents(newValue);
		}

		/**
		 * Sets whether optional dynamic checks should be performed during model
		 * execution. These checks include checking lower bounds of
		 * multiplicities, checking whether the guards of two transitions from
		 * the same vertex are overlapping, etc.
		 * <p>
		 * These checks are performed by default.
		 * 
		 * @param newValue
		 *            whether optional dynamic checks should be performed
		 */
		public static void setDynamicChecks(boolean newValue) {
			Settings.dynamicChecks = newValue;
		}

		/**
		 * The model execution time helps testing txtUML models in the following
		 * way: when any time-related event inside the model is set to take
		 * <i>ms</i> milliseconds, that event will take <i>ms</i> <code>*</code>
		 * <i>mul</i> millseconds during model execution, where <i>mul</i> is
		 * the current execution time multiplier. This way, txtUML models might
		 * be tested at the desired speed.
		 * <p>
		 * Execution time multiplier is 1 by default.
		 * 
		 * @param newMultiplier
		 *            the new execution time multiplier
		 */
		public static void setExecutionTimeMultiplier(float newMultiplier) {
			synchronized (Settings.LOCK_ON_EXECUTION_TIME_MULTIPLIER) {
				if (Settings.canChangeExecutionTimeMultiplier) {
					Settings.executionTimeMultiplier = newMultiplier;
				} else {
					Report.error.forEach(x -> x.changingLockedExecutionTimeMultiplier());
				}
			}
		}

		/**
		 * The model execution time helps testing txtUML models in the following
		 * way: when any time-related event inside the model is set to take
		 * <i>ms</i> milliseconds, that event will take <i>ms</i> <code>*</code>
		 * <i>mul</i> millseconds during model execution, where <i>mul</i> is
		 * the current execution time multiplier. This way, txtUML models might
		 * be tested at the desired speed.
		 * 
		 * @return the current execution time multiplier
		 * @see #setExecutionTimeMultiplier(float)
		 */
		public static float getExecutionTimeMultiplier() {
			return Settings.executionTimeMultiplier;
		}

		/**
		 * Provides a conversion from <i>'real time'</i> to model execution time
		 * by multiplying its parameter with the execution time multiplier.
		 * <p>
		 * The model execution time helps testing txtUML models in the following
		 * way: when any time-related event inside the model is set to take
		 * <i>ms</i> milliseconds, that event will take <i>ms</i> <code>*</code>
		 * <i>mul</i> millseconds during model execution, where <i>mul</i> is
		 * the current execution time multiplier. This way, txtUML models might
		 * be tested at the desired speed.
		 * 
		 * @param time
		 *            the amount of time to be given in model execution time
		 * @return the specified amount of time in model execution time
		 * @see #setExecutionTimeMultiplier(float)
		 */
		public static long inExecutionTime(long time) {
			return (long) (time * executionTimeMultiplier);
		}

		/**
		 * Locks the execution time multiplier so that it may not be changed in
		 * the future. It should be called when a time-related event happens in
		 * the model to ensure that such events are not influenced by the change
		 * of this multiplier in a bad or unspecified way. If called multiple
		 * times, this method does nothing after the first call.
		 */
		public static void lockExecutionTimeMultiplier() {
			Settings.canChangeExecutionTimeMultiplier = false;
		}

		/**
		 * @return whether optional dynamic checks should be performed
		 */
		static boolean dynamicChecks() {
			return Settings.dynamicChecks;
		}

	}

	// REPORT

	/**
	 * A special class to manage runtime reports about the model execution.
	 * 
	 * <p>
	 * <b>Represents:</b> no model element
	 * <p>
	 * <b>Usage:</b>
	 * <p>
	 * 
	 * Calling its static methods only affect the model execution, they are not
	 * exported.
	 * 
	 * <p>
	 * <b>Java restrictions:</b>
	 * <ul>
	 * <li><i>Instantiate:</i> disallowed</li>
	 * <li><i>Define subtype:</i> disallowed</li>
	 * </ul>
	 * 
	 * <p>
	 * See the documentation of {@link Model} for an overview on modeling in
	 * JtxtUML.
	 */
	public static final class Report {

		/**
		 * Registered {@link ModelExecutionEventsListener}s.
		 */
		static final Queue<ModelExecutionEventsListener> event = new ConcurrentLinkedQueue<>();

		/**
		 * Registered {@link RuntimeErrorsListener}s.
		 */
		static final Queue<RuntimeErrorsListener> error = new ConcurrentLinkedQueue<>();

		/**
		 * Registered {@link RuntimeWarningsListener}s.
		 */
		static final Queue<RuntimeWarningsListener> warning = new ConcurrentLinkedQueue<>();

		static {
			DiagnosticsServiceConnector.startAndGetInstance();
		}

		public static void addModelExecutionEventsListener(ModelExecutionEventsListener listener) {
			event.add(listener);
		}

		public static void addRuntimeErrorsListener(RuntimeErrorsListener listener) {
			error.add(listener);
		}

		public static void addRuntimeWarningsListener(RuntimeWarningsListener listener) {
			warning.add(listener);
		}

		public static void removeModelExecutionEventsListener(ModelExecutionEventsListener listener) {
			event.remove(listener);
		}

		public static void removeRuntimeErrorsListener(RuntimeErrorsListener listener) {
			error.remove(listener);
		}

		public static void removeRuntimeWarningsListener(RuntimeWarningsListener listener) {
			warning.remove(listener);
		}
	}

	// EXECUTION

	/**
	 * Sets the model executor to be shut down after the currently running and
	 * all scheduled actions have been performed and every non-external event
	 * caused by them have been processed. To shut down the executor instantly,
	 * call {@link #shutdownNow}.
	 * <p>
	 * This method <b>does not</b> await the termination of the executor, it
	 * returns instantly.
	 * 
	 * @see #awaitTermination
	 */
	public static void shutdown() {
		thread.shutdown();
	}

	/**
	 * Shuts down the model executor without waiting for any currently running
	 * or scheduled actions to perform. In most cases, {@link #shutdown} should
	 * be called instead.
	 * 
	 * This method <b>does not</b> await the termination of the executor, it
	 * returns instantly.
	 * 
	 * @see #awaitTermination
	 */
	public static void shutdownNow() {
		thread.shutdownImmediately();
	}

	/**
	 * This method awaits the model execution to terminate and only returns
	 * after (or when the current thread is interrupted).
	 */
	public static void awaitTermination() {
		try {
			thread.join();
		} catch (InterruptedException e) {
			Logger.sys.error("Interrupted while awaiting termination", e);
		}
	}

	/**
	 * Registers the specified {@link Runnable} to be run when the model
	 * executor is shut down.
	 * 
	 * @param shutdownAction
	 *            the action to be run when the executor is shut down
	 */
	public static void addToShutdownQueue(Runnable shutdownAction) {
		thread.addToShutdownQueue(shutdownAction);
	}

	/**
	 * Sends a signal to the specified target object asynchronously.
	 * 
	 * @param target
	 *            the target object of the send operation
	 * @param signal
	 *            the signal to send
	 */
	static void send(Region target, Signal signal) {
		send(target, null, signal);
	}
	
	/**
	 * Sends a signal to the specified target object asynchronously.
	 * 
	 * @param target
	 *            the target object of the send operation
	 * @param port
	 *            the port through which the signal arrived (might be
	 *            {@code null} in case the signal did not arrive through a port)
	 * @param signal
	 *            the signal to send
	 */
	static void send(Region target, Port<?, ?> port, Signal signal) {
		thread.send(target, port, signal);
	}

	/**
	 * Registers a check of the lower bound of the specified association end's
	 * multiplicity to be performed in the next <i>execution step</i>.
	 * <p>
	 * The lower bound of multiplicities might be offended temporarily but has
	 * to be restored before returning from the current <i>execution step</i>.
	 * <p>
	 * See the documentation of {@link Model} for information about execution
	 * steps.
	 * 
	 * @param obj
	 *            the object on the opposite end of the association
	 * @param assocEnd
	 *            the association end which's multiplicity is to be checked
	 */
	static void checkLowerBoundInNextExecutionStep(ModelClass obj, Class<? extends AssociationEnd<?, ?>> assocEnd) {

		thread.checkLowerBoundOfMultiplicity(obj, assocEnd);
	}

}
