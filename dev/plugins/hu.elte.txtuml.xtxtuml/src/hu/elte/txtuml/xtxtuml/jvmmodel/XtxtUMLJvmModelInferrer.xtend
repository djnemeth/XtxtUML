package hu.elte.txtuml.xtxtuml.jvmmodel

import com.google.inject.Inject
import hu.elte.txtuml.api.model.Association
import hu.elte.txtuml.api.model.BehaviorPort
import hu.elte.txtuml.api.model.Composition
import hu.elte.txtuml.api.model.Composition.Container
import hu.elte.txtuml.api.model.Composition.HiddenContainer
import hu.elte.txtuml.api.model.Connector
import hu.elte.txtuml.api.model.ConnectorBase.One
import hu.elte.txtuml.api.model.Delegation
import hu.elte.txtuml.api.model.From
import hu.elte.txtuml.api.model.Interface
import hu.elte.txtuml.api.model.Max
import hu.elte.txtuml.api.model.Min
import hu.elte.txtuml.api.model.ModelClass
import hu.elte.txtuml.api.model.Port
import hu.elte.txtuml.api.model.Signal
import hu.elte.txtuml.api.model.StateMachine
import hu.elte.txtuml.api.model.To
import hu.elte.txtuml.api.model.Trigger
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociation
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociationEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAttribute
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClass
import hu.elte.txtuml.xtxtuml.xtxtUML.XUComposition
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConnector
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConnectorEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConstructor
import hu.elte.txtuml.xtxtuml.xtxtUML.XUDeclarationPrefix
import hu.elte.txtuml.xtxtuml.xtxtUML.XUEntryOrExitActivity
import hu.elte.txtuml.xtxtuml.xtxtUML.XUExecution
import hu.elte.txtuml.xtxtuml.xtxtUML.XUInterface
import hu.elte.txtuml.xtxtuml.xtxtUML.XUModelDeclaration
import hu.elte.txtuml.xtxtuml.xtxtUML.XUOperation
import hu.elte.txtuml.xtxtuml.xtxtUML.XUPort
import hu.elte.txtuml.xtxtuml.xtxtUML.XUPortMember
import hu.elte.txtuml.xtxtuml.xtxtUML.XUReception
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignal
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignalAttribute
import hu.elte.txtuml.xtxtuml.xtxtUML.XUState
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransition
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionEffect
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionGuard
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionPort
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionTrigger
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionVertex
import hu.elte.txtuml.xtxtuml.xtxtUML.XUVisibility
import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.common.types.JvmDeclaredType
import org.eclipse.xtext.common.types.JvmFormalParameter
import org.eclipse.xtext.common.types.JvmGenericType
import org.eclipse.xtext.common.types.JvmMember
import org.eclipse.xtext.common.types.JvmVisibility
import org.eclipse.xtext.common.types.TypesFactory
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.xbase.jvmmodel.AbstractModelInferrer
import org.eclipse.xtext.xbase.jvmmodel.IJvmDeclaredTypeAcceptor
import org.eclipse.xtext.xbase.jvmmodel.IJvmModelAssociations

class XtxtUMLJvmModelInferrer extends AbstractModelInferrer {

	Map<EObject, JvmDeclaredType> registeredTypes = newHashMap;

	@Inject extension XtxtUMLTypesBuilder
	@Inject extension IJvmModelAssociations
	@Inject extension IQualifiedNameProvider

	def dispatch void infer(XUModelDeclaration decl, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		acceptor.accept(decl.toPackageInfo(decl.fullyQualifiedName, decl.modelName))
	}

	def dispatch void infer(XUExecution exec, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		acceptor.accept(exec.toClass(exec.fullyQualifiedName)) [
			documentation = exec.documentation
			visibility = JvmVisibility.PUBLIC

			members += exec.toMethod("main", Void.TYPE.typeRef) [
				documentation = exec.documentation
				parameters += exec.toParameter("args", String.typeRef.addArrayTypeDimension)
				varArgs = true

				static = true
				body = exec.body
			]
		]
	}

