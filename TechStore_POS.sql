--Authors: Adrián Bedón, Pablo Chasipanta, José Miguel Merlo, Dennis Ocaña, Xavier Ramos
--Date: 2024-11-04
--Version: 1.0.0

/******************************************************************/
----------------------Procedimiento de ventas----------------------
/******************************************************************/

CREATE OR REPLACE PROCEDURE ResgitrarVenta(
    p_IDProducto INT,
    p_IDInventario INT,
    p_CantidadVendida INT,
    p_FechaVenta TIMESTAMP,
    p_TiendaOrigen VARCHAR(250)
) 
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verificar si hay stock
    IF (SELECT CantidadDisp FROM inventario WHERE IDInventario = p_IDInventario AND IDProducto = p_IDProducto) < p_CantidadVendida THEN
        raise exception 'Stock insuficiente en inventario IDInventario % para el producto IDProducto %', p_IDInventario, p_IDProducto;
    END IF;

    -- Insertar la venta
    INSERT INTO ventas (IDProducto, IDInventario, CantidadVendida, FechaVenta, TiendaOrigen)
    VALUES (p_IDProducto, p_IDInventario, p_CantidadVendida, p_FechaVenta, p_TiendaOrigen);

    -- Actualizar el inventario
    UPDATE inventario
    SET CantidadDisp = CantidadDisp - p_CantidadVendida
    WHERE IDInventario = p_IDInventario AND IDProducto = p_IDProducto;

END;
$$;

/**********************************************************************************/
----------------------Trigger para disponibilidad de producto----------------------
/**********************************************************************************/

CREATE OR REPLACE FUNCTION statusInventario()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- revisar la cantidad de producto
    IF new.CantidadDisp <= 0 THEN
        new.Estado := 0;
    else
        new.Estado := 1;
    END IF;
    
    RETURN new;
END;
$$;

CREATE trigger updateEstadoInventario
BEFORE UPDATE of CantidadDisp on inventario
FOR each ROW
EXECUTE FUNCTION statusInventario();

/************************************************************/
----------------------Vista para ventas----------------------
/************************************************************/

--drop view infoVentas;

CREATE VIEW InfoVentas AS
SELECT 
    v.IDVenta AS "Venta Nro.",
    v.IDProducto AS "Producto Nro.",
    p.Nombre AS "Nombre del producto",
    p.Descripción AS "Descripción del producto",
    p.Precio AS "Precio del producto",
    v.CantidadVendida AS "Cantidad vendida del producto",
    v.FechaVenta AS "Fecha de venta",
    v.TiendaOrigen AS "Tienda de venta"
FROM 
    ventas v
JOIN 
    productos p ON v.IDProducto = p.IDProducto;