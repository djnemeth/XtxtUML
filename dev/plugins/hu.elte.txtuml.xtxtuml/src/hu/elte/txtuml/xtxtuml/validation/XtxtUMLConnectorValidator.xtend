package hu.elte.txtuml.xtxtuml.validation

import com.google.inject.Inject
import hu.elte.txtuml.xtxtuml.xtxtUML.XUComposition
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConnector
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConnectorEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUPort
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.validation.Check

import static hu.elte.txtuml.xtxtuml.validation.XtxtUMLIssueCodes.*
import static hu.elte.txtuml.xtxtuml.xtxtUML.XtxtUMLPackage.Literals.*

class XtxtUMLConnectorValidator extends XtxtUMLAssociationValidator {

	@Inject extension IQualifiedNameProvider;

	@Check
	def checkConnectorHaveExactlyTwoEnds(XUConnector connector) {
		if (connector.ends.length != 2) {
			error("Connector " + connector.name + " must have exactly two ends", connector, XU_MODEL_ELEMENT__NAME,
				CONNECTOR_END_COUNT_MISMATCH);
		}
	}

	@Check
	def checkContainerEndIsAllowedAndNeededOnlyInDelegation(XUConnector connector) {
		val containerEnds = connector.ends.filter[role.isContainer];
		if (connector.delegation) {
			if (containerEnds.length != 1) {
				error("Delegation connector " + connector.name + " must have exactly one container role", connector,
					XU_MODEL_ELEMENT__NAME, CONTAINER_ROLE_COUNT_MISMATCH);
			}
		} else {
			containerEnds.forEach [
				error("Container role " + role?.name + " of connector end " + connector.name + "." + name +
					" must not be present in an assembly connector", it, XU_CONNECTOR_END__ROLE,
					CONTAINER_ROLE_IN_ASSSEMBLY_CONNECTOR);
			]
		}
	}

	@Check
	def checkCompositionsBehindConnectorEnds(XUConnector connector) {
		if (connector.ends.size != 2) {
			return;
		}

		val roleA = connector.ends.get(0).role;
		val roleB = connector.ends.get(1).role;

		val compositionOfRoleA = if(roleA?.eContainer instanceof XUComposition) roleA.eContainer as XUComposition;
		val compositionOfRoleB = if(roleB?.eContainer instanceof XUComposition) roleB.eContainer as XUComposition;

		if (connector.delegation) {
			if (compositionOfRoleA == null ||
				compositionOfRoleA.fullyQualifiedName != compositionOfRoleB?.fullyQualifiedName) {
				error("Delegation connector " + connector.name +
					" must connect ports of a component and one of its parts", connector, XU_MODEL_ELEMENT__NAME,
					COMPOSITION_MISMATCH_IN_DELEGATION_CONNECTOR);
			}
		} else { // assembly connector
			if (compositionOfRoleA == null || compositionOfRoleB == null // roles must be from compositions
			|| compositionOfRoleA.fullyQualifiedName == compositionOfRoleB.fullyQualifiedName // underlying compositions must be different
			|| compositionOfRoleA.ends.findFirst[container]?.endClass?.fullyQualifiedName !=
				compositionOfRoleB.ends.findFirst[container]?.endClass?.fullyQualifiedName // container must be the same
			) {
				error("Assembly connector " + connector.name +
					" must connect ports of parts belonging to the same component", connector, XU_MODEL_ELEMENT__NAME,
					COMPOSITION_MISMATCH_IN_ASSEMBLY_CONNECTOR);
			}
		}
	}

	@Check
	def checkConnectorEndPortCompatibility(XUConnector connector) {
		if (connector.ends.size != 2) {
			return;
		}

		val portA = connector.ends.get(0).port;
		val portB = connector.ends.get(1).port;

		val requiredAName = portA?.getInterface(true)?.fullyQualifiedName;
		val requiredBName = portB?.getInterface(true)?.fullyQualifiedName;
		val providedAName = portA?.getInterface(false)?.fullyQualifiedName;
		val providedBName = portB?.getInterface(false)?.fullyQualifiedName;

		if (connector.delegation && (requiredAName != requiredBName || providedAName != providedBName) ||
			!connector.delegation && (requiredAName != providedBName || providedAName != requiredBName)) {
			error("Connector " + connector.name + " connects incompatible ports", connector, XU_MODEL_ELEMENT__NAME,
				INCOMPATIBLE_PORTS);
		}
	}

	@Check
	def checkOwnerOfConnectorEndPort(XUConnectorEnd connEnd) {
		val ownerOfPort = connEnd.port?.eContainer;
		val classInRole = connEnd.role?.endClass;

		if (ownerOfPort?.fullyQualifiedName != classInRole?.fullyQualifiedName) {
			error(connEnd.port?.name + " cannot be resolved as a port of class " + classInRole?.name, connEnd,
				XU_CONNECTOR_END__PORT, NOT_OWNED_PORT);
		}
	}

	def protected getInterface(XUPort port, boolean ofTypeRequired) {
		port.members.findFirst[required == ofTypeRequired]?.interface
	}

}
