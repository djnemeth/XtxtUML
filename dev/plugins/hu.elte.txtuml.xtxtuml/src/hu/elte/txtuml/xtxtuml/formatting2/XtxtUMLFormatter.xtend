package hu.elte.txtuml.xtxtuml.formatting2;

import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociation
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociationEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAttribute
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClass
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClassPropertyAccessExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUComposition
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConnector
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConnectorEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConstructor
import hu.elte.txtuml.xtxtuml.xtxtUML.XUDeclarationPrefix
import hu.elte.txtuml.xtxtuml.xtxtUML.XUDeleteObjectExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUEntryOrExitActivity
import hu.elte.txtuml.xtxtuml.xtxtUML.XUExecution
import hu.elte.txtuml.xtxtuml.xtxtUML.XUFile
import hu.elte.txtuml.xtxtuml.xtxtUML.XUInterface
import hu.elte.txtuml.xtxtuml.xtxtUML.XULogExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUModelDeclaration
import hu.elte.txtuml.xtxtuml.xtxtUML.XUMultiplicity
import hu.elte.txtuml.xtxtuml.xtxtUML.XUOperation
import hu.elte.txtuml.xtxtuml.xtxtUML.XUPort
import hu.elte.txtuml.xtxtuml.xtxtUML.XUPortMember
import hu.elte.txtuml.xtxtuml.xtxtUML.XUReception
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSendSignalExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignal
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignalAttribute
import hu.elte.txtuml.xtxtuml.xtxtUML.XUStartObjectExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUState
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransition
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionEffect
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionGuard
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionPort
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionTrigger
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionVertex
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.xtext.formatting2.IFormattableDocument
import org.eclipse.xtext.formatting2.regionaccess.ISemanticRegion
import org.eclipse.xtext.xbase.XBlockExpression
import org.eclipse.xtext.xbase.XForLoopExpression
import org.eclipse.xtext.xbase.XSwitchExpression
import org.eclipse.xtext.xbase.XVariableDeclaration
import org.eclipse.xtext.xbase.formatting2.XbaseFormatter

import static hu.elte.txtuml.xtxtuml.xtxtUML.XtxtUMLPackage.Literals.*

class XtxtUMLFormatter extends XbaseFormatter {

	def dispatch void format(XUModelDeclaration it, extension IFormattableDocument document) {
		regionForKeyword('model-package').prepend[noSpace].append[oneSpace];
		regionForKeyword('as').surround[oneSpace];
		regionForFeature(XU_MODEL_DECLARATION__SEMI_COLON).prepend[noSpace].append[newLine];
	}

	def dispatch void format(XUFile it, extension IFormattableDocument document) {
		regionForKeyword('package').prepend[noSpace];
		regionForFeature(XU_FILE__NAME).prepend[oneSpace].append[noSpace];
		regionForKeyword(';').append[newLines = 2];

		format(importSection, document);

		for (element : elements) {
			element.append[newLines = 2];
			format(element, document);
		}
	}

	def dispatch void format(XUExecution it, extension IFormattableDocument document) {
		regionForKeyword('execution').prepend[noIndentation];
		regionForFeature(XU_MODEL_ELEMENT__NAME).surround[oneSpace];
		regionForKeyword(';').prepend[noSpace];

		format(body, document);
	}

	def dispatch void format(XUSignal it, extension IFormattableDocument document) {
		formatBlockElement(it, document, regionForKeyword('signal'), attributes, false);
	}

	def dispatch void format(XUClass it, extension IFormattableDocument document) {
		formatBlockElement(it, document, regionForKeyword('class'), members, true);
		regionForKeyword('extends').surround[oneSpace];
	}

	def dispatch void format(XUAssociation it, extension IFormattableDocument document) {
		formatBlockElement(it, document,
			regionForKeyword(if(it instanceof XUComposition) 'composition' else 'association'), ends, false);
	}

