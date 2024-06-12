package rs.etf.sab.student;

import rs.etf.sab.student.util.DB;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class db200260_DistrictOperations implements rs.etf.sab.operations.DistrictOperations {

    @Override
    public int insertDistrict(String name, int cityId, int xCord, int yCord) {
        try {
            final var connection = DB.getInstance().getConnection();
            try (final var ps = connection.prepareStatement(
                    "INSERT INTO [District] ([Name], [IdCity], [CoordinateX], [CoordinateY]) VALUES (?, ?, ?, ?)",
                    java.sql.Statement.RETURN_GENERATED_KEYS)
            ) {
                ps.setString(1, name);
                ps.setInt(2, cityId);
                ps.setInt(3, xCord);
                ps.setInt(4, yCord);
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
    public int deleteDistricts(String... names) {
        try {
            final var connection = DB.getInstance().getConnection();
            try (final var ps = connection.prepareStatement(
                    "DELETE FROM [District] WHERE [Name] = ?")
            ) {
                for (final var name : names) {
                    ps.setString(1, name);
                    ps.addBatch();
                }
                final var result = ps.executeBatch();
                return Arrays.stream(result).filter(i -> i > 0).map(i -> 1).sum();
            }
        } catch (SQLException e) {
            return 0;
        }
    }

    @Override
    public boolean deleteDistrict(int id) {
        final var connection = DB.getInstance().getConnection();
        try (final var ps = connection.prepareStatement(
                "DELETE FROM [District] WHERE [IdDist] = ?")
        ) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            return false;
        }
    }

    @Override
    public int deleteAllDistrictsFromCity(String nameOfTheCity) {
        final var connection = DB.getInstance().getConnection();
        try (final var ps = connection.prepareStatement(
                "DELETE FROM [District] WHERE [IdCity] = (SELECT [IdCity] FROM [City] WHERE [Name] = ?)")
        ) {
            ps.setString(1, nameOfTheCity);
            return ps.executeUpdate();
        } catch (SQLException e) {
            return 0;
        }
    }

    @Override
    public List<Integer> getAllDistrictsFromCity(int idCity) {
        final var connection = DB.getInstance().getConnection();
        try (final var ps = connection.prepareStatement(
                "SELECT [IdDist] FROM [District] WHERE [IdCity] = ?")
        ) {
            //noinspection DuplicatedCode
            ps.setInt(1, idCity);
            try (final var rs = ps.executeQuery()) {
                final var districts = new ArrayList<Integer>();
                while (rs.next()) {
                    districts.add(rs.getInt(1));
                }
                return districts;
            }
        } catch (SQLException e) {
            return List.of();
        }
    }

    @Override
    public List<Integer> getAllDistricts() {
        final var connection = DB.getInstance().getConnection();
        try (final var stmt = connection.createStatement();
             final var rs = stmt.executeQuery("SELECT [IdDist] FROM [District]")
        ) {
            final var districts = new java.util.ArrayList<Integer>();
            while (rs.next()) {
                districts.add(rs.getInt(1));
            }
            return districts;
        } catch (SQLException e) {
            return List.of();
        }
    }
}
