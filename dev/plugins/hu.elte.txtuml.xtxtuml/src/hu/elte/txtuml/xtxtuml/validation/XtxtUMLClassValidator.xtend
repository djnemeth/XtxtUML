package hu.elte.txtuml.xtxtuml.validation;

import com.google.inject.Inject
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClass
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClassMember
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConstructor
import hu.elte.txtuml.xtxtuml.xtxtUML.XUEntryOrExitActivity
import hu.elte.txtuml.xtxtuml.xtxtUML.XUState
import hu.elte.txtuml.xtxtuml.xtxtUML.XUStateMember
import hu.elte.txtuml.xtxtuml.xtxtUML.XUStateType
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransition
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionGuard
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionMember
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionPort
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionTrigger
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionVertex
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.validation.Check

import static hu.elte.txtuml.xtxtuml.validation.XtxtUMLIssueCodes.*
import static hu.elte.txtuml.xtxtuml.xtxtUML.XtxtUMLPackage.Literals.*

class XtxtUMLClassValidator extends XtxtUMLFileValidator {

	@Inject extension IQualifiedNameProvider;

	@Check
	def checkNoCycleInClassHiearchy(XUClass clazz) {
		if (clazz.superClass == null) {
			return;
		}

		val visitedClasses = newHashSet;
		visitedClasses.add(clazz);

		var currentClass = clazz.superClass;
		while (currentClass != null) {
			if (visitedClasses.contains(currentClass)) {
				error("Cycle in hierarchy of class " + clazz.name + " reaching " + currentClass.name,
					XU_CLASS__SUPER_CLASS, CLASS_HIERARCHY_CYCLE);
				return;
			}

			visitedClasses.add(currentClass);
			currentClass = currentClass.superClass;
		}
	}

	@Check
	def checkConstructorName(XUConstructor ctor) {
		val name = ctor.name;
		val enclosingClassName = (ctor.eContainer as XUClass).name;
		if (name != enclosingClassName) {
			error('''Constructor «name»(«ctor.parameters.typeNames.join(", ")») in class «enclosingClassName» must be named as its enclosing class''',
				ctor, XU_CONSTRUCTOR__NAME, INVALID_CONSTRUCTOR_NAME);
		}
	}

	@Check
	def checkInitialStateIsDefinedInClass(XUClass clazz) {
		if (clazz.members.isInitialStateMissing) {
			missingInitialState(clazz, "class " + clazz.name, XU_MODEL_ELEMENT__NAME)
		}
	}

	@Check
	def checkInitialStateIsDefinedInCompositeState(XUState state) {
		if (state.type == XUStateType.COMPOSITE && state.members.isInitialStateMissing) {
			missingInitialState(state, "composite state " + state.classQualifiedName, XU_STATE__NAME)
		}
	}

	@Check
	def checkPseudostateIsLeavable(XUState state) {
		if (state.isPseudostate && !state.membersOfEnclosingElement.exists [
			it instanceof XUTransition &&
				(it as XUTransition).sourceState?.fullyQualifiedName == state.fullyQualifiedName
		]) {
			error("There are no outgoing transitions from pseudostate " + state.classQualifiedName +
				" – state machines cannot stop in pseudostates", state, XU_STATE__NAME, NOT_LEAVABLE_PSEUDOSTATE);
		}
	}

	@Check
	def checkStateIsReachable(XUState state) {
		if (!state.membersOfEnclosingElement.isInitialStateMissing &&
			!state.isReachableFromInitialState(newHashSet, false)) {
			warning("State " + state.classQualifiedName + " is unreachable", state, XU_STATE__NAME, UNREACHABLE_STATE);
		}
	}

	@Check
	def checkStateOrTransitionIsDefinedInClassOrCompositeState(XUStateMember stateMember) {
		var isStateOrTransition = false;
		val nameAndMarkerTarget = switch (stateMember) {
			XUState: {
				isStateOrTransition = true;
				"State " -> XU_STATE__NAME
			}
			XUTransition: {
				isStateOrTransition = true;
				"Transition " -> XU_TRANSITION__NAME
			}
		}

		if (isStateOrTransition && stateMember.eContainer instanceof XUState &&
			(stateMember.eContainer as XUState).type != XUStateType.COMPOSITE) {
			error(nameAndMarkerTarget.key + (stateMember as XUClassMember).classQualifiedName +
				" can be defined only in a class or a composite state", stateMember, nameAndMarkerTarget.value,
				STATE_OR_TRANSITION_IN_NOT_COMPOSITE_STATE);
		}
	}

	@Check
	def checkNoActivityInPseudostate(XUEntryOrExitActivity activity) {
		if (activity.eContainer.isPseudostate) {
			error("Activities must not be present in pseudostate " +
				(activity.eContainer as XUState).classQualifiedName, activity, activity.markerTargetForStateActivity,
				ACTIVITY_IN_PSEUDOSTATE);
		}
	}

