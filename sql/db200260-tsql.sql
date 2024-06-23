-- Promote user into an admin
DROP PROCEDURE IF EXISTS [spDeclareAdmin];
GO

CREATE PROCEDURE [spDeclareAdmin]
    @username VARCHAR(100)
AS
BEGIN
    DECLARE @IdUser int
    SELECT @IdUser= [IdUser] FROM [User] WHERE [Username] = @username
    IF @@ROWCOUNT = 0 RETURN 2 -- User does not exist

    BEGIN TRY
        INSERT INTO [Admin] VALUES(@IdUser);
    END TRY
    BEGIN CATCH
        RETURN 1;
    END CATCH

    RETURN 0;
END
GO

-- Insert Courier Request
DROP PROCEDURE IF EXISTS [spInsertCourierRequest]
go

CREATE PROCEDURE [spInsertCourierRequest]
    @username VARCHAR(100),
    @licencePlateNumber VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdUser int, @IdVeh int

    SELECT @IdUser = [IdUser] FROM [User] WHERE [Username] = @username;
    IF @@ROWCOUNT = 0 RETURN 1; -- Verify that user exits

    SELECT @IdVeh = [IdVeh] FROM [Vehicle] WHERE [LicencePlateNumber] = @licencePlateNumber;
    IF @@ROWCOUNT = 0 RETURN 2 -- Verify that vehicle exists

    -- Verify that user is not already a courier
    IF EXISTS (SELECT [IdUser] FROM [Courier] WHERE [IdUser] = @IdUser) RETURN 3

    -- Verify that vehicle is not already used, before creating the request
    IF EXISTS (SELECT [IdVeh] FROM [Courier] WHERE [IdVeh] = @IdVeh) RETURN 4

    -- Try to insert a new request, fails if user already posted a request
    BEGIN TRY
        INSERT INTO [CourierRequest](IdUser, IdVeh) VALUES (@IdUser, @IdVeh)
    END TRY
    BEGIN CATCH
        RETURN 5;
    END CATCH

    RETURN 0;
END
go

-- Change Vehicle in Courier Request
DROP PROCEDURE IF EXISTS [spChangeVehicleInCourierRequest];
go

CREATE PROCEDURE [spChangeVehicleInCourierRequest]
    @username VARCHAR(100),
    @licencePlateNumber VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdUser int, @IdVeh int

    SELECT @IdUser = [IdUser] FROM [User] WHERE [Username] = @username;
    IF @@ROWCOUNT = 0 RETURN 1; -- Verify that user exits

    SELECT @IdVeh = [IdVeh] FROM [Vehicle] WHERE [LicencePlateNumber] = @licencePlateNumber;
    IF @@ROWCOUNT = 0 RETURN 2; -- Verify that vehicle exists

    -- Verify that vehicle is not already used
    IF EXISTS (SELECT [IdVeh] FROM [Courier] WHERE [IdVeh] = @IdVeh) RETURN 3;

    UPDATE [CourierRequest] SET [IdVeh] = @IdVeh WHERE [IdUser] = @IdUser
    IF @@ROWCOUNT = 0 RETURN 4; -- Verify that the request was updated, ie. the user had a request

    RETURN 0;
END

go

-- Accept Courier Request
DROP PROCEDURE IF EXISTS [spGrantRequest];
go

CREATE PROCEDURE [spGrantRequest]
    @username VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdUser int
    DECLARE @IdVeh int

    SELECT @IdUser = u.[IdUser], @IdVeh = [IdVeh]
    FROM [CourierRequest] cr
        JOIN [User] u ON (cr.[IdUser] = u.[IdUser])
    WHERE [Username] = @username;
    IF @@ROWCOUNT = 0 RETURN 1; -- Verify that user exits and that he has a request

    DECLARE @errorcode int
    SET @errorcode = 0
    BEGIN TRY
        BEGIN TRANSACTION
        -- Insert user as courier
        INSERT INTO [Courier](IdUser, IdVeh) VALUES (@IdUser, @IdVeh)
        IF @@ROWCOUNT != 1 SET @errorcode = 2 -- Verify that the user was inserted

        -- Delete request and all other requests for the same vehicle
        DELETE FROM [CourierRequest] WHERE [IdUser] = @IdUser OR [IdVeh] = @IdVeh
        IF @@ROWCOUNT = 0 SET @errorcode = 3 -- Verify that the request was deleted
    END TRY
    BEGIN CATCH
        SET @errorcode = 4
    END CATCH

    IF @errorcode > 1
    BEGIN
        ROLLBACK TRANSACTION;
    END

    COMMIT TRANSACTION
    RETURN @errorcode
END
go

-- Insert new Courier
DROP PROCEDURE IF EXISTS [spInsertCourier];
go

