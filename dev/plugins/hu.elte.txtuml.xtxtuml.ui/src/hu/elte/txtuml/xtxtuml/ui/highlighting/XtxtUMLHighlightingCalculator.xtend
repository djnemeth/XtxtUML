package hu.elte.txtuml.xtxtuml.ui.highlighting;

import com.google.inject.Inject
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAttribute
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConstructor
import hu.elte.txtuml.xtxtuml.xtxtUML.XUMultiplicity
import hu.elte.txtuml.xtxtuml.xtxtUML.XUOperation
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignalAttribute
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.common.types.JvmFormalParameter
import org.eclipse.xtext.documentation.impl.MultiLineCommentDocumentationProvider
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.ui.editor.syntaxcoloring.IHighlightedPositionAcceptor
import org.eclipse.xtext.xbase.XAbstractFeatureCall
import org.eclipse.xtext.xbase.ui.highlighting.XbaseHighlightingCalculator

import static hu.elte.txtuml.xtxtuml.ui.highlighting.XtxtUMLHighlightingConfiguration.*
import static hu.elte.txtuml.xtxtuml.xtxtUML.XtxtUMLPackage.Literals.*
import static org.eclipse.xtext.common.types.TypesPackage.Literals.*
import static org.eclipse.xtext.xbase.XbasePackage.Literals.*
import static org.eclipse.xtext.xbase.ui.highlighting.XbaseHighlightingConfiguration.*

class XtxtUMLHighlightingCalculator extends XbaseHighlightingCalculator {

	@Inject extension MultiLineCommentDocumentationProvider;

	override highlightElement(EObject object, IHighlightedPositionAcceptor acceptor) {
		highlightDocumentationComment(object, acceptor);

		switch (object) {
			XUAttribute:
				highlightFeature(acceptor, object, XU_ATTRIBUTE__NAME, FIELD)
			XUSignalAttribute:
				highlightFeature(acceptor, object, XU_SIGNAL_ATTRIBUTE__NAME, FIELD)
			XUConstructor:
				object.parameters.forEach [
					highlightFeature(acceptor, it, JVM_FORMAL_PARAMETER__NAME, FORMAL_PARAMETER)
				]
			XUOperation:
				object.parameters.forEach [
					highlightFeature(acceptor, it, JVM_FORMAL_PARAMETER__NAME, FORMAL_PARAMETER)
				]
			XUMultiplicity: {
				val textRegion = NodeModelUtils.findActualNodeFor(object).textRegion;
				acceptor.addPosition(textRegion.offset, textRegion.length, MULTIPLICITY);
			}
			default:
				super.highlightElement(object, acceptor)
		}

		return false;
	}

	def highlightDocumentationComment(EObject object, IHighlightedPositionAcceptor acceptor) {
		for (docNode : object.documentationNodes) {
			if (docNode.text.startsWith("/**")) {
				val textRegion = docNode.textRegion;
				acceptor.addPosition(textRegion.offset, textRegion.length, DOCUMENTATION_COMMENT);
			}
		}
	}

	override computeFeatureCallHighlighting(XAbstractFeatureCall featureCall, IHighlightedPositionAcceptor acceptor) {
		if (featureCall.isExtension) {
			return;
		} else if (featureCall.feature instanceof JvmFormalParameter) {
			highlightFeature(acceptor, featureCall, XABSTRACT_FEATURE_CALL__FEATURE, FORMAL_PARAMETER);
		}

		super.computeFeatureCallHighlighting(featureCall, acceptor);
	}

}
