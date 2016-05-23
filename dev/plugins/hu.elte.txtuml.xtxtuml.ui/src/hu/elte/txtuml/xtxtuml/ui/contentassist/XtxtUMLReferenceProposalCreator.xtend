package hu.elte.txtuml.xtxtuml.ui.contentassist

import com.google.common.base.Function
import com.google.common.base.Predicate
import com.google.inject.Inject
import hu.elte.txtuml.api.model.DataType
import hu.elte.txtuml.api.model.ModelClass
import hu.elte.txtuml.api.model.Signal
import hu.elte.txtuml.api.model.external.ExternalType
import hu.elte.txtuml.xtxtuml.common.XtxtUMLReferenceProposalScopeProvider
import hu.elte.txtuml.xtxtuml.common.XtxtUMLUtils
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociation
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociationEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClass
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClassPropertyAccessExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUComposition
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConnector
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConnectorEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUDeclarationPrefix
import hu.elte.txtuml.xtxtuml.xtxtUML.XUOperation
import hu.elte.txtuml.xtxtuml.xtxtUML.XUPort
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignal
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignalAttribute
import hu.elte.txtuml.xtxtuml.xtxtUML.XUState
import hu.elte.txtuml.xtxtuml.xtxtUML.XUStateType
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransition
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionPort
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionTrigger
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionVertex
import hu.elte.txtuml.xtxtuml.xtxtUML.XtxtUMLPackage
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.jface.text.contentassist.ICompletionProposal
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.common.types.JvmGenericType
import org.eclipse.xtext.common.types.JvmTypeReference
import org.eclipse.xtext.common.types.TypesPackage
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.ui.editor.contentassist.ConfigurableCompletionProposal
import org.eclipse.xtext.xbase.XBlockExpression
import org.eclipse.xtext.xbase.XVariableDeclaration
import org.eclipse.xtext.xbase.XbasePackage
import org.eclipse.xtext.xbase.scoping.batch.InstanceFeatureDescription
import org.eclipse.xtext.xbase.typesystem.IBatchTypeResolver
import org.eclipse.xtext.xbase.typesystem.references.LightweightTypeReference
import org.eclipse.xtext.xbase.typesystem.references.LightweightTypeReferenceFactory
import org.eclipse.xtext.xbase.typesystem.references.StandardTypeReferenceOwner
import org.eclipse.xtext.xbase.typesystem.util.CommonTypeComputationServices
import org.eclipse.xtext.xbase.ui.contentassist.MultiNameDescription
import org.eclipse.xtext.xbase.ui.contentassist.XbaseReferenceProposalCreator

class XtxtUMLReferenceProposalCreator extends XbaseReferenceProposalCreator {

