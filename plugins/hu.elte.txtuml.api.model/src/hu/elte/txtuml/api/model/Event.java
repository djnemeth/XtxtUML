package hu.elte.txtuml.api.model;

/**
 * Base class for events in the model.
 * 
 * <p>
 * <b>Represents:</b> event
 * <p>
 * <b>Usage:</b>
 * <p>
 * 
 * As <code>Event</code> is just a base class for events, it is not used
 * directly to define certain kinds of events.
 * 
 * <p>
 * <b>Java restrictions:</b>
 * <ul>
 * <li><i>Instantiate:</i> disallowed</li>
 * <li><i>Define subtype:</i> disallowed, inherit from its predefined
 * subclasses, like {@link Signal}</li>
 * </ul>
 * 
 * See the documentation of {@link Model} for an overview on modeling in JtxtUML.
 *
 * @author Gabor Ferenc Kovacs
 * @see Signal
 * 
 */
public class Event implements ModelElement {

	/**
	 * Sole constructor of <code>Event</code>.
	 */
	Event() {
	}

	@Override
	public String toString() {
		return "event:" + getClass().getSimpleName();
	}

}
