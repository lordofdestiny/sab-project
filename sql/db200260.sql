
CREATE TYPE [MyDecimal]
    FROM DECIMAL(10,3) NOT NULL
go

CREATE TYPE [CourierStatus]
    FROM INTEGER NOT NULL
go

CREATE TYPE [DeliveryStatus]
    FROM INTEGER NOT NULL
go

CREATE TABLE [Admin]
(
    [IdUser]             integer  NOT NULL
)
go

CREATE TABLE [City]
(
    [IdCity]             integer  IDENTITY ( 1,1 )  NOT NULL ,
    [PostalCode]         varchar(100)  NOT NULL ,
    [Name]               varchar(100)  NOT NULL
)
go

CREATE TABLE [Courier]
(
    [IdUser]             integer  NOT NULL
        CONSTRAINT [DF_Zero_573303825]
            DEFAULT  0,
    [DeliveredPackages]  integer  NOT NULL
        CONSTRAINT [DF_Zero_892127923]
            DEFAULT  0
        CONSTRAINT [CK_GreaterThanOrEqualToZero_1027783113]
            CHECK  ( DeliveredPackages >= 0 ),
    [TotalProfit]        [MyDecimal]
        CONSTRAINT [DF_Zero_1973267804]
            DEFAULT  0
        CONSTRAINT [CK_GreaterThanOrEqualToZero_2108922994]
            CHECK  ( TotalProfit >= 0 ),
    [Status]             [CourierStatus]
        CONSTRAINT [DF_Zero_287304439]
            DEFAULT  0,
    [IdVeh]              integer  NOT NULL
)
go

ALTER TABLE [Courier]
    WITH CHECK ADD CONSTRAINT [CK_Courier_Status_253687243] CHECK  ( [Status]=0 OR [Status]=1 )
go

CREATE TABLE [CourierRequest]
(
    [IdUser]             integer  NOT NULL ,
    [IdVeh]              integer  NOT NULL
)
go

CREATE TABLE [District]
(
    [IdDist]             integer  IDENTITY ( 1,1 )  NOT NULL ,
    [IdCity]             integer  NOT NULL ,
    [CoordinateX]        [MyDecimal]  NOT NULL ,
    [CoordinateY]        [MyDecimal]  NOT NULL ,
    [Name]               varchar(100)  NOT NULL
)
go

CREATE TABLE [FuelType]
(
    [IdFuelT]            integer  NOT NULL ,
    [Description]        varchar(100)  NOT NULL ,
    [FuelPrice]          [MyDecimal]  NOT NULL
        CONSTRAINT [GreaterThanZero_1486860202]
            CHECK  ( FuelPrice > 0 )
)
go

CREATE TABLE [Offer]
(
    [IdPkg]              integer  NOT NULL
        CONSTRAINT [GreaterThanZero_659841506]
            CHECK  ( IdPkg > 0 ),
    [IdUser]             integer  NOT NULL ,
    [PercentOffer]       char(18)  NOT NULL
        CONSTRAINT [CK_GreaterThanOrEqualToZero_957770346]
            CHECK  ( PercentOffer >= 0 )
)
go

CREATE TABLE [Package]
(
    [IdPkg]              integer  IDENTITY ( 1,1 )  NOT NULL ,
    [IdDistFrom]         integer  NOT NULL ,
    [IdDistTo]           integer  NOT NULL ,
    [IdSender]           integer  NOT NULL ,
    [Weight]             [MyDecimal]  NOT NULL
        CONSTRAINT [GreaterThanZero_1682187296]
            CHECK  ( Weight > 0 ),
    [PackageType]        integer  NOT NULL ,
    [DeliveryStatus]     [DeliveryStatus]
        CONSTRAINT [DF_Zero_1095575363]
            DEFAULT  0,
    [IdCourier]          integer  NULL
        CONSTRAINT [DF_NULL_350091192]
            DEFAULT  NULL,
    [Price]              [MyDecimal]  NULL
        CONSTRAINT [DF_NULL_1874707671]
            DEFAULT  NULL
        CONSTRAINT [GreaterThanZero_833478113]
            CHECK  ( Price > 0 ),
    [TimeAccepted]       datetime  NULL
        CONSTRAINT [DF_NULL_1175160234]
            DEFAULT  NULL
)
go

