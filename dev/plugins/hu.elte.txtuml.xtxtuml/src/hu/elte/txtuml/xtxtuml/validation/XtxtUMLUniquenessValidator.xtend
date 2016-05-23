package hu.elte.txtuml.xtxtuml.validation;

import com.google.inject.Inject
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociation
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociationEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAttribute
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClass
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClassMember
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConnector
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConnectorEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConstructor
import hu.elte.txtuml.xtxtuml.xtxtUML.XUEntryOrExitActivity
import hu.elte.txtuml.xtxtuml.xtxtUML.XUFile
import hu.elte.txtuml.xtxtuml.xtxtUML.XUModelElement
import hu.elte.txtuml.xtxtuml.xtxtUML.XUOperation
import hu.elte.txtuml.xtxtuml.xtxtUML.XUPort
import hu.elte.txtuml.xtxtuml.xtxtUML.XUPortMember
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignal
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignalAttribute
import hu.elte.txtuml.xtxtuml.xtxtUML.XUState
import hu.elte.txtuml.xtxtuml.xtxtUML.XUStateMember
import hu.elte.txtuml.xtxtuml.xtxtUML.XUStateType
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransition
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionEffect
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionGuard
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionMember
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionPort
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionTrigger
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionVertex
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.common.types.JvmFormalParameter
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.validation.Check

import static hu.elte.txtuml.xtxtuml.validation.XtxtUMLIssueCodes.*
import static hu.elte.txtuml.xtxtuml.xtxtUML.XtxtUMLPackage.Literals.*

class XtxtUMLUniquenessValidator extends AbstractXtxtUMLValidator {

	@Inject extension IQualifiedNameProvider;

	@Check
	def checkModelElementNameIsUniqueExternal(XUModelElement modelElement) {
		try {
			Class.forName(modelElement.fullyQualifiedName.toString, false, getClass.getClassLoader);

			// class with the same qualified name is found
			error("Duplicate model element " + modelElement.name, modelElement, XU_MODEL_ELEMENT__NAME,
				NOT_UNIQUE_NAME);
		} catch (ClassNotFoundException ex) {
			// no problem
		}
	}

	@Check
	def checkModelElementNameIsUniqueInternal(XUModelElement modelElement) {
		val siblingsAndSelf = (modelElement.eContainer as XUFile).elements;
		if (siblingsAndSelf.exists [
			name == modelElement.name && it != modelElement // direct comparison is safe here
		]) {
			error("Duplicate model element " + modelElement.name, modelElement, XU_MODEL_ELEMENT__NAME,
				NOT_UNIQUE_NAME);
		}
	}

	@Check
	def checkSignalAttributeNameIsUnique(XUSignalAttribute attribute) {
		val containingSignal = attribute.eContainer as XUSignal;
		if (containingSignal.attributes.exists [
			name == attribute.name && it != attribute // direct comparison is safe here
		]) {
			error("Duplicate attribute " + attribute.name + " in signal " + containingSignal.name, attribute,
				XU_SIGNAL_ATTRIBUTE__NAME, NOT_UNIQUE_NAME);
		}
	}

	@Check
	def checkAttributeNameIsUnique(XUAttribute attribute) {
		val containingClass = attribute.eContainer as XUClass;
		if (containingClass.members.exists [
			it instanceof XUAttribute && (it as XUAttribute).name == attribute.name && it != attribute // direct comparison is safe here
		]) {
			error("Duplicate attribute " + attribute.name + " in class " + containingClass.name, attribute,
				XU_ATTRIBUTE__NAME, NOT_UNIQUE_NAME);
		}
	}

	@Check
	def checkConstructorIsUnique(XUConstructor ctor) {
		val enclosingClass = (ctor.eContainer as XUClass);
		if (enclosingClass.members.exists [
			it instanceof XUConstructor && {
				val otherCtor = it as XUConstructor;
				otherCtor.name == ctor.name && otherCtor.parameters.typeNames == ctor.parameters.typeNames
			} && it != ctor // direct comparison is safe here
		]) {
			error('''Duplicate constructor «ctor.name»(«ctor.parameters.typeNames.join(", ")») in class «enclosingClass.name»''',
				ctor, XU_CONSTRUCTOR__NAME, NOT_UNIQUE_CONSTRUCTOR);
		}
	}

