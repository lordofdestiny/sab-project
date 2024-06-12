-- Insert PackageTypes
INSERT INTO [PackageType] ([IdPkgT], [Description], [InitialPrice], [WeightFactor], [PricePerKg])
VALUES
    (0, 'pismo', 10, 0, 0),
    (1, 'standard', 25, 1, 100),
    (2, 'lomljivo', 75, 2, 300)
go

-- Insert Fuel Types
INSERT INTO [FuelType] ([IdFuelT], [Description], [FuelPrice])
VALUES
    (0, 'plin', 15),
    (1, 'dizel', 36),
    (2, 'benzin', 32)
go