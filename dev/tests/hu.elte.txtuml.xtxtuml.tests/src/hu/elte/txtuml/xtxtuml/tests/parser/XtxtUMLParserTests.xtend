package hu.elte.txtuml.xtxtuml.tests.parser;

import com.google.inject.Inject
import hu.elte.txtuml.xtxtuml.XtxtUMLInjectorProvider
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociation
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAssociationEnd
import hu.elte.txtuml.xtxtuml.xtxtUML.XUAttribute
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClass
import hu.elte.txtuml.xtxtuml.xtxtUML.XUClassPropertyAccessExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUComposition
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConnector
import hu.elte.txtuml.xtxtuml.xtxtUML.XUConstructor
import hu.elte.txtuml.xtxtuml.xtxtUML.XUEntryOrExitActivity
import hu.elte.txtuml.xtxtuml.xtxtUML.XUExecution
import hu.elte.txtuml.xtxtuml.xtxtUML.XUFile
import hu.elte.txtuml.xtxtuml.xtxtUML.XUInterface
import hu.elte.txtuml.xtxtuml.xtxtUML.XULogExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUModelDeclaration
import hu.elte.txtuml.xtxtuml.xtxtUML.XUOperation
import hu.elte.txtuml.xtxtuml.xtxtUML.XUPort
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSendSignalExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignal
import hu.elte.txtuml.xtxtuml.xtxtUML.XUSignalAccessExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUStartObjectExpression
import hu.elte.txtuml.xtxtuml.xtxtUML.XUState
import hu.elte.txtuml.xtxtuml.xtxtUML.XUStateType
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransition
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionEffect
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionGuard
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionPort
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionTrigger
import hu.elte.txtuml.xtxtuml.xtxtUML.XUTransitionVertex
import hu.elte.txtuml.xtxtuml.xtxtUML.XUVisibility
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
class XtxtUMLParserTests {

	@Inject extension ParseHelper<XUFile>;

	@Test
	def parseFile() {
		val file = '''package test.model;'''.parse;
		assertEquals("test.model", file.name);
	}

	@Test
	def parseModelDeclarationWithoutName() {
		val file = '''model-package test.model;'''.parse;
		assertTrue(file instanceof XUModelDeclaration);

		val modelDeclaration = file as XUModelDeclaration;
		assertEquals("test.model", modelDeclaration.name);
		assertNull(modelDeclaration.modelName);
	}

	@Test
	def parseModelDeclarationWithName() {
		val file = '''model-package test.model as "TestModel";'''.parse;
		assertTrue(file instanceof XUModelDeclaration);

		val modelDeclaration = file as XUModelDeclaration;
		assertEquals("test.model", modelDeclaration.name);
		assertEquals("TestModel", modelDeclaration.modelName);
	}

	@Test
	def parseExecution() {
		val file = '''
			package test.model;
			execution TestExecution {}
		'''.parse;

		assertEquals(1, file.elements.size);
		assertTrue(file.elements.head instanceof XUExecution);
		assertEquals("TestExecution", (file.elements.head as XUExecution).name);
	}

	@Test
	def parseSignal() {
		val file = '''
			package test.model;
			signal EmptyTestSignal;
			signal NotEmptyTestSignal {
				public int testAttribute;
			}
		'''.parse;

		assertEquals(2, file.elements.size);
		assertTrue(file.elements.forall[it instanceof XUSignal]);

		val emptySignal = file.elements.head as XUSignal;
		assertEquals("EmptyTestSignal", emptySignal.name);
		assertTrue(emptySignal.attributes.empty);

		val notEmptySignal = file.elements.get(1) as XUSignal;
		assertEquals("NotEmptyTestSignal", notEmptySignal.name);
		assertEquals(1, notEmptySignal.attributes.size);

		val attribute = notEmptySignal.attributes.head;
		assertEquals(XUVisibility.PUBLIC, attribute.visibility);
		assertEquals("int", attribute.type.qualifiedName);
		assertEquals("testAttribute", attribute.name);
	}

