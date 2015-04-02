package hu.elte.txtuml.export.papyrus.elementsarrangers.txtumllayout;

import java.util.List;

import org.eclipse.gef.EditPart;
import org.eclipse.gmf.runtime.diagram.ui.editparts.DiagramEditPart;
import org.eclipse.gmf.runtime.diagram.ui.editparts.GraphicalEditPart;
import org.eclipse.papyrus.uml.diagram.statemachine.edit.parts.StateEditPart;

public class StateMachineDiagramElementsTxtUmlArranger extends
		AbstractDiagramElementsTxtUmlArranger {

	public StateMachineDiagramElementsTxtUmlArranger(DiagramEditPart diagramEditPart) {
		super(diagramEditPart);
	}

	@Override
	public void arrange() {
		GraphicalEditPart stateMachineEP = (GraphicalEditPart) diagep.getChildren().get(0);
		super.resizeGraphicalEditPart(stateMachineEP, 400, 200);
		arrange_recurively(stateMachineEP);
		
	}

	private void arrange_recurively(GraphicalEditPart stateEP) {
		@SuppressWarnings("unchecked")
		List<GraphicalEditPart> stateChildren = stateEP.getChildren();

		@SuppressWarnings("unchecked")
		List<GraphicalEditPart> regions =  ((EditPart) stateChildren.get(1)).getChildren();
		
		for(GraphicalEditPart region: regions){		
			GraphicalEditPart regioncompartement = (GraphicalEditPart) region.getChildren().get(0);
			@SuppressWarnings("unchecked")
			List<EditPart> listEp = regioncompartement.getChildren();
			super.arrangeAll(regioncompartement, listEp);
			super.hideConnectionLabelsForEditParts(listEp);
			for(EditPart Ep : listEp){
				if(Ep instanceof StateEditPart){
					arrange_recurively((GraphicalEditPart) Ep);
					/* TODO : Resize and postfix arrange */
				}
			}
		}
	}

}
