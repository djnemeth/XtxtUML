package hu.elte.txtuml.xtxtuml.tests.compiler

import com.google.inject.Inject
import hu.elte.txtuml.xtxtuml.XtxtUMLInjectorProvider
import org.eclipse.xtext.junit4.InjectWith
import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.xbase.compiler.CompilationTestHelper
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(XtextRunner)
@InjectWith(XtxtUMLInjectorProvider)
class XtxtUMLStructureCompilerTest {

	@Inject extension CompilationTestHelper;

	@Test
	def compileModelDeclaration() {
		'''
			model-package test.model;
		'''.assertCompilesTo('''
			@Model
			package test.model;
			
			import hu.elte.txtuml.api.model.Model;
		''');

		'''
			model-package test.model as "TestModel";
		'''.assertCompilesTo('''
			@Model("TestModel")
			package test.model;
			
			import hu.elte.txtuml.api.model.Model;
		''');
	}

	@Test
	def compileExecution() {
		'''
			package test.model;
			execution E {}
		'''.assertCompilesTo('''
			package test.model;
			
			@SuppressWarnings("all")
			public class E {
			  public static void main(final String... args) {
			  }
			}
		''');
	}

	@Test
	def compileSignal() {
		'''
			package test.model;
			signal EmptyTestSignal;
		'''.assertCompilesTo('''
			package test.model;
			
			import hu.elte.txtuml.api.model.Signal;
			
			@SuppressWarnings("all")
			public class EmptyTestSignal extends Signal {
			}
		''');

		'''
			package test.model;
			signal TestSignal {
				public int a1;
				public String a2;
			}
		'''.assertCompilesTo('''
			package test.model;
			
			import hu.elte.txtuml.api.model.Signal;
			
			@SuppressWarnings("all")
			public class TestSignal extends Signal {
			  public int a1;
			  
			  public String a2;
			  
			  public TestSignal(final int a1, final String a2) {
			    this.a1 = a1;
			    this.a2 = a2;
			  }
			}
		''');
	}

	@Test
	def compileClass() {
		'''
			package test.model;
			class TestClass;
		'''.assertCompilesTo('''
			package test.model;
			
			import hu.elte.txtuml.api.model.ModelClass;
			
			@SuppressWarnings("all")
			public class TestClass extends ModelClass {
			}
		''');

		'''
			package test.model;
			class Base;
			class Derived extends Base;
		'''.assertCompilesTo('''
			MULTIPLE FILES WERE GENERATED
			
			File 1 : /myProject/src-gen/test/model/Base.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.ModelClass;
			
			@SuppressWarnings("all")
			public class Base extends ModelClass {
			}
			
			File 2 : /myProject/src-gen/test/model/Derived.java
			
			package test.model;
			
			import test.model.Base;
			
			@SuppressWarnings("all")
			public class Derived extends Base {
			}
			
		''');
	}

	@Test
	def compileClassAttributeAndOperation() {
		'''
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
		'''.assertCompilesTo('''
			package test.model;
			
			import hu.elte.txtuml.api.model.ModelClass;
			
			@SuppressWarnings("all")
			public class TestClass extends ModelClass {
			  int a1;
			  
			  protected int a2;
			  
			  public void o1() {
			  }
			  
			  private int o2() {
			    return 0;
			  }
			  
			  TestClass o3(final int p) {
			    return null;
			  }
			  
			  public TestClass(final int p1, final TestClass p2) {
			  }
			}
		''');
	}

