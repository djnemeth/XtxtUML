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
class XtxtUMLConnectorValidatorTest {

	@Inject extension ParseHelper<XUFile>
	@Inject extension ValidationTestHelper

	@Test
	def checkConnectorHasExactlyTwoEnds() {
		'''
			package test.model;
			connector AC {
				r->p e1;
				r->p e2;
			}
			delegation DC {
				r->p e1;
				r->p e2;
			}
		'''.parse.assertNoError(CONNECTOR_END_COUNT_MISMATCH);

		val file = '''
			package test.model;
			connector C1 {}
			connector C2 {
				r->p e1;
			}
			connector C3 {
				r->p e1;
				r->p e2;
				r->p e3;
			}
		'''.parse;

		file.assertError(XU_CONNECTOR, CONNECTOR_END_COUNT_MISMATCH, 31, 2);
		file.assertError(XU_CONNECTOR, CONNECTOR_END_COUNT_MISMATCH, 48, 2);
		file.assertError(XU_CONNECTOR, CONNECTOR_END_COUNT_MISMATCH, 78, 2);
	}

	@Test
	def checkContainerEndIsAllowedAndNeededOnlyInDelegation() {
		val ok = '''
			package test.model;
			composition C {
				container A a;
				B b;
			}
			delegation DC {
				C.a->A.P e1;
				C.b->B.P e2;
			}
		'''.parse;

		ok.assertNoError(CONTAINER_ROLE_COUNT_MISMATCH);
		ok.assertNoError(CONTAINER_ROLE_IN_ASSSEMBLY_CONNECTOR);

		val invalid = '''
			package test.model;
			composition C {
				container A a;
				B b;
			}
			connector AC {
				C.a->A.P e1;
				C.b->B.P e2;
			}
			delegation DC1 {
				C.b->B.P e1;
				C.b->B.P e2;
			}
			delegation DC2 {
				C.a->A.P e1;
				C.a->A.P e2;
			}
		'''.parse;

		invalid.assertError(XU_CONNECTOR_END, CONTAINER_ROLE_IN_ASSSEMBLY_CONNECTOR, 82, 3);
		invalid.assertError(XU_CONNECTOR, CONTAINER_ROLE_COUNT_MISMATCH, 125, 3);
		invalid.assertError(XU_CONNECTOR, CONTAINER_ROLE_COUNT_MISMATCH, 176, 3);
	}

	@Test
	def checkCompositionsBehindConnectorEnds() {
		'''
			package test.model;
			class A { port P {} }
			class B { port P {} }
			class C { port P {} }
			composition CA {
				container C c;
				A a;
			}
			composition CB {
				container C c;
				B b;
			}
			connector AC {
				CA.a->A.P e1;
				CB.b->B.P e2;
			}
			delegation DC {
				CA.c->C.P e1;
				CA.a->A.P e2;
			}
		'''.parse.assertNoErrors;

		val file = '''
			package test.model;
			class A { port P {} }
			class B { port P {} }
			class C { port P {} }
			class D;
			composition CA {
				container C c;
				A a;
			}
			composition CB {
				container C c;
				B b;
			}
			composition DB {
				container D d;
				B b;
			}
			connector AC {
				CA.a->A.P e1;
				DB.b->B.P e2;
			}
			delegation DC {
				CB.c->C.P e1;
				DB.b->B.P e2;
			}
		'''.parse;

		file.assertError(XU_CONNECTOR, COMPOSITION_MISMATCH_IN_ASSEMBLY_CONNECTOR, 245, 2);
		file.assertError(XU_CONNECTOR, COMPOSITION_MISMATCH_IN_DELEGATION_CONNECTOR, 297, 2);
	}

	@Test
	def checkConnectorEndPortCompatibility() {
		'''
			package test.model;
			
			interface I1 {}
			interface I2 {}
			interface I3 {}
			
			class A {
			    port AP1 {
			        provided I1;
			        required I2;
			    }
			
			    port AP2 {
			        provided I3;
			    }
			}
			
			class B {
			    port BP {
			        provided I2;
			        required I1;
			    }
			}
			
			class C {
			    port CP {
			        provided I3;
			    }
			}
			
			composition CA {
			    container C c;
			    A a;
			}
			
			composition CB {
			    container C c;
			    B b;
			}
			
			connector A_AB {
			    CA.a->A.AP1 aap;
			    CB.b->B.BP abp;
			}
			
			delegation D_CA {
			    CA.c->C.CP dcp;
			    CA.a->A.AP2 dap;
			}
		'''.parse.assertNoErrors;

		val file = '''
			package test.model;
			
			interface I1 {}
			interface I2 {}
			interface I3 {}
			
			class A {
			    port AP1 {
			        provided I1;
			        required I2;
			    }
			
			    port AP2 {
			        provided I3;
			    }
			}
			
			class B {
			    port BP {
			        provided I1;
			        required I2;
			    }
			}
			
			class C {
			    port CP {
			        required I3;
			    }
			}
			
			composition CA {
			    container C c;
			    A a;
			}
			
			composition CB {
			    container C c;
			    B b;
			}
			
			connector A_AB {
			    CA.a->A.AP1 aap;
			    CB.b->B.BP abp;
			}
			
			delegation D_CA {
			    CA.c->C.CP dcp;
			    CA.a->A.AP2 dap;
			}
		'''.parse;

		file.assertError(XU_CONNECTOR, INCOMPATIBLE_PORTS, 464, 4);
		file.assertError(XU_CONNECTOR, INCOMPATIBLE_PORTS, 531, 4);
	}

	@Test
	def checkOwnerOfConnectorEndPort() {
		'''
			package test.model;
			class A { port P {} }
			class B { port P {} }
			composition C {
				container A a;
				B b;
			}
			delegation DC {
				C.a->A.P e1;
				C.b->B.P e2;
			}
		'''.parse.assertNoErrors;

		val file = '''
			package test.model;
			class A { port P {} }
			class B { port P {} }
			composition C {
				container A a;
				B b;
			}
			delegation DC {
				C.a->B.P e1;
				C.b->A.P e2;
			}
		'''.parse;

		file.assertError(XU_CONNECTOR_END, NOT_OWNED_PORT, 134, 3);
		file.assertError(XU_CONNECTOR_END, NOT_OWNED_PORT, 149, 3);
	}

}
