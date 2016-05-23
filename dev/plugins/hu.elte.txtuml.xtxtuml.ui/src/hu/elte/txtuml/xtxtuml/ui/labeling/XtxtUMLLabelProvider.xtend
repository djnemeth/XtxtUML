package hu.elte.txtuml.xtxtuml.ui.labeling

import com.google.inject.Inject
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociation
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociationEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAttribute
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClass
import hu.elte.txtuml.xtxtuml.xtxtUML.XUComposition
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConnector
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConnectorEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConstructor
import hu.elte.txtuml.xtxtuml.xtxtUML.XUEntryOrExitActivity
import hu.elte.txtuml.xtxtuml.xtxtUML.XUExecution
import hu.elte.txtuml.xtxtuml.xtxtUML.XUFile
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
import org.eclipse.emf.edit.ui.provider.AdapterFactoryLabelProvider
import org.eclipse.jface.viewers.StyledString
import org.eclipse.xtext.common.types.JvmGenericType
import org.eclipse.xtext.xbase.ui.labeling.XbaseLabelProvider

/**
 * Provides labels for EObjects.
 */
class XtxtUMLLabelProvider extends XbaseLabelProvider {

	@Inject
	new(AdapterFactoryLabelProvider delegate) {
		super(delegate);
	}

	/**
	 * @returns <code>null</code>
	 * customized is icon is used instead.
	 */
	override protected dispatch imageDescriptor(JvmGenericType genericType) {
		null
	}

	def image(JvmGenericType it) {
		if (interface) {
			"java_iface.png"
		} else {
			"java_class.png"
		}
	}

	def image(XUFile it) {
		"uml2/Package.gif"
	}

	def image(XUModelDeclaration it) {
		"uml2/Model.gif"
	}

	def image(XUExecution it) {
		"execution.gif"
	}

	def image(XUClass it) {
		"uml2/Class.gif"
	}

	def image(XUSignal it) {
		"uml2/Signal.gif"
	}

	def image(XUSignalAttribute it) {
		"uml2/Property.gif"
	}

	def text(XUSignalAttribute it) {
		createStyledOutlineText(name, type.simpleName)
	}

	def image(XUInterface it) {
		"uml2/Interface.gif"
	}

	def image(XUReception it) {
		"uml2/Reception.gif"
	}

	def text(XUReception it) {
		createStyledOutlineText("reception", signal.name)
	}

	def image(XUAssociation it) {
		if (it instanceof XUComposition) {
			"uml2/Association_composite.gif"
		} else {
			"uml2/Association.gif"
		}
	}

	def image(XUAssociationEnd it) {
		"uml2/Property.gif"
	}

	def text(XUAssociationEnd it) {
		createStyledOutlineText(name, multiplicityAsString + " " + endClass.name + propertiesAsString)
	}

	def image(XUConnector it) {
		if (delegation) {
			"uml2/Connector_delegation.gif"
		} else {
			"uml2/Connector_assembly.gif"
		}
	}

	def image(XUConnectorEnd it) {
		"uml2/ConnectorEnd.gif"
	}

	def text(XUConnectorEnd it) {
		createStyledOutlineText(name, role?.name + "->" + port?.name)
	}

	def image(XUAttribute it) {
		"uml2/Property.gif"
	}

	def text(XUAttribute it) {
		createStyledOutlineText(name, prefix.type.simpleName)
	}

	def image(XUConstructor it) {
		"uml2/Operation.gif"
	}

	def text(XUConstructor it) {
		val parameterList = if (parameters.empty) {
				"()"
			} else {
				parameters.join("(", ", ", ")", [parameterType.simpleName])
			}

		return new StyledString(name + parameterList)
	}

	def image(XUOperation it) {
		"uml2/Operation.gif"
	}

	def text(XUOperation it) {
		it.text(false) // `it` cannot be omitted here because of incorrect resolution
	}

	def text(XUOperation it, boolean showNames) {
		val parameterList = if (parameters.empty) {
				"()"
			} else {
				parameters.join("(", ", ", ")", [parameterType.simpleName + if(showNames) " " + name else ""])
			}

		createStyledOutlineText(name + parameterList, prefix.type.simpleName)
	}

	def image(XUPort it) {
		"uml2/Port.gif"
	}

	def text(XUPort it) {
		var text = new StyledString(name);
		if (behavior) {
			text = text.append(new StyledString(
				" (behavior)",
				StyledString::DECORATIONS_STYLER
			))
		}

		return text;
	}

	def image(XUPortMember it) {
		"uml2/Property.gif"
	}

	def text(XUPortMember it) {
		createStyledOutlineText(if(required) "required" else "provided", interface.name)
	}

	def image(XUState it) {
		switch (type) {
			case PLAIN,
			case COMPOSITE: "uml2/State.gif"
			case INITIAL: "uml2/Pseudostate_initial.gif"
			case CHOICE: "uml2/Pseudostate_choice.gif"
		}
	}

	def image(XUEntryOrExitActivity it) {
		"uml2/Activity.gif"
	}

	def text(XUEntryOrExitActivity it) {
		if(entry) "entry" else "exit"
	}

	def image(XUTransition it) {
		"uml2/Transition.gif"
	}

	def image(XUTransitionEffect it) {
		"uml2/Activity.gif"
	}

	def text(XUTransitionEffect it) {
		"effect"
	}

	def image(XUTransitionGuard it) {
		"uml2/Constraint.gif"
	}

	def text(XUTransitionGuard it) {
		"guard"
	}

	def image(XUTransitionVertex it) {
		"uml2/Property.gif"
	}

	def text(XUTransitionVertex it) {
		createStyledOutlineText(if(from) "from" else "to", vertex.name)
	}

	def image(XUTransitionTrigger it) {
		"uml2/Trigger.gif"
	}

	def text(XUTransitionTrigger it) {
		createStyledOutlineText("trigger", trigger.name)
	}

	def image(XUTransitionPort it) {
		"uml2/Port.gif"
	}

	def text(XUTransitionPort it) {
		createStyledOutlineText("port", port.name)
	}

	def private multiplicityAsString(XUAssociationEnd it) {
		if (container) {
			"0..1"
		} else if (multiplicity == null) {
			"1"
		} else if (multiplicity.any) {
			"*"
		} else {
			multiplicity.lower + if (multiplicity.isUpperSet) {
				".." + if(multiplicity.isUpperInf) "*" else multiplicity.upper
			} else {
				""
			}
		}
	}

	def private propertiesAsString(XUAssociationEnd it) {
		if (notNavigable || container) {
			var propString = " (";

			if(notNavigable) propString += "hidden ";
			if(container) propString += "container ";

			return propString.substring(0, propString.length - 1) + ")";
		} else {
			return "";
		}
	}

	/**
	 * Creates a StyledString, concatenating the given name and details
	 * section with a colon, where the latter will be formatted with the
	 * default decorations styler.
	 */
	def private createStyledOutlineText(String name, String details) {
		new StyledString(name).append(new StyledString(
			" : " + details,
			StyledString::DECORATIONS_STYLER
		))
	}

}