	@Test
	def compileStatemachine() {
		'''
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
		'''.assertCompilesTo('''
			MULTIPLE FILES WERE GENERATED
			
			File 1 : /myProject/src-gen/test/model/Sig.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Signal;
			
			@SuppressWarnings("all")
			public class Sig extends Signal {
			}
			
			File 2 : /myProject/src-gen/test/model/TestClass.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.From;
			import hu.elte.txtuml.api.model.Interface;
			import hu.elte.txtuml.api.model.ModelClass;
			import hu.elte.txtuml.api.model.StateMachine;
			import hu.elte.txtuml.api.model.To;
			import hu.elte.txtuml.api.model.Trigger;
			import test.model.Sig;
			
			@SuppressWarnings("all")
			public class TestClass extends ModelClass {
			  public class Port extends hu.elte.txtuml.api.model.Port<Interface.Empty, Interface.Empty> {
			  }
			  
			  public class Init extends StateMachine.Initial {
			  }
			  
			  public class Choice extends StateMachine.Choice {
			  }
			  
			  @From(TestClass.Init.class)
			  @To(TestClass.Choice.class)
			  public class T1 extends StateMachine.Transition {
			    @Override
			    public void effect() {
			    }
			  }
			  
			  @From(TestClass.Choice.class)
			  @To(TestClass.Composite.class)
			  public class T2 extends StateMachine.Transition {
			    @Override
			    public boolean guard() {
			      return Else();
			    }
			  }
			  
			  public class Composite extends StateMachine.CompositeState {
			    @Override
			    public void entry() {
			    }
			    
			    @Override
			    public void exit() {
			    }
			    
			    public class CInit extends StateMachine.Initial {
			    }
			    
			    public class State extends StateMachine.State {
			    }
			    
			    @From(TestClass.Composite.CInit.class)
			    @To(TestClass.Composite.State.class)
			    public class T3 extends StateMachine.Transition {
			    }
			    
			    @From(TestClass.Composite.State.class)
			    @To(TestClass.Composite.State.class)
			    @Trigger(port = TestClass.Port.class, value = Sig.class)
			    public class T4 extends StateMachine.Transition {
			    }
			  }
			}
			
		''');
	}

	@Test
	def compilePort() {
		'''
			package test.model;
			interface TestInterface;
			class TestClass {
				port EmptyPort {}
				behavior port BehaviorPort {
					required TestInterface;
					provided TestInterface;
				}
			}
		'''.assertCompilesTo('''
			MULTIPLE FILES WERE GENERATED
			
			File 1 : /myProject/src-gen/test/model/TestClass.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Interface;
			import hu.elte.txtuml.api.model.ModelClass;
			import hu.elte.txtuml.api.model.Port;
			import test.model.TestInterface;
			
			@SuppressWarnings("all")
			public class TestClass extends ModelClass {
			  public class EmptyPort extends Port<Interface.Empty, Interface.Empty> {
			  }
			  
			  @hu.elte.txtuml.api.model.BehaviorPort
			  public class BehaviorPort extends Port<TestInterface, TestInterface> {
			  }
			}
			
			File 2 : /myProject/src-gen/test/model/TestInterface.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Interface;
			
			@SuppressWarnings("all")
			public interface TestInterface extends Interface {
			}
			
		''');
	}

	@Test
	def compileAssociation() {
		'''
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
		'''.assertCompilesTo('''
			MULTIPLE FILES WERE GENERATED
			
			File 1 : /myProject/src-gen/test/model/TestAssociation1.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Association;
			import test.model.TestClass;
			
			@SuppressWarnings("all")
			public class TestAssociation1 extends Association {
			  public class plainEnd extends Association.One<TestClass> {
			  }
			  
			  public class hiddenEnd extends Association.HiddenMany<TestClass> {
			  }
			}
			
			File 2 : /myProject/src-gen/test/model/TestAssociation2.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Association;
			import hu.elte.txtuml.api.model.Max;
			import hu.elte.txtuml.api.model.Min;
			import test.model.TestClass;
			
			@SuppressWarnings("all")
			public class TestAssociation2 extends Association {
			  public class intervalEnd extends Association.HiddenSome<TestClass> {
			  }
			  
			  @Min(5)
			  @Max(5)
			  public class exactEnd extends Association.Multiple<TestClass> {
			  }
			}
			
			File 3 : /myProject/src-gen/test/model/TestClass.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.ModelClass;
			
			@SuppressWarnings("all")
			public class TestClass extends ModelClass {
			}
			
		''');
	}

	@Test
	def compileComposition() {
		'''
			package test.model;
			class TestClass;
			composition TestComposition {
				hidden container TestClass containerEnd;
				TestClass otherEnd;
			}
		'''.assertCompilesTo('''
			MULTIPLE FILES WERE GENERATED
			
			File 1 : /myProject/src-gen/test/model/TestClass.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.ModelClass;
			
			@SuppressWarnings("all")
			public class TestClass extends ModelClass {
			}
			
			File 2 : /myProject/src-gen/test/model/TestComposition.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Association;
			import hu.elte.txtuml.api.model.Composition;
			import test.model.TestClass;
			
			@SuppressWarnings("all")
			public class TestComposition extends Composition {
			  public class containerEnd extends Composition.HiddenContainer<TestClass> {
			  }
			  
			  public class otherEnd extends Association.One<TestClass> {
			  }
			}
			
		''');
	}

