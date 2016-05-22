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
class XtxtUMLUniquenessValidatorTest {

	@Inject extension ParseHelper<XUFile>;
	@Inject extension ValidationTestHelper;

	@Test
	def checkModelElementNameIsUniqueExternal() {
		'''
			package java.lang;
			class __4416cWAUcf77;
		'''.parse.assertNoErrors;

		'''
			package java.lang;
			class String;
		'''.parse.assertError(XU_CLASS, NOT_UNIQUE_NAME, 26, 6);
	}

	@Test
	def checkModelElementNameIsUniqueInternal() {
		'''
			package test.model;
			class A;
			class B;
		'''.parse.assertNoErrors;

		val sameType = '''
			package test.model;
			class A;
			class A;
		'''.parse;

		sameType.assertError(XU_CLASS, NOT_UNIQUE_NAME, 27, 1);
		sameType.assertError(XU_CLASS, NOT_UNIQUE_NAME, 37, 1);

		val differentTypes = '''
			package test.model
			class A;
			signal A;
		'''.parse;

		differentTypes.assertError(XU_CLASS, NOT_UNIQUE_NAME, 26, 1);
		differentTypes.assertError(XU_SIGNAL, NOT_UNIQUE_NAME, 37, 1);
	}

	@Test
	def checkSignalAttributeNameIsUnique() {
		'''
			package test.model;
			signal S {
				int a;
			}
		'''.parse.assertNoErrors;

		val file = '''
			package test.model;
			signal S {
				int a;
				double a;
			}
		'''.parse;

		file.assertError(XU_SIGNAL_ATTRIBUTE, NOT_UNIQUE_NAME, 38, 1);
		file.assertError(XU_SIGNAL_ATTRIBUTE, NOT_UNIQUE_NAME, 50, 1);
	}

	@Test
	def checkAttributeNameIsUnique() {
		'''
			package test.model;
			class A {
				int a;
			}
		'''.parse.assertNoErrors;

		val file = '''
			package test.model;
			class A {
				int a;
				double a;
			}
		'''.parse;

		file.assertError(XU_ATTRIBUTE, NOT_UNIQUE_NAME, 37, 1);
		file.assertError(XU_ATTRIBUTE, NOT_UNIQUE_NAME, 49, 1);
	}

	@Test
	def checkConstructorIsUnique() {
		'''
			package test.model;
			class A {
				public A() {}
			}
		'''.parse.assertNoErrors;

		'''
			package test.model;
			class A {
				public A() {}
				public A(int a) {}
			}
		'''.parse.assertNoErrors;

		val file = '''
			package test.model;
			class A {
				public A() {}
				A() {}
				public A(int a) {}
				A(int a) {}
			}
		'''.parse;

		file.assertError(XU_CONSTRUCTOR, NOT_UNIQUE_CONSTRUCTOR, 40, 1);
		file.assertError(XU_CONSTRUCTOR, NOT_UNIQUE_CONSTRUCTOR, 49, 1);
		file.assertError(XU_CONSTRUCTOR, NOT_UNIQUE_CONSTRUCTOR, 65, 1);
		file.assertError(XU_CONSTRUCTOR, NOT_UNIQUE_CONSTRUCTOR, 79, 1);
	}

	@Test
	def checkOperationIsUnique() {
		'''
			package test.model;
			class A {
				void foo() {}
			}
		'''.parse.assertNoErrors;

		'''
			package test.model;
			class A {
				void foo() {}
				void bar() {}
			}
		'''.parse.assertNoErrors;

		'''
			package test.model;
			class A {
				void foo() {}
				void foo(int a) {}
			}
		'''.parse.assertNoErrors;

		val file = '''
			package test.model;
			class A {
				void foo() {}
				int foo() { return 0; }
			}
		'''.parse;

		file.assertError(XU_OPERATION, NOT_UNIQUE_OPERATION, 38, 3);
		file.assertError(XU_OPERATION, NOT_UNIQUE_OPERATION, 53, 3);
	}

	@Test
	def checkInitialStateIsUnique() {
		'''
			package test.model;
			class A {
				initial Init;
			}
		'''.parse.assertNoError(NOT_UNIQUE_INITIAL_STATE);

		'''
			package test.model;
			class A {
				initial Init;
				composite CS {
					initial Init;
				}
			}
		'''.parse.assertNoError(NOT_UNIQUE_INITIAL_STATE);

		val file = '''
			package test.model;
			class A {
				initial Init1;
				initial Init2;
				composite CS {
					initial Init3;
					initial Init4;
				}
			}
		'''.parse;

		file.assertError(XU_STATE, NOT_UNIQUE_INITIAL_STATE, 41, 5);
		file.assertError(XU_STATE, NOT_UNIQUE_INITIAL_STATE, 58, 5);
		file.assertError(XU_STATE, NOT_UNIQUE_INITIAL_STATE, 93, 5);
		file.assertError(XU_STATE, NOT_UNIQUE_INITIAL_STATE, 111, 5);
	}