	@Test
	def parseEmptyClass() {
		val file = '''
			package test.model;
			class BaseTestClass;
			class DerivedTestClass extends BaseTestClass;
		'''.parse;

		assertEquals(2, file.elements.size);
		assertTrue(file.elements.forall[it instanceof XUClass]);

		val base = file.elements.head as XUClass;
		assertEquals("BaseTestClass", base.name);
		assertNull(base.superClass);
		assertTrue(base.members.empty);

		val derived = file.elements.get(1) as XUClass;
		assertEquals("DerivedTestClass", derived.name);
		assertEquals("BaseTestClass", derived.superClass.name);
		assertTrue(derived.members.empty);
	}

	@Test
	def parseClassAttributeAndOperation() {
		val file = '''
			package test.model;
			class TestClass {
				int a1;
				protected int a2;
			
				public void o1() {}
			
				private int o2() {
					return 0;
				}
			
				package TestClass o3(int p) {
					return null;
				}
			
				public c(int p1, TestClass p2) {}
			}
		'''.parse;

		assertEquals(1, file.elements.size);
		assertTrue(file.elements.head instanceof XUClass);

		val class = file.elements.head as XUClass;
		assertEquals("TestClass", class.name);
		assertEquals(6, class.members.size);
		assertTrue(class.members.get(0) instanceof XUAttribute);
		assertTrue(class.members.get(1) instanceof XUAttribute);
		assertTrue(class.members.get(2) instanceof XUOperation);
		assertTrue(class.members.get(3) instanceof XUOperation);
		assertTrue(class.members.get(4) instanceof XUOperation);
		assertTrue(class.members.get(5) instanceof XUConstructor);

		val a1 = class.members.get(0) as XUAttribute;
		assertEquals("a1", a1.name);
		assertEquals(XUVisibility.PACKAGE, a1.prefix.visibility);
		assertEquals("int", a1.prefix.type.qualifiedName);

		val a2 = class.members.get(1) as XUAttribute;
		assertEquals("a2", a2.name);
		assertEquals(XUVisibility.PROTECTED, a2.prefix.visibility);
		assertEquals("int", a2.prefix.type.qualifiedName);

		val o1 = class.members.get(2) as XUOperation;
		assertEquals("o1", o1.name);
		assertEquals(XUVisibility.PUBLIC, o1.prefix.visibility);
		assertEquals("void", o1.prefix.type.qualifiedName);
		assertTrue(o1.parameters.empty);
		assertTrue((o1.body as XBlockExpression).expressions.empty);

		val o2 = class.members.get(3) as XUOperation;
		assertEquals("o2", o2.name);
		assertEquals(XUVisibility.PRIVATE, o2.prefix.visibility);
		assertEquals("int", o2.prefix.type.qualifiedName);
		assertTrue(o2.parameters.empty);
		assertEquals(1, (o2.body as XBlockExpression).expressions.size);

		val o3 = class.members.get(4) as XUOperation;
		assertEquals("o3", o3.name);
		assertEquals(XUVisibility.PACKAGE, o3.prefix.visibility);
		assertEquals("test.model.TestClass", o3.prefix.type.qualifiedName);
		assertEquals(1, (o3.body as XBlockExpression).expressions.size);
		assertEquals(1, o3.parameters.size);

		val p = o3.parameters.head;
		assertEquals("p", p.name);
		assertEquals("int", p.parameterType.qualifiedName);

		val c = class.members.get(5) as XUConstructor;
		assertEquals("c", c.name);
		assertEquals(XUVisibility.PUBLIC, c.visibility);
		assertTrue((c.body as XBlockExpression).expressions.empty);
		assertEquals(2, c.parameters.size);

		val p1 = c.parameters.head;
		assertEquals("p1", p1.name);
		assertEquals("int", p1.parameterType.qualifiedName);

		val p2 = c.parameters.get(1);
		assertEquals("p2", p2.name);
		assertEquals("test.model.TestClass", p2.parameterType.qualifiedName);
	}

