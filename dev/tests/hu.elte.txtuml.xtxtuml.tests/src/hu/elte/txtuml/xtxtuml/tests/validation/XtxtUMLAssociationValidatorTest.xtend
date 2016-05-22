package hu.elte.txtuml.xtxtuml.tests.validation;

import com.google.inject.Inject
import hu.elte.txtuml.xtxtuml.XtxtUMLInjectorProvider
import hu.elte.txtuml.xtxtuml.xtxtUML.XUFile
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
class XtxtUMLAssociationValidatorTest {

	@Inject extension ParseHelper<XUFile>
	@Inject extension ValidationTestHelper

	@Test
	def checkAssociationHasExactlyTwoEnds() {
		'''
			package test.model;
			class A;
			association AA {
				A a1;
				A a2;
			}
		'''.parse.assertNoErrors;

		val file = '''
			package test.model;
			class A;
			association A1 {}
			association A2 {
				A a1;
			}
			association A3 {
				A a1;
				A a2;
				A a3;
			}
		'''.parse;

		file.assertError(XU_ASSOCIATION, ASSOCIATION_END_COUNT_MISMATCH, 43, 2);
		file.assertError(XU_ASSOCIATION, ASSOCIATION_END_COUNT_MISMATCH, 62, 2);
		file.assertError(XU_ASSOCIATION, ASSOCIATION_END_COUNT_MISMATCH, 91, 2);
	}

	@Test
	def checkContainerEndIsAllowedAndNeededOnlyInComposition() {
		'''
			package test.model;
			class A;
			composition C {
				container A a1;
				A a2;
			}
		'''.parse.assertNoErrors;

		val file = '''
			package test.model;
			class A;
			association AA {
				container A a1;
				A a2;
			}
			composition C1 {
				A a1;
				A a2;
			}
			composition C2 {
				container A a1;
				container A a2;
			}
		'''.parse;

		file.assertError(XU_ASSOCIATION_END, CONTAINER_END_IN_ASSOCIATION, 50, 9);
		file.assertError(XU_COMPOSITION, CONTAINER_END_COUNT_MISMATCH, 90, 2);
		file.assertError(XU_COMPOSITION, CONTAINER_END_COUNT_MISMATCH, 127, 2);
	}

}
