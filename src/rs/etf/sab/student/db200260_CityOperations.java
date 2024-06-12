package rs.etf.sab.student;

import rs.etf.sab.operations.CityOperations;
import rs.etf.sab.student.util.DB;

import java.sql.SQLException;
import java.sql.Statement;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Stream;

public class db200260_CityOperations implements CityOperations {
    @Override
    public int insertCity(String name, String postalCode) {
        try {
            final var connection = DB.getInstance().getConnection();
            try (final var ps = connection.prepareStatement(
                    "INSERT INTO [City] ([Name], [PostalCode]) VALUES (?, ?)",
                    Statement.RETURN_GENERATED_KEYS)
            ) {
                ps.setString(1, name);
                ps.setString(2, postalCode);
                if (ps.executeUpdate() == 0) {
                    return -1;
                }
                try (final var rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        return rs.getInt(1);
                    } else {
                        return -1;
                    }
                }
            }
        } catch (SQLException e) {
            return -1;
        }
    }

    @Override
    public int deleteCity(String... names) {
        final var deleteQuery = "DELETE FROM [City] WHERE [Name] = ?";
        try {
            final var connection = DB.getInstance().getConnection();
            try (final var ps = connection.prepareStatement(deleteQuery)) {
                for (var name : names) {
                    ps.setString(1, name);
                    ps.addBatch();
                }
                final var result = ps.executeBatch();
                return Arrays.stream(result).filter(r -> r > 0).map(r -> 1).sum();
            }
        } catch (SQLException e) {
            return -1;
        }
    }

    @Override
    public boolean deleteCity(int idCity) {
        try {
            final var connection = DB.getInstance().getConnection();
            try (final var ps = connection.prepareStatement("DELETE FROM [City] WHERE [IdCity] = ?")) {
                ps.setInt(1, idCity);
                return ps.executeUpdate() != 0;
            }
        } catch (SQLException e) {
            return false;
        }
    }

    @Override
    public List<Integer> getAllCities() {
        try {
            final var connection = DB.getInstance().getConnection();
            try (final var stmt = connection.createStatement();
                 final var rs = stmt.executeQuery("SELECT [IdCity] FROM [City]")) {
                final var cities = new java.util.ArrayList<Integer>();
                while (rs.next()) {
                    cities.add(rs.getInt(1));
                }
                return cities;
            }
        } catch (SQLException e) {
            return List.of();
        }
    }
}
