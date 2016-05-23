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
import static org.eclipse.xtext.xbase.XbasePackage.Literals.*

@RunWith(XtextRunner)
@InjectWith(XtxtUMLInjectorProvider)
class XtxtUMLExpressionValidatorTest {

	@Inject extension ParseHelper<XUFile>;
	@Inject extension ValidationTestHelper;

	@Test
	def checkMandatoryIntentionalReturn() {
		'''
			package test.model;
			class A {
				void foo() { return; }
				int bar() { return 0; }
				int baz() {
					if (true) {
						return 0;
					} else {
						return 0;
					}
				}
				int foobar() {
					for (int i = 0; i < 1; i++) {
						return 0;
					}
				}
				int foobaz() {
					while (true) {
						return 0;
					}
				}
				int barbaz() {
					do {
						return 0;
					} while (true);
				}
			}
		'''.parse.assertNoError(MISSING_RETURN);

		val file = '''
			package test.model;
			class A {
				int foo() {}
				int bar() {
					for (int i = 0; i < 1; i++) {}
				}
				int baz() {
					while (true) {}
				}
				int foobar() {
					do {} while (true);
				}
			}
		'''.parse;

		file.assertError(XU_OPERATION, MISSING_RETURN, 37, 3);
		file.assertError(XU_OPERATION, MISSING_RETURN, 52, 3);
		file.assertError(XU_OPERATION, MISSING_RETURN, 104, 3);
		file.assertError(XU_OPERATION, MISSING_RETURN, 141, 6);
	}

	@Test
	def checkNoExplicitExtensionCall() {
		val file = '''
			package test.model;
			class A {
				void foo(A a) {
					foo();
					this.foo();
				}
			}
		'''.parse;

		file.assertError(XFEATURE_CALL, UNDEFINED_OPERATION, 52, 3)
		file.assertError(XMEMBER_FEATURE_CALL, UNDEFINED_OPERATION, 67, 3);
	}

	@Test
	def checkExplicitOperationCall() {
		'''
			package test.model;
			class A {
				void foo() {
					foo();
					this.foo();
				}
			}
		'''.parse.assertNoErrors;

		val file = '''
			package test.model;
			class A {
				void foo() {
					foo;
					this.foo;
				}
			}
		'''.parse;

		file.assertError(XFEATURE_CALL, MISSING_OPERATION_PARENTHESES, 49, 3);
		file.assertError(XMEMBER_FEATURE_CALL, MISSING_OPERATION_PARENTHESES, 62, 3);
	}

	@Test
	def checkSignalAccessExpression() {
		'''
			package test.model;
			class A {
				state S {
					entry {
						trigger;
					}
					exit {
						trigger;
					}
				}
			}
		'''.parse.assertNoError(INVALID_SIGNAL_ACCESS);

		'''
			package test.model;
			class A {
				transition T {
					effect {
						trigger;
					}
				}
			}
		'''.parse.assertNoError(INVALID_SIGNAL_ACCESS);

		'''
			package test.model;
			class A {
				initial Init;
				state S {
					exit {
						trigger;
					}
				}
				transition T {
					from Init;
					to S;
				}
			}
		'''.parse.assertNoError(INVALID_SIGNAL_ACCESS);

		'''
			package test.model;
			class A {
				initial Init;
				state S;
				choice C;
				
				transition T1 {
					from Init;
					to S;
				}
				
				transition T2 {
					from S;
					to C;
				}
				
				transition T3 {
					from C;
					to S;
					effect {
						trigger;
					}
				}
			}
		'''.parse.assertNoError(INVALID_SIGNAL_ACCESS);

		val trivialInvalid = '''
			package test.model;
			execution E {
				trigger;
			}
			class A {
				void foo() {
					trigger;
				}
			}
		'''.parse;

		trivialInvalid.assertError(XU_SIGNAL_ACCESS_EXPRESSION, INVALID_SIGNAL_ACCESS, 37, 7);
		trivialInvalid.assertError(XU_SIGNAL_ACCESS_EXPRESSION, INVALID_SIGNAL_ACCESS, 78, 7);

		val nonTrivialInvalid = '''
			package test.model;
			class A {
				initial Init;
				choice C1;
				choice C2;
				choice C3;
				choice C4;
				state S1 {
					entry { trigger; }
				}
				state S2;
			
				transition T1 {
					from Init;
					to C1;
					effect { trigger; }
				}
			
				transition T2 {
					from C1;
					to C2;
					effect { trigger; }
				}
			
				transition T3 {
					from C2;
					to C3;
				}
			
				transition T4 {
					from C3;
					to C1;
				}
			
				transition T5 {
					from C3;
					to S1;
					effect { trigger; }
				}
			
				transition T6 {
					from S2;
					to S1;
				}
			}
		'''.parse;

		nonTrivialInvalid.assertError(XU_SIGNAL_ACCESS_EXPRESSION, INVALID_SIGNAL_ACCESS, 123, 7);
		nonTrivialInvalid.assertError(XU_SIGNAL_ACCESS_EXPRESSION, INVALID_SIGNAL_ACCESS, 206, 7);
		nonTrivialInvalid.assertError(XU_SIGNAL_ACCESS_EXPRESSION, INVALID_SIGNAL_ACCESS, 275, 7);
		nonTrivialInvalid.assertError(XU_SIGNAL_ACCESS_EXPRESSION, INVALID_SIGNAL_ACCESS, 436, 7);
	}