	def dispatch void infer(XUAssociation assoc, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		acceptor.accept(assoc.toClass(assoc.fullyQualifiedName)) [
			documentation = assoc.documentation
			superTypes += switch assoc {
				XUComposition: Composition
				default: Association
			}.typeRef

			for (end : assoc.ends) {
				members += end.inferredType as JvmMember
			}
		]

		for (end : assoc.ends) {
			register(end, acceptor, isPreIndexingPhase)
		}
	}

	def dispatch void infer(XUSignal signal, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		acceptor.accept(signal.toClass(signal.fullyQualifiedName)) [
			documentation = signal.documentation
			superTypes += Signal.typeRef

			for (attr : signal.attributes) {
				members += attr.toJvmMember
			}

			if (!signal.attributes.isEmpty) {
				members += signal.toConstructor [
					for (attr : signal.attributes) {
						parameters += attr.toParameter(attr.name, attr.type)
					}

					body = '''
						«FOR attr : signal.attributes»
							this.«attr.name» = «attr.name»;
						«ENDFOR»
					'''
				]
			}
		]
	}

	def dispatch void infer(XUClass tUClass, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		acceptor.accept(tUClass.toClass(tUClass.fullyQualifiedName)) [
			documentation = tUClass.documentation
			if (tUClass.superClass != null) {
				superTypes += tUClass.superClass.inferredTypeRef
			} else {
				superTypes += ModelClass.typeRef
			}

			for (member : tUClass.members) {
				if (member instanceof XUState || member instanceof XUPort) {
					members += member.inferredType as JvmMember
				} else if (!(member instanceof XUDeclarationPrefix)) { // TODO refactor grammar
					members += member.toJvmMember
				}
			}
		]

		for (member : tUClass.members) {
			if (member instanceof XUState || member instanceof XUPort) {
				register(member, acceptor, isPreIndexingPhase)
			}
		}
	}

	def dispatch void infer(XUConnector connector, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		acceptor.accept(connector.toClass(connector.fullyQualifiedName)) [
			documentation = connector.documentation
			superTypes += if (connector.delegation) {
				Delegation.typeRef
			} else {
				Connector.typeRef
			}

			for (end : connector.ends) {
				members += end.inferredType as JvmMember
			}
		]

		for (end : connector.ends) {
			register(end, acceptor, isPreIndexingPhase)
		}
	}

	def dispatch void infer(XUInterface iFace, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		acceptor.accept(iFace.toClass(iFace.fullyQualifiedName)) [
			documentation = iFace.documentation

			superTypes += Interface.typeRef
			interface = true

			for (reception : iFace.receptions) {
				members += reception.toJvmMember
			}
		]
	}

	def private dispatch void register(XUAssociationEnd assocEnd, IJvmDeclaredTypeAcceptor acceptor,
		boolean isPreIndexingPhase) {
		acceptor.register(assocEnd, assocEnd.toClass(assocEnd.fullyQualifiedName)) [
			documentation = assocEnd.documentation
			visibility = JvmVisibility.PUBLIC

			val calcApiSuperTypeResult = assocEnd.calculateApiSuperType
			superTypes += calcApiSuperTypeResult.key

			if (calcApiSuperTypeResult.value != null) {
				annotations += calcApiSuperTypeResult.value.key.toAnnotationRef(Min)
				if (!assocEnd.multiplicity.isUpperInf) {
					annotations += calcApiSuperTypeResult.value.value.toAnnotationRef(Max)
				}
			}
		]
	}

	def private dispatch void register(XUPort port, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		acceptor.register(port, port.toClass(port.fullyQualifiedName)) [
			documentation = port.documentation
			visibility = JvmVisibility.PUBLIC

			val requiredIFace = port.members.findFirst[required]
			val providedIFace = port.members.findFirst[!required]

			superTypes += typeRef(Port, providedIFace.toInterfaceTypeRef, requiredIFace.toInterfaceTypeRef)

			if (port.behavior) {
				annotations += BehaviorPort.annotationRef
			}
		]
	}