	@Test
	def parseStatemachine() {
		val file = '''
			package test.model;
			signal Sig;
			class TestClass {
				port Port {}
			
				initial Init;
				choice Choice;
			
				transition T1 {
					from Init;
					to Choice;
					effect {}
				}
			
				transition T2 {
					from Choice;
					to Composite;
					guard ( else );
				}
			
				composite Composite {
					entry {}
					exit {}
			
					initial CInit;
					state State;
			
					transition T3 {
						from CInit;
						to State;
					}
			
					transition T4 {
						from State;
						to State;
						trigger Sig;
						port Port;
					}
				}
			}
		'''.parse;

		assertEquals(2, file.elements.size);
		assertTrue(file.elements.get(1) instanceof XUClass);

		val class = file.elements.get(1) as XUClass;
		assertEquals(6, class.members.size);
		assertTrue(class.members.head instanceof XUPort);
		assertTrue(class.members.get(1) instanceof XUState);
		assertTrue(class.members.get(2) instanceof XUState);
		assertTrue(class.members.get(3) instanceof XUTransition);
		assertTrue(class.members.get(4) instanceof XUTransition);
		assertTrue(class.members.get(5) instanceof XUState);

		val init = class.members.get(1) as XUState;
		assertEquals("Init", init.name);
		assertEquals(XUStateType.INITIAL, init.type);
		assertTrue(init.members.empty);

		val choice = class.members.get(2) as XUState;
		assertEquals("Choice", choice.name);
		assertEquals(XUStateType.CHOICE, choice.type);
		assertTrue(choice.members.empty);

		val t1 = class.members.get(3) as XUTransition;
		assertEquals("T1", t1.name);
		assertEquals(3, t1.members.size);
		assertTrue(t1.members.head instanceof XUTransitionVertex);
		assertTrue(t1.members.get(1) instanceof XUTransitionVertex);
		assertTrue(t1.members.get(2) instanceof XUTransitionEffect);

		val t1From = t1.members.head as XUTransitionVertex;
		assertTrue(t1From.from);
		assertEquals("Init", t1From.vertex.name);

		val t1To = t1.members.get(1) as XUTransitionVertex;
		assertFalse(t1To.from);
		assertEquals("Choice", t1To.vertex.name);

		val t1Effect = t1.members.get(2) as XUTransitionEffect;
		assertTrue((t1Effect.body as XBlockExpression).expressions.empty);

		val t2 = class.members.get(4) as XUTransition;
		assertEquals("T2", t2.name);
		assertEquals(3, t2.members.size);
		assertTrue(t2.members.head instanceof XUTransitionVertex);
		assertTrue(t2.members.get(1) instanceof XUTransitionVertex);
		assertTrue(t2.members.get(2) instanceof XUTransitionGuard);

		val t2From = t2.members.head as XUTransitionVertex;
		assertTrue(t2From.from);
		assertEquals("Choice", t2From.vertex.name);

		val t2To = t2.members.get(1) as XUTransitionVertex;
		assertFalse(t2To.from);
		assertEquals("Composite", t2To.vertex.name);

		val t2Guard = t2.members.get(2) as XUTransitionGuard;
		assertTrue(t2Guard.^else);

		val composite = class.members.get(5) as XUState;
		assertEquals("Composite", composite.name);
		assertEquals(XUStateType.COMPOSITE, composite.type);
		assertEquals(6, composite.members.size);
		assertTrue(composite.members.head instanceof XUEntryOrExitActivity);
		assertTrue(composite.members.get(1) instanceof XUEntryOrExitActivity);
		assertTrue(composite.members.get(2) instanceof XUState);
		assertTrue(composite.members.get(3) instanceof XUState);
		assertTrue(composite.members.get(4) instanceof XUTransition);
		assertTrue(composite.members.get(5) instanceof XUTransition);

		val entry = composite.members.head as XUEntryOrExitActivity;
		assertTrue(entry.entry);
		assertTrue((entry.body as XBlockExpression).expressions.empty);

		val exit = composite.members.get(1) as XUEntryOrExitActivity;
		assertFalse(exit.entry);
		assertTrue((exit.body as XBlockExpression).expressions.empty);

		val cInit = composite.members.get(2) as XUState;
		assertEquals("CInit", cInit.name);
		assertEquals(XUStateType.INITIAL, cInit.type);
		assertTrue(cInit.members.empty);

		val state = composite.members.get(3) as XUState;
		assertEquals("State", state.name);
		assertEquals(XUStateType.PLAIN, state.type);
		assertTrue(state.members.empty);

		val t3 = composite.members.get(4) as XUTransition;
		assertEquals("T3", t3.name);
		assertEquals(2, t3.members.size);
		assertTrue(t3.members.head instanceof XUTransitionVertex);
		assertTrue(t3.members.get(1) instanceof XUTransitionVertex);

		val t3From = t3.members.head as XUTransitionVertex;
		assertTrue(t3From.from);
		assertEquals("CInit", t3From.vertex.name);

		val t3To = t3.members.get(1) as XUTransitionVertex;
		assertFalse(t3To.from);
		assertEquals("State", t3To.vertex.name);

		val t4 = composite.members.get(5) as XUTransition;
		assertEquals("T4", t4.name);
		assertEquals(4, t4.members.size);
		assertTrue(t4.members.head instanceof XUTransitionVertex);
		assertTrue(t4.members.get(1) instanceof XUTransitionVertex);
		assertTrue(t4.members.get(2) instanceof XUTransitionTrigger);
		assertTrue(t4.members.get(3) instanceof XUTransitionPort);

		val t4From = t4.members.head as XUTransitionVertex;
		assertTrue(t4From.from);
		assertEquals("State", t4From.vertex.name);

		val t4To = t4.members.get(1) as XUTransitionVertex;
		assertFalse(t4To.from);
		assertEquals("State", t4To.vertex.name);

		val t4Trigger = t4.members.get(2) as XUTransitionTrigger;
		assertEquals("Sig", t4Trigger.trigger.name);

		val t4Port = t4.members.get(3) as XUTransitionPort;
		assertEquals("Port", t4Port.port.name);
	}