	@Check
	def checkOperationIsUnique(XUOperation operation) {
		val containingClass = (operation.eContainer as XUClass);
		if (containingClass.members.exists [
			it instanceof XUOperation &&
				{
					val siblingOperationOrSelf = it as XUOperation;
					siblingOperationOrSelf.name == operation.name &&
						siblingOperationOrSelf.parameters.typeNames == operation.parameters.typeNames
				} && it != operation // direct comparison is safe here
		]) {
			error('''Duplicate operation «operation.name»(«operation.parameters.typeNames.join(", ")») in class «containingClass.name»''',
				operation, XU_OPERATION__NAME, NOT_UNIQUE_OPERATION);
		}
	}

	@Check
	def checkInitialStateIsUnique(XUState state) {
		if (state.type == XUStateType.INITIAL && state.membersOfEnclosingElement.exists [
			it instanceof XUState && (it as XUState).type == XUStateType.INITIAL && it != state // direct comparison is safe here
		]) {
			error("Duplicate initial pseudostate " + state.classQualifiedName +
				" – only one initial pseudostate per state machine level is allowed", state, XU_STATE__NAME,
				NOT_UNIQUE_INITIAL_STATE);
		}
	}

	@Check
	def checkStateNameIsUnique(XUState state) {
		if (state.membersOfEnclosingElement.exists [
			it instanceof XUState && (it as XUState).name == state.name && it != state || // direct comparison is safe here
			it instanceof XUTransition && (it as XUTransition).name == state.name ||
				it instanceof XUPort && (it as XUPort).name == state.name
		]) {
			error("State " + state.classQualifiedName +
				" must have a unique name among states, transitions and ports of the enclosing element", state,
				XU_STATE__NAME, NOT_UNIQUE_NAME);
		}
	}

	@Check
	def checkStateActivityIsUnique(XUEntryOrExitActivity stateActivity) {
		if ((stateActivity.eContainer as XUState).members.exists [
			it instanceof XUEntryOrExitActivity && (it as XUEntryOrExitActivity).entry == stateActivity.entry &&
				it != stateActivity // direct comparison is safe here
		]) {
			error(
				"Duplicate activity in state " + (stateActivity.eContainer as XUState).classQualifiedName,
				stateActivity,
				stateActivity.markerTargetForStateActivity,
				NOT_UNIQUE_STATE_ACTIVITY
			);
		}
	}

	@Check
	def checkInitialTransitionIsUnique(XUTransition transition) {
		val sourceState = transition.sourceState;
		if (sourceState?.type == XUStateType.INITIAL) {
			if (transition.membersOfEnclosingElement.exists [
				it instanceof XUTransition &&
					(it as XUTransition).sourceState?.fullyQualifiedName == sourceState?.fullyQualifiedName &&
					it != transition // direct comparison is safe here
			]) {
				error("Duplicate initial transition " + transition.classQualifiedName +
					" – only one per initial state is allowed", transition, XU_TRANSITION__NAME,
					NOT_UNIQUE_INITIAL_TRANSITION);
			}
		}
	}

	@Check
	def checkTransitionNameIsUnique(XUTransition transition) {
		if (transition.membersOfEnclosingElement.exists [
			it instanceof XUTransition && (it as XUTransition).name == transition.name && it != transition || // direct comparison is safe here
			it instanceof XUState && (it as XUState).name == transition.name ||
				it instanceof XUPort && (it as XUPort).name == transition.name
		]) {
			error("Transition " + transition.classQualifiedName +
				" must have a unique name among states, transitions and ports of the enclosing element",
				transition, XU_TRANSITION__NAME, NOT_UNIQUE_NAME);
		}

	}

	@Check
	def checkTransitionMemberIsUnique(XUTransitionMember transitionMember) {
		val enclosingTransition = transitionMember.eContainer as XUTransition;
		if (enclosingTransition.members.exists [
			eClass == transitionMember.eClass && (if (it instanceof XUTransitionVertex)
				from == (transitionMember as XUTransitionVertex).from
			else
				true) && it != transitionMember // direct comparison is safe here
		]) {
			error("Duplicate member in transition " + enclosingTransition.classQualifiedName, transitionMember,
				transitionMember.markerTargetForTransitionMember, NOT_UNIQUE_TRANSITION_MEMBER);
		}
	}

