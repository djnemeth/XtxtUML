package hu.elte.txtuml.xtxtuml.validation

import hu.elte.txtuml.xtxtuml.xtxtUML.XUClassPropertyAccessExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUDeleteObjectExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSendSignalExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignalAccessExpression
import org.eclipse.xtext.xbase.XExpression
import org.eclipse.xtext.xbase.util.XExpressionHelper

class XtxtUMLExpressionHelper extends XExpressionHelper {

	public override hasSideEffects(XExpression expr) {
		switch (expr) {
			XUDeleteObjectExpression,
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
