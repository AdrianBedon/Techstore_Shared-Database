--Authors: Adrián Bedón, Pablo Chasipanta, José Miguel Merlo, Dennis Ocaña, Xavier Ramos
--Date: 2024-11-04
--Version: 1.0.0

----------------------------------------------------------- Tables Section -----------------------------------------------------------
/*************************************************************/
----------------------Creación de tablas----------------------
/*************************************************************/

CREATE TABLE productos (
    IDProducto INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Descripción VARCHAR(250) NOT NULL,
    Precio float NOT NULL
);

CREATE TABLE inventario (
    IDInventario INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    IDProducto INT NOT NULL references productos(IDProducto),
    CantidadDisp INT NOT NULL,
    Ubicacion VARCHAR(250) NOT NULL,
    Estado BIT NOT NULL
);

CREATE TABLE ventas (
    IDVenta INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    IDProducto INT NOT NULL references productos(IDProducto),
    IDInventario INT NOT NULL references inventario(IDInventario),
    CantidadVendida INT NOT NULL,
    FechaVenta TIMESTAMP NOT NULL,
    TiendaOrigen VARCHAR(250) NOT NULL
);

--------------------------------------------------------- End Tables Section ---------------------------------------------------------

---------------------------------------------------------- Procedure Section ----------------------------------------------------------
/**************************************************************************************/
----------------------Procedimiento de actualizacíón de productos----------------------
/**************************************************************************************/

CREATE OR REPLACE PROCEDURE ActualizarProducto(
    p_IDProducto INT,
    p_Nombre VARCHAR(100) DEFAULT NULL,
    p_Descripción VARCHAR(250) DEFAULT NULL,
    p_Precio float DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Revisar si existe el producto
    IF NOT EXISTS (SELECT 1 FROM productos WHERE IDProducto = p_IDProducto) THEN
        raise exception 'Product with ID % does not exist', p_IDProducto;
    END IF;

    -- Actualiza aquellos campos que sean not null
    UPDATE productos
    SET 
        Nombre = coalesce(p_Nombre, Nombre),
        Descripción = coalesce(p_Descripción, Descripción),
        Precio = coalesce(p_Precio, Precio)
    WHERE IDProducto = p_IDProducto;
    
    raise notice 'Producto con ID % actualizado exitosamente', p_IDProducto;
END;
$$;

-------------------------------------------------------- End Procedure Section --------------------------------------------------------

------------------------------------------------------------ View Section ------------------------------------------------------------
/*******************************************************************/
----------------------Vista para el inventario----------------------
/*******************************************************************/

--drop view EstadoInventario;

CREATE VIEW EstadoInventario AS
SELECT 
    i.IDInventario AS "Inventario Nro.",
    p.IDProducto AS "Producto Nro.",
    p.Nombre AS "Nombre del producto",
    p.Descripción AS "Descripción del producto",
    --p.Precio "Precio del producto",
    i.CantidadDisp AS "Cantidad disponible del producto",
    case 
        when i.Estado = '1' THEN 'Disponible'
        else 'No Disponible'
    END AS "Estado del producto",
    i.Ubicacion AS "Ubicacion de la Tienda"
FROM 
    inventario i
JOIN 
    productos p ON i.IDProducto = p.IDProducto;

--------------------------------------------------------- End View Section ---------------------------------------------------------

----------------------------------------------------------- Trigger Section -----------------------------------------------------------
/**************************************************************************/
----------------------Trigger para precio de producto----------------------
/--************************************************************************/

CREATE OR REPLACE FUNCTION PrecioMinimo()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verificar precio > 0
    IF new.Precio < 0 THEN
        raise exception 'El precio del producto no puede ser menor a 0';
    END IF;
    RETURN new;
END;
$$;

CREATE trigger PrecioMayor0
BEFORE insert ON productos
FOR each ROW
EXECUTE FUNCTION PrecioMinimo();

/******************************************************************************************/
----------------------Trigger para cantidad de producto en inventario----------------------
/******************************************************************************************/

CREATE OR REPLACE FUNCTION CantidadMinimaInv()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verificar cantidad > 0
    IF new.CantidadDisp < 0 THEN
        raise exception 'Cantidad en el inventario no puede ser menor a 0';
    END IF;
    RETURN new;
END;
$$;

CREATE trigger CantidadInvMayor0
BEFORE insert ON inventario
FOR each ROW
EXECUTE FUNCTION CantidadMinimaInv();

/*************************************************************************************/
----------------------Trigger para cantidad de producto en venta----------------------
/*************************************************************************************/

CREATE OR REPLACE FUNCTION CantidadMinimaVenta()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verificar cantidad > 0
    IF new.CantidadVendida < 0 THEN
        raise exception 'Cantidad en la venta no puede ser menor a 0';
    END IF;
    RETURN new;
END;
$$;

CREATE trigger CantidadVentaMayor0
BEFORE insert ON ventas
FOR each ROW
EXECUTE FUNCTION CantidadMinimaVenta();

--------------------------------------------------------- End Trigger Section ---------------------------------------------------------