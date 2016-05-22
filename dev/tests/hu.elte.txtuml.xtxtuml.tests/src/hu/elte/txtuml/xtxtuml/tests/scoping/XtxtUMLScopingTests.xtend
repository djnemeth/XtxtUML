package hu.elte.txtuml.xtxtuml.tests.scoping;

import com.google.inject.Inject
import hu.elte.txtuml.xtxtuml.XtxtUMLInjectorProvider
import hu.elte.txtuml.xtxtuml.xtxtUML.XUExecution
import hu.elte.txtuml.xtxtuml.xtxtUML.XUFile
import org.eclipse.xtext.junit4.InjectWith
import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.junit4.util.ParseHelper
import org.eclipse.xtext.junit4.validation.ValidationTestHelper
import org.eclipse.xtext.xbase.XAbstractFeatureCall
import org.eclipse.xtext.xbase.XBlockExpression
import org.junit.Test
import org.junit.runner.RunWith

import static org.junit.Assert.*

@RunWith(XtextRunner)
@InjectWith(XtxtUMLInjectorProvider)
class XtxtUMLScopingTests {

	@Inject extension ParseHelper<XUFile>;
	@Inject extension ValidationTestHelper;

	@Test
	def resolveJtxtUMLActionMethods() {
		val file = '''
			package test.model;
			
			execution E {
				A a = new A();
				B b = new B();
			
				^log("message");
				^start(a);
				^start(b);
			
				link(CAB.a, a, CAB.b, b);
				connect(a->(A.P), DAB.bp, b->(B.P));
				unlink(CAB.a, a, CAB.b, b);
			
				^delete(a);
				^delete(b);
			}
			
			signal S;
			interface I { reception S; }
			
			class A {
				port P {
					required I;
				}
			}
			
			class B {
				port P {
					required I;
				}
			}
			
			composition CAB {
				container A a;
				B b;
			}
			
			delegation DAB {
				CAB.a->A.P ap;
				CAB.b->B.P bp;
			}
		'''.parse;

		file.assertNoErrors;
		assertEquals(7, file.elements.size);
		assertTrue(file.elements.head instanceof XUExecution);

		val exec = file.elements.head as XUExecution;
		assertTrue(exec.body instanceof XBlockExpression);

		val block = exec.body as XBlockExpression;
		assertEquals(10, block.expressions.size);
		assertTrue(block.expressions.drop(2).forall [
			it instanceof XAbstractFeatureCall &&
				(it as XAbstractFeatureCall).feature.identifier.startsWith("hu.elte.txtuml.api.model.Action")
		]);
	}

}
