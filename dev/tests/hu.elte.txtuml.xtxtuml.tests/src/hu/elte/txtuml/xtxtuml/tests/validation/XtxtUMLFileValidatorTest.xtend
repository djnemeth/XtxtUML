package hu.elte.txtuml.xtxtuml.tests.validation

import com.google.inject.Inject
import hu.elte.txtuml.xtxtuml.XtxtUMLInjectorProvider
import hu.elte.txtuml.xtxtuml.xtxtUML.XUFile
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.xtext.junit4.InjectWith
import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.junit4.util.ParseHelper
import org.eclipse.xtext.junit4.validation.ValidationTestHelper
import org.junit.Test
import org.junit.runner.RunWith

import static hu.elte.txtuml.xtxtuml.validation.XtxtUMLIssueCodes.*
import static hu.elte.txtuml.xtxtuml.xtxtUML.XtxtUMLPackage.Literals.*

@RunWith(XtextRunner)
@InjectWith(XtxtUMLInjectorProvider)
class XtxtUMLFileValidatorTest {

	@Inject extension ParseHelper<XUFile>;
	@Inject extension ValidationTestHelper;

	@Test
	def checkModelDeclarationIsInModelInfoFile() {
		val rawFile = '''
			model-package test.model;
		''';

		rawFile.parse(URI.createURI("model-info.xtxtuml"), new ResourceSetImpl()).assertNoErrors;
		rawFile.parse(URI.createURI("model-info.txtuml"), new ResourceSetImpl()).assertNoErrors;
		rawFile.parse(URI.createURI("modelinfo.xtxtuml"), new ResourceSetImpl()).assertError(XU_MODEL_DECLARATION,
			MISPLACED_MODEL_DECLARATION, 0, 13);
	}

}