	@Test
	def parsePort() {
		val file = '''
			package test.model;
			interface TestInterface;
			class TestClass {
				port EmptyPort {}
				behavior port BehaviorPort {
					required TestInterface;
					provided TestInterface;
				}
			}
		'''.parse;

		assertEquals(2, file.elements.size);
		assertTrue(file.elements.head instanceof XUInterface);
		assertTrue(file.elements.get(1) instanceof XUClass);

		val class = file.elements.get(1) as XUClass;
		assertEquals("TestClass", class.name);
		assertEquals(2, class.members.size);
		assertTrue(class.members.forall[it instanceof XUPort]);

		val emptyPort = class.members.head as XUPort;
		assertEquals("EmptyPort", emptyPort.name);
		assertFalse(emptyPort.behavior);
		assertTrue(emptyPort.members.empty);

		val behaviorPort = class.members.get(1) as XUPort;
		assertEquals("BehaviorPort", behaviorPort.name);
		assertTrue(behaviorPort.behavior);
		assertEquals(2, behaviorPort.members.size);

		val required = behaviorPort.members.head;
		assertEquals("TestInterface", required.interface.name);
		assertTrue(required.required);

		val provided = behaviorPort.members.get(1);
		assertEquals("TestInterface", provided.interface.name);
		assertFalse(provided.required);
	}

	@Test
	def parseAssociation() {
		val file = '''
			package test.model;
			class TestClass;
			association TestAssociation1 {
				TestClass plainEnd;
				hidden * TestClass hiddenEnd;
			}
			association TestAssociation2 {
				hidden 1..* TestClass intervalEnd;
				5 TestClass exactEnd;
			}
		'''.parse;

		assertEquals(3, file.elements.size);
		assertTrue(file.elements.head instanceof XUClass);
		assertTrue(file.elements.get(1) instanceof XUAssociation);
		assertTrue(file.elements.get(2) instanceof XUAssociation);

		val assoc1 = file.elements.get(1) as XUAssociation;
		assertEquals("TestAssociation1", assoc1.name);
		assertEquals(2, assoc1.ends.size);
		assertTrue(assoc1.ends.forall[endClass.name == "TestClass"]);

		val plainEnd = assoc1.ends.head;
		assertEquals("plainEnd", plainEnd.name);
		assertFalse(plainEnd.notNavigable);
		assertNull(plainEnd.multiplicity);

		val hiddenEnd = assoc1.ends.get(1);
		assertEquals("hiddenEnd", hiddenEnd.name);
		assertTrue(hiddenEnd.notNavigable);
		assertFalse(hiddenEnd.multiplicity.upperSet);
		assertFalse(hiddenEnd.multiplicity.upperInf);
		assertTrue(hiddenEnd.multiplicity.any);

		val assoc2 = file.elements.get(2) as XUAssociation;
		assertEquals("TestAssociation2", assoc2.name);
		assertEquals(2, assoc2.ends.size);
		assertTrue(assoc2.ends.forall[endClass.name == "TestClass"]);

		val intervalEnd = assoc2.ends.head;
		assertEquals("intervalEnd", intervalEnd.name);
		assertTrue(intervalEnd.notNavigable);
		assertEquals(1, intervalEnd.multiplicity.lower);
		assertTrue(intervalEnd.multiplicity.upperSet);
		assertTrue(intervalEnd.multiplicity.upperInf);

		val exactEnd = assoc2.ends.get(1);
		assertEquals("exactEnd", exactEnd.name);
		assertFalse(exactEnd.notNavigable);
		assertEquals(5, exactEnd.multiplicity.lower);
		assertFalse(exactEnd.multiplicity.upperSet);
		assertFalse(exactEnd.multiplicity.upperInf);
	}

