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
import static org.eclipse.xtext.common.types.TypesPackage.Literals.*

@RunWith(XtextRunner)
@InjectWith(XtxtUMLInjectorProvider)
class XtxtUMLTypeValidatorTest {

	@Inject extension ParseHelper<XUFile>;
	@Inject extension ValidationTestHelper;

	@Test
	def checkTypeReference() {
		'''
			package test.model;
			
			signal S {
				int a1;
				boolean a2;
				double a3;
				String a4;
				Integer a5;
				Boolean a6;
				Double a7;
			}
			
			class A {
				int a1;
				boolean a2;
				double a3;
				String a4;
				Integer a5;
				Boolean a6;
				Double a7;
			
				void o1(int p) {}
				int o2(boolean p) {}
				boolean o3(double p) {}
				double o4(String p) {}
				String o5(Integer p) {}
				Integer o6(Boolean p) {}
				Boolean o7(Double p) {}
				Double o8(A p) {}
				A o9() {}
			}
		'''.parse.assertNoError(INVALID_TYPE);

		val file = '''
			package test.model;
			
			signal S {
				long a1;
				A a2;
				Class a3;
				void a4;
			}
			
			class A {
				long a1;
				A a2;
				Class a3;
				void a4;
			
				long o1() {}
				Class o2(Class p) {}
			}
		'''.parse;

		file.assertError(JVM_PARAMETERIZED_TYPE_REFERENCE, INVALID_TYPE, 36, 4);
		file.assertError(JVM_PARAMETERIZED_TYPE_REFERENCE, INVALID_TYPE, 47, 1);
		file.assertError(JVM_PARAMETERIZED_TYPE_REFERENCE, INVALID_TYPE, 55, 5);
		file.assertError(JVM_PARAMETERIZED_TYPE_REFERENCE, INVALID_TYPE, 67, 4);

		file.assertError(JVM_PARAMETERIZED_TYPE_REFERENCE, INVALID_TYPE, 94, 4);
		file.assertError(JVM_PARAMETERIZED_TYPE_REFERENCE, INVALID_TYPE, 105, 1);
		file.assertError(JVM_PARAMETERIZED_TYPE_REFERENCE, INVALID_TYPE, 113, 5);
		file.assertError(JVM_PARAMETERIZED_TYPE_REFERENCE, INVALID_TYPE, 125, 4);

		file.assertError(JVM_PARAMETERIZED_TYPE_REFERENCE, INVALID_TYPE, 138, 4);
		file.assertError(JVM_PARAMETERIZED_TYPE_REFERENCE, INVALID_TYPE, 153, 5);
		file.assertError(JVM_PARAMETERIZED_TYPE_REFERENCE, INVALID_TYPE, 162, 5);
	}

	@Test
	def checkSendSignalExpressionTypes() {
		'''
			package test.model;
			signal S;
			class A;
			execution E {
				send new S() to new A();
			}
		'''.parse.assertNoErrors;

		val nulls = '''
			package test.model;
			execution E {
				send null to null;
			}
		'''.parse;

		nulls.assertError(XU_SEND_SIGNAL_EXPRESSION, TYPE_MISMATCH, 42, 4);
		nulls.assertError(XU_SEND_SIGNAL_EXPRESSION, TYPE_MISMATCH, 50, 4);

		val strings = '''
			package test.model;
			execution E {
				send "signal" to "object";
			}
		'''.parse;

		strings.assertError(XU_SEND_SIGNAL_EXPRESSION, TYPE_MISMATCH, 42, 8);
		strings.assertError(XU_SEND_SIGNAL_EXPRESSION, TYPE_MISMATCH, 54, 8);
	}

	@Test
	def checkDeleteObjectExpressionTypes() {
		'''
			package test.model;
			class A;
			execution E {
				delete new A();
			}
		'''.parse.assertNoErrors;

		val nulls = '''
			package test.model;
			execution E {
				delete null;
			}
		'''.parse;

		nulls.assertError(XU_DELETE_OBJECT_EXPRESSION, TYPE_MISMATCH, 44, 4);

		val strings = '''
			package test.model;
			execution E {
				delete "object";
			}
		'''.parse;

		strings.assertError(XU_DELETE_OBJECT_EXPRESSION, TYPE_MISMATCH, 44, 8);
	}

	@Test
	def checkLogExpressionTypes() {
		'''
			package test.model;
			execution E {
				log "message";
			}
		'''.parse.assertNoErrors;

		val nulls = '''
			package test.model;
			execution E {
				log null;
			}
		'''.parse;

		nulls.assertError(XU_LOG_EXPRESSION, TYPE_MISMATCH, 41, 4);

		val ints = '''
			package test.model;
			execution E {
				log 0;
			}
		'''.parse;

		ints.assertError(XU_LOG_EXPRESSION, TYPE_MISMATCH, 41, 1);
	}

	@Test
	def checkClassPropertyAccessExpressionTypes() {
		'''
			package test.model;
			signal S;
			class A {
				port P {}
				void foo() {
					send new S() to this->(P);
				}
			}
		'''.parse.assertNoError(TYPE_MISMATCH);

		val nulls = '''
			package test.model;
			signal S;
			class A {
				port P {}
				void foo() {
					send new S() to null->(P);
				}
			}
		'''.parse;

		nulls.assertError(XU_CLASS_PROPERTY_ACCESS_EXPRESSION, TYPE_MISMATCH, 88, 4);

		val strings = '''
			package test.model;
			signal S;
			class A {
				port P {}
				void foo() {
					send new S() to "this"->(P);
				}
			}
		'''.parse;

		strings.assertError(XU_CLASS_PROPERTY_ACCESS_EXPRESSION, TYPE_MISMATCH, 88, 6);
	}

}
