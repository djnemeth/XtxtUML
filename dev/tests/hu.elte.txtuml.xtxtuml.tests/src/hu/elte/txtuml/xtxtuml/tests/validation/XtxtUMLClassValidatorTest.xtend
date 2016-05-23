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
class XtxtUMLClassValidatorTest {

	@Inject extension ParseHelper<XUFile>;
	@Inject extension ValidationTestHelper;

	@Test
	def checkNoCycleInClassHiearchy() {
		'''
			package test.model;
			class A;
			class B extends A;
			class C extends B;
			class D extends B;
			class E extends C;
		'''.parse.assertNoErrors;

		val file = '''
			package test.model;
			class A extends A;
			class B extends C;
			class C extends D;
			class D extends B;
			class E extends D;
			class F extends E;
		'''.parse;

		file.assertError(XU_CLASS, CLASS_HIERARCHY_CYCLE, 37, 1);
		file.assertError(XU_CLASS, CLASS_HIERARCHY_CYCLE, 57, 1);
		file.assertError(XU_CLASS, CLASS_HIERARCHY_CYCLE, 77, 1);
		file.assertError(XU_CLASS, CLASS_HIERARCHY_CYCLE, 97, 1);
		file.assertError(XU_CLASS, CLASS_HIERARCHY_CYCLE, 117, 1);
		file.assertError(XU_CLASS, CLASS_HIERARCHY_CYCLE, 137, 1);
	}

	@Test
	def checkConstructorName() {
		'''
			package test.model;
			class A {
				A() {}
			}
		'''.parse.assertNoErrors;

		'''
			package test.model;
			class A {
				a() {}
			}
		'''.parse.assertError(XU_CONSTRUCTOR, INVALID_CONSTRUCTOR_NAME, 33, 1);
	}

	@Test
	def checkInitialStateIsDefined() {
		val noWarningFile = '''
			package test.model;
			class A;
			class B {
				initial Init;
				composite CS;
			}
		'''.parse;

		noWarningFile.assertNoWarnings(XU_CLASS, MISSING_INITIAL_STATE);
		noWarningFile.assertNoWarnings(XU_STATE, MISSING_INITIAL_STATE);

		val file = '''
			package test.model;
			class A {
				composite CS {
					state S;
				}
			}
		'''.parse;

		file.assertWarning(XU_CLASS, MISSING_INITIAL_STATE, 27, 1);
		file.assertWarning(XU_STATE, MISSING_INITIAL_STATE, 43, 2);
	}

	@Test
	def checkPseudostateIsLeavable() {
		'''
			package test.model;
			class A {
				initial Init;
				choice C;
				state S;
				transition T1 {
					from Init;
					to C;
				}
				transition T2 {
					from C;
					to S;
				}
			}
		'''.parse.assertNoError(NOT_LEAVABLE_PSEUDOSTATE);

		val file = '''
			package test.model;
			class A {
				initial Init;
				choice C;
			}
		'''.parse;

		file.assertError(XU_STATE, NOT_LEAVABLE_PSEUDOSTATE, 41, 4);
		file.assertError(XU_STATE, NOT_LEAVABLE_PSEUDOSTATE, 56, 1);
	}

	@Test
	def checkStateIsReachable() {
		'''
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
					from S1;
					to S2;
				}
			}
		'''.parse.assertNoWarnings(XU_STATE, UNREACHABLE_STATE);

		val file = '''
			package test.model;
			class A {
				initial Init;
				state S1;
				state S2;
			}
		'''.parse;

		file.assertWarning(XU_STATE, UNREACHABLE_STATE, 55, 2);
		file.assertWarning(XU_STATE, UNREACHABLE_STATE, 67, 2);
	}

