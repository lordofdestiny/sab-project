package rs.etf.sab.student.tests;

public class PublicModuleTest extends rs.etf.sab.tests.PublicModuleTest implements StandaloneTest {
    @Override
    public void setUp(){
        try {
            StandaloneTest.super.setUp();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        super.setUp();
    }
}
