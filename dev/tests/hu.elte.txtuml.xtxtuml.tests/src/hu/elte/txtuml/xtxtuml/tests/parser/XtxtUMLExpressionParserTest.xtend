package hu.elte.txtuml.xtxtuml.tests.parser;

import com.google.inject.Inject
import hu.elte.txtuml.xtxtuml.XtxtUMLInjectorProvider
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociationEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClass
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClassPropertyAccessExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUFile
import hu.elte.txtuml.xtxtuml.xtxtUML.XULogExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUOperation
import hu.elte.txtuml.xtxtuml.xtxtUML.XUPort
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSendSignalExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignalAccessExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUStartObjectExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransition
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionEffect
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionTrigger
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionVertex
import org.eclipse.xtext.common.types.JvmParameterizedTypeReference
import org.eclipse.xtext.junit4.InjectWith
import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.junit4.util.ParseHelper
import org.eclipse.xtext.xbase.XBlockExpression
import org.eclipse.xtext.xbase.XConstructorCall
import org.eclipse.xtext.xbase.XFeatureCall
import org.eclipse.xtext.xbase.XMemberFeatureCall
import org.eclipse.xtext.xbase.XStringLiteral
import org.eclipse.xtext.xbase.XVariableDeclaration
import org.junit.Test
import org.junit.runner.RunWith

import static org.junit.Assert.*

@RunWith(XtextRunner)
@InjectWith(XtxtUMLInjectorProvider)
class XtxtUMLExpressionParserTest {

	@Inject extension ParseHelper<XUFile>;

	@Test
	def parseSendSignalExpression() {
		val file = '''
			package test.model;
			signal TestSignal;
			class TestClass {
				void testOperation() {
					send new TestSignal() to this;
					send new TestSignal() to new TestClass();
			
					TestSignal sig = new TestSignal();
					send sig to this->(TestPort);
				}
			
				port TestPort {}
			}
		'''.parse;

		assertEquals(2, file.elements.size);
		assertTrue(file.elements.get(1) instanceof XUClass);

		val class = file.elements.get(1) as XUClass;
		assertEquals(2, class.members.size);
		assertTrue(class.members.head instanceof XUOperation);

		val op = class.members.head as XUOperation;
		assertTrue(op.body instanceof XBlockExpression);

		val body = op.body as XBlockExpression;
		assertEquals(4, body.expressions.size);
		assertTrue(body.expressions.head instanceof XUSendSignalExpression);
		assertTrue(body.expressions.get(1) instanceof XUSendSignalExpression);
		assertTrue(body.expressions.get(2) instanceof XVariableDeclaration);
		assertTrue(body.expressions.get(3) instanceof XUSendSignalExpression);

		val sendSignalExpr1 = body.expressions.head as XUSendSignalExpression;
		assertTrue(sendSignalExpr1.signal instanceof XConstructorCall);
		assertTrue(sendSignalExpr1.target instanceof XFeatureCall);

		val sendSignalExpr2 = body.expressions.get(1) as XUSendSignalExpression;
		assertTrue(sendSignalExpr2.signal instanceof XConstructorCall);
		assertTrue(sendSignalExpr2.target instanceof XConstructorCall);

		val sendSignalExpr3 = body.expressions.get(3) as XUSendSignalExpression;
		assertTrue(sendSignalExpr3.signal instanceof XFeatureCall);
		assertTrue(sendSignalExpr3.target instanceof XUClassPropertyAccessExpression);
	}

	@Test
	def parseStartObjectExpression() {
		val file = '''
			package test.model;
			class TestClass {
				void testOperation() {
					start this;
					start new TestClass();
			
					TestSignal obj = new TestClass();
					start obj;
				}
			}
		'''.parse;

		assertEquals(1, file.elements.size);
		assertTrue(file.elements.head instanceof XUClass);

		val class = file.elements.head as XUClass;
		assertEquals(1, class.members.size);
		assertTrue(class.members.head instanceof XUOperation);

		val op = class.members.head as XUOperation;
		assertTrue(op.body instanceof XBlockExpression);

		val body = op.body as XBlockExpression;
		assertEquals(4, body.expressions.size);
		assertTrue(body.expressions.head instanceof XUStartObjectExpression);
		assertTrue(body.expressions.get(1) instanceof XUStartObjectExpression);
		assertTrue(body.expressions.get(2) instanceof XVariableDeclaration);
		assertTrue(body.expressions.get(3) instanceof XUStartObjectExpression);

		val startExpr1 = body.expressions.head as XUStartObjectExpression;
		assertTrue(startExpr1.object instanceof XFeatureCall);

		val startExpr2 = body.expressions.get(1) as XUStartObjectExpression;
		assertTrue(startExpr2.object instanceof XConstructorCall);

		val startExpr3 = body.expressions.get(3) as XUStartObjectExpression;
		assertTrue(startExpr3.object instanceof XFeatureCall);
	}