	@Check
	def checkPortNameIsUnique(XUPort port) {
		val containingClass = port.eContainer as XUClass;
		if (containingClass.members.exists [
			it instanceof XUPort && (it as XUPort).name == port.name && it != port // direct comparison is safe here
			|| it instanceof XUState && (it as XUState).name == port.name ||
				it instanceof XUTransition && (it as XUTransition).name == port.name
		]) {
			error("Port " + port.name + " in class " + containingClass.name +
				" must have a unique name among states, transitions and ports of the enclosing element", port,
				XU_CLASS_PROPERTY__NAME, NOT_UNIQUE_NAME);
		}
	}

	@Check
	def checkPortMemberIsUnique(XUPortMember portMember) {
		val enclosingPort = portMember.eContainer as XUPort;
		if (enclosingPort.members.exists [
			required == portMember.required && it != portMember // direct comparison is safe here
		]) {
			error("Duplicate interface type in port " + enclosingPort.name + " of class " +
				(enclosingPort.eContainer as XUClass).name, portMember,
				if(portMember.required) XU_PORT_MEMBER__REQUIRED else XU_PORT_MEMBER__PROVIDED,
				NOT_UNIQUE_PORT_MEMBER);
		}
	}

	@Check
	def checkAssociationEndNamesAreUnique(XUAssociationEnd associationEnd) {
		val association = associationEnd.eContainer as XUAssociation;
		if (1 < association.ends.filter[name == associationEnd.name].length) {
			error("Association end " + associationEnd.name + " in association " + association.name +
				" must have a unique name", associationEnd, XU_CLASS_PROPERTY__NAME, NOT_UNIQUE_NAME);
		}
	}

	@Check
	def checkConnectorEndIsUnique(XUConnectorEnd connectorEnd) {
		val container = connectorEnd.eContainer as XUConnector;
		if (container.ends.exists [
			(name == connectorEnd.name ||
				role?.fullyQualifiedName == connectorEnd.role?.fullyQualifiedName) && it != connectorEnd // direct comparison is safe here
		]) {
			error("Duplicate connector end " + connectorEnd.name + " in connector " + container.name +
				" – names and roles must be unique among ends of a connector", connectorEnd,
				XU_CONNECTOR_END__NAME, NOT_UNIQUE_CONNECTOR_END);
		}
	}

	def protected typeNames(EList<JvmFormalParameter> parameters) {
		parameters.map[parameterType?.type?.fullyQualifiedName]
	}

	/**
	 * Returns the class qualified name of the given class member.
	 * That is, the returned String will be the fully qualified name
	 * of the enclosing class of the given member.
	 */
	def protected classQualifiedName(XUClassMember classMember) {
		val fqnOfClass = EcoreUtil2.getContainerOfType(classMember, XUClass)?.fullyQualifiedName;
		if (fqnOfClass != null) {
			val fqnOfMember = classMember.fullyQualifiedName;
			return fqnOfClass.lastSegment + fqnOfMember.toString.substring(fqnOfClass.toString.length);
		}
	}

	def protected isPseudostate(EObject object) {
		object instanceof XUState && {
			val state = object as XUState;
			state.type == XUStateType.INITIAL || state.type == XUStateType.CHOICE
		}
	}

	def protected sourceState(XUTransition it) {
		sourceOrTargetState(true)
	}

	def protected targetState(XUTransition it) {
		sourceOrTargetState(false)
	}

	def private sourceOrTargetState(XUTransition it, boolean isSource) {
		(members.findFirst [
			it instanceof XUTransitionVertex && (it as XUTransitionVertex).from == isSource
		] as XUTransitionVertex)?.vertex
	}

	def protected markerTargetForStateActivity(XUEntryOrExitActivity stateActivity) {
		if(stateActivity.entry) XU_ENTRY_OR_EXIT_ACTIVITY__ENTRY else XU_ENTRY_OR_EXIT_ACTIVITY__EXIT
	}

	def protected markerTargetForTransitionMember(XUTransitionMember transitionMember) {
		switch (transitionMember) {
			XUTransitionTrigger:
				XU_TRANSITION_TRIGGER__TRIGGER_KEYWORD
			XUTransitionVertex:
				if(transitionMember.from) XU_TRANSITION_VERTEX__FROM else XU_TRANSITION_VERTEX__TO
			XUTransitionEffect:
				XU_TRANSITION_EFFECT__EFFECT
			XUTransitionGuard:
				XU_TRANSITION_GUARD__GUARD
			XUTransitionPort:
				XU_TRANSITION_PORT__PORT_KEYWORD
		}
	}

	def protected membersOfEnclosingElement(XUStateMember stateMember) {
		switch (container : stateMember.eContainer) {
			XUClass: container.members
			XUState: container.members
		}
	}

}
