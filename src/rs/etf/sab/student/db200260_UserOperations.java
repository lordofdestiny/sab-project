package rs.etf.sab.student;

import rs.etf.sab.student.util.DB;

import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.regex.Pattern;

public class db200260_UserOperations implements rs.etf.sab.operations.UserOperations {

    @Override
    public boolean insertUser(String userName, String firstName, String lastName, String password) {
        final var connection = DB.getInstance().getConnection();
        // Check that first and last names start with capital letters
        // Check that first name starts with an uppercase letter
        if (firstName.isEmpty() || !Character.isUpperCase(firstName.charAt(0))) {
            return false;
        }
        // Check that last name starts with an uppercase letter
        if (lastName.isEmpty() || !Character.isUpperCase(firstName.charAt(0))) {
            return false;
        }
        // Check that password is at least 8 characters long
        // and that it has at least one letter and one digit
        if (password.length() <= 8
                || !Pattern.matches(".*[a-zA-Z].*", password)
                || !Pattern.matches(".*\\d.*", password)) {
            return false;
        }

        // Check password format conditions
        try (final var insertUser = connection.prepareStatement(
                "INSERT INTO [User](FirstName, LastName, Username, Password) VALUES (?, ?, ?, ?)"
        )) {
            insertUser.setString(1, firstName);
            insertUser.setString(2, lastName);
            insertUser.setString(3, userName);
            insertUser.setString(4, password);

            return insertUser.executeUpdate() > 0;
        } catch (SQLException e) {
            return false;
        }
    }

    @Override
    public int declareAdmin(String userName) {
        final var connection = DB.getInstance().getConnection();
        try (final var insertAdmin = connection.prepareCall(
                "{? = call [spDeclareAdmin](?)}"
        )) {
            insertAdmin.registerOutParameter(1, Types.INTEGER);
            insertAdmin.setString(2, userName);
            insertAdmin.execute();
            return insertAdmin.getInt(1);
        } catch (SQLException e) {
            return -2;
        }
    }

    @Override
    public Integer getSentPackages(String... userNames) {
        final var connection = DB.getInstance().getConnection();
        try (final var userPackageCounts = connection.createStatement();
             final var resultSet = userPackageCounts.executeQuery(
                     "SELECT [Username], SentPackages FROM [User]"
             )
        ) {
            var foundUsers = false;
            var total = 0;
            final var usernames = new HashSet<>(Arrays.asList(userNames));
            while (resultSet.next()) {
                final var username = resultSet.getString(1);
                if (!usernames.contains(username)) continue;
                total += resultSet.getInt(2);
                foundUsers = true;
            }
            if (!foundUsers) {
                return null;
            }
            return total;
        } catch (SQLException e) {
            return -1;
        }
    }

    @Override
    public int deleteUsers(String... userNames) {
        final var connection = DB.getInstance().getConnection();
        try (final var ps = connection.prepareStatement("DELETE FROM [User] WHERE [Username] = ?")) {
            // noinspection Duplicates
            for (var name : userNames) {
                ps.setString(1, name);
                ps.addBatch();
            }
            final var result = ps.executeBatch();
            return Arrays.stream(result).filter(r -> r > 0).map(r -> 1).sum();
        } catch (SQLException e) {
            return -1;
        }
    }

    @Override
    public List<String> getAllUsers() {
        final var connection = DB.getInstance().getConnection();
        try (final var stmt = connection.createStatement();
             final var rs = stmt.executeQuery("SELECT [Username] FROM [User]")
        ) {
            final var users = new ArrayList<String>();
            while (rs.next()) {
                users.add(rs.getString(1));
            }
            return users;
        } catch (SQLException e) {
            return List.of();
        }
    }
}
