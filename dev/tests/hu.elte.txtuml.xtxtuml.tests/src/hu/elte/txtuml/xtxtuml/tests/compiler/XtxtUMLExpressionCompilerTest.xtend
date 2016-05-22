package hu.elte.txtuml.xtxtuml.tests.compiler;

import com.google.inject.Inject
import hu.elte.txtuml.xtxtuml.XtxtUMLInjectorProvider
import org.eclipse.xtext.junit4.InjectWith
import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.xbase.compiler.CompilationTestHelper
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(XtextRunner)
@InjectWith(XtxtUMLInjectorProvider)
class XtxtUMLExpressionCompilerTest {

	@Inject extension CompilationTestHelper;

	@Test
	def compileSendSignalExpression() {
		'''
			package test.model;
			signal TestSignal;
			interface TestInterface {
				reception TestSignal;
			}
			class TestClass {
				void testOperation() {
					send new TestSignal() to this;
					send new TestSignal() to new TestClass();
			
					TestSignal sig = new TestSignal();
					send sig to this->(TestPort);
				}
			
				port TestPort {
					required TestInterface;
				}
			}
		'''.assertCompilesTo('''
			MULTIPLE FILES WERE GENERATED
			
			File 1 : /myProject/src-gen/test/model/TestClass.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Action;
			import hu.elte.txtuml.api.model.Interface;
			import hu.elte.txtuml.api.model.ModelClass;
			import hu.elte.txtuml.api.model.Port;
			import test.model.TestInterface;
			import test.model.TestSignal;
			
			@SuppressWarnings("all")
			public class TestClass extends ModelClass {
			  void testOperation() {
			    Action.send(new TestSignal(), this);
			    Action.send(new TestSignal(), new TestClass());
			    TestSignal sig = new TestSignal();
			    Action.send(sig, this.port(TestClass.TestPort.class).required::reception);
			  }
			  
			  public class TestPort extends Port<Interface.Empty, TestInterface> {
			  }
			}
			
			File 2 : /myProject/src-gen/test/model/TestInterface.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Interface;
			import test.model.TestSignal;
			
			@SuppressWarnings("all")
			public interface TestInterface extends Interface {
			  void reception(final TestSignal signal);
			}
			
			File 3 : /myProject/src-gen/test/model/TestSignal.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Signal;
			
			@SuppressWarnings("all")
			public class TestSignal extends Signal {
			}
			
		''');
	}

	@Test
	def compileStartObjectExpression() {
		'''
			package test.model;
			class TestClass {
				void testOperation() {
					start this;
					start new TestClass();
			
					TestClass obj = new TestClass();
					start obj;
				}
			}
		'''.assertCompilesTo('''
			package test.model;
			
			import hu.elte.txtuml.api.model.Action;
			import hu.elte.txtuml.api.model.ModelClass;
			
			@SuppressWarnings("all")
			public class TestClass extends ModelClass {
			  void testOperation() {
			    Action.start(this);
			    Action.start(new TestClass());
			    TestClass obj = new TestClass();
			    Action.start(obj);
			  }
			}
		''');
	}

	@Test
	def compileLogExpression() {
		'''
			package test.model;
			class TestClass {
				void testOperation() {
					log "test";
			
					String test = "test";
					log test;
				}
			}
		'''.assertCompilesTo('''
			package test.model;
			
			import hu.elte.txtuml.api.model.Action;
			import hu.elte.txtuml.api.model.ModelClass;
			
			@SuppressWarnings("all")
			public class TestClass extends ModelClass {
			  void testOperation() {
			    Action.log("test");
			    String test = "test";
			    Action.log(test);
			  }
			}
		''');
	}