	@Check
	def checkMandatoryTransitionMembers(XUTransition transition) {
		var hasSource = false;
		var hasTarget = false;
		var hasTrigger = false;

		for (member : transition.members) {
			switch (member) {
				XUTransitionVertex:
					if (member.from) {
						hasSource = true;
						if (member.vertex.isPseudostate) {
							hasTrigger = true;
						}
					} else {
						hasTarget = true;
					}
				XUTransitionTrigger:
					hasTrigger = true
			}
		}

		if (!hasSource || !hasTarget || !hasTrigger) {
			error("Missing mandatory member ('from', 'to' or 'trigger') in transition " + transition.classQualifiedName,
				transition, XU_TRANSITION__NAME, MISSING_MANDATORY_TRANSITION_MEMBER);
		}
	}

	@Check
	def checkTransitionTargetIsNotInitialState(XUTransitionVertex transitionVertex) {
		if (!transitionVertex.from && transitionVertex.vertex?.type == XUStateType.INITIAL) {
			error("Initial state cannot be the target of transition " +
				(transitionVertex.eContainer as XUTransition).classQualifiedName, transitionVertex,
				XU_TRANSITION_VERTEX__VERTEX, TARGET_IS_INITIAL_STATE);
		}
	}

	@Check
	def checkGuardIsNotForInitialTransition(XUTransitionGuard transitionGuard) {
		val enclosingTransition = transitionGuard.eContainer as XUTransition;
		if (enclosingTransition.sourceState?.type == XUStateType.INITIAL) {
			error("Guards must not be present in initial transition " + enclosingTransition.classQualifiedName,
				transitionGuard, XU_TRANSITION_GUARD__GUARD, INVALID_TRANSITION_MEMBER);
		}
	}

	@Check
	def checkMemberOfTransitionFromPseudostate(XUTransitionMember transitionMember) {
		val enclosingTransition = transitionMember.eContainer as XUTransition;
		val sourceState = enclosingTransition.sourceState;

		if (sourceState != null && sourceState.isPseudostate &&
			(transitionMember instanceof XUTransitionTrigger || transitionMember instanceof XUTransitionPort)) {
			error(
				"Triggers and port restrictions must not be present in transition " +
					enclosingTransition.classQualifiedName + ", as its source is a pseudostate", transitionMember,
				transitionMember.markerTargetForTransitionMember, INVALID_TRANSITION_MEMBER);
		}
	}

	@Check
	def checkElseGuard(XUTransitionGuard guard) {
		if (guard.^else && (guard.eContainer as XUTransition).sourceState?.type != XUStateType.CHOICE) {
			error("'else' condition can be used only if the source of the transition is a choice pseudostate", guard,
				XU_TRANSITION_GUARD__ELSE, INVALID_ELSE_GUARD)
		}
	}

	@Check
	def checkOwnerOfTriggerPort(XUTransitionPort triggerPort) {
		val containingClass = EcoreUtil2.getContainerOfType(triggerPort, XUClass); // due to composite states
		if (triggerPort.port != null &&
			triggerPort.port.eContainer.fullyQualifiedName != containingClass.fullyQualifiedName) {
			error(triggerPort.port.name + " cannot be resolved as a port of class " + containingClass.name, triggerPort,
				XU_TRANSITION_PORT__PORT, NOT_OWNED_TRIGGER_PORT);
		}
	}

	@Check
	def checkTriggerPortIsBehavior(XUTransitionPort triggerPort) {
		if (triggerPort.port != null && !triggerPort.port.behavior) {
			error("Port " + triggerPort.port.name + " in class " + (triggerPort.port.eContainer as XUClass).name +
				" is not a behavior port", triggerPort, XU_TRANSITION_PORT__PORT, NOT_BEHAVIOR_TRIGGER_PORT)
		}
	}

	@Check
	def checkTransitionVertexLevel(XUTransitionVertex transitionVertex) {
		val enclosingTransition = transitionVertex.eContainer as XUTransition;
		if (transitionVertex.vertex != null && transitionVertex.vertex.eContainer.fullyQualifiedName !=
			enclosingTransition.eContainer.fullyQualifiedName) {
			error(
				"Invalid vertex " + transitionVertex.vertex.classQualifiedName + " in transition " +
					enclosingTransition.classQualifiedName + " – transition must not cross state machine levels",
				transitionVertex, XU_TRANSITION_VERTEX__VERTEX, VERTEX_LEVEL_MISMATCH);
		}
	}

	def protected isInitialStateMissing(EList<? extends EObject> members) {
		if (members == null) {
			return false;
		}

		var isOtherStateDefined = false;
		for (member : members) {
			if (member instanceof XUState) {
				if (member.type == XUStateType.INITIAL) {
					return false;
				} else {
					isOtherStateDefined = true;
				}
			}
		}

		return isOtherStateDefined;
	}

	def protected missingInitialState(EObject element, String name, EStructuralFeature markerTarget) {
		warning("Missing initial pseudostate in " + name +
			", therefore its other states and transitions are unreachable", element, markerTarget,
			MISSING_INITIAL_STATE);
	}

}
