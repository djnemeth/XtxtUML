package hu.elte.txtuml.export.uml2.transform.exporters;

import org.eclipse.emf.ecore.EClass;
import org.eclipse.jdt.core.dom.MethodDeclaration;
import org.eclipse.jdt.core.dom.TypeDeclaration;
import org.eclipse.uml2.uml.Activity;
import org.eclipse.uml2.uml.Pseudostate;
import org.eclipse.uml2.uml.PseudostateKind;
import org.eclipse.uml2.uml.Region;
import org.eclipse.uml2.uml.State;
import org.eclipse.uml2.uml.StateMachine;
import org.eclipse.uml2.uml.UMLPackage;
import org.eclipse.uml2.uml.Vertex;

import hu.elte.txtuml.export.uml2.TxtUMLToUML2.ExportMode;
import hu.elte.txtuml.export.uml2.transform.backend.ExportException;
import hu.elte.txtuml.utils.jdt.ElementTypeTeller;
import hu.elte.txtuml.utils.jdt.SharedUtils;

public class VertexExporter {

	private final ModelExporter modelExporter;
	private final StateMachine stateMachine;
	private final Region region;
	private ExportMode exportMode;

	public VertexExporter(ModelExporter modelExporter, StateMachine stateMachine, Region region,
			ExportMode exportMode) {
		this.modelExporter = modelExporter;
		this.stateMachine = stateMachine;
		this.region = region;
		this.exportMode = exportMode;
	}

	/**
	 * Exports the specified vertex.
	 * 
	 * @param vertexDeclaration
	 *            The type declaration of the txtUML vertex.
	 */
	public void exportVertex(TypeDeclaration vertexDeclaration) {
		Vertex vertex = createVertex(vertexDeclaration);

		if (ElementTypeTeller.isCompositeState(vertexDeclaration)) {
			exportSubRegion(vertexDeclaration, (State) vertex);
		}

		if (ElementTypeTeller.isState(vertexDeclaration) && exportMode == ExportMode.ExportActionCode) {

			exportStateEntryAction(vertexDeclaration, (State) vertex);
			exportStateExitAction(vertexDeclaration, (State) vertex);
		}

		modelExporter.getMapping().put(SharedUtils.qualifiedName(vertexDeclaration), vertex);
	}

	/**
	 * Exports a sub-region (a region belonging to a state).
	 * 
	 * @param stateDeclaration
	 *            The type declaration of the state.
	 * @param state
	 *            The UML2 state.
	 */
	private void exportSubRegion(TypeDeclaration stateDeclaration, State state) {
		Region subRegion = state.createRegion(state.getName());
		modelExporter.getRegionExporter().exportRegion(stateDeclaration, stateMachine, subRegion);

		subRegion.setState(state);
	}

	/**
	 * Exports the entry action of a state.
	 * 
	 * @param stateDeclaration
	 *            The type declaration txtUML state.
	 * @param exportedState
	 *            The exported UML2 state.
	 */
	private void exportStateEntryAction(TypeDeclaration stateDeclaration, State exportedState) {
		MethodDeclaration entryMethodDeclaration = SharedUtils.findMethodDeclarationByName(stateDeclaration, "entry");

		if (entryMethodDeclaration != null) {
			Activity activity = (Activity) exportedState.createEntry(exportedState.getName() + "_entry",
					UMLPackage.Literals.ACTIVITY);

			MethodBodyExporter.export(activity, modelExporter, entryMethodDeclaration);
		}
	}

	/**
	 * Exports the exit action of a state.
	 * 
	 * @param stateDeclaration
	 *            The type declaration txtUML state.
	 * @param exportedState
	 *            The exported UML2 state.
	 */
	private void exportStateExitAction(TypeDeclaration stateDeclaration, State exportedState) {
		MethodDeclaration exitMethodDeclaration = SharedUtils.findMethodDeclarationByName(stateDeclaration, "exit");

		if (exitMethodDeclaration != null) {
			Activity activity = (Activity) exportedState.createExit(exportedState.getName() + "_exit",
					UMLPackage.Literals.ACTIVITY);

			MethodBodyExporter.export(activity, modelExporter, exitMethodDeclaration);
		}
	}

	/**
	 * Creates a vertex of the right type (state/initial/choice) based on the
	 * given txtUML vertex type declaration.
	 * 
	 * @param vertexDeclaration
	 *            The type declaration of the vertex.
	 * @return The created vertex.
	 * @throws ExportException
	 */
	private Vertex createVertex(TypeDeclaration vertexDeclaration) {
		if (ElementTypeTeller.isInitialPseudoState(vertexDeclaration)) {
			return createInitial(vertexDeclaration);
		} else if (ElementTypeTeller.isChoicePseudoState(vertexDeclaration)) {
			return createChoice(vertexDeclaration);
		} else {
			return createVertex(vertexDeclaration, UMLPackage.Literals.STATE);
		}

	}

	private Vertex createVertex(TypeDeclaration vertexDeclaration, EClass type) {
		return region.createSubvertex(vertexDeclaration.getName().getFullyQualifiedName(), type);
	}

	/**
	 * Creates an UML2 initial pseudostate.
	 * 
	 * @param vertexDeclaration
	 *            The type declaration of the vertex.
	 * @return The created UML2 initial pseudostate.
	 */
	private Pseudostate createInitial(TypeDeclaration vertexDeclaration) {
		return (Pseudostate) createVertex(vertexDeclaration, UMLPackage.Literals.PSEUDOSTATE);
	}

	/**
	 * Creates an UML2 choice pseudostate.
	 * 
	 * @param vertexDeclaration
	 *            The type declaration of the vertex.
	 * @return The created UML2 choice pseudostate.
	 */
	private Pseudostate createChoice(TypeDeclaration vertexDeclaration) {
		Pseudostate result = (Pseudostate) createVertex(vertexDeclaration, UMLPackage.Literals.PSEUDOSTATE);
		result.setKind(PseudostateKind.CHOICE_LITERAL);
		return result;
	}

}
