package hu.elte.txtuml.export.papyrus.elementsarrangers;

import java.util.List;

import org.eclipse.gef.EditPart;
import org.eclipse.gmf.runtime.diagram.ui.editparts.DiagramEditPart;

public class ActivityDiagramElementsArranger extends AbstractDiagramElementsArranger {

	@Override
	public void arrange(DiagramEditPart diagep) {
		EditPart activityEditpart = (EditPart) diagep.getChildren().get(0);
		EditPart activityContentEditpart = (EditPart) activityEditpart.getChildren().get(5);
		@SuppressWarnings("unchecked")
		List<EditPart> listEp =  activityContentEditpart.getChildren();
		super.arrangeAll(activityContentEditpart, listEp);
		super.hideConnectionLabelsForEditParts(listEp);	}	
}