	def private dispatch void register(XUState state, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		acceptor.register(state, state.toClass(state.fullyQualifiedName)) [
			documentation = state.documentation
			superTypes += switch (state.type) {
				case PLAIN: StateMachine.State.typeRef
				case INITIAL: StateMachine.Initial.typeRef
				case CHOICE: StateMachine.Choice.typeRef
				case COMPOSITE: StateMachine.CompositeState.typeRef
			}

			for (member : state.members) {
				if (member instanceof XUState) {
					members += member.inferredType as JvmMember
				} else {
					members += member.toJvmMember
				}
			}
		]

		for (member : state.members) {
			if (member instanceof XUState) {
				register(member, acceptor, isPreIndexingPhase)
			}
		}
	}

	def private dispatch void register(XUConnectorEnd connEnd, IJvmDeclaredTypeAcceptor acceptor,
		boolean isPreIndexingPhase) {
		acceptor.register(connEnd, connEnd.toClass(connEnd.fullyQualifiedName)) [
			documentation = connEnd.documentation
			visibility = JvmVisibility.PUBLIC
			superTypes += typeRef(One, connEnd.role.inferredTypeRef, connEnd.port.inferredTypeRef)
		]
	}

	def dispatch private toJvmMember(XUConstructor ctor) {
		ctor.toConstructor [
			documentation = ctor.documentation
			visibility = ctor.visibility.toJvmVisibility

			for (param : ctor.parameters) {
				parameters += param.toParameter(param.name, param.parameterType) => [
					documentation = ctor.documentation
				]
			}

			body = ctor.body
		]
	}

	def dispatch private toJvmMember(XUAttribute attr) {
		attr.toField(attr.name, attr.prefix.type) [
			documentation = attr.documentation
			visibility = attr.prefix.visibility.toJvmVisibility
		]
	}

	def dispatch private toJvmMember(XUSignalAttribute attr) {
		attr.toField(attr.name, attr.type) [
			documentation = attr.documentation
			visibility = attr.visibility.toJvmVisibility
		]
	}

	def dispatch private toJvmMember(XUOperation op) {
		op.toMethod(op.name, op.prefix.type) [
			documentation = op.documentation
			visibility = op.prefix.visibility.toJvmVisibility

			for (JvmFormalParameter param : op.parameters) {
				parameters += param.toParameter(param.name, param.parameterType) => [
					documentation = param.documentation
				]
			}

			body = op.body
		]
	}

	def dispatch private toJvmMember(XUEntryOrExitActivity act) {
		val name = if(act.entry) "entry" else "exit"

		return act.toMethod(name, Void.TYPE.typeRef) [
			documentation = act.documentation
			visibility = JvmVisibility.PUBLIC
			annotations += annotationRef(Override)
			body = act.body
		]
	}

	def dispatch private JvmMember toJvmMember(XUTransition trans) {
		trans.toClass(trans.fullyQualifiedName) [
			documentation = trans.documentation
			superTypes += StateMachine.Transition.typeRef

			for (member : trans.members) {
				switch (member) {
					XUTransitionTrigger,
					XUTransitionVertex: {
						annotations += member.toAnnotationRef
					}
					XUTransitionPort: {
					} // do nothing, handled together with triggers
					default: {
						members += member.toJvmMember
					}
				}
			}
		]
	}

	def dispatch private toJvmMember(XUTransitionEffect effect) {
		effect.toMethod("effect", Void.TYPE.typeRef) [
			documentation = effect.documentation
			visibility = JvmVisibility.PUBLIC
			annotations += annotationRef(Override)
			body = effect.body
		]
	}

	def dispatch private toJvmMember(XUTransitionGuard guard) {
		guard.toMethod("guard", Boolean.TYPE.typeRef) [
			documentation = guard.documentation
			visibility = JvmVisibility.PUBLIC

			annotations += annotationRef(Override)
			if (guard.^else) {
				body = '''return Else();'''
			} else {
				body = guard.expression
			}
		]
	}

	def dispatch private toJvmMember(XUReception reception) {
		reception.toMethod("reception", Void.TYPE.typeRef) [
			visibility = JvmVisibility.DEFAULT
			documentation = reception.documentation
			parameters += reception.toParameter("signal", reception.signal.inferredTypeRef)
		]
	}