	@Test
	def checkStateOrTransitionIsDefinedInClassOrCompositeState() {
		'''
			package test.model;
			class A {
				composite CS {
					state S;
					transition T2 {
						from S;
						to S;
					}
				}
				transition T1 {
					from CS;
					to CS;
				}
			}
		'''.parse.assertNoError(STATE_OR_TRANSITION_IN_NOT_COMPOSITE_STATE);

		val file = '''
			package test.model;
			class A {
				state CS {
					state S;
					transition T2 {
						from S;
						to S;
					}
				}
			}
		'''.parse;

		file.assertError(XU_STATE, STATE_OR_TRANSITION_IN_NOT_COMPOSITE_STATE, 53, 1);
		file.assertError(XU_TRANSITION, STATE_OR_TRANSITION_IN_NOT_COMPOSITE_STATE, 70, 2);
	}

	@Test
	def checkNoActivityInPseudostate() {
		'''
			package test.model;
			class A {
				state S {
					entry {}
					exit {}
				}
				composite CS {
					entry {}
					exit {}
				}
			}
		'''.parse.assertNoError(ACTIVITY_IN_PSEUDOSTATE);

		val file = '''
			package test.model;
			class A {
				initial Init {
					entry {}
					exit {}
				}
				choice C {
					entry {}
					exit {}
				}
			}
		'''.parse;

		file.assertError(XU_ENTRY_OR_EXIT_ACTIVITY, ACTIVITY_IN_PSEUDOSTATE, 51, 5);
		file.assertError(XU_ENTRY_OR_EXIT_ACTIVITY, ACTIVITY_IN_PSEUDOSTATE, 63, 4);
		file.assertError(XU_ENTRY_OR_EXIT_ACTIVITY, ACTIVITY_IN_PSEUDOSTATE, 91, 5);
		file.assertError(XU_ENTRY_OR_EXIT_ACTIVITY, ACTIVITY_IN_PSEUDOSTATE, 103, 4);
	}

	@Test
	def checkMandatoryTransitionMembers() {
		'''
			package test.model;
			signal Sig;
			class A {
				initial Init;
				state St;
				choice C;
				transition T1 {
					from Init;
					to St;
				}
				transition T2 {
					from C;
					to St;
				}
				transition T3 {
					from St;
					to C;
					trigger Sig;
				}
			}
		'''.parse.assertNoErrors;

		val file = '''
			package test.model;
			signal Sig;
			class A {
				state St;
				transition T1 {
					to St;
					trigger Sig;
				}
				transition T2 {
					from St;
					trigger Sig;
				}
				transition T3 {
					from St;
					to St;
				}
			}
		'''.parse;

		file.assertError(XU_TRANSITION, MISSING_MANDATORY_TRANSITION_MEMBER, 69, 2);
		file.assertError(XU_TRANSITION, MISSING_MANDATORY_TRANSITION_MEMBER, 117, 2);
		file.assertError(XU_TRANSITION, MISSING_MANDATORY_TRANSITION_MEMBER, 167, 2);
	}

	@Test
	def checkTransitionTargetIsNotInitialState() {
		'''
			package test.model;
			class A {
				state S;
				transition T {
					to S;
				}
			}
		'''.parse.assertNoError(TARGET_IS_INITIAL_STATE);

		'''
			package test.model;
			class A {
				initial Init;
				transition T {
					to Init;
				}
			}
		'''.parse.assertError(XU_TRANSITION_VERTEX, TARGET_IS_INITIAL_STATE, 70, 4);
	}

	@Test
	def checkGuardIsNotForInitialTransition() {
		'''
			package test.model;
			class A {
				state S;
				transition T {
					from S;
					to S;
					guard ( true );
				}
			}
		'''.parse.assertNoError(INVALID_TRANSITION_MEMBER);

		'''
			package test.model;
			class A {
				initial Init;
				transition T {
					from Init;
					guard ( true );
				}
			}
		'''.parse.assertError(XU_TRANSITION_GUARD, INVALID_TRANSITION_MEMBER, 81, 5);
	}