CREATE PROCEDURE [spInsertCourier]
    @username VARCHAR(100),
    @licencePlateNumber VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdUser int
    DECLARE @IdVeh int

    SELECT @IdUser = [IdUser] FROM [User] WHERE [Username] = @username;
    IF @@ROWCOUNT = 0 RETURN 1; -- Verify that user exits

    SELECT @IdVeh = [IdVeh] FROM [Vehicle] WHERE [LicencePlateNumber] = @licencePlateNumber;
    IF @@ROWCOUNT = 0 RETURN 2; -- Verify that vehicle exists

    DECLARE @errorcode int
    SET @errorcode = 0
    BEGIN TRY
        BEGIN TRANSACTION
        -- Insert user as courier
        INSERT INTO [Courier](IdUser, IdVeh) VALUES (@IdUser, @IdVeh)
        IF @@ROWCOUNT != 1 SET @errorcode = 3 -- Verify that the user was inserted

        -- Delete request in it existed before
        DELETE FROM [CourierRequest] WHERE [IdUser] = @IdUser
    END TRY
    BEGIN CATCH
        SET @errorcode = 4
    END CATCH

    IF @errorcode > 2
    BEGIN
        ROLLBACK TRANSACTION;
    END
    COMMIT TRANSACTION
    RETURN @errorcode
END
go

-- Insert package delivery offer
DROP PROCEDURE IF EXISTS [spInsertOffer];
go

CREATE PROCEDURE [spInsertOffer]
    @courierUsername VARCHAR(100),
    @IdPkg int,
    @pricePercentage DECIMAL(10, 3),
    @newOfferId int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdCourier int
    DECLARE @CourierStatus int
    DECLARE @PkgStatus int

    SELECT @IdCourier = c.[IdUser], @CourierStatus = [Status]
    FROM [Courier] c
        JOIN [User] u ON (c.[IdUser] = u.[IdUser])
    WHERE u.[Username] = @courierUsername
    IF @@ROWCOUNT = 0 RETURN 1 -- Verify that user is a courier
    IF @CourierStatus != 0 RETURN 2 -- Verify that the courier is not driving

    SELECT @PkgStatus = DeliveryStatus FROM [Package] WHERE [IdPkg] = @IdPkg;
    IF @@ROWCOUNT = 0 RETURN 3 -- Verify that package exists
    IF @PkgStatus != 0 RETURN 4 -- Verify that the offer was not accepted for this package

    IF @pricePercentage IS NULL
    BEGIN
        SELECT @pricePercentage = CONVERT(DECIMAL(10, 3), -10 + (10 - -10) * RAND(CHECKSUM(NEWID())));
    END

    BEGIN TRY
        INSERT INTO [Offer](IdPkg, IdUser, [Percent])
        VALUES (@IdPkg, @IdCourier, @pricePercentage)
        SET @newOfferId = SCOPE_IDENTITY()
    END TRY
    BEGIN CATCH
        RETURN 5 -- Insert failed because of duplicate keys
    END CATCH

    RETURN 0;
END
go

-- Function to calculate distance between two districts
DROP FUNCTION IF EXISTS [fDistrictDistance];
GO

CREATE FUNCTION [fDistrictDistance](
    @IdDistFrom int,
    @IdDistTo int
)
    RETURNS DECIMAL(10, 3)
BEGIN
    RETURN (
        SELECT SQRT(
            SQUARE(dFrom.[CoordinateX] - dTo.[CoordinateX]) +
            SQUARE(dFrom.[CoordinateY] - dTo.[CoordinateY])
        )
        FROM [District] dFrom, [District] dTo
        WHERE dFrom.[IdDist] = @IdDistFrom AND dTo.[IdDist] = @IdDistTo
    )
END
GO

-- Function to calculate the price for the package
DROP FUNCTION IF EXISTS [fDeliveryPrice];
GO

CREATE FUNCTION [fDeliveryPrice](
    @IdPkg int
)
RETURNS DECIMAL(10, 3)
BEGIN
    RETURN (
        SELECT (
            pt.[InitialPrice] + (pt.[WeightFactor] * p.[Weight]) * pt.[PricePerKg]
        ) * [dbo].[fDistrictDistance](IdDistFrom, IdDistTo)
        FROM [Package] p JOIN [PackageType] pt ON (p.[PackageType] = pt.[IdPkgT])
        WHERE p.[IdPkg] = @IdPkg
    )
END
GO

-- Accept offer for package delivery
-- Utility wrapper to avoid two subqueries
DROP PROCEDURE IF EXISTS [spAcceptOffer];
GO

CREATE PROCEDURE [spAcceptOffer]
    @IdOff int
