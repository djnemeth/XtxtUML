package hu.elte.txtuml.xtxtuml.tests.validation

import org.junit.runner.RunWith
import org.junit.runners.Suite
import org.junit.runners.Suite.SuiteClasses

@RunWith(Suite)
@SuiteClasses(XtxtUMLUniquenessValidatorTest, XtxtUMLTypeValidatorTest, XtxtUMLExpressionValidatorTest,
	XtxtUMLFileValidatorTest, XtxtUMLClassValidatorTest, XtxtUMLAssociationValidatorTest,
	XtxtUMLConnectorValidatorTest)
class XtxtUMLValidatorTests {
}