	def dispatch void format(XUInterface it, extension IFormattableDocument document) {
		formatBlockElement(it, document, regionForKeyword('interface'), receptions, false);
	}

	def dispatch void format(XUReception it, extension IFormattableDocument document) {
		formatSimpleMember(it, document, XU_RECEPTION__SIGNAL);
	}

	def dispatch void format(XUConnector it, extension IFormattableDocument document) {
		formatBlockElement(it, document, regionForKeyword(if(delegation) 'delegation' else 'connector'), ends, false);
	}

	def dispatch void format(XUConnectorEnd it, extension IFormattableDocument document) {
		regionForKeyword('->').surround[noSpace];
		regionForFeature(XU_CONNECTOR_END__NAME).prepend[oneSpace].append[noSpace];
	}

	def dispatch void format(XUSignalAttribute it, extension IFormattableDocument document) {
		regionForFeature(XU_SIGNAL_ATTRIBUTE__VISIBILITY).append[oneSpace];
		regionForFeature(XU_SIGNAL_ATTRIBUTE__NAME).prepend[oneSpace].append[noSpace];
		format(type, document);
	}

	def dispatch void format(XUOperation it, extension IFormattableDocument document) {
		regionForFeature(XU_OPERATION__NAME).prepend[oneSpace];
		regionForKeyword('(').surround[noSpace];
		regionForKeyword(')').prepend[noSpace].append[oneSpace];
		regionsForKeywords(',').forEach[prepend[noSpace].append[oneSpace]];

		format(body, document);
		format(prefix, document);
		for (parameter : parameters) {
			format(parameter, document);
		}
	}

	def dispatch void format(XUConstructor it, extension IFormattableDocument document) {
		regionForFeature(XU_CONSTRUCTOR__VISIBILITY).append[oneSpace];
		regionForKeyword('(').surround[noSpace];
		regionForKeyword(')').prepend[noSpace].append[oneSpace];
		regionsForKeywords(',').forEach[prepend[noSpace].append[oneSpace]];

		format(body, document);
		for (parameter : parameters) {
			format(parameter, document);
		}
	}

	def dispatch void format(XUDeclarationPrefix it, extension IFormattableDocument document) {
		regionForFeature(XU_DECLARATION_PREFIX__VISIBILITY).append[oneSpace];
		format(type, document);
	}

	def dispatch void format(XUState it, extension IFormattableDocument document) {
		formatBlockElement(it, document, regionForFeature(XU_STATE__TYPE), members, false);
	}

	def dispatch void format(XUEntryOrExitActivity it, extension IFormattableDocument document) {
		formatUnnamedBlockElement(it, document, body as XBlockExpression);
	}

	def dispatch void format(XUTransition it, extension IFormattableDocument document) {
		formatBlockElement(it, document, regionForKeyword('transition'), members, false);
	}

	def dispatch void format(XUTransitionTrigger it, extension IFormattableDocument document) {
		formatSimpleMember(it, document, XU_TRANSITION_TRIGGER__TRIGGER);
	}

	def dispatch void format(XUTransitionVertex it, extension IFormattableDocument document) {
		formatSimpleMember(it, document, XU_TRANSITION_VERTEX__VERTEX);
	}

	def dispatch void format(XUTransitionEffect it, extension IFormattableDocument document) {
		formatUnnamedBlockElement(it, document, body as XBlockExpression);
	}

	def dispatch void format(XUTransitionGuard it, extension IFormattableDocument document) {
		regionForKeyword('(').surround[oneSpace];
		expression.append[oneSpace];
		regionForKeyword(';').prepend[noSpace];

		format(expression, document);
	}

	def dispatch void format(XUTransitionPort it, extension IFormattableDocument document) {
		formatSimpleMember(it, document, XU_TRANSITION_PORT__PORT);
	}

	def dispatch void format(XUPort it, extension IFormattableDocument document) {
		regionForKeyword('behavior').append[oneSpace];
		formatBlockElement(it, document, regionForKeyword('port'), members, false);
	}

