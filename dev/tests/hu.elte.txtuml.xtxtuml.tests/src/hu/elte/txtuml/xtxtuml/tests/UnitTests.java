package hu.elte.txtuml.xtxtuml.tests;

import org.junit.runner.RunWith;
import org.junit.runners.Suite;
import org.junit.runners.Suite.SuiteClasses;

import hu.elte.txtuml.xtxtuml.tests.compiler.XtxtUMLCompilerTests;
import hu.elte.txtuml.xtxtuml.tests.parser.XtxtUMLParserTests;
import hu.elte.txtuml.xtxtuml.tests.scoping.XtxtUMLScopingTests;
import hu.elte.txtuml.xtxtuml.tests.validation.XtxtUMLValidatorTests;

@RunWith(Suite.class)
@SuiteClasses({ XtxtUMLParserTests.class, XtxtUMLValidatorTests.class, XtxtUMLCompilerTests.class,
		XtxtUMLScopingTests.class })
public class UnitTests {
}
