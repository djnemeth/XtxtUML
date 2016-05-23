package hu.elte.txtuml.xtxtuml.validation

import hu.elte.txtuml.xtxtuml.xtxtUML.XUClassPropertyAccessExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUDeleteObjectExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XULogExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSendSignalExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignalAccessExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUStartObjectExpression
import org.eclipse.xtext.xbase.XExpression
import org.eclipse.xtext.xbase.util.XExpressionHelper

class XtxtUMLExpressionHelper extends XExpressionHelper {

	/**
	 * Extends the default behavior to XtxtUML expressions.
	 */
	public override hasSideEffects(XExpression expr) {
		switch (expr) {
			XUStartObjectExpression,
			XUDeleteObjectExpression,
			XULogExpression,
			XUSendSignalExpression:
				true
			XUSignalAccessExpression,
			XUClassPropertyAccessExpression:
				false
			default:
				super.hasSideEffects(expr)
		}
	}

}