	@Test
	def checkMemberOfTransitionFromPseudostate() {
		'''
			package test.model;
			signal Sig;
			class A {
				behavior port P {}
				state St;
				composite CS;
				transition T1 {
					from St;
					trigger Sig;
					port P;
				}
				transition T2 {
					from CS;
					trigger Sig;
					port P;
				}
			}
		'''.parse.assertNoError(INVALID_TRANSITION_MEMBER);

		val file = '''
			package test.model;
			signal Sig;
			class A {
				behavior port P {}
				initial Init;
				choice C;
				transition T1 {
					from Init;
					trigger Sig;
					port P;
				}
				transition T2 {
					from C;
					trigger Sig;
					port P;
				}
			}
		'''.parse;

		file.assertError(XU_TRANSITION_TRIGGER, INVALID_TRANSITION_MEMBER, 128, 7)
		file.assertError(XU_TRANSITION_PORT, INVALID_TRANSITION_MEMBER, 144, 4)
		file.assertError(XU_TRANSITION_TRIGGER, INVALID_TRANSITION_MEMBER, 188, 7)
		file.assertError(XU_TRANSITION_PORT, INVALID_TRANSITION_MEMBER, 204, 4);
	}

	@Test
	def checkElseGuard() {
		'''
			package test.model;
			class A {
				choice C;
				transition T1 {
					from C;
					guard ( false );
				}
				transition T2 {
					from C;
					guard ( else );
				}
			}
		'''.parse.assertNoError(INVALID_ELSE_GUARD);

		'''
			package test.model;
			class A {
				state S;
				transition T {
					from S;
					guard ( else );
				}
			}
		'''.parse.assertError(XU_TRANSITION_GUARD, INVALID_ELSE_GUARD, 81, 4);
	}

	@Test
	def checkOwnerOfTriggerPort() {
		'''
			package test.model;
			class A {
				behavior port P {}
				transition T {
					port P;
				}
				composite CS {
					transition T {
						port P;
					}
				}
			}
			class B {
				behavior port P {}
				transition T {
					port P;
				}
			}
		'''.parse.assertNoError(NOT_OWNED_TRIGGER_PORT);

		val file = '''
			package test.model;
			class A {
				behavior port P {}
				transition T {
					port B.P;
				}
			}
			class B {
				behavior port P {}
				transition T {
					port A.P;
				}
			}
		'''.parse;

		file.assertError(XU_TRANSITION_PORT, NOT_OWNED_TRIGGER_PORT, 77, 3);
		file.assertError(XU_TRANSITION_PORT, NOT_OWNED_TRIGGER_PORT, 146, 3);
	}

	@Test
	def checkTriggerPortIsBehavior() {
		'''
			package test.model;
			class A {
				behavior port P {}
				transition T {
					port P;
				}
			}
		'''.parse.assertNoError(NOT_BEHAVIOR_TRIGGER_PORT);

		'''
			package test.model;
			class A {
				port P {}
				transition T {
					port P;
				}
			}
		'''.parse.assertError(XU_TRANSITION_PORT, NOT_BEHAVIOR_TRIGGER_PORT, 68, 1);
	}

	@Test
	def checkTransitionVertexLevel() {
		'''
			package test.model;
			class A {
				composite CS {
					state S;
					transition T2 {
						from S;
						to S;
					}
				}
				transition T1 {
					from CS;
					to CS;
				}
			}
		'''.parse.assertNoError(VERTEX_LEVEL_MISMATCH);

		val file = '''
			package test.model;
			class A {
				composite CS {
					state S;
					transition T2 {
						from CS;
						to CS;
					}
					transition T3 {
						from S;
						to CS;
					}
				}
				transition T1 {
					from CS.S;
					to CS;
				}
				transition T4 {
					from CS;
					to B.S;
				}
			}
			class B {
				state S;
			}
		'''.parse;

		file.assertError(XU_TRANSITION_VERTEX, VERTEX_LEVEL_MISMATCH, 88, 2);
		file.assertError(XU_TRANSITION_VERTEX, VERTEX_LEVEL_MISMATCH, 99, 2);
		file.assertError(XU_TRANSITION_VERTEX, VERTEX_LEVEL_MISMATCH, 146, 2);
		file.assertError(XU_TRANSITION_VERTEX, VERTEX_LEVEL_MISMATCH, 185, 4);
		file.assertError(XU_TRANSITION_VERTEX, VERTEX_LEVEL_MISMATCH, 241, 3);
	}

}