ALTER TABLE [Package]
    WITH CHECK ADD CONSTRAINT [CK_Package_DeliveryStatus_1953536455] CHECK  ( [DeliveryStatus]=0 OR [DeliveryStatus]=1 OR [DeliveryStatus]=2 OR [DeliveryStatus]=3 )
go

CREATE TABLE [PackageType]
(
    [IdPkgT]             integer  NOT NULL ,
    [Description]        varchar(100)  NOT NULL ,
    [InitialPrice]       integer  NOT NULL ,
    [WeightFactor]       integer  NOT NULL ,
    [PricePerKg]         integer  NOT NULL
)
go

CREATE TABLE [Ride]
(
    [IdRide]             integer  IDENTITY ( 1,1 )  NOT NULL ,
    [IdUser]             integer  NOT NULL ,
    [Profit]             [MyDecimal]
        CONSTRAINT [DF_Zero_1434614566]
            DEFAULT  0
        CONSTRAINT [CK_GreaterThanOrEqualToZero_1570269756]
            CHECK  ( Profit >= 0 )
)
go

CREATE TABLE [RidePackages]
(
    [IdPkg]              integer  NOT NULL ,
    [IdRide]             integer  NOT NULL
)
go

CREATE TABLE [User]
(
    [IdUser]             integer  IDENTITY ( 1,1 )  NOT NULL ,
    [FirstName]          varchar(100)  NOT NULL ,
    [LastName]           varchar(100)  NOT NULL ,
    [Username]           varchar(100)  NOT NULL ,
    [Password]           varchar(100)  NOT NULL ,
    [SentPackages]       integer  NOT NULL
        CONSTRAINT [DF_Zero_537156203]
            DEFAULT  0
        CONSTRAINT [CK_GreaterThanOrEqualToZero_401501013]
            CHECK  ( SentPackages >= 0 )
)
go

CREATE TABLE [Vehicle]
(
    [IdVeh]              integer  IDENTITY ( 1,1 )  NOT NULL ,
    [FuelConsumption]    [MyDecimal]  NOT NULL
        CONSTRAINT [GreaterThanZero_1800700368]
            CHECK  ( FuelConsumption > 0 ),
    [LicencePlateNumber] varchar(100)  NOT NULL ,
    [FuelType]           integer  NOT NULL
)
go

CREATE UNIQUE CLUSTERED INDEX [XPKAdmin] ON [Admin]
    (
     [IdUser]              ASC
        )
go

CREATE UNIQUE NONCLUSTERED INDEX [XIF1Admin] ON [Admin]
    (
     [IdUser]              ASC
        )
go

CREATE UNIQUE CLUSTERED INDEX [XPKCity] ON [City]
    (
     [IdCity]              ASC
        )
go

ALTER TABLE [City]
    ADD CONSTRAINT [XAK_City_Name] UNIQUE ([Name]  ASC)
go

ALTER TABLE [City]
    ADD CONSTRAINT [XAK_City_PostalCode] UNIQUE ([PostalCode]  ASC)
go

CREATE UNIQUE CLUSTERED INDEX [XPKCourier] ON [Courier]
    (
     [IdUser]              ASC
        )
go

ALTER TABLE [Courier]
    ADD CONSTRAINT [XAK1Courier_IdVeh] UNIQUE ([IdVeh]  ASC)
go

CREATE UNIQUE NONCLUSTERED INDEX [XIF1Courier] ON [Courier]
    (
     [IdUser]              ASC
        )
go