	@Test
	def parseLogExpression() {
		val file = '''
			package test.model;
			class TestClass {
				void testOperation() {
					log "test";
			
					String test = "test";
					log test;
				}
			}
		'''.parse;

		assertEquals(1, file.elements.size);
		assertTrue(file.elements.head instanceof XUClass);

		val class = file.elements.head as XUClass;
		assertEquals(1, class.members.size);
		assertTrue(class.members.head instanceof XUOperation);

		val op = class.members.head as XUOperation;
		assertTrue(op.body instanceof XBlockExpression);

		val body = op.body as XBlockExpression;
		assertEquals(3, body.expressions.size);
		assertTrue(body.expressions.head instanceof XULogExpression);
		assertTrue(body.expressions.get(1) instanceof XVariableDeclaration);
		assertTrue(body.expressions.get(2) instanceof XULogExpression);

		val logExpr1 = body.expressions.head as XULogExpression;
		assertTrue(logExpr1.message instanceof XStringLiteral);

		val logExpr2 = body.expressions.get(2) as XULogExpression;
		assertTrue(logExpr2.message instanceof XFeatureCall);
	}

	@Test
	def parseSignalAccessExpression() {
		val file = '''
			package test.model;
			signal TestSignal {
				public String message;
			}
			class TestClass {
				state TestState;
				transition TestTransition {
					from TestState;
					to TestState;
					trigger TestSignal;
					effect {
						log trigger.message
					}
				}
			}
		'''.parse;

		assertEquals(2, file.elements.size);
		assertTrue(file.elements.get(1) instanceof XUClass);

		val class = file.elements.get(1) as XUClass;
		assertEquals(2, class.members.size);
		assertTrue(class.members.get(1) instanceof XUTransition);

		val transition = class.members.get(1) as XUTransition;
		assertEquals("TestTransition", transition.name);
		assertEquals(4, transition.members.size);
		assertTrue(transition.members.head instanceof XUTransitionVertex)
		assertTrue(transition.members.get(1) instanceof XUTransitionVertex)
		assertTrue(transition.members.get(2) instanceof XUTransitionTrigger)
		assertTrue(transition.members.get(3) instanceof XUTransitionEffect);

		val effect = transition.members.get(3) as XUTransitionEffect;
		assertTrue(effect.body instanceof XBlockExpression);

		val block = effect.body as XBlockExpression;
		assertEquals(1, block.expressions.size);
		assertTrue(block.expressions.head instanceof XULogExpression);

		val log = block.expressions.head as XULogExpression;
		assertTrue(log.message instanceof XMemberFeatureCall);

		val featureCall = log.message as XMemberFeatureCall;
		assertTrue(featureCall.memberCallTarget instanceof XUSignalAccessExpression);
		assertEquals("message", featureCall.feature.simpleName);
	}