AS
BEGIN
    DECLARE @IdCourier int
    DECLARE @IdPkg int

    SELECT @IdCourier = [IdUser], @IdPkg = [IdPkg] FROM [Offer] WHERE [IdOff] = @IdOff
    IF @@ROWCOUNT = 0 RETURN 1;

    BEGIN TRY
        UPDATE [Package] SET [IdCourier] = @IdCourier WHERE [IdPkg] = @IdPkg
    END TRY
    BEGIN CATCH
        RETURN 2;
    END CATCH

    RETURN 0;
end
GO

-- Select package courier from offer
DROP TRIGGER IF EXISTS [TR_TransportOffer_Confirm]
GO

CREATE TRIGGER [TR_TransportOffer_Confirm]
ON [Package]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS(
        SELECT * FROM INSERTED I JOIN DELETED D ON (I.IdPkg = D.IdPkg)
        WHERE
                I.[IdSender] != D.[IdSender] -- Cannot change sender
            OR  I.[DeliveryStatus] < D.[DeliveryStatus] -- Cannot go to previous states
            OR  (D.[DeliveryStatus] > 0 AND ( -- If was accepted
                 I.[PackageType] != D.[PackageType] OR -- Cannot change type
                 I.[IdDistFrom] != D.[IdDistFrom] OR -- Cannot change origin district
                 I.[IdDistTo] != D.[IdDistTo] OR -- cannot change destination district
                 I.[Weight] != D.[Weight] OR -- cannot change weight
                 I.[IdCourier] IS NULL OR -- cannot unset courier
                 I.[IdCourier] != D.[IdCourier] -- cannot change courier
            ))
    )
    BEGIN
        ROLLBACK TRANSACTION
        RAISERROR ('Invalid column update for current package state', 10, 1);
        RETURN
    END

    DECLARE [@cursorConfirmedPackages] CURSOR LOCAL FOR
    SELECT I.[IdPkg], I.[IdCourier], D.[IdCourier]
    FROM INSERTED I JOIN DELETED D ON (I.IdPkg = D.IdPkg)
    WHERE I.[IdCourier] IS NOT NULL AND D.[IdCourier] IS NULL

    DECLARE @IdPkg int
    DECLARE @IdCourierOld int
    DECLARE @IdCourierNew int

    OPEN [@cursorConfirmedPackages]

    FETCH NEXT FROM [@cursorConfirmedPackages]
    INTO @IdPkg, @IdCourierNew, @IdCourierOld

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @priceFactor DECIMAL(10, 3)
        SELECT @priceFactor = (1 + [Percent] / 100)FROM [Offer]
        WHERE [IdUser] = @IdCourierNew AND [IdPkg] = @IdPkg
        IF @@ROWCOUNT = 0 -- Verify that offer existed for this Courier
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR ('Attempted to accept non-existent offer', 10, 2)
            BREAK
        END
        -- now update the status, price and time
        UPDATE [Package]
        SET
            [DeliveryStatus] = 1,
            [Price] = [dbo].[fDeliveryPrice](@IdPkg) * @priceFactor,
            [TimeAccepted] = GETDATE()
        WHERE [IdPkg] = @IdPkg
        IF @@ROWCOUNT = 0 -- Update failed for unknown reason
        BEGIN
            ROLLBACK TRANSACTION
            RAISERROR ('Failed to set package status, price and date', 10, 3);
            BREAK
        END
        -- and delete all offers for that package
        DELETE FROM [Offer] WHERE [IdPkg] = @IdPkg

        FETCH NEXT FROM [@cursorConfirmedPackages]
        INTO @IdPkg, @IdCourierNew, @IdCourierOld
    END

    CLOSE [@cursorConfirmedPackages]
    DEALLOCATE [@cursorConfirmedPackages]
END
GO

-- Implements driveNextPackage interface method
DROP PROCEDURE IF EXISTS [spDriveNext]
GO

CREATE PROCEDURE [spDriveNext]
    @username VARCHAR(100),
    @result int OUTPUT
