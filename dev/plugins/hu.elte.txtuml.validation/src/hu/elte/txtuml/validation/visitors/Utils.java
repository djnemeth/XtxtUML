package hu.elte.txtuml.validation.visitors;

import java.util.Arrays;
import java.util.List;

import org.eclipse.jdt.core.dom.BodyDeclaration;
import org.eclipse.jdt.core.dom.Modifier;
import org.eclipse.jdt.core.dom.PrimitiveType;
import org.eclipse.jdt.core.dom.PrimitiveType.Code;
import org.eclipse.jdt.core.dom.Type;
import org.eclipse.jdt.core.dom.TypeDeclaration;
import org.eclipse.jdt.core.dom.TypeParameter;

import hu.elte.txtuml.api.model.ModelClass;
import hu.elte.txtuml.utils.jdt.ElementTypeTeller;
import hu.elte.txtuml.utils.jdt.SharedUtils;
import hu.elte.txtuml.validation.ProblemCollector;
import hu.elte.txtuml.validation.problems.general.InvalidModifier;
import hu.elte.txtuml.validation.problems.general.InvalidTemplate;

public class Utils {

	private static List<String> BASIC_CLASSES = Arrays.asList(String.class.getCanonicalName(),
			Integer.class.getCanonicalName(), Double.class.getCanonicalName(), Boolean.class.getCanonicalName());

	private static List<Code> PRIMITIVE_TYPES = Arrays.asList(PrimitiveType.BOOLEAN, PrimitiveType.DOUBLE,
			PrimitiveType.INT);

	public static void checkTemplate(ProblemCollector collector, TypeDeclaration elem) {
		if (elem.typeParameters().size() > 0) {
			collector.report(
					new InvalidTemplate(collector.getSourceInfo(), (TypeParameter) (elem.typeParameters().get(0))));
		}
	}

	public static void checkModifiers(ProblemCollector collector, BodyDeclaration elem) {
		for (Object obj : elem.modifiers()) {
			if (!(obj instanceof Modifier)) {
				continue;
			}
			Modifier modifier = (Modifier) obj;
			boolean valid;
			if (modifier.isStatic()) {
				valid = false;
			} else {
				valid = modifier.isPrivate() || modifier.isPublic() || modifier.isProtected();
			}
			if (!valid) {
				collector.report(new InvalidModifier(collector.getSourceInfo(), modifier));
			}
		}
	}

	public static boolean isAllowedAttributeType(Type type, boolean isVoidAllowed) {
		return isBasicType(type, isVoidAllowed) || ElementTypeTeller.isDataType(type.resolveBinding())
				|| ElementTypeTeller.isExternalInterface(type.resolveBinding());
	}

	public static boolean isAllowedParameterType(Type type, boolean isVoidAllowed) {
		if (isAllowedAttributeType(type, isVoidAllowed) || ElementTypeTeller.isModelClass(type.resolveBinding())) {
			return true;
		}

		return (SharedUtils.typeIsAssignableFrom(type.resolveBinding(), ModelClass.class));
	}

	public static boolean isVoid(Type type) {
		if (type instanceof PrimitiveType) {
			return ((PrimitiveType) type).getPrimitiveTypeCode().equals(PrimitiveType.VOID);
		} else {
			return false;
		}
	}

	public static boolean isBoolean(Type type) {
		if (type instanceof PrimitiveType) {
			return ((PrimitiveType) type).getPrimitiveTypeCode().equals(PrimitiveType.BOOLEAN);
		} else {
			return false;
		}
	}

	public static boolean isBasicType(Type type, boolean isVoidAllowed) {
		if (type.isPrimitiveType()) {
			PrimitiveType.Code code = ((PrimitiveType) type).getPrimitiveTypeCode();
			return (PRIMITIVE_TYPES.contains(code) || (code == PrimitiveType.VOID && isVoidAllowed));
		}
		if (BASIC_CLASSES.contains(type.resolveBinding().getQualifiedName())) {
			return true;
		}
		return false;
	}

}
