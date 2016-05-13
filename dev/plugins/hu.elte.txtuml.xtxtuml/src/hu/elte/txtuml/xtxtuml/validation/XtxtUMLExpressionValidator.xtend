package hu.elte.txtuml.xtxtuml.validation;

import com.google.inject.Inject
import hu.elte.txtuml.api.model.Port
import hu.elte.txtuml.api.model.Signal
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociation
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociationEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClass
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClassPropertyAccessExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUDeleteObjectExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUEntryOrExitActivity
import hu.elte.txtuml.xtxtuml.xtxtUML.XUOperation
import hu.elte.txtuml.xtxtuml.xtxtUML.XUPort
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSendSignalExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignal
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignalAccessExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUState
import hu.elte.txtuml.xtxtuml.xtxtUML.XUStateType
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransition
import java.util.HashSet
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.common.types.JvmOperation
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.validation.Check
import org.eclipse.xtext.xbase.XAbstractFeatureCall
import org.eclipse.xtext.xbase.XBlockExpression
import org.eclipse.xtext.xbase.XExpression
import org.eclipse.xtext.xbase.XFeatureCall
import org.eclipse.xtext.xbase.XMemberFeatureCall
import org.eclipse.xtext.xbase.XbasePackage
import org.eclipse.xtext.xbase.jvmmodel.IJvmModelAssociations
import org.eclipse.xtext.xbase.typesystem.util.ExtendedEarlyExitComputer

import static hu.elte.txtuml.xtxtuml.validation.XtxtUMLIssueCodes.*
import static hu.elte.txtuml.xtxtuml.xtxtUML.XtxtUMLPackage.Literals.*

class XtxtUMLExpressionValidator extends XtxtUMLTypeValidator {

	@Inject extension ExtendedEarlyExitComputer;
	@Inject extension IJvmModelAssociations;
	@Inject extension IQualifiedNameProvider;

	@Check
	def checkMandatoryIntentionalReturn(XUOperation operation) {
		val returnTypeName = operation.prefix?.type?.type?.fullyQualifiedName;
		if (returnTypeName != null && returnTypeName.toString != "void" && !operation.body.definiteEarlyExit) {
			error('''Operation «operation.name» in class «(operation.eContainer as XUClass).name» must return a result of type «returnTypeName.lastSegment»''',
				operation, XU_OPERATION__NAME, MISSING_RETURN);
		}
	}

	@Check
	def checkNoExplicitExtensionCall(XFeatureCall featureCall) {
		doCheckNoExplicitExtensionCall(featureCall)
	}

	@Check
	def checkNoExplicitExtensionCall(XMemberFeatureCall featureCall) {
		doCheckNoExplicitExtensionCall(featureCall)
	}

	@Check
	def checkXtxtUMLExplicitOperationCall(XFeatureCall featureCall) {
		doCheckExplicitOperationCall(featureCall)
	}

	@Check
	def checkXtxtUMLExplicitOperationCall(XMemberFeatureCall featureCall) {
		doCheckExplicitOperationCall(featureCall)
	}

	@Check
	def checkSignalAccessExpression(XUSignalAccessExpression sigExpr) {
		var container = sigExpr.eContainer;
		while (container != null && !(container instanceof XUEntryOrExitActivity) &&
			!(container instanceof XUTransition)) {
			container = container.eContainer;
		}

		if (container instanceof XUEntryOrExitActivity) {
			if (container.entry) {
				container = container.eContainer;
			} else {
				return;
			}
		}

		if (container == null || container.isReachableFromInitialState(newHashSet, true)) {
			error("'trigger' cannot be used here, as its container is directly reachable from the initial state",
				sigExpr, XU_SIGNAL_ACCESS_EXPRESSION__TRIGGER, INVALID_SIGNAL_ACCESS);
		}
	}

	@Check
	def checkSignalSentToPortIsRequired(XUSendSignalExpression sendExpr) {
		if (!sendExpr.target.isConformantWith(Port, false) || !sendExpr.signal.isConformantWith(Signal, false)) {
			return;
		}

		val sentSignalSourceElement = sendExpr.signal.actualType.type.primarySourceElement as XUSignal;

		val portSourceElement = sendExpr.target.actualType.type.primarySourceElement as XUPort;
		val requiredReceptionsOfPort = portSourceElement.members.findFirst[required]?.interface?.receptions;

		if (requiredReceptionsOfPort?.findFirst [
			signal?.fullyQualifiedName == sentSignalSourceElement?.fullyQualifiedName
		] == null) {
			error("Signal type " + sentSignalSourceElement.name + " is not required by port " + portSourceElement.name,
				sendExpr, XU_SEND_SIGNAL_EXPRESSION__SIGNAL, NOT_REQUIRED_SIGNAL);
		}
	}