	static val allowedJavaClassTypes = #["java.lang.Boolean", "java.lang.Double", "java.lang.Integer",
		"java.lang.String"];

	@Inject extension IBatchTypeResolver;
	@Inject extension IQualifiedNameProvider;
	@Inject extension XtxtUMLUtils;

	@Inject XtxtUMLReferenceProposalScopeProvider scopeProvider;
	@Inject CommonTypeComputationServices services;

	/**
	 * Provides a scope with a customized JDT based scope.
	 * @see XtxtUMLReferenceProposalTypeScope
	 */
	override getScopeProvider() {
		return scopeProvider;
	}

	/**
	 * Replaces the dollar mark with dots in content assist proposals.
	 */
	override protected getWrappedFactory(EObject model, EReference reference,
		Function<IEObjectDescription, ICompletionProposal> proposalFactory) {
		[
			val proposal = super.getWrappedFactory(model, reference, proposalFactory).apply(it);
			if (proposal instanceof ConfigurableCompletionProposal) {
				proposal.replacementString = proposal.replacementString.replace("$", ".");
			}

			return proposal;
		]
	}

	/**
	 * Extends the default implementation with proposals for XtxtUML cross references.
	 */
	override queryScope(IScope scope, EObject model, EReference ref, Predicate<IEObjectDescription> filter) {
		switch (ref) {
			case XtxtUMLPackage::eINSTANCE.XUConnectorEnd_Role:
				scope.selectCompositionEnds(model)
			case XtxtUMLPackage::eINSTANCE.XUConnectorEnd_Port:
				scope.selectOwnedPorts(model)
			case XtxtUMLPackage::eINSTANCE.XUTransitionPort_Port:
				scope.selectOwnedBehaviorPorts(model)
			case XtxtUMLPackage::eINSTANCE.XUTransitionTrigger_Trigger:
				scope.selectApplicableTriggers(model)
			case XtxtUMLPackage::eINSTANCE.XUTransitionVertex_Vertex:
				scope.selectOwnedStates(model)
			case XtxtUMLPackage::eINSTANCE.XUClassPropertyAccessExpression_Right:
				scope.selectNavigableClassProperties(model)
			case XtxtUMLPackage::eINSTANCE.XUClass_SuperClass:
				scope.selectExtendableClasses(model)
			case XbasePackage::eINSTANCE.XAbstractFeatureCall_Feature:
				scope.selectAllowedFeatures(model, ref, filter)
			case TypesPackage::eINSTANCE.jvmParameterizedTypeReference_Type:
				scope.selectAllowedTypes(model)
		} ?: super.queryScope(scope, model, ref, filter)
	}

	def private selectCompositionEnds(IScope scope, EObject model) {
		if (model instanceof XUConnector || model instanceof XUConnectorEnd) {
			scope.allElements.filter [
				EContainerDescription.EObjectOrProxy instanceof XUComposition
			]
		}
	}

	def private selectOwnedPorts(IScope scope, EObject model) {
		if (model instanceof XUConnectorEnd) {
			val roleClassName = model.role?.endClass?.fullyQualifiedName;
			return scope.allElements.filter [
				EContainerDescription.qualifiedName == roleClassName
			];
		}
	}

	def private selectOwnedBehaviorPorts(IScope scope, EObject model) {
		if (model instanceof XUTransitionPort) {
			val containerClassName = EcoreUtil2.getContainerOfType(model, XUClass).fullyQualifiedName;
			return scope.allElements.filter [
				val port = EObjectOrProxy as XUPort;
				return port != null && port.behavior && EContainerDescription.qualifiedName == containerClassName;
			]
		}
	}

	def private selectApplicableTriggers(IScope scope, EObject model) {
		if (model instanceof XUTransitionTrigger && model.eContainer instanceof XUTransition) {
			val transPort = (model.eContainer as XUTransition).members?.findFirst [
				it instanceof XUTransitionPort
			] as XUTransitionPort;

			if (transPort != null) { // check if port is specified
				val providedIFace = transPort.port?.members?.findFirst[!required];
				val providedSignals = providedIFace?.interface?.receptions?.map[signal];

				return scope.allElements.filter [ descr |
					providedSignals?.findFirst[fullyQualifiedName == descr.qualifiedName] != null
				// `findFirst` is used instead of `exists` to eliminate the warning about null-safe'd primitives
				]
			}
		}
	}

	def private selectOwnedStates(IScope scope, EObject model) {
		if (model instanceof XUTransitionVertex) {
			val transContainerName = model.eContainer?.eContainer?.fullyQualifiedName;
			return scope.allElements.filter [
				EContainerDescription.qualifiedName == transContainerName &&
					(model.from || (EObjectOrProxy as XUState).type != XUStateType.INITIAL)
			];
		}
	}

	def private selectNavigableClassProperties(IScope scope, EObject model) {
		if (model instanceof XUClassPropertyAccessExpression) {
			val containerClassName = model.left.resolveTypes.getActualType(model.left).type.fullyQualifiedName;
			return scope.allElements.filter [ descr |
				switch (proposedObj : descr.EObjectOrProxy) {
					XUPort:
						descr.EContainerDescription.qualifiedName == containerClassName
					XUAssociationEnd:
						!proposedObj.notNavigable && descr.endsOfEnclosingAssociation.exists [
							endClass?.fullyQualifiedName == containerClassName &&
								fullyQualifiedName != descr.qualifiedName
						]
					default:
						false // to make Xtend happy
				}
			]
		}
	}

	def private endsOfEnclosingAssociation(IEObjectDescription assocEndDescription) {
		val container = assocEndDescription.EObjectOrProxy.eContainer ?:
			assocEndDescription.EContainerDescription.EObjectOrProxy;

		return if (container instanceof XUAssociation) {
			container.ends
		} else {
			newArrayList
		}
	}

	def private selectExtendableClasses(IScope scope, EObject model) {
		if (model instanceof XUClass) {
			val selfName = model.fullyQualifiedName;
			return scope.allElements.filter [
				qualifiedName != selfName
			]
		}
	}

	def private selectAllowedFeatures(IScope scope, EObject model, EReference ref,
		Predicate<IEObjectDescription> filter) {
		super.queryScope(scope, model, ref, filter).filter [
			val fqn = qualifiedName?.toString;
			val isObjectOrXbaseLibCall = fqn != null &&
				(fqn.startsWith("java.lang.Object") || fqn.startsWith("org.eclipse.xtext.xbase.lib"));

			if (isObjectOrXbaseLibCall) {
				return false;
			}

			val isExtensionCall = it instanceof MultiNameDescription && {
				val delegate = (it as MultiNameDescription).delegate;
				if (delegate instanceof InstanceFeatureDescription) {
					delegate.isExtension
				} else {
					false
				}
			}

			return !isExtensionCall;
		]
	}

	def private selectAllowedTypes(IScope scope, EObject model) {
		val isClassAllowed = switch (model) {
			XUSignal,
			XUSignalAttribute: false
			XUClass,
			XUDeclarationPrefix,
			XUOperation,
			XBlockExpression,
			XVariableDeclaration: true
			default: null
		}

		return if (isClassAllowed != null) {
			val isSignalAllowed = EcoreUtil2.getContainerOfType(model, XBlockExpression) != null;
			scope.allElements.filter[isAllowedType(isClassAllowed, isSignalAllowed)]
		}
	}

	def private isAllowedType(IEObjectDescription desc, boolean isClassAllowed, boolean isSignalAllowed) {
		// primitives are handled as keywords on this level, nothing to do with them
		allowedJavaClassTypes.contains(desc.qualifiedName.toString) || {
			val proposedObj = desc.EObjectOrProxy;

			// investigating superTypes only is sufficient and convenient here
			// sufficient:
			// a valid txtUML class always has a JtxtUML API supertype
			// convenient:
			// supertypes are already in type reference format, which state would
			// be difficult to achieve starting from a plain JvmType
			proposedObj instanceof JvmGenericType && (proposedObj as JvmGenericType).superTypes.exists [
				val typeRef = toLightweightTypeReference;
				typeRef.isSubtypeOf(DataType) || typeRef.isInterface && typeRef.isSubtypeOf(ExternalType) ||
					isClassAllowed && typeRef.isSubtypeOf(ModelClass) || isSignalAllowed && typeRef.isSubtypeOf(Signal)
			]
		}
	}

	def private isInterface(LightweightTypeReference typeRef) {
		typeRef.type instanceof JvmGenericType && (typeRef.type as JvmGenericType).isInterface();
	}

	def private toLightweightTypeReference(JvmTypeReference typeRef) {
		val owner = new StandardTypeReferenceOwner(services, typeRef);
		val factory = new LightweightTypeReferenceFactory(owner, false);
		return factory.toLightweightReference(typeRef);
	}

}