	def private toJvmVisibility(XUVisibility it) {
		if (it == XUVisibility.PACKAGE)
			JvmVisibility.DEFAULT
		else
			JvmVisibility.getByName(getName())
	}

	def dispatch private toAnnotationRef(XUTransitionTrigger it) {
		val port = (eContainer as XUTransition).members.findFirst[it instanceof XUTransitionPort] as XUTransitionPort

		createAnnotationRef(Trigger, if (port != null) {
			#["port" -> port.port, "value" -> trigger]
		} else {
			#["value" -> trigger]
		})
	}

	def dispatch private toAnnotationRef(XUTransitionVertex it) {
		createAnnotationRef(
			if (from) {
				From
			} else {
				To
			},
			"value" -> vertex
		)
	}

	def private toAnnotationRef(int i, Class<?> annotationType) {
		annotationRef(annotationType) => [
			explicitValues += TypesFactory::eINSTANCE.createJvmIntAnnotationValue => [
				values += i
			]
		]
	}

	def private createAnnotationRef(Class<?> annotationType, Pair<String, EObject>... params) {
		annotationRef(annotationType) => [ annotationRef |
			for (param : params) {
				annotationRef.explicitValues += TypesFactory::eINSTANCE.createJvmTypeAnnotationValue => [
					values += param.value.inferredTypeRef
					if (params.size != 1 || param.key != "value") {
						operation = annotationRef.annotation.declaredOperations.findFirst[it.simpleName == param.key]
					}
				]
			}

		]
	}

	def private calculateApiSuperType(XUAssociationEnd it) {
		val endClassTypeParam = endClass.inferredTypeRef
		if (isContainer) {
			// Do not try to simplify the code here, as it breaks standalone builds.
			// The inferred type will be Class<? extend MaybeOneBase>, which is invalid,
			// as MaybeOneBase is a package private class in its own package.
			if (notNavigable) {
				return HiddenContainer.typeRef(endClassTypeParam) -> null
			} else {
				return Container.typeRef(endClassTypeParam) -> null
			}
		}

		val optionalHidden = if(notNavigable) "Hidden" else ""
		var Pair<Integer, Integer> explicitMultiplicities = null
		val apiBoundTypeName = if (multiplicity == null) // omitted
				"One"
			else if (multiplicity.any) // *
				"Many"
			else if (!multiplicity.upperSet) { // <lower> (exact)
				if (multiplicity.lower == 1)
					"One"
				else {
					explicitMultiplicities = multiplicity.lower -> multiplicity.lower
					"Multiple"
				}
			} else { // <lower> .. <upper>
				if (multiplicity.lower == 0 && multiplicity.upper == 1)
					"MaybeOne"
				else if (multiplicity.lower == 1 && multiplicity.upper == 1)
					"One"
				else if (multiplicity.lower == 0 && multiplicity.upperInf)
					"Many"
				else if (multiplicity.lower == 1 && multiplicity.upperInf)
					"Some"
				else {
					explicitMultiplicities = multiplicity.lower -> multiplicity.upper
					"Multiple"
				}
			}

		val endClassImpl = "hu.elte.txtuml.api.model.Association$" + optionalHidden + apiBoundTypeName
		return endClassImpl.typeRef(endClassTypeParam) -> explicitMultiplicities
	}

	def private inferredTypeRef(EObject sourceElement) {
		val type = sourceElement.inferredType
		if (type instanceof JvmDeclaredType) {
			return type.typeRef
		}
	}

	def private toInterfaceTypeRef(XUPortMember portMember) {
		if (portMember?.interface != null) {
			portMember.interface.inferredTypeRef
		} else {
			Interface.Empty.typeRef
		}
	}

	def private void register(IJvmDeclaredTypeAcceptor acceptor, EObject sourceElement, JvmGenericType type,
		(JvmGenericType)=>void initializer) {
		registeredTypes.put(sourceElement, type)
		acceptor.accept(type, initializer)
		if (type?.eResource != null) { // to eliminate warning about null-safe'd primitives
			type.eResource.contents.remove(type)
		}
	}

	def private inferredType(EObject sourceElement) {
		registeredTypes.get(sourceElement) ?: sourceElement.getPrimaryJvmElement
	}

}
