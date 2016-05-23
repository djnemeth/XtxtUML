package hu.elte.txtuml.xtxtuml.ui.outline;

import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociationEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAttribute
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConstructor
import hu.elte.txtuml.xtxtuml.xtxtUML.XUEntryOrExitActivity
import hu.elte.txtuml.xtxtuml.xtxtUML.XUExecution
import hu.elte.txtuml.xtxtuml.xtxtUML.XUFile
import hu.elte.txtuml.xtxtuml.xtxtUML.XUOperation
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignalAttribute
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionEffect
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionGuard
import org.eclipse.xtext.ui.editor.outline.impl.DefaultOutlineTreeProvider
import org.eclipse.xtext.ui.editor.outline.impl.DocumentRootNode

/**
 * Customization of the default outline structure.
 */
class XtxtUMLOutlineTreeProvider extends DefaultOutlineTreeProvider {

	def _isLeaf(XUFile op) {
		true
	}

	def _isLeaf(XUExecution exec) {
		true
	}

	def _isLeaf(XUSignalAttribute sAttr) {
		true
	}

	def _isLeaf(XUAttribute attr) {
		true
	}

	def _isLeaf(XUConstructor ctor) {
		true
	}

	def _isLeaf(XUOperation op) {
		true
	}

	def _isLeaf(XUEntryOrExitActivity act) {
		true
	}

	def _isLeaf(XUAssociationEnd assocEnd) {
		true
	}

	def _isLeaf(XUTransitionEffect effect) {
		true
	}

	def _isLeaf(XUTransitionGuard guard) {
		true
	}

	def _createChildren(DocumentRootNode rootNode, XUFile file) {
		createNode(rootNode, file);
		for (element : file.elements) {
			createNode(rootNode, element);
		}
	}

}
