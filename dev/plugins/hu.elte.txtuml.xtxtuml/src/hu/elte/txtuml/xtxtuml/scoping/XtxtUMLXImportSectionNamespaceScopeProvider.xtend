package hu.elte.txtuml.xtxtuml.scoping

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.xbase.scoping.XImportSectionNamespaceScopeProvider

class XtxtUMLXImportSectionNamespaceScopeProvider extends XImportSectionNamespaceScopeProvider {

	override protected getImplicitImports(boolean ignoreCase) {
		#[
			doCreateImportNormalizer(JAVA_LANG, true, false)
		]
	}

	override protected internalGetAllDescriptions(Resource resource) {
		return new XtxtUMLMultimapBasedSelectable(super.internalGetAllDescriptions(resource).exportedObjects);
	}

	override protected doCreateImportNormalizer(QualifiedName importedNamespace, boolean wildcard, boolean ignoreCase) {
		return new XtxtUMLImportNormalizer(importedNamespace, wildcard, ignoreCase);
	}

}