	def dispatch void format(XUPortMember it, extension IFormattableDocument document) {
		formatSimpleMember(it, document, XU_PORT_MEMBER__INTERFACE);
	}

	def dispatch void format(XUAssociationEnd it, extension IFormattableDocument document) {
		regionForKeyword('hidden').append[oneSpace];

		multiplicity.append[oneSpace];

		regionForKeyword('container').append[oneSpace];
		regionForFeature(XU_CLASS_PROPERTY__NAME).prepend[oneSpace].append[noSpace];

		format(multiplicity, document);
	}

	def dispatch void format(XUMultiplicity it, extension IFormattableDocument document) {
		regionForKeyword('..').surround[noSpace];
	}

	def dispatch void format(XUSendSignalExpression it, extension IFormattableDocument document) {
		signal.surround[oneSpace];
		target.prepend[oneSpace];

		format(signal, document);
		format(target, document);
	}

	def dispatch void format(XUStartObjectExpression it, extension IFormattableDocument document) {
		object.prepend[oneSpace];
		format(object, document);
	}

	def dispatch void format(XUDeleteObjectExpression it, extension IFormattableDocument document) {
		object.prepend[oneSpace];
		format(object, document);
	}

	def dispatch void format(XULogExpression it, extension IFormattableDocument document) {
		message.prepend[oneSpace];
		format(message, document);
	}

	override dispatch void format(XBlockExpression it, extension IFormattableDocument document) {
		val open = regionForKeyword('{');

		if (expressions.empty && !open.nextHiddenRegion.containsComment) {
			open.append[noSpace];
		} else {
			super._format(it, document); // generated _format is used to prevent infinite recursion
		}
	}

	override dispatch void format(XForLoopExpression it, extension IFormattableDocument document) {
		format(declaredParam, document);
		super._format(it, document); // generated _format is used to prevent infinite recursion
	}

	override dispatch void format(XSwitchExpression it, extension IFormattableDocument document) {
		^switch.surround[noSpace];
		super._format(it, document); // generated _format is used to prevent infinite recursion
	}

	override dispatch void format(XVariableDeclaration it, extension IFormattableDocument document) {
		regionForKeyword(';').prepend[noSpace];
		super._format(it, document); // generated _format is used to prevent infinite recursion
	}

	def dispatch void format(XUAttribute it, extension IFormattableDocument document) {
		formatSimpleMember(it, document, XU_ATTRIBUTE__NAME);
		format(prefix, document);
	}

	def dispatch void format(XUClassPropertyAccessExpression it, extension IFormattableDocument document) {
		regionForKeyword('->').surround[noSpace];
		regionForFeature(XU_CLASS_PROPERTY_ACCESS_EXPRESSION__RIGHT).surround[noSpace];

		format(left, document);
	}

	def private formatBlockElement(EObject it, extension IFormattableDocument document, ISemanticRegion typeKeyword,
		EList<? extends EObject> members, boolean isSpacious) {
		typeKeyword.append[oneSpace];

		val open = regionForKeyword('{');
		open.prepend[oneSpace];

		val delimiterLineCount = if(isSpacious) 2 else 1;
		if (members.empty && (open == null || !open.nextHiddenRegion.containsComment)) {
			open.append[noSpace];
		} else {
			open.append[newLines = delimiterLineCount; increaseIndentation];
			regionForKeyword('}').prepend[decreaseIndentation];
		}

		regionForKeyword(';').prepend[noSpace];

		for (member : members) {
			member.append[newLines = delimiterLineCount];
			format(member, document);
		}
	}

	def private formatSimpleMember(EObject it, extension IFormattableDocument document,
		EStructuralFeature mainFeature) {
		regionForFeature(mainFeature).prepend[oneSpace].append[noSpace];
	}

	def private formatUnnamedBlockElement(EObject it, extension IFormattableDocument document, XBlockExpression body) {
		body.regionForKeyword('{').prepend[oneSpace];
		format(body, document);
	}

}
