package hu.elte.txtuml.xtxtuml.validation;

import hu.elte.txtuml.api.model.DataType
import hu.elte.txtuml.api.model.ModelClass
import hu.elte.txtuml.api.model.Port
import hu.elte.txtuml.api.model.Signal
import hu.elte.txtuml.api.model.external.ExternalType
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClassPropertyAccessExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUDeclarationPrefix
import hu.elte.txtuml.xtxtuml.xtxtUML.XUDeleteObjectExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUOperation
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSendSignalExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignalAttribute
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.xtext.common.types.JvmFormalParameter
import org.eclipse.xtext.common.types.JvmTypeReference
import org.eclipse.xtext.common.types.TypesPackage
import org.eclipse.xtext.validation.Check
import org.eclipse.xtext.xbase.XExpression

import static hu.elte.txtuml.xtxtuml.validation.XtxtUMLIssueCodes.*
import static hu.elte.txtuml.xtxtuml.xtxtUML.XtxtUMLPackage.Literals.*

class XtxtUMLTypeValidator extends XtxtUMLUniquenessValidator {

	static val allowedBasicTypes = #[Integer.TYPE, Integer, Boolean.TYPE, Boolean, Double.TYPE, Double, String];

	@Check
	def checkTypeReference(JvmTypeReference typeRef) {
		var isAttribute = false;
		val isValid = switch (container : typeRef.eContainer) {
			XUSignalAttribute: {
				isAttribute = true;
				typeRef.isAllowedAttributeType(false)
			}
			XUDeclarationPrefix: {
				if (container.eContainer instanceof XUOperation) {
					typeRef.isAllowedParameterType(true)
				} else {
					isAttribute = true;
					typeRef.isAllowedAttributeType(false)
				}
			}
			JvmFormalParameter: {
				typeRef.isAllowedParameterType(false)
			}
			// TODO check types inside XBlockExpression
			default:
				true
		}

		if (!isValid) {
			error(
				if (isAttribute) {
					"Invalid type. Only boolean, Boolean, double, Double, int, Integer, String, model data types and external interfaces are allowed"
				} else {
					"Invalid type. Only boolean, Boolean, double, Double, int, Integer, String, model data types, external interfaces and model class types are allowed"
				}, typeRef, TypesPackage.Literals.JVM_PARAMETERIZED_TYPE_REFERENCE__TYPE, INVALID_TYPE);
		}
	}

	@Check
	def checkSendSignalExpressionTypes(XUSendSignalExpression sendExpr) {
		if (!sendExpr.signal.isConformantWith(Signal, false)) {
			typeMismatch("Signal", sendExpr, XU_SEND_SIGNAL_EXPRESSION__SIGNAL);
		}

		if (!sendExpr.target.isConformantWith(ModelClass, false) && !sendExpr.target.isConformantWith(Port, false)) {
			typeMismatch("Class or Port", sendExpr, XU_SEND_SIGNAL_EXPRESSION__TARGET);
		}
	}

	@Check
	def checkDeleteObjectExpressionTypes(XUDeleteObjectExpression deleteExpr) {
		if (!deleteExpr.object.isConformantWith(ModelClass, false)) {
			typeMismatch("Class", deleteExpr, XU_DELETE_OBJECT_EXPRESSION__OBJECT)
		}
	}

	@Check
	def checkClassPropertyAccessExpressionTypes(XUClassPropertyAccessExpression accessExpr) {
		if (!accessExpr.left.isConformantWith(ModelClass, false)) {
			typeMismatch("Class", accessExpr, XU_CLASS_PROPERTY_ACCESS_EXPRESSION__LEFT)
		}
	}

	def protected isAllowedParameterType(JvmTypeReference typeRef, boolean isVoidAllowed) {
		isAllowedAttributeType(typeRef, isVoidAllowed) || typeRef.isConformantWith(ModelClass)
	}

	def protected isAllowedAttributeType(JvmTypeReference typeRef, boolean isVoidAllowed) {
		isAllowedBasicType(typeRef, isVoidAllowed) || typeRef.isConformantWith(DataType) ||
			typeRef.type.isInterface && typeRef.isConformantWith(ExternalType)
	}

	def protected isAllowedBasicType(JvmTypeReference typeRef, boolean isVoidAllowed) {
		allowedBasicTypes.exists[typeRef.isType(it)] || typeRef.isType(Void.TYPE) && isVoidAllowed
	}

	def protected isType(JvmTypeReference typeRef, Class<?> expectedType) {
		typeRef.toLightweightTypeReference.isType(expectedType)
	}

	def protected isConformantWith(JvmTypeReference typeRef, Class<?> expectedType) {
		typeRef.toLightweightTypeReference.isSubtypeOf(expectedType)
	}

	def protected isConformantWith(XExpression expr, Class<?> expectedType, boolean isNullAllowed) {
		expr != null && expr.actualType.isSubtypeOf(expectedType) && (isNullAllowed || !isNullLiteral(expr))
	}

	def protected isNullLiteral(XExpression expr) {
		expr != null && expr.actualType.canonicalName == "null"
	}

	def protected typeMismatch(String expectedType, EObject source, EStructuralFeature feature) {
		error("Type mismatch: cannot convert the expression to " + expectedType, source, feature, TYPE_MISMATCH)
	}

}
