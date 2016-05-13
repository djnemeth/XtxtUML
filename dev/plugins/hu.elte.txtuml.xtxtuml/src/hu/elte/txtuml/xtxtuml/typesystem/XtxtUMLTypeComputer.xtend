package hu.elte.txtuml.xtxtuml.typesystem

import com.google.inject.Inject
import hu.elte.txtuml.api.model.Collection
import hu.elte.txtuml.api.model.ModelClass
import hu.elte.txtuml.api.model.Port
import hu.elte.txtuml.api.model.Signal
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociationEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClass
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClassPropertyAccessExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUDeleteObjectExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUEntryOrExitActivity
import hu.elte.txtuml.xtxtuml.xtxtUML.XUPort
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSendSignalExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignalAccessExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUState
import hu.elte.txtuml.xtxtuml.xtxtUML.XUStateType
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransition
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionTrigger
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionVertex
import java.util.ArrayList
import java.util.HashSet
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.common.types.JvmGenericType
import org.eclipse.xtext.common.types.JvmType
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.xbase.XBlockExpression
import org.eclipse.xtext.xbase.XVariableDeclaration
import org.eclipse.xtext.xbase.annotations.typesystem.XbaseWithAnnotationsTypeComputer
import org.eclipse.xtext.xbase.jvmmodel.IJvmModelAssociations
import org.eclipse.xtext.xbase.resource.BatchLinkableResource
import org.eclipse.xtext.xbase.typesystem.computation.ITypeComputationState
import org.eclipse.xtext.xbase.typesystem.conformance.ConformanceFlags
import org.eclipse.xtext.xbase.typesystem.references.LightweightTypeReference
import org.eclipse.xtext.xbase.typesystem.references.ParameterizedTypeReference

class XtxtUMLTypeComputer extends XbaseWithAnnotationsTypeComputer {

	@Inject extension IJvmModelAssociations;
	@Inject extension IQualifiedNameProvider;

	def dispatch void computeTypes(XUClassPropertyAccessExpression accessExpr, ITypeComputationState state) {
		// expectations for childs are enabled by default,
		// see val foo = if (bar) foobar else baz
		val childState = state.withoutRootExpectation;

		// left child
		childState.computeTypes(accessExpr.left);

		// right child
		val rightChild = accessExpr.right;
		// if the reference couldn't be resolved
		if (rightChild?.name == null) {
			return;
		}

		switch (rightChild) {
			XUAssociationEnd: {
				val collectionOfAssocEndTypeRef = getTypeForName(Collection, state).
					rawTypeReference as ParameterizedTypeReference;
				collectionOfAssocEndTypeRef.addTypeArgument(
					state.nullSafeJvmElementTypeRef(rightChild.endClass, ModelClass));

				state.acceptActualType(collectionOfAssocEndTypeRef);
			}
			XUPort: {
				state.acceptActualType(state.nullSafeJvmElementTypeRef(rightChild, Port));
			}
		}
	}

	def private nullSafeJvmElementTypeRef(ITypeComputationState state, EObject sourceElement, Class<?> fallbackType) {
		val inferredType = sourceElement.getPrimaryJvmElement as JvmType;
		return if (inferredType != null) {
			state.referenceOwner.toLightweightTypeReference(inferredType)
		} else {
			val newEquivalent = sourceElement.findNewJvmEquivalent(state.referenceOwner.contextResourceSet.resources);
			if (newEquivalent != null) {
				state.referenceOwner.toLightweightTypeReference(newEquivalent)
			} else {
				getTypeForName(fallbackType, state)
			}
		}
	}

	/**
	 * Returns a <i>JvmType</i> equivalent of <code>sourceElement</code> from the given <code>resourceSet</code>,
	 * or <code>null</code>, if no equivalent could be found. The call of this method might be expensive.
	 */
	def private findNewJvmEquivalent(EObject sourceElement, EList<Resource> resourceSet) {
		for (resource : resourceSet) {
			if (resource instanceof BatchLinkableResource) {
				val newEquivalent = resource.allContents.findFirst [
					it instanceof JvmGenericType && it.fullyQualifiedName == sourceElement.fullyQualifiedName
				];
				if (newEquivalent != null) {
					return newEquivalent as JvmGenericType;
				}
			}
		}

		return null;
	}

