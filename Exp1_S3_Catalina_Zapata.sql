-- || CASE 1 ||

ACCEPT VALOR_ARRIENDO_USER PROMPT 'Ingrese el valor corte de arriendo:' -- Variable de sustitución para que el usuario ingrese el valor maximo de arriendo

SELECT
    NRO_PROPIEDAD AS "PROPIEDAD",
    
    DIRECCION_PROPIEDAD AS "DIRECCION",
    
    TO_CHAR (VALOR_ARRIENDO, 'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS = '',.''') AS ARRIENDO, -- Formato para que se vea con $ y puntos cada 3 numeros
    
    CASE -- Gastos comunes actuales, tiene variables de manejo de NULL y de formato
        WHEN VALOR_GASTO_COMUN IS NULL THEN '(null)'
        ELSE TO_CHAR(VALOR_GASTO_COMUN, 'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS = '',.''')
        END AS "GGCC_ACTUAL",
        
    CASE -- Mismo que arriba pero agrega el 10% de aumento en una nueva columna
        WHEN VALOR_GASTO_COMUN IS NULL THEN '(null)'
        ELSE TO_CHAR(ROUND(VALOR_GASTO_COMUN * 1.1), 'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS = '',.''')
    END AS "GGCC_AJUSTADO",
    
    'Propiedad ubicada en comuna ' || ID_COMUNA AS "UBICACION" -- Agrega "Propiedad ubicada en comuna" al inicio
    
    FROM PROPIEDAD
    
    WHERE 
        VALOR_ARRIENDO < &VALOR_MAXIMO -- Filtro por la variable ingresada
        AND NRO_DORMITORIOS IS NOT NULL -- Filtro de valores no nulos
        AND ID_COMUNA IN (82, 84, 87) -- Filtro de comunas especificas
        
    ORDER BY -- Ordena gastos comunes ascendente (nulos al final) y arriendo de forma descendente
        VALOR_GASTO_COMUN ASC NULLS LAST,
        VALOR_ARRIENDO DESC

-- || CASE 2 ||

ACCEPT DIAS_MIN PROMPT 'Por favor ingrese el número mínimo de días de arriendo:'  -- Variable de sustitución para el mínimo de días arrendados

SELECT
    NRO_PROPIEDAD AS "Propiedad",
    
    NUMRUT_CLI AS "Código Arrendatario",
    
    TO_CHAR(FECINI_ARRIENDO, 'DD.mon.YYYY') as "Fecha Inicio Arriendo", -- Formato de fecha para que sea como la tabla solicitada
    
    NVL(TO_CHAR(FECTER_ARRIENDO, 'DD.mon.YYYY'), 'PROPIEDAD ACTUALMENTE ARRENDADA') as "Fecha Término Arriendo", -- Nuevamente formato de fecha para que sea como la tabla
    
    TO_CHAR(ROUND(NVL(fecter_arriendo, SYSDATE) - fecini_arriendo), 'FM999G999G999', 'NLS_NUMERIC_CHARACTERS = '',.''') AS "Dias Arriendo", -- Calculo de dias usando SYSDATE si es nula y con formato en los miles
    
    TRUNC(MONTHS_BETWEEN(NVL(fecter_arriendo, SYSDATE), fecini_arriendo) / 12) AS "Años Arriendo", -- Calculo de años. Meses entre fechas dividido en 12 y truncado sin decimales
    
   CASE  -- Expresión condicional para clasificar el estado según los años calculados
        WHEN TRUNC(MONTHS_BETWEEN(NVL(fecter_arriendo, SYSDATE), fecini_arriendo) / 12) >= 10 THEN 'COMPROMISO DE VENTA'
        WHEN TRUNC(MONTHS_BETWEEN(NVL(fecter_arriendo, SYSDATE), fecini_arriendo) / 12) BETWEEN 5 AND 9 THEN 'CLIENTE ANTIGUO'
        ELSE 'CLIENTE NUEVO'
        END AS "Clasificación Estado"
    
FROM ARRIENDO_PROPIEDAD

WHERE -- Restricción de datos utilizando el cálculo de días y la variable de sustitución
    ROUND(NVL(fecter_arriendo, SYSDATE) - fecini_arriendo) >= &DIAS_MIN
    
ORDER BY -- Ordena de descendente por dias de arriendo
    ROUND(NVL(fecter_arriendo, SYSDATE) - fecini_arriendo) DESC

-- || CASE 3 ||

ACCEPT VALOR_MIN PROMPT 'Ingrese el valor de arriendo promedio mínimo: ' -- Variable de sustitucion para filtrar el promedio minimo

SELECT 
    id_tipo_propiedad AS "TIPO PROPIEDAD",
    
    CASE id_tipo_propiedad  -- Condicion para dar descripcion al tipo de propiedad
        WHEN 'A' THEN 'Casa'
        WHEN 'B' THEN 'Departamento'
        WHEN 'C' THEN 'Local'
        WHEN 'D' THEN 'Parcela sin casa'
        WHEN 'E' THEN 'Parcela con casa'
    END AS "DESCRIPCION",
    
    TO_CHAR(ROUND(AVG(valor_gasto_comun)), 'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS = '',.''') AS "PROMEDIO GASTO COMUN", -- Funcion de agrupacion, con formato y redondeo
    
    COUNT(nro_propiedad) AS "CANTIDAD PROPIEDADES", -- Funcion de agrupacion con conteo
    
    TO_CHAR(ROUND(AVG(valor_arriendo)), 'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS = '',.''') AS "PROMEDIO VALOR ARRIENDO" -- Promedio de arriendo con formato y redondeado
    
    FROM PROPIEDAD   
    
    GROUP BY -- Agrupacion de datos para todas las columnas que no tienen funciones de grupos
        id_tipo_propiedad,
        CASE id_tipo_propiedad
            WHEN 'A' THEN 'Casa'
            WHEN 'B' THEN 'Departamento'
            WHEN 'C' THEN 'Local'
            WHEN 'D' THEN 'Parcela sin casa'
            WHEN 'E' THEN 'Parcela con casa'
        END
        
    HAVING -- Restriccion de datos usando el promedio calculado y la variable de sustitucion
    ROUND(AVG(VALOR_ARRIENDO)) >= &VALOR_MIN
    
    ORDER BY -- Ordena ascendente por tipo de propiedad y descendente por promedio de arriendo 
        id_tipo_propiedad ASC, 
        ROUND(AVG(valor_arriendo)) DESC

   
