package rs.etf.sab.student;

import java.util.List;

public class db200260_UserOperations implements rs.etf.sab.operations.UserOperations {

    @Override
    public boolean insertUser(String userName, String firstName, String lastName, String password) {
        return false;
    }

    @Override
    public int declareAdmin(String userName) {
        return 0;
    }

    @Override
    public Integer getSentPackages(String... userNames) {
        return 0;
    }

    @Override
    public int deleteUsers(String... userNames) {
        return 0;
    }

    @Override
    public List<String> getAllUsers() {
        return List.of();
    }
}