	@Test
	def parseComposition() {
		val file = '''
			package test.model;
			class TestClass;
			composition TestComposition {
				hidden container TestClass containerEnd;
				TestClass otherEnd;
			}
		'''.parse;

		assertEquals(2, file.elements.size);
		assertTrue(file.elements.head instanceof XUClass);
		assertTrue(file.elements.get(1) instanceof XUComposition);

		val composition = file.elements.get(1) as XUComposition;
		assertEquals("TestComposition", composition.name);
		assertEquals(2, composition.ends.size);
		assertTrue(composition.ends.forall[endClass.name == "TestClass"]);

		val containerEnd = composition.ends.head;
		assertEquals("containerEnd", containerEnd.name);
		assertTrue(containerEnd.notNavigable);
		assertTrue(containerEnd.container);
		assertNull(containerEnd.multiplicity);
	}

	@Test
	def parseInterface() {
		val file = '''
			package test.model;
			signal TestSignal;
			interface EmptyTestInterface {}
			interface NotEmptyTestInterface {
				reception TestSignal;
			}
		'''.parse;

		assertEquals(3, file.elements.size);
		assertTrue(file.elements.head instanceof XUSignal);
		assertTrue(file.elements.get(1) instanceof XUInterface);
		assertTrue(file.elements.get(2) instanceof XUInterface);

		val emptyInterface = file.elements.get(1) as XUInterface;
		assertEquals("EmptyTestInterface", emptyInterface.name);
		assertTrue(emptyInterface.receptions.empty);

		val notEmptyInterface = file.elements.get(2) as XUInterface;
		assertEquals("NotEmptyTestInterface", notEmptyInterface.name);
		assertEquals(1, notEmptyInterface.receptions.size);

		val reception = notEmptyInterface.receptions.head;
		assertEquals("TestSignal", reception.signal.name);
	}

	@Test
	def parseConnector() {
		val file = '''
			package test.model;
			
			interface I1;
			interface I2;
			interface I3;
			
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
		'''.parse;

		assertEquals(10, file.elements.size);
		assertTrue(file.elements.get(8) instanceof XUConnector);
		assertTrue(file.elements.get(9) instanceof XUConnector);

		val assembly = file.elements.get(8) as XUConnector;
		assertEquals("A_AB", assembly.name);
		assertFalse(assembly.delegation);
		assertEquals(2, assembly.ends.size);

		val aap = assembly.ends.head;
		assertEquals("aap", aap.name);
		assertEquals("a", aap.role.name);
		assertEquals("AP1", aap.port.name);

		val abp = assembly.ends.get(1);
		assertEquals("abp", abp.name);
		assertEquals("b", abp.role.name);
		assertEquals("BP", abp.port.name);

		val delegation = file.elements.get(9) as XUConnector;
		assertEquals("D_CA", delegation.name);
		assertTrue(delegation.delegation);
		assertEquals(2, delegation.ends.size);

		val dcp = delegation.ends.head;
		assertEquals("dcp", dcp.name);
		assertEquals("c", dcp.role.name);
		assertEquals("CP", dcp.port.name);

		val dap = delegation.ends.get(1);
		assertEquals("dap", dap.name);
		assertEquals("a", dap.role.name);
		assertEquals("AP2", dap.port.name);
	}

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