	@Test
	def parseVariableDeclaration() {
		val file = '''
			package test.model;
			
			import hu.elte.txtuml.api.model.Collection;
			
			class TestClass {
				void testOperation() {
					int a;
					String b = "test";
					Collection<TestClass> c;
					Collection<TestClass> d = new Collection<TestClass>();
				}
			}
		'''.parse;

		assertEquals(1, file.elements.size);
		assertTrue(file.elements.head instanceof XUClass);

		val class = file.elements.head as XUClass;
		assertEquals(1, class.members.size);
		assertTrue(class.members.head instanceof XUOperation);

		val op = class.members.head as XUOperation;
		assertTrue(op.body instanceof XBlockExpression);

		val body = op.body as XBlockExpression;
		assertEquals(4, body.expressions.size);
		assertTrue(body.expressions.forall[it instanceof XVariableDeclaration]);
		assertTrue(body.expressions.forall[(it as XVariableDeclaration).writeable]);

		val a = body.expressions.head as XVariableDeclaration;
		assertEquals("a", a.name);
		assertEquals("int", a.type.qualifiedName);
		assertNull(a.right);

		val b = body.expressions.get(1) as XVariableDeclaration;
		assertEquals("b", b.name);
		assertEquals("java.lang.String", b.type.qualifiedName);
		assertTrue(b.right instanceof XStringLiteral);
		assertEquals("test", (b.right as XStringLiteral).value);

		val c = body.expressions.get(2) as XVariableDeclaration;
		assertEquals("c", c.name);
		assertTrue(c.type instanceof JvmParameterizedTypeReference);

		val cType = c.type as JvmParameterizedTypeReference;
		assertEquals("hu.elte.txtuml.api.model.Collection", cType.type.qualifiedName);
		assertEquals(1, cType.arguments.size);
		assertEquals("test.model.TestClass", cType.arguments.head.qualifiedName);

		val d = body.expressions.get(3) as XVariableDeclaration;
		assertEquals("d", d.name);
		assertTrue(d.type instanceof JvmParameterizedTypeReference);
		assertTrue(d.right instanceof XConstructorCall);

		val dType = d.type as JvmParameterizedTypeReference;
		assertEquals("hu.elte.txtuml.api.model.Collection", dType.type.qualifiedName);
		assertEquals(1, dType.arguments.size);
		assertEquals("test.model.TestClass", dType.arguments.head.qualifiedName);
	}

	@Test
	def parseClassPropertyAccessExpression() {
		val file = '''
			package test.model;
			
			class A {
				void foo() {
					send new S() to this->(P);
					send new S() to this->(AB.b).selectAny();
					new B()->(AB.a).selectAny();
				}
				
				port P {}
			}
			
			signal S;
			class B;
			association AB {
				A a;
				B b;
			}
		'''.parse;

		assertEquals(4, file.elements.size);
		assertTrue(file.elements.head instanceof XUClass);

		val class = file.elements.head as XUClass;
		assertEquals(2, class.members.size);
		assertTrue(class.members.head instanceof XUOperation);

		val op = class.members.head as XUOperation;
		assertTrue(op.body instanceof XBlockExpression);

		val block = op.body as XBlockExpression;
		assertEquals(3, block.expressions.size);
		assertTrue(block.expressions.head instanceof XUSendSignalExpression);
		assertTrue(block.expressions.get(1) instanceof XUSendSignalExpression);
		assertTrue(block.expressions.get(2) instanceof XMemberFeatureCall);

		val sendExpr1 = block.expressions.head as XUSendSignalExpression;
		assertTrue(sendExpr1.target instanceof XUClassPropertyAccessExpression);

		val accessExpr1 = sendExpr1.target as XUClassPropertyAccessExpression;
		assertEquals("P", accessExpr1.right.name);
		assertTrue(accessExpr1.right instanceof XUPort);

		val sendExpr2 = block.expressions.get(1) as XUSendSignalExpression;
		assertTrue(sendExpr2.target instanceof XMemberFeatureCall);

		val featureCall1 = sendExpr2.target as XMemberFeatureCall;
		assertEquals("hu.elte.txtuml.api.model.Collection.selectAny()", featureCall1.feature.identifier);
		assertTrue(featureCall1.memberCallTarget instanceof XUClassPropertyAccessExpression);

		val accessExpr2 = featureCall1.memberCallTarget as XUClassPropertyAccessExpression;
		assertEquals("b", accessExpr2.right.name);
		assertTrue(accessExpr2.right instanceof XUAssociationEnd);

		val featureCall2 = block.expressions.get(2) as XMemberFeatureCall;
		assertEquals("hu.elte.txtuml.api.model.Collection.selectAny()", featureCall2.feature.identifier);
		assertTrue(featureCall2.memberCallTarget instanceof XUClassPropertyAccessExpression);

		val accessExpr3 = featureCall2.memberCallTarget as XUClassPropertyAccessExpression;
		assertEquals("a", accessExpr3.right.name);
		assertTrue(accessExpr3.right instanceof XUAssociationEnd);
	}

}