AS
BEGIN
    DECLARE @IdCourier int
    DECLARE @Status int

    SELECT @IdCourier = u.[IdUser], @Status = [Status]
    FROM [User] u JOIN [Courier] c ON (u.[IdUser] = c.[IdUser])
    WHERE [Username] = @username
    IF @@ROWCOUNT = 0 -- Not a courier
    BEGIN
        SET @result = -2
        RETURN 1
    END

    BEGIN TRANSACTION
    BEGIN TRY
        IF @Status = 0
        BEGIN
            -- First check that there are packages to drive
            IF NOT EXISTS (
                SELECT * FROM [Package]
                WHERE [IdCourier] = @IdCourier AND [DeliveryStatus] = 1
            )
            BEGIN
                ROLLBACK TRANSACTION
                SET @result = -1
                RETURN 2;
            END
            -- Begin drive
            --------------------------------------------------
            -- Set Courier to driving state
            UPDATE [Courier] SET [Status] = 1 WHERE [IdUser] = @IdCourier
            -- Add Packages into the drive
            INSERT INTO [Drive]([IdUser], [IdPkg])
            SELECT @IdCourier, [IdPkg] FROM [Package]
            WHERE [IdCourier] = @IdCourier AND [DeliveryStatus] = 1
            -- Set all packages as picked up
            UPDATE [Package] SET [DeliveryStatus] = 2
            WHERE [IdCourier] = @IdCourier AND [DeliveryStatus] = 1
        END

        -- Drive the package
        --------------------------------------------------
        -- Find package to deliver
        DECLARE @IdCurrentPkg int = (
            SELECT TOP (1) d.[IdPkg]
            FROM [Drive] d
                JOIN [Package] p ON (d.[IdPkg] = p.[IdPkg])
            WHERE [IdUser] = @IdCourier AND [DeliveryStatus] = 2
            ORDER BY [TimeAccepted], d.[IdPkg]
        )
        -- Mark it as delivered
        UPDATE [Package] SET [DeliveryStatus] = 3 WHERE [IdPkg] = @IdCurrentPkg
        SET @result = @IdCurrentPkg

        -- Update number of delivered packages
        UPDATE [Courier] SET [DeliveredPackages] = [DeliveredPackages] + 1
        WHERE [IdUser] = @IdCourier

        -- If Drive is finished
        IF NOT EXISTS(
            SELECT * FROM [Drive] d JOIN [Package] p ON (d.IdPkg = p.IdPkg)
            WHERE [IdUser] = @IdCourier AND [DeliveryStatus] = 2
        )
        BEGIN
            -- Finish Drive
            --------------------------------------------------
            -- Calculate fuel price per km
            DECLARE @fuelPricePerKm DECIMAL(10, 3)
            SELECT @fuelPricePerKm = [FuelConsumption] * [FuelPrice]
            FROM [Vehicle] v
                     JOIN [Courier] c ON (v.[IdVeh] = c.[IdVeh])
                     JOIN [FuelType] ft ON (v.[FuelType] = ft.[IdFuelT])
            WHERE c.[IdUser] = @IdCourier

            -- Calculate profit and package count
            DECLARE @driveProfit DECIMAL(10, 3);
            WITH Path(price, currFrom, currTo, nextFrom) AS (
                SELECT
                    [Price],
                    [IdDistFrom], [IdDistTo],
                    LEAD(IdDistFrom) OVER (ORDER BY [TimeAccepted])
                FROM [Drive] d JOIN [Package] p ON (d.IdPkg = p.IdPkg)
                WHERE [IdCourier] = @IdCourier
            )
            SELECT
                @driveProfit = SUM(price) - SUM(
                    dbo.[fDistrictDistance](currFrom, currTo) +
                    COALESCE(dbo.[fDistrictDistance](currTo, nextFrom), 0)
                ) * @fuelPricePerKm
            FROM Path

            -- Update courier total profit and package count,
            UPDATE [Courier]
            SET
                [Status] = 0, -- Drive is finished
                [TotalProfit] = [TotalProfit] + @driveProfit
            WHERE [IdUser] = @IdCourier

            -- Delete packages from Drive
            DELETE FROM [Drive] WHERE [IdUser] = @IdCourier
        END

        COMMIT TRANSACTION
        RETURN 0
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        RETURN 3;
    END CATCH
END
GO


DROP TRIGGER IF EXISTS TR_Update_User_SentPackages;
GO

CREATE TRIGGER TR_Update_User_SentPackages
ON [Package]
AFTER INSERT, DELETE
AS
BEGIN
    CREATE TABLE #UpdateList(IdUser int, Count int);

    INSERT INTO #UpdateList SELECT [IdSender], 1 FROM INSERTED

    INSERT INTO #UpdateList SELECT [IdSender], -1 FROM DELETED

    DECLARE [@cursor] CURSOR LOCAL FOR
    SELECT IdUser, Count FROM #UpdateList

    DECLARE @IdUser int
    DECLARE @Count int

    OPEN [@cursor]

    FETCH NEXT FROM [@cursor]
    INTO @IdUser, @Count

    WHILE @@FETCH_STATUS = 0
    BEGIN
        UPDATE [User] SET [SentPackages] = [SentPackages] + @Count
        WHERE [IdUser] = @IdUser

        FETCH NEXT FROM [@cursor]
        INTO @IdUser, @Count
    END

    CLOSE [@cursor]
    DEALLOCATE [@cursor]

END
GO