CREATE NONCLUSTERED INDEX [XIF2Courier] ON [Courier]
    (
     [IdVeh]               ASC
        )
go

CREATE UNIQUE CLUSTERED INDEX [XPKCourierRequest] ON [CourierRequest]
    (
     [IdUser]              ASC
        )
go

CREATE UNIQUE NONCLUSTERED INDEX [XIF1CourierRequest] ON [CourierRequest]
    (
     [IdUser]              ASC
        )
go

CREATE NONCLUSTERED INDEX [XIF2CourierRequest] ON [CourierRequest]
    (
     [IdVeh]               ASC
        )
go

CREATE UNIQUE CLUSTERED INDEX [XPKDistrict] ON [District]
    (
     [IdDist]              ASC
        )
go

CREATE NONCLUSTERED INDEX [XIF1District] ON [District]
    (
     [IdCity]              ASC
        )
go

CREATE UNIQUE CLUSTERED INDEX [XPKFuelType] ON [FuelType]
    (
     [IdFuelT]             ASC
        )
go

CREATE UNIQUE CLUSTERED INDEX [XPKOffer] ON [Offer]
    (
     [IdPkg]               ASC,
     [IdUser]              ASC
        )
go

CREATE NONCLUSTERED INDEX [XIF1Offer] ON [Offer]
    (
     [IdPkg]               ASC
        )
go

CREATE NONCLUSTERED INDEX [XIF2Offer] ON [Offer]
    (
     [IdUser]              ASC
        )
go

CREATE UNIQUE CLUSTERED INDEX [XPKPackage] ON [Package]
    (
     [IdPkg]               ASC
        )
go

CREATE NONCLUSTERED INDEX [XIF1Package] ON [Package]
    (
     [IdDistFrom]          ASC
        )
go

CREATE NONCLUSTERED INDEX [XIF2Package] ON [Package]
    (
     [IdDistTo]            ASC
        )
go

CREATE NONCLUSTERED INDEX [XIF3Package] ON [Package]
    (
     [IdSender]            ASC
        )
go

CREATE NONCLUSTERED INDEX [XIF4Package] ON [Package]
    (
     [PackageType]         ASC
        )
go

CREATE NONCLUSTERED INDEX [XIF5Package] ON [Package]
    (
     [IdCourier]           ASC
        )
go

CREATE UNIQUE CLUSTERED INDEX [XPKPackageType] ON [PackageType]
    (
     [IdPkgT]              ASC
        )
go

CREATE UNIQUE CLUSTERED INDEX [XPKRide] ON [Ride]
    (
     [IdRide]              ASC
        )
go

CREATE NONCLUSTERED INDEX [XIF1Ride] ON [Ride]
    (
     [IdUser]              ASC
        )
go

CREATE UNIQUE CLUSTERED INDEX [XPKRidePackages] ON [RidePackages]
    (
     [IdPkg]               ASC,
     [IdRide]              ASC
        )
go

CREATE NONCLUSTERED INDEX [XIF1RidePackages] ON [RidePackages]
    (
     [IdPkg]               ASC
        )
go

CREATE NONCLUSTERED INDEX [XIF2RidePackages] ON [RidePackages]
    (
     [IdRide]              ASC
        )
go

CREATE UNIQUE CLUSTERED INDEX [XPKUser] ON [User]
    (
     [IdUser]              ASC
        )
go

ALTER TABLE [User]
    ADD CONSTRAINT [XAK_User_Username] UNIQUE ([Username]  ASC)
go

CREATE UNIQUE CLUSTERED INDEX [XPKVehicle] ON [Vehicle]
    (
     [IdVeh]               ASC
        )
go

ALTER TABLE [Vehicle]
    ADD CONSTRAINT [XAK1Vehicle_Unique_LicencePlateNumber] UNIQUE ([LicencePlateNumber]  ASC)
go

CREATE NONCLUSTERED INDEX [XIF1Vehicle] ON [Vehicle]
    (
     [FuelType]            ASC
        )