	def dispatch computeTypes(XUSignalAccessExpression sigExpr, ITypeComputationState state) {
		var container = sigExpr.eContainer;
		while (container != null && !(container instanceof XUEntryOrExitActivity) &&
			!(container instanceof XUTransition)) {
			container = container.eContainer;
		}

		var visitedStates = new HashSet<XUState>();
		var type = switch (container) {
			XUEntryOrExitActivity:
				if (container.eContainer instanceof XUState) {
					getCommonSignalSuperType(
						container.eContainer as XUState,
						state,
						container.entry,
						visitedStates
					)
				} else {
					getTypeForName(Signal, state)
				}
			XUTransition:
				getCommonSignalSuperType(container, state, visitedStates)
			default:
				getTypeForName(Signal, state)
		}

		state.acceptActualType(type);
	}

	def private LightweightTypeReference getCommonSignalSuperType(
		XUTransition trans,
		ITypeComputationState cState,
		HashSet<XUState> visitedStates
	) {
		var trigger = (trans.members.findFirst [
			it instanceof XUTransitionTrigger
		] as XUTransitionTrigger)?.trigger;

		if (trigger != null) {
			return cState.nullSafeJvmElementTypeRef(trigger, Signal);
		}

		var from = (trans.members.findFirst [
			it instanceof XUTransitionVertex && (it as XUTransitionVertex).from
		] as XUTransitionVertex)?.vertex;

		if (from != null && from.type == XUStateType.CHOICE) {
			return getCommonSignalSuperType(from, cState, true, visitedStates);
		}

		return getTypeForName(Signal, cState);
	}

	def private LightweightTypeReference getCommonSignalSuperType(
		XUState state,
		ITypeComputationState cState,
		boolean toState,
		HashSet<XUState> visitedStates
	) {
		if (!visitedStates.add(state)) {
			return getTypeForName(Signal, cState);
		}

		val siblingsAndSelf = switch (c : state.eContainer) {
			XUState: c.members
			XUClass: c.members
		}

		var signalCandidates = new ArrayList<LightweightTypeReference>();
		for (siblingOrSelf : siblingsAndSelf) {
			if (siblingOrSelf instanceof XUTransition && ((siblingOrSelf as XUTransition).members.findFirst [
				it instanceof XUTransitionVertex && toState != (it as XUTransitionVertex).from
			] as XUTransitionVertex)?.vertex?.fullyQualifiedName == state.fullyQualifiedName) {
				signalCandidates.add(
					getCommonSignalSuperType(
						siblingOrSelf as XUTransition,
						cState,
						visitedStates
					)
				);
			}
		}

		return if (!signalCandidates.empty) {
			getCommonSuperType(signalCandidates, cState)
		} else {
			getTypeForName(Signal, cState)
		}
	}

	def dispatch computeTypes(XUDeleteObjectExpression deleteExpr, ITypeComputationState state) {
		state.computeTypes(deleteExpr.object);
		state.acceptActualType(state.getPrimitiveVoid);
	}

	def dispatch computeTypes(XUSendSignalExpression sendExpr, ITypeComputationState state) {
		state.computeTypes(sendExpr.signal);
		state.computeTypes(sendExpr.target);
		state.acceptActualType(state.getPrimitiveVoid);
	}

	override dispatch computeTypes(XBlockExpression block, ITypeComputationState state) {
		val children = block.expressions;
		if (!children.isEmpty) {
			state.withinScope(block);
		}

		for (child : children) {
			val expressionState = state.withoutExpectation; // no expectation
			expressionState.computeTypes(child);
			if (child instanceof XVariableDeclaration) {
				addLocalToCurrentScope(child as XVariableDeclaration, state);
			}
		}

		for (expectation : state.expectations) {
			val expectedType = expectation.expectedType;
			if (expectedType != null) {
				expectation.acceptActualType(expectedType, ConformanceFlags.CHECKED_SUCCESS);
			} else {
				expectation.acceptActualType(
					expectation.referenceOwner.newAnyTypeReference,
					ConformanceFlags.UNCHECKED
				);
			}
		}
	}

}
