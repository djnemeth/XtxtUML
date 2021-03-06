package hu.elte.txtuml.export.papyrus.handlers;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.jface.wizard.WizardDialog;

import hu.elte.txtuml.export.papyrus.wizardz.UmlToPapyrusWizard;

/**
 * Handles the call to visualization from wizard
 */
public class WizardHandler extends AbstractHandler{
	/**
	 * Opens a UmlToPapyrus wizard
	 */
	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		
		WizardDialog wizardDialog = new WizardDialog( null,
	      new UmlToPapyrusWizard());
		
		wizardDialog.open();
		return null;
	}

}