	@Test
	def checkNestedClassMemberNameIsUnique() {
		'''
			package test.model;
			class A {
				state S;
			}
		'''.parse.assertNoError(NOT_UNIQUE_NAME);

		'''
			package test.model;
			class A {
				transition T {}
			}
		'''.parse.assertNoError(NOT_UNIQUE_NAME);

		'''
			package test.model;
			class A {
				port P {}
			}
		'''.parse.assertNoError(NOT_UNIQUE_NAME);

		val states = '''
			package test.model;
			class A {
				state S;
				state S;
			}
		'''.parse;

		states.assertError(XU_STATE, NOT_UNIQUE_NAME, 39, 1);
		states.assertError(XU_STATE, NOT_UNIQUE_NAME, 50, 1);

		val transitions = '''
			package test.model;
			class A {
				transition T {}
				transition T {}
			}
		'''.parse;

		transitions.assertError(XU_TRANSITION, NOT_UNIQUE_NAME, 44, 1);
		transitions.assertError(XU_TRANSITION, NOT_UNIQUE_NAME, 62, 1);

		val ports = '''
			package test.models;
			class A {
				port P {}
				port P {}
			}
		'''.parse;

		ports.assertError(XU_PORT, NOT_UNIQUE_NAME, 39, 1);
		ports.assertError(XU_PORT, NOT_UNIQUE_NAME, 51, 1);

		val all = '''
			package test.models;
			class A {
				state D;
				transition D {}
				port D {}
			}
		'''.parse;

		all.assertError(XU_STATE, NOT_UNIQUE_NAME, 40, 1);
		all.assertError(XU_TRANSITION, NOT_UNIQUE_NAME, 56, 1);
		all.assertError(XU_PORT, NOT_UNIQUE_NAME, 68, 1);
	}

	@Test
	def checkStateActivityIsUnique() {
		'''
			package test.model;
			class A {
				state S {
					entry {}
				}
			}
		'''.parse.assertNoError(NOT_UNIQUE_STATE_ACTIVITY);

		'''
			package test.model;
			class A {
				state S {
					entry {}
					exit {}
				}
			}
		'''.parse.assertNoError(NOT_UNIQUE_STATE_ACTIVITY);

		val file = '''
			package test.model;
			class A {
				state S {
					entry {}
					entry {}
				}
			}
		'''.parse;

		file.assertError(XU_ENTRY_OR_EXIT_ACTIVITY, NOT_UNIQUE_STATE_ACTIVITY, 46, 5);
		file.assertError(XU_ENTRY_OR_EXIT_ACTIVITY, NOT_UNIQUE_STATE_ACTIVITY, 58, 5);
	}

	@Test
	def checkInitialTransitionIsUnique() {
		'''
			package test.model;
			class A {
				initial I;
				state S;
				transition {
					from I;
					to S;
				}
			}
		'''.parse.assertNoError(NOT_UNIQUE_INITIAL_TRANSITION);

		'''
			package test.model;
			class A {
				initial Init;
				transition T1 {
					from Init;
					to CS;
				}
			
				composite CS {
					initial Init;
					state S;
					transition T2 {
						from Init;
						to S;
					}
				}
			}
		'''.parse.assertNoError(NOT_UNIQUE_INITIAL_TRANSITION);

		val flat = '''
			package test.model;
			class A {
				initial Init;
				state S1;
				state S2;
			
				transition T1 {
					from Init;
					to S1;
				}
			
				transition T2 {
					from Init;
					to S2;
				}
			}
		'''.parse;

		flat.assertError(XU_TRANSITION, NOT_UNIQUE_INITIAL_TRANSITION, 86, 2);
		flat.assertError(XU_TRANSITION, NOT_UNIQUE_INITIAL_TRANSITION, 134, 2);

		val hierarchical = '''
			package test.model;
			class A {
				composite CS {
					initial Init;
					state S1;
					state S2;
			
					transition T1 {
						from Init;
						to S1;
					}
			
					transition T2 {
						from Init;
						to S2;
					}
				}
			}
		'''.parse;

		hierarchical.assertError(XU_TRANSITION, NOT_UNIQUE_INITIAL_TRANSITION, 107, 2);
		hierarchical.assertError(XU_TRANSITION, NOT_UNIQUE_INITIAL_TRANSITION, 159, 2);
	}

