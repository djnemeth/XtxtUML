package hu.elte.txtuml.xtxtuml.imports;

import com.google.inject.Inject
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociationEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClass
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClassPropertyAccessExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConnectorEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUPortMember
import hu.elte.txtuml.xtxtuml.xtxtUML.XUReception
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionPort
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionTrigger
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionVertex
import hu.elte.txtuml.xtxtuml.xtxtUML.XtxtUMLPackage
import java.util.ArrayList
import org.eclipse.emf.common.util.TreeIterator
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtext.common.types.JvmDeclaredType
import org.eclipse.xtext.common.types.JvmType
import org.eclipse.xtext.resource.ILocationInFileProvider
import org.eclipse.xtext.util.ITextRegion
import org.eclipse.xtext.util.TextRegion
import org.eclipse.xtext.xbase.imports.ImportedTypesCollector
import org.eclipse.xtext.xbase.jvmmodel.IJvmModelAssociations

class XtxtUMLImportedTypesCollector extends ImportedTypesCollector {

	@Inject extension IJvmModelAssociations;
	@Inject extension ILocationInFileProvider;

	/**
	 * Extends the default behavior to collect XtxtUML references as well.
	 */
	override protected collectAllReferences(EObject rootElement) {
		super.collectAllReferences(rootElement);

		// explicit type declaration is required to avoid incorrect type inference
		val TreeIterator<EObject> contents = EcoreUtil.getAllContents(rootElement, true);

		while (contents.hasNext()) {
			val references = new ArrayList<Pair<JvmType, ITextRegion>>();

			// determine the grammar-level cross-referenced types inside XtxtUML expressions
			switch (next : contents.next()) {
				XUClass:
					references.add(next.superClass?.getPrimaryJvmElement as JvmType ->
						next.getFullTextRegion(XtxtUMLPackage::eINSTANCE.XUClass_SuperClass, 0))
				XUTransitionTrigger:
					references.add(next.trigger?.getPrimaryJvmElement as JvmType ->
						next.getFullTextRegion(XtxtUMLPackage::eINSTANCE.XUTransitionTrigger_Trigger, 0))
				XUTransitionVertex:
					references.add(next.vertex?.getPrimaryJvmElement as JvmType ->
						next.getFullTextRegion(XtxtUMLPackage::eINSTANCE.XUTransitionVertex_Vertex, 0))
				XUAssociationEnd:
					references.add(next.endClass?.getPrimaryJvmElement as JvmType ->
						next.getFullTextRegion(XtxtUMLPackage::eINSTANCE.XUAssociationEnd_EndClass, 0))
				XUClassPropertyAccessExpression:
					references.add(adjustedNestedClassReference(next.right?.getPrimaryJvmElement as JvmType,
						next.getFullTextRegion(XtxtUMLPackage::eINSTANCE.XUClassPropertyAccessExpression_Right, 0)))
				XUReception:
					references.add(next.signal?.getPrimaryJvmElement as JvmType ->
						next.getFullTextRegion(XtxtUMLPackage::eINSTANCE.XUReception_Signal, 0))
				XUConnectorEnd: {
					references.add(adjustedNestedClassReference(next.role?.getPrimaryJvmElement as JvmType,
						next.getFullTextRegion(XtxtUMLPackage::eINSTANCE.XUConnectorEnd_Role, 0)))
					references.add(adjustedNestedClassReference(next.port?.getPrimaryJvmElement as JvmType,
						next.getFullTextRegion(XtxtUMLPackage::eINSTANCE.XUConnectorEnd_Port, 0)))
				}
				XUPortMember:
					references.add(next.interface?.getPrimaryJvmElement as JvmType ->
						next.getFullTextRegion(XtxtUMLPackage::eINSTANCE.XUPortMember_Interface, 0))
				XUTransitionPort:
					references.add(next.port?.getPrimaryJvmElement as JvmType ->
						next.getFullTextRegion(XtxtUMLPackage::eINSTANCE.XUTransitionPort_Port, 0))
			}

			for (ref : references) {
				if (ref.key != null && ref.value != null) {
					acceptType(ref.key, ref.value);
				}
			}
		}
	}

	/**
	 * Overrides the super implementation to accept types even in case of fully qualified name references.
	 * This aspect is used to make fully qualified name references simplifiable during import organization.
	 */
	override protected acceptType(JvmType type, JvmType usedType, ITextRegion refRegion) {
		val currentContext = getCurrentContext();
		if (currentContext == null) {
			return;
		}

		if (type == null || type.eIsProxy()) {
			throw new IllegalArgumentException();
		}

		if (type instanceof JvmDeclaredType) {
			getTypeUsages().addTypeUsage(type as JvmDeclaredType, usedType as JvmDeclaredType, refRegion,
				currentContext);
		}
	}

	/**
	 * Adjusts the given (type, reference) pair if the type is a nested class which is referenced
	 * through its enclosing class, such that the actually used type becomes the enclosing class.
	 * Used to preserve this indirection during import organization.
	 */
	def private adjustedNestedClassReference(JvmType nestedClass, ITextRegion refRegion) {
		if (refRegion == null || nestedClass == null || !(nestedClass.eContainer instanceof JvmType)) {
			return null -> null;
		}

		if (refRegion.length > nestedClass.simpleName.length) {
			val enclosingClassRefLength = refRegion.length - ("." + nestedClass.simpleName).length;
			return nestedClass.eContainer as JvmType ->
				new TextRegion(refRegion.offset, enclosingClassRefLength) as ITextRegion;
		}

		return nestedClass -> refRegion;
	}

}