go


ALTER TABLE [Admin]
    ADD CONSTRAINT [R_2] FOREIGN KEY ([IdUser]) REFERENCES [User]([IdUser])
        ON DELETE CASCADE
        ON UPDATE CASCADE
go


ALTER TABLE [Courier]
    ADD CONSTRAINT [R_3] FOREIGN KEY ([IdUser]) REFERENCES [User]([IdUser])
        ON DELETE CASCADE
        ON UPDATE CASCADE
go

ALTER TABLE [Courier]
    ADD CONSTRAINT [R_28] FOREIGN KEY ([IdVeh]) REFERENCES [Vehicle]([IdVeh])
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
go


ALTER TABLE [CourierRequest]
    ADD CONSTRAINT [R_4] FOREIGN KEY ([IdUser]) REFERENCES [User]([IdUser])
        ON DELETE NO ACTION
        ON UPDATE CASCADE
go

ALTER TABLE [CourierRequest]
    ADD CONSTRAINT [R_5] FOREIGN KEY ([IdVeh]) REFERENCES [Vehicle]([IdVeh])
        ON DELETE NO ACTION
        ON UPDATE CASCADE
go


ALTER TABLE [District]
    ADD CONSTRAINT [R_1] FOREIGN KEY ([IdCity]) REFERENCES [City]([IdCity])
        ON DELETE NO ACTION
        ON UPDATE CASCADE
go


ALTER TABLE [Offer]
    ADD CONSTRAINT [R_18] FOREIGN KEY ([IdPkg]) REFERENCES [Package]([IdPkg])
        ON DELETE CASCADE
        ON UPDATE CASCADE
go

ALTER TABLE [Offer]
    ADD CONSTRAINT [R_19] FOREIGN KEY ([IdUser]) REFERENCES [Courier]([IdUser])
        ON DELETE CASCADE
        ON UPDATE CASCADE
go


ALTER TABLE [Package]
    ADD CONSTRAINT [R_11] FOREIGN KEY ([IdDistFrom]) REFERENCES [District]([IdDist])
        ON DELETE NO ACTION
        ON UPDATE CASCADE
go

ALTER TABLE [Package]
    ADD CONSTRAINT [R_13] FOREIGN KEY ([IdDistTo]) REFERENCES [District]([IdDist])
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
go

ALTER TABLE [Package]
    ADD CONSTRAINT [R_14] FOREIGN KEY ([IdSender]) REFERENCES [User]([IdUser])
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
go

ALTER TABLE [Package]
    ADD CONSTRAINT [R_15] FOREIGN KEY ([PackageType]) REFERENCES [PackageType]([IdPkgT])
        ON DELETE NO ACTION
        ON UPDATE CASCADE
go

ALTER TABLE [Package]
    ADD CONSTRAINT [R_21] FOREIGN KEY ([IdCourier]) REFERENCES [Courier]([IdUser])
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
go


ALTER TABLE [Ride]
    ADD CONSTRAINT [R_23] FOREIGN KEY ([IdUser]) REFERENCES [Courier]([IdUser])
        ON DELETE CASCADE
        ON UPDATE CASCADE
go


ALTER TABLE [RidePackages]
    ADD CONSTRAINT [R_24] FOREIGN KEY ([IdPkg]) REFERENCES [Package]([IdPkg])
        ON DELETE CASCADE
        ON UPDATE CASCADE
go

ALTER TABLE [RidePackages]
    ADD CONSTRAINT [R_25] FOREIGN KEY ([IdRide]) REFERENCES [Ride]([IdRide])
        ON DELETE CASCADE
        ON UPDATE CASCADE
go


ALTER TABLE [Vehicle]
    ADD CONSTRAINT [R_17] FOREIGN KEY ([FuelType]) REFERENCES [FuelType]([IdFuelT])
        ON DELETE NO ACTION
        ON UPDATE CASCADE
go