	@Test
	def compileInterface() {
		'''
			package test.model;
			signal TestSignal;
			interface EmptyTestInterface {}
			interface NotEmptyTestInterface {
				reception TestSignal;
			}
		'''.assertCompilesTo('''
			MULTIPLE FILES WERE GENERATED
			
			File 1 : /myProject/src-gen/test/model/EmptyTestInterface.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Interface;
			
			@SuppressWarnings("all")
			public interface EmptyTestInterface extends Interface {
			}
			
			File 2 : /myProject/src-gen/test/model/NotEmptyTestInterface.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Interface;
			import test.model.TestSignal;
			
			@SuppressWarnings("all")
			public interface NotEmptyTestInterface extends Interface {
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
	def compileConnector() {
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
		'''.assertCompilesTo('''
			MULTIPLE FILES WERE GENERATED
			
			File 1 : /myProject/src-gen/test/model/A.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Interface;
			import hu.elte.txtuml.api.model.ModelClass;
			import hu.elte.txtuml.api.model.Port;
			import test.model.I1;
			import test.model.I2;
			import test.model.I3;
			
			@SuppressWarnings("all")
			public class A extends ModelClass {
			  public class AP1 extends Port<I1, I2> {
			  }
			  
			  public class AP2 extends Port<I3, Interface.Empty> {
			  }
			}
			
			File 2 : /myProject/src-gen/test/model/A_AB.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Connector;
			import hu.elte.txtuml.api.model.ConnectorBase;
			import test.model.A;
			import test.model.B;
			import test.model.CA;
			import test.model.CB;
			
			@SuppressWarnings("all")
			public class A_AB extends Connector {
			  public class aap extends ConnectorBase.One<CA.a, A.AP1> {
			  }
			  
			  public class abp extends ConnectorBase.One<CB.b, B.BP> {
			  }
			}
			
			File 3 : /myProject/src-gen/test/model/B.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.ModelClass;
			import hu.elte.txtuml.api.model.Port;
			import test.model.I1;
			import test.model.I2;
			
			@SuppressWarnings("all")
			public class B extends ModelClass {
			  public class BP extends Port<I2, I1> {
			  }
			}
			
			File 4 : /myProject/src-gen/test/model/C.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Interface;
			import hu.elte.txtuml.api.model.ModelClass;
			import hu.elte.txtuml.api.model.Port;
			import test.model.I3;
			
			@SuppressWarnings("all")
			public class C extends ModelClass {
			  public class CP extends Port<I3, Interface.Empty> {
			  }
			}
			
			File 5 : /myProject/src-gen/test/model/CA.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Association;
			import hu.elte.txtuml.api.model.Composition;
			import test.model.A;
			import test.model.C;
			
			@SuppressWarnings("all")
			public class CA extends Composition {
			  public class c extends Composition.Container<C> {
			  }
			  
			  public class a extends Association.One<A> {
			  }
			}
			
			File 6 : /myProject/src-gen/test/model/CB.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Association;
			import hu.elte.txtuml.api.model.Composition;
			import test.model.B;
			import test.model.C;
			
			@SuppressWarnings("all")
			public class CB extends Composition {
			  public class c extends Composition.Container<C> {
			  }
			  
			  public class b extends Association.One<B> {
			  }
			}
			
			File 7 : /myProject/src-gen/test/model/D_CA.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.ConnectorBase;
			import hu.elte.txtuml.api.model.Delegation;
			import test.model.A;
			import test.model.C;
			import test.model.CA;
			
			@SuppressWarnings("all")
			public class D_CA extends Delegation {
			  public class dcp extends ConnectorBase.One<CA.c, C.CP> {
			  }
			  
			  public class dap extends ConnectorBase.One<CA.a, A.AP2> {
			  }
			}
			
			File 8 : /myProject/src-gen/test/model/I1.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Interface;
			
			@SuppressWarnings("all")
			public interface I1 extends Interface {
			}
			
			File 9 : /myProject/src-gen/test/model/I2.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Interface;
			
			@SuppressWarnings("all")
			public interface I2 extends Interface {
			}
			
			File 10 : /myProject/src-gen/test/model/I3.java
			
			package test.model;
			
			import hu.elte.txtuml.api.model.Interface;
			
			@SuppressWarnings("all")
			public interface I3 extends Interface {
			}
			
		''');
	}
}
