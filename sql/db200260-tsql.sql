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