	@Test
	def checkTransitionMemberIsUnique() {
		'''
			package test.model;
			signal Sig;
			class A {
				port P {}
				state St;
				transition T {
					from St;
					to St;
					trigger Sig;
					port P;
					guard ( true );
					effect {}
				}
			}
		'''.parse.assertNoError(NOT_UNIQUE_TRANSITION_MEMBER);

		val file = '''
			package test.model;
			signal Sig;
			class A {
				port P {}
				state St;
				transition T {
					from St; from St;
					to St; to St;
					trigger Sig; trigger Sig;
					port P; port P;
					guard ( true ); guard ( true );
					effect {} effect {}
				}
			}
		'''.parse;

		file.assertError(XU_TRANSITION_VERTEX, NOT_UNIQUE_TRANSITION_MEMBER, 88, 4);
		file.assertError(XU_TRANSITION_VERTEX, NOT_UNIQUE_TRANSITION_MEMBER, 97, 4);
		file.assertError(XU_TRANSITION_VERTEX, NOT_UNIQUE_TRANSITION_MEMBER, 109, 2);
		file.assertError(XU_TRANSITION_VERTEX, NOT_UNIQUE_TRANSITION_MEMBER, 116, 2);
		file.assertError(XU_TRANSITION_TRIGGER, NOT_UNIQUE_TRANSITION_MEMBER, 126, 7);
		file.assertError(XU_TRANSITION_TRIGGER, NOT_UNIQUE_TRANSITION_MEMBER, 139, 7);
		file.assertError(XU_TRANSITION_PORT, NOT_UNIQUE_TRANSITION_MEMBER, 155, 4);
		file.assertError(XU_TRANSITION_PORT, NOT_UNIQUE_TRANSITION_MEMBER, 163, 4);
		file.assertError(XU_TRANSITION_GUARD, NOT_UNIQUE_TRANSITION_MEMBER, 174, 5);
		file.assertError(XU_TRANSITION_GUARD, NOT_UNIQUE_TRANSITION_MEMBER, 190, 5);
		file.assertError(XU_TRANSITION_EFFECT, NOT_UNIQUE_TRANSITION_MEMBER, 209, 6);
		file.assertError(XU_TRANSITION_EFFECT, NOT_UNIQUE_TRANSITION_MEMBER, 219, 6);
	}

	@Test
	def checkPortMemberIsUnique() {
		'''
			package test.model;
			interface I1 {}
			class A {
				port P {
					provided I1;
				}
			}
		'''.parse.assertNoErrors;

		'''
			package test.model;
			interface I1 {}
			class A {
				port P {
					provided I1;
					required I1;
				}		
			}
		'''.parse.assertNoErrors;

		val file = '''
			package test.model;
			interface I1 {}
			interface I2 {}
			class A {
				port P {
					provided I1;
					provided I1;
					required I1;
					required I2;
				}
			}
		'''.parse

		file.assertError(XU_PORT_MEMBER, NOT_UNIQUE_PORT_MEMBER, 79, 8);
		file.assertError(XU_PORT_MEMBER, NOT_UNIQUE_PORT_MEMBER, 95, 8);
		file.assertError(XU_PORT_MEMBER, NOT_UNIQUE_PORT_MEMBER, 111, 8);
		file.assertError(XU_PORT_MEMBER, NOT_UNIQUE_PORT_MEMBER, 127, 8);
	}

	@Test
	def checkAssociationEndNamesAreUnique() {
		'''
			package test.model;
			class A;
			class B;
			association AB {
				A a;
				B b;
			}
		'''.parse.assertNoErrors;

		'''
			package test.model;
			class A;
			association AA {
				A e1;
				A e2;
			}
		'''.parse.assertNoErrors;

		val file = '''
			package test.model;
			class A;
			class B;
			association AB {
				A e;
				B e;
			}
		'''.parse;

		file.assertError(XU_ASSOCIATION_END, NOT_UNIQUE_NAME, 62, 1);
		file.assertError(XU_ASSOCIATION_END, NOT_UNIQUE_NAME, 69, 1);
	}

	@Test
	def checkConnectorEndIsUnique() {
		'''
			package test.model;
			class A { port P {} }
			class B { port P {} }
			composition CAB {
				container A a;
				B b;
			}
			
			delegation DAB {
				CAB.a->A.P a;
				CAB.b->B.P b;
			}
		'''.parse.assertNoError(NOT_UNIQUE_CONNECTOR_END);

		val nameDuplicate = '''
			package test.model;
			class A { port P {} }
			class B { port P {} }
			composition CAB {
				container A a;
				B b;
			}
			
			delegation DAB {
				CAB.a->A.P a;
				CAB.b->B.P a;
			}
		'''.parse;

		nameDuplicate.assertError(XU_CONNECTOR_END, NOT_UNIQUE_CONNECTOR_END, 145, 1);
		nameDuplicate.assertError(XU_CONNECTOR_END, NOT_UNIQUE_CONNECTOR_END, 161, 1);

		val roleDuplicate = '''
			package test.model;
			class A { port P {} }
			class B { port P {} }
			composition CAB {
				container A a;
				B b;
			}
			
			delegation DAB {
				CAB.a->A.P a;
				CAB.a->A.P b;
			}
		'''.parse;

		roleDuplicate.assertError(XU_CONNECTOR_END, NOT_UNIQUE_CONNECTOR_END, 145, 1);
		roleDuplicate.assertError(XU_CONNECTOR_END, NOT_UNIQUE_CONNECTOR_END, 161, 1);

		val nameAndRoleDuplicate = '''
			package test.model;
			class A { port P {} }
			class B { port P {} }
			composition CAB {
				container A a;
				B b;
			}
			
			delegation DAB {
				CAB.a->A.P a;
				CAB.a->A.P a;
			}
		'''.parse;

		nameAndRoleDuplicate.assertError(XU_CONNECTOR_END, NOT_UNIQUE_CONNECTOR_END, 145, 1);
		nameAndRoleDuplicate.assertError(XU_CONNECTOR_END, NOT_UNIQUE_CONNECTOR_END, 161, 1);
	}

}
