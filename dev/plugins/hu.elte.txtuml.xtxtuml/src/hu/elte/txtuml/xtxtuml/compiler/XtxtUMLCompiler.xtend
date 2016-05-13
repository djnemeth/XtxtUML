package hu.elte.txtuml.xtxtuml.compiler

import com.google.inject.Inject
import hu.elte.txtuml.api.model.Action
import hu.elte.txtuml.api.model.Port
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociationEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClassPropertyAccessExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUDeleteObjectExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSendSignalExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignalAccessExpression
import org.eclipse.xtext.common.types.JvmType
import org.eclipse.xtext.xbase.XExpression
import org.eclipse.xtext.xbase.compiler.XbaseCompiler
import org.eclipse.xtext.xbase.compiler.output.ITreeAppendable
import org.eclipse.xtext.xbase.jvmmodel.IJvmModelAssociations

class XtxtUMLCompiler extends XbaseCompiler {

	@Inject extension IJvmModelAssociations;

	override protected doInternalToJavaStatement(XExpression obj, ITreeAppendable builder, boolean isReferenced) {
		switch (obj) {
			XUClassPropertyAccessExpression,
			XUDeleteObjectExpression,
			XUSendSignalExpression,
			XUSignalAccessExpression:
				obj.toJavaStatement(builder)
			default:
				super.doInternalToJavaStatement(obj, builder, isReferenced)
		}
	}

	def dispatch toJavaStatement(XUClassPropertyAccessExpression accessExpr, ITreeAppendable it) {
		// intentionally left empty
	}

	def dispatch toJavaStatement(XUSignalAccessExpression sigExpr, ITreeAppendable it) {
		// intentionally left empty
	}

	def dispatch toJavaStatement(XUDeleteObjectExpression deleteExpr, ITreeAppendable it) {
		newLine;
		append(Action);
		append(".delete(")
		deleteExpr.object.internalToJavaExpression(it);
		append(");");
	}

	def dispatch toJavaStatement(XUSendSignalExpression sendExpr, ITreeAppendable it) {
		newLine;
		append(Action)
		append(".send(");

		sendExpr.signal.internalToJavaExpression(it);
		append(", ");

		sendExpr.target.internalToJavaExpression(it);
		if (sendExpr.target.lightweightType.isSubtypeOf(Port)) {
			append(".required::reception");
		}

		append(");");
	}

	override protected internalToConvertedExpression(XExpression obj, ITreeAppendable it) {
		switch (obj) {
			XUClassPropertyAccessExpression,
			XUSignalAccessExpression:
				obj.toJavaExpression(it)
			default:
				super.internalToConvertedExpression(obj, it)
		}
	}

	def dispatch toJavaExpression(XUClassPropertyAccessExpression accessExpr, ITreeAppendable it) {
		accessExpr.left.internalToConvertedExpression(it);

		if (accessExpr.right instanceof XUAssociationEnd) {
			append(".assoc(");
		} else {
			append(".port(");
		}

		append(accessExpr.right.getPrimaryJvmElement as JvmType);
		append(".class)");
	}

	def dispatch toJavaExpression(XUSignalAccessExpression sigExpr, ITreeAppendable it) {
		append("getTrigger(");
		append(sigExpr.lightweightType);
		append(".class)");
	}

}
