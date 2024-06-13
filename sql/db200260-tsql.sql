-- Insert Courier Request
DROP PROCEDURE IF EXISTS [spInsertCourierRequest];
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
    IF @@ROWCOUNT = 0 RETURN 2; -- Verify that vehicle exists

    -- Verify that user is not already a courier
    IF EXISTS (SELECT [IdUser] FROM [Courier] WHERE [IdUser] = @IdUser) RETURN 3;

    -- Verify that vehicle is not already used, before creating the request
    IF EXISTS (SELECT [IdVeh] FROM [Courier] WHERE [IdVeh] = @IdVeh ) RETURN 4;

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
    IF @@ROWCOUNT = 0 RETURN 1; -- Verify that user exits and has a request

    SELECT @IdVeh = [IdVeh] FROM [Vehicle] WHERE [LicencePlateNumber] = @licencePlateNumber;
    IF @@ROWCOUNT = 0 RETURN 2; -- Verify that vehicle exists

    -- Verify that vehicle is not already used, before creating the request
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
    FROM [CourierRequest] cr JOIN [User] u ON (cr.[IdUser] = u.[IdUser])
    WHERE [Username] = @username;
    IF @@ROWCOUNT = 0 RETURN 1; -- Verify that user exits and that he has a request

    DECLARE @errorcode int
    SET @errorcode = 0
    BEGIN TRY
        -- Insert user as courier
        INSERT INTO [Courier](IdUser, IdVeh) VALUES(@IdUser, @IdVeh)
        IF @@ROWCOUNT != 1 SET @errorcode = 2 -- Verify that the user was inserted

        -- Delete request
        DELETE FROM [CourierRequest] WHERE [IdUser] = @IdUser
        IF @@ROWCOUNT != 1 SET @errorcode = 3 -- Verify that the request was deleted
    END TRY
    BEGIN CATCH
        SET @errorcode = 4
    END CATCH

    IF @errorcode != 0
    BEGIN
        ROLLBACK TRANSACTION;
    END

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
        -- Insert user as courier
        INSERT INTO [Courier](IdUser, IdVeh) VALUES(@IdUser, @IdVeh)
        IF @@ROWCOUNT != 1 SET @errorcode = 3 -- Verify that the user was inserted

        -- Delete request in it existed before
        DELETE FROM [CourierRequest] WHERE [IdUser] = @IdUser
    END TRY
    BEGIN CATCH
        SET @errorcode = 4
    END CATCH

    IF @errorcode != 0
    BEGIN
        ROLLBACK TRANSACTION;
    END

    RETURN @errorcode
END
go

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
    FROM [Courier] c JOIN [User] u ON (c.[IdUser] = u.[IdUser])
    WHERE u.[Username] = @courierUsername
    IF @@ROWCOUNT = 0 RETURN 1 -- Verify that user is a courier
    IF @CourierStatus != 0 RETURN 2 -- Verify that the courier is not driving

    SELECT @PkgStatus = DeliveryStatus FROM [Package] WHERE [IdPkg] = @IdPkg;
    IF @@ROWCOUNT = 0 RETURN 3 -- Verify that package exists
    IF @PkgStatus != 0 RETURN 4 -- Verify that the offer was not accepted for this package

    IF @pricePercentage IS NULL
    BEGIN
        SELECT @pricePercentage =  CONVERT(DECIMAL(10,3), -10 + (10 - -10)*RAND(CHECKSUM(NEWID())));
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

-- Function to calculate the price for the package
DROP FUNCTION IF EXISTS [fDeliveryPrice];
GO

CREATE FUNCTION [fDeliveryPrice](
    @IdPkg int
)
    RETURNS DECIMAL(10, 3)
