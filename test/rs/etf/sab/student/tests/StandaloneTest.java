package rs.etf.sab.student.tests;

import rs.etf.sab.student.*;
import rs.etf.sab.tests.TestHandler;

import java.lang.reflect.Field;
import java.lang.reflect.Method;

public interface StandaloneTest {
    TestHandler handler = createTestHandler();

    default void setUp() throws Exception {
        setField(this, "testHandler", handler);
    }

    private static void setField(Object obj, String fieldName, Object value) {
        final var klass = obj.getClass();
        try {
            Field field = klass.getSuperclass().getDeclaredField(fieldName);
            field.setAccessible(true);
            field.set(obj, value);
            field.setAccessible(false);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private static TestHandler getTestHandler() {
        final var klass = TestHandler.class;
        try {
            Method method = klass.getDeclaredMethod("getInstance");
            method.setAccessible(true);
            return (TestHandler) method.invoke(null);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private static TestHandler createTestHandler() {
        TestHandler.createInstance(
                new rs.etf.sab.student.db200260_CityOperations(),
                new db200260_CourierOperations(),
                new db200260_CourierRequestOperations(),
                new db200260_DistrictOperations(),
                new db200260_GeneralOperations(),
                new db200260_UserOperations(),
                new db200260_VehicleOperations(),
                new db200260_PackageOperations()
        );
        return getTestHandler();
    }
}
