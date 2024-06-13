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
    IF EXISTS (SELECT [IdVeh] FROM [Courier] WHERE [IdVeh] = @IdVeh) RETURN 4;

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

-- Select package courier from offer
