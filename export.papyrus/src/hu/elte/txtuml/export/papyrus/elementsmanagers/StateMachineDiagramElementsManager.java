package hu.elte.txtuml.export.papyrus.elementsmanagers;

import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.gef.EditPart;
import org.eclipse.gmf.runtime.diagram.ui.editparts.DiagramEditPart;
import org.eclipse.gmf.runtime.notation.View;
import org.eclipse.papyrus.infra.core.services.ServiceException;
import org.eclipse.papyrus.uml.diagram.statemachine.edit.parts.StateEditPart;
import org.eclipse.uml2.uml.Element;
import hu.elte.txtuml.export.papyrus.ModelManager;
import hu.elte.txtuml.export.papyrus.preferences.PreferencesManager;

public class StateMachineDiagramElementsManager extends AbstractDiagramElementsManager {

	private PreferencesManager preferencesManager;
	
	private List<String> elementsToBeAdded;
	private List<String> edgesToBeAdded;

	public StateMachineDiagramElementsManager(ModelManager modelManager,DiagramEditPart diagramEditPart) {
		super(modelManager, diagramEditPart);
		preferencesManager = new PreferencesManager();
		elementsToBeAdded = generateElementsToBeAdded();
		edgesToBeAdded = generateEdgesToBeAdded();
	}
	
	private List<String> generateElementsToBeAdded() {
		List<String> nodes = new LinkedList<String>(Arrays.asList("FinalState", "State", "Pseudostate"));
		
		if(preferencesManager.getBoolean(PreferencesManager.STATEMACHINE_DIAGRAM_CONSTRAINT_PREF))
			nodes.add("Constraint");
		if(preferencesManager.getBoolean(PreferencesManager.STATEMACHINE_DIAGRAM_COMMENT_PREF))
			nodes.add("Comment");
		
		return nodes;
	}
	
	private List<String> generateEdgesToBeAdded() {
		List<String> edges = Arrays.asList("Transition");
		return edges;
	}
	
	@Override
	public void addElementsToDiagram(List<Element> elements) throws ServiceException {
		
		/* The diagram creation creates an empty StateMachine, but it may have more Regions. 
		 * So we delete it and place it on the diagram again.  */
		EditPart stateMachineEditpart = (EditPart) diagramEditPart.getChildren().get(0);
		View smModel = (View) stateMachineEditpart.getModel();
		Element smElement = (Element) smModel.getElement();
		
		super.removeEditParts(diagramEditPart.getEditingDomain(), Arrays.asList(stateMachineEditpart));
		super.addElementsToEditpart(diagramEditPart, Arrays.asList(smElement));
		
		stateMachineEditpart = (EditPart) diagramEditPart.getChildren().get(0);
		fillState(stateMachineEditpart);
	}
	

	private void fillState(EditPart state){
		EditPart stateCompartmentEditPart = (EditPart) state.getChildren().get(1);
		@SuppressWarnings("unchecked")
		List<EditPart> regions = stateCompartmentEditPart.getChildren();
		
		for(EditPart region : regions){
			EditPart regionCompartment = (EditPart) region.getChildren().get(0);
			this.addSubElements(regionCompartment);
		}
	}
	
	private void addSubElements(EditPart ep){
		EObject parent = ((View) ep.getModel()).getElement();
		List<Element> list = ((Element) parent).getOwnedElements();
		
		List<Element> nodes = modelManager.getElementsOfTypesFromList(list, elementsToBeAdded);
		List<Element> transitions = modelManager.getElementsOfTypesFromList(list, edgesToBeAdded);
	
		addElementsToEditpart(ep, nodes);
		addElementsToEditpart(ep, transitions);

		@SuppressWarnings("unchecked")
		List<EditPart> subEPs = ep.getChildren();
		for(EditPart subEP : subEPs){
			if(subEP instanceof StateEditPart){
				fillState(subEP);
			}
		}
	}
}