	@Check
	def checkQueriedPortIsOwned(XUSendSignalExpression sendExpr) {
		if (!sendExpr.target.isConformantWith(Port, false)) {
			return;
		}

		val portType = sendExpr.target.actualType.type;
		val portEnclosingClassName = portType.eContainer?.fullyQualifiedName;
		val sendExprEnclosingClassName = EcoreUtil2.getContainerOfType(sendExpr, XUClass)?.fullyQualifiedName;

		if (portEnclosingClassName != sendExprEnclosingClassName) {
			error(
				"Port " + portType.simpleName + " does not belong to class " + sendExprEnclosingClassName?.lastSegment +
					" – signals can be sent only to owned ports",
				sendExpr,
				XU_SEND_SIGNAL_EXPRESSION__TARGET,
				QUERIED_PORT_IS_NOT_OWNED
			);
		}
	}

	@Check
	def checkAccessedClassPropertyIsSpecified(XUClassPropertyAccessExpression propAccessExpr) {
		if (propAccessExpr.right == null) {
			error("The accessed class property cannot be null", propAccessExpr,
				XU_CLASS_PROPERTY_ACCESS_EXPRESSION__ARROW, MISSING_CLASS_PROPERTY);
		}
	}

	@Check
	def checkOwnerOfAccessedClassProperty(XUClassPropertyAccessExpression propAccessExpr) {
		if (propAccessExpr.right == null) {
			return;
		}

		val leftSourceElement = propAccessExpr.left.actualType.type.primarySourceElement;
		if (!(leftSourceElement instanceof XUClass)) {
			return; // typechecks will mark it
		}

		val sourceClass = leftSourceElement as XUClass;
		switch (prop : propAccessExpr.right) {
			XUAssociationEnd: {
				val enclosingAssociation = prop.eContainer as XUAssociation;
				val validAccessor = enclosingAssociation.ends.findFirst[name != prop.name]?.endClass;

				if (sourceClass.fullyQualifiedName != validAccessor?.fullyQualifiedName) {
					error(
						"Association end " + enclosingAssociation.name + "." + prop.name +
							" is not accessible from class " + sourceClass?.name, propAccessExpr,
						XU_CLASS_PROPERTY_ACCESS_EXPRESSION__RIGHT, NOT_ACCESSIBLE_ASSOCIATION_END);
				} else if (prop.notNavigable) {
					error("Association end " + enclosingAssociation.name + "." + prop.name + " is not navigable",
						propAccessExpr, XU_CLASS_PROPERTY_ACCESS_EXPRESSION__RIGHT, NOT_NAVIGABLE_ASSOCIATION_END);
				}
			}
			XUPort: {
				val validAccessor = prop.eContainer as XUClass;
				if (sourceClass.fullyQualifiedName != validAccessor.fullyQualifiedName) {
					error(prop.name + " cannot be resolved as a port of class " + sourceClass.name, propAccessExpr,
						XU_CLASS_PROPERTY_ACCESS_EXPRESSION__RIGHT, NOT_ACCESSIBLE_PORT);
				}
			}
		}
	}

	/*
	 * TODO modify ExtensionScopeHelper
	 */
	def private doCheckNoExplicitExtensionCall(XAbstractFeatureCall featureCall) {
		if (featureCall.isExtension) {
			val actualArgs = featureCall.
				actualArguments
			;

			error('''The operation «featureCall.feature?.simpleName»(«actualArgs.drop(1).join(", ")[actualType.simpleName.replace("$", ".")]») is undefined for the class «actualArgs.head.actualType.simpleName.replace("$", ".")»''',
				featureCall, XbasePackage.Literals.XABSTRACT_FEATURE_CALL__FEATURE, UNDEFINED_OPERATION);
		}
	}

	def private doCheckExplicitOperationCall(XAbstractFeatureCall featureCall) {
		val explicitOperationCall = if (featureCall instanceof XFeatureCall) {
				featureCall.isExplicitOperationCall
			} else if (featureCall instanceof XMemberFeatureCall) {
				featureCall.isExplicitOperationCall
			} else {
				true
			}

		if (featureCall.feature instanceof JvmOperation && !explicitOperationCall) {
			error("Empty parentheses are required for operations without parameters", featureCall,
				XbasePackage.Literals.XABSTRACT_FEATURE_CALL__FEATURE, MISSING_OPERATION_PARENTHESES);
		}
	}

	def protected dispatch boolean isReachableFromInitialState(XUTransition transition, HashSet<XUState> visitedStates,
		boolean throughPseudostatesOnly) {
		val from = transition.sourceState;
		return from != null && (!throughPseudostatesOnly || from.isPseudostate) &&
			isReachableFromInitialState(from, visitedStates, throughPseudostatesOnly);
	}

	def protected dispatch boolean isReachableFromInitialState(XUState state, HashSet<XUState> visitedStates,
		boolean throughPseudostatesOnly) {
		if (state.type == XUStateType.INITIAL) {
			return true;
		}

		if (!visitedStates.add(state)) {
			return false;
		}

		return state.membersOfEnclosingElement.exists [
			it instanceof XUTransition &&
				(it as XUTransition).targetState?.fullyQualifiedName == state?.fullyQualifiedName &&
				isReachableFromInitialState(it, visitedStates, throughPseudostatesOnly)
		];
	}

	override protected isValueExpectedRecursive(XExpression expr) {
		val container = expr.eContainer;
		return switch (container) {
			XUSendSignalExpression,
			XUDeleteObjectExpression: true
			XBlockExpression: false
			default: super.isValueExpectedRecursive(expr)
		}
	}

}