	@Test
	def checkSignalSentToPortIsRequired() {
		'''
			package test.model;
			signal S1;
			signal S2;
			interface I {
				reception S1;
				reception S2;
			}
			class A {
				port P { required I; }
				void foo() {
					send new S1() to this->(P);
					send new S2() to this->(P);
				}
			}
		'''.parse.assertNoErrors;

		val file = '''
			package test.model;
			signal S1;
			signal S2;
			interface I {
				reception S1;
			}
			class A {
				port P1 { required I; }
				port P2 {}
				void foo() {
					send new S1() to this->(P1);
					send new S2() to this->(P1);
					send new S1() to this->(P2);
					send new S2() to this->(P2);
				}
			}
		'''.parse;

		file.assertError(XU_SEND_SIGNAL_EXPRESSION, NOT_REQUIRED_SIGNAL, 183, 8);
		file.assertError(XU_SEND_SIGNAL_EXPRESSION, NOT_REQUIRED_SIGNAL, 215, 8);
		file.assertError(XU_SEND_SIGNAL_EXPRESSION, NOT_REQUIRED_SIGNAL, 247, 8);
	}

	@Test
	def checkQueriedPortIsOwned() {
		'''
			package test.model;
			class A {
				port P {}
				void foo() {
					send null to this->(P);
				}
			}
			class B {
				port P {}
				void bar() {
					send null to this->(P);
				}
			}
			execution E {
				A a = new A();
				B b = new B();
				connect(null, a->(A.P), null, b->(B.P));
			}
		'''.parse.assertNoError(QUERIED_PORT_IS_NOT_OWNED);

		val file = '''
			package test.model;
			class A {
				port P {}
				void foo() {
					send null to this->(B.P);
				}
			}
			class B {
				port P {}
				void bar() {
					send null to this->(A.P);
				}
			}
		'''.parse;

		file.assertError(XU_SEND_SIGNAL_EXPRESSION, QUERIED_PORT_IS_NOT_OWNED, 74, 11);
		file.assertError(XU_SEND_SIGNAL_EXPRESSION, QUERIED_PORT_IS_NOT_OWNED, 148, 11);
	}

	@Test
	def checkAccessedClassPropertyIsSpecified() {
		'''
			package test.model;
			class A {
				void foo() {
					this->(AB.b);
				}
			}
			class B;
			association AB {
				A a;
				B b;
			}
		'''.parse.assertNoError(MISSING_CLASS_PROPERTY);

		'''
			package test.model;
			class A {
				void foo() {
					this->();
				}
			}
			class B;
			association AB {
				A a;
				B b;
			}
		'''.parse.assertError(XU_CLASS_PROPERTY_ACCESS_EXPRESSION, MISSING_CLASS_PROPERTY, 53, 2);
	}

	@Test
	def checkClassPropertyIsAccessible() {
		val accessibleProperties = '''
			package test.model;
			class A {
				port P {}
				void foo() {
					this->(AB.b);
					this->(P);
				}
			}
			class B {
				port P {}
				void bar() {
					this->(AB.a);
					this->(P);
				}
			}
			association AB {
				A a;
				B b;
			}
		'''.parse;

		accessibleProperties.assertNoError(NOT_NAVIGABLE_ASSOCIATION_END);
		accessibleProperties.assertNoError(NOT_ACCESSIBLE_ASSOCIATION_END);
		accessibleProperties.assertNoError(NOT_ACCESSIBLE_PORT);

		val notAccessibleProperties = '''
			package test.model;
			class A {
				port P {}
				void foo() {
					this->(AB1.a);
					this->(AB2.b);
					this->(B.P);
				}
			}
			class B {
				port P {}
				void bar() {
					this->(AB1.b);
					this->(A.P);
				}
			}
			association AB1 {
				A a;
				B b;
			}
			association AB2 {
				A a;
				hidden B b;
			}
		'''.parse;

		notAccessibleProperties.assertError(XU_CLASS_PROPERTY_ACCESS_EXPRESSION, NOT_ACCESSIBLE_ASSOCIATION_END, 68, 5);
		notAccessibleProperties.assertError(XU_CLASS_PROPERTY_ACCESS_EXPRESSION, NOT_NAVIGABLE_ASSOCIATION_END, 86, 5);
		notAccessibleProperties.assertError(XU_CLASS_PROPERTY_ACCESS_EXPRESSION, NOT_ACCESSIBLE_PORT, 104, 3);

		notAccessibleProperties.assertError(XU_CLASS_PROPERTY_ACCESS_EXPRESSION, NOT_ACCESSIBLE_ASSOCIATION_END, 165,
			5);
		notAccessibleProperties.assertError(XU_CLASS_PROPERTY_ACCESS_EXPRESSION, NOT_ACCESSIBLE_PORT, 183, 3);
	}

}