	@Test
	def compileSignalAccessExpression() {
		'''
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
						log trigger.message;
					}
				}
			}
		'''.assertCompilesTo('''
			MULTIPLE FILES WERE GENERATED
			
			File 1 : /myProject/src-gen/test/model/TestClass.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Action;
			import hu.elte.txtuml.api.model.From;
			import hu.elte.txtuml.api.model.ModelClass;
			import hu.elte.txtuml.api.model.StateMachine;
			import hu.elte.txtuml.api.model.To;
			import hu.elte.txtuml.api.model.Trigger;
			import test.model.TestSignal;
			
			@SuppressWarnings("all")
			public class TestClass extends ModelClass {
			  public class TestState extends StateMachine.State {
			  }
			  
			  @From(TestClass.TestState.class)
			  @To(TestClass.TestState.class)
			  @Trigger(TestSignal.class)
			  public class TestTransition extends StateMachine.Transition {
			    @Override
			    public void effect() {
			      Action.log(getTrigger(TestSignal.class).message);
			    }
			  }
			}
			
			File 2 : /myProject/src-gen/test/model/TestSignal.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Signal;
			
			@SuppressWarnings("all")
			public class TestSignal extends Signal {
			  public String message;
			  
			  public TestSignal(final String message) {
			    this.message = message;
			  }
			}
			
		''');
	}

	@Test
	def compileVariableDeclaration() {
		'''
			package test.model;
			
			import hu.elte.txtuml.api.model.Collection;
			
			class TestClass {
				void testOperation() {
					int a;
					String b = "test";
					Collection<TestClass> c;
					Collection<TestClass> d = null;
				}
			}
		'''.assertCompilesTo('''
			package test.model;
			
			import hu.elte.txtuml.api.model.Collection;
			import hu.elte.txtuml.api.model.ModelClass;
			
			@SuppressWarnings("all")
			public class TestClass extends ModelClass {
			  void testOperation() {
			    int a = 0;
			    String b = "test";
			    Collection<TestClass> c = null;
			    Collection<TestClass> d = null;
			  }
			}
		''');
	}

	@Test
	def compileClassPropertyAccessExpression() {
		'''
			package test.model;
			
			class A {
				void foo() {
					send new S() to this->(P);
					send new S() to this->(AB.b).selectAny();
					new B()->(AB.a).selectAny();
				}
				
				port P {
					required I;
				}
			}
			
			signal S;
			interface I {
				reception S;
			}
			class B;
			association AB {
				A a;
				B b;
			}
		'''.assertCompilesTo('''
			MULTIPLE FILES WERE GENERATED
			
			File 1 : /myProject/src-gen/test/model/A.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Action;
			import hu.elte.txtuml.api.model.Interface;
			import hu.elte.txtuml.api.model.ModelClass;
			import hu.elte.txtuml.api.model.Port;
			import test.model.AB;
			import test.model.B;
			import test.model.I;
			import test.model.S;
			
			@SuppressWarnings("all")
			public class A extends ModelClass {
			  void foo() {
			    Action.send(new S(), this.port(A.P.class).required::reception);
			    Action.send(new S(), this.assoc(AB.b.class).selectAny());
			    new B().assoc(AB.a.class).selectAny();
			  }
			  
			  public class P extends Port<Interface.Empty, I> {
			  }
			}
			
			File 2 : /myProject/src-gen/test/model/AB.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Association;
			import test.model.A;
			import test.model.B;
			
			@SuppressWarnings("all")
			public class AB extends Association {
			  public class a extends Association.One<A> {
			  }
			  
			  public class b extends Association.One<B> {
			  }
			}
			
			File 3 : /myProject/src-gen/test/model/B.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.ModelClass;
			
			@SuppressWarnings("all")
			public class B extends ModelClass {
			}
			
			File 4 : /myProject/src-gen/test/model/I.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Interface;
			import test.model.S;
			
			@SuppressWarnings("all")
			public interface I extends Interface {
			  void reception(final S signal);
			}
			
			File 5 : /myProject/src-gen/test/model/S.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Signal;
			
			@SuppressWarnings("all")
			public class S extends Signal {
			}
			
		''');
	}
}