BEGIN
    DECLARE @fromDistX DECIMAL(10, 3)
    DECLARE @fromDistY DECIMAL(10, 3)
    DECLARE @toDistX DECIMAL(10, 3)
    DECLARE @toDistY DECIMAL (10, 3)
    DECLARE @weight DECIMAL(10, 3)
    DECLARE @basePrice DECIMAL(10, 3)
    DECLARE @pricePerKg DECIMAL(10, 3)
    DECLARE @weightFactor DECIMAL(10, 3)

    SELECT
        @fromDistX = dFrom.[CoordinateX],
        @fromDistY = dFrom.[CoordinateY],
        @toDistX = dTo.[CoordinateX],
        @toDistY = dTo.[CoordinateX],
        @weight = p.[Weight],
        @basePrice = pt.InitialPrice,
        @pricePerKg = pt.PricePerKg,
        @weightFactor = pt.WeightFactor
    FROM [Package] p
             JOIN [District] dFrom ON (p.[IdDistFrom] = dFrom.[IdDist])
             JOIN [District] dTo ON (p.[IdDistTo] = dTo.[IdDist])
             JOIN [PackageType] pt ON (p.[PackageType] = pt.IdPkgT)
    WHERE p.[IdPkg] = @IdPkg

    -- Calculate euclidean distance
    DECLARE @distance DECIMAL(10, 3)
    SET @distance = SQRT(SQUARE(@fromDistX - @toDistX) + SQUARE(@fromDistY - @toDistY))

    RETURN (@basePrice + (@weightFactor * @weight) * @pricePerKg) * @distance
END
GO

DROP PROCEDURE IF EXISTS [spAcceptOffer];
GO

CREATE PROCEDURE [spAcceptOffer]
    @IdOff int
AS
BEGIN
    DECLARE @IdCourier int
    DECLARE @IdPkg int

    SELECT
        @IdCourier = [IdUser],
        @IdPkg = [IdPkg]
    FROM [Offer] WHERE [IdOff] = @IdOff
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
    ON  [Package]
    AFTER UPDATE
    AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS(
        SELECT *
        FROM INSERTED I JOIN DELETED D ON (I.IdPkg = D.IdPkg)
        WHERE
                I.[IdSender] != D.[IdSender] -- Cannot change sender
           OR	I.[DeliveryStatus] < D.[DeliveryStatus] -- Cannot go to previous states
           OR	(D.[DeliveryStatus] > 0 AND ( -- If was accepted
                I.[PackageType] != D.[PackageType] OR -- Cannot change type
                I.[IdDistFrom] != D.[IdDistTo] OR -- Cannot change origin district
                I.[IdDistTo] != D.[IdDistTo] OR -- cannot change destination district
                I.[Weight] != D.[Weight] OR -- cannot change weight
                i.[IdCourier] IS NULL OR -- cannot unset courier
                I.[IdCourier] != D.[IdCourier] -- cannot change courier
            ))
    )
        BEGIN
            ROLLBACK TRANSACTION
            RAISERROR ('Invalid column update for current package state', 10, 1);
            RETURN
        END

    DECLARE cursorConfirmedPacakges CURSOR FOR
        SELECT I.[IdPkg], I.[IdCourier], D.[IdCourier]
        FROM INSERTED I JOIN DELETED D ON (I.IdPkg = D.IdPkg)
        WHERE I.[IdCourier] IS NOT NULL AND D.[IdCourier] IS NULL

    DECLARE @IdPkg int
    DECLARE @IdCourierOld int
    DECLARE @IdCourierNew int

    OPEN cursorConfirmedPacakges

    FETCH NEXT FROM cursorConfirmedPacakges
        INTO @IdPkg, @IdCourierOld, @IdCourierNew

    WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @priceFactor DECIMAL(10, 3)
            SELECT @priceFactor = (1 + [Percent] / 100) FROM [Offer]
            WHERE [IdUser] = @IdCourierNew AND [IdPkg] = @IdPkg
            IF @@ROWCOUNT = 0 -- Verify that offer existed for this Courier
                BEGIN
                    ROLLBACK TRANSACTION;
                    RAISERROR('Attempted to accept non-existent offer', 10, 2)
                    RETURN
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
                    RAISERROR ('Failed to set package price and date', 10, 3);
                    RETURN
                END

            -- and delete all offers for that package
            DELETE FROM [Offer] WHERE [IdPkg] = @IdPkg

            FETCH NEXT FROM cursorConfirmedPacakges
                INTO @IdPkg, @IdCourierOld, @IdCourierNew
        END

    CLOSE cursorConfirmedPacakges
    DEALLOCATE cursorConfirmedPacakges
END
GO
