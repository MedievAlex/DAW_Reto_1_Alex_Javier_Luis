USE reto_2daw;

-- ============================================================
-- DATOS DE PRUEBA - RETO 2DAW
-- ============================================================


-- ============================================================
-- 1. USUARIOS
-- ============================================================

INSERT INTO usuarios
    (nombre, apellidos, nombre_usuario, password_hash, rol)
VALUES
    ('Ana', 'Garcia Lopez', 'agarcia',
     '$2y$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ123456',
     'ADMIN'),

    ('Iker', 'Martinez Gomez', 'imartinez',
     '$2y$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ123457',
     'USER'),

    ('Maite', 'Rodriguez Perez', 'mrodriguez',
     '$2y$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ123458',
     'USER'),

    ('Jon', 'Sanchez Ruiz', 'jsanchez',
     '$2y$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ123459',
     'USER'),

    ('Laura', 'Fernandez Martin', 'lfernandez',
     '$2y$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ123450',
     'USER');


-- ============================================================
-- 2. UBICACIONES
-- ============================================================
-- Almacen ya existe porque lo crea el script principal.
-- No lo volvemos a insertar.

INSERT INTO ubicaciones
    (nombre, descripcion)
VALUES
    ('Aula 101', 'Aula de informatica de primer curso'),

    ('Aula 102', 'Aula de informatica de segundo curso'),

    ('Aula 103', 'Aula de informatica para proyectos'),

    ('Sala de Profesores', 'Sala destinada al personal docente'),

    ('Despacho Direccion', 'Despacho de direccion'),

    ('Laboratorio', 'Laboratorio de pruebas y sistemas'),

    ('Salon de Actos', 'Espacio para presentaciones y eventos');


-- ============================================================
-- 3. EQUIPAMIENTOS
-- ============================================================
-- IMPORTANTE:
-- Aunque indiquemos una ubicacion, el trigger
-- trg_equipamiento_ubicacion_inicial obliga a que todos
-- los equipos nuevos comiencen en Almacen.
--
-- Por tanto, todos estos equipos comenzaran en Almacen.


INSERT INTO equipamientos
    (nombre, descripcion, marca, modelo, categoria, id_ubicacion_actual)
VALUES
    (
        'Portatil Profesor 01',
        'Portatil utilizado por el profesorado',
        'Lenovo',
        'ThinkPad E15',
        'PORTATIL',
        1
    ),

    (
        'Portatil Alumno 01',
        'Portatil para uso de alumnado',
        'HP',
        '250 G9',
        'PORTATIL',
        1
    ),

    (
        'Ordenador Sobremesa 01',
        'Equipo de sobremesa del aula',
        'Dell',
        'OptiPlex 7010',
        'SOBREMESA',
        1
    ),

    (
        'Ordenador Sobremesa 02',
        'Equipo de sobremesa del aula',
        'Dell',
        'OptiPlex 7010',
        'SOBREMESA',
        1
    ),

    (
        'Monitor 24 Pulgadas 01',
        'Monitor externo para puesto informatico',
        'LG',
        '24MP400',
        'PERIFERICO',
        1
    ),

    (
        'Teclado USB 01',
        'Teclado USB para ordenador',
        'Logitech',
        'K120',
        'PERIFERICO',
        1
    ),

    (
        'Proyector Aula 101',
        'Proyector utilizado para las clases',
        'Epson',
        'EB-E01',
        'AUDIOVISUAL',
        1
    ),

    (
        'Altavoces Salon Actos',
        'Sistema de altavoces para eventos',
        'Logitech',
        'Z333',
        'AUDIOVISUAL',
        1
    ),

    (
        'Webcam Aula',
        'Camara web para videoconferencias',
        'Logitech',
        'C920',
        'PERIFERICO',
        1
    ),

    (
        'Material Electronico',
        'Material diverso para mantenimiento',
        'Varios',
        'Lote 01',
        'OTROS',
        1
    );


-- ============================================================
-- 4. NOTIFICACIONES
-- ============================================================
-- Solo los usuarios USER pueden crear notificaciones.
-- Por eso utilizamos los usuarios 2, 3, 4 y 5.
--
-- El trigger obliga a que todas las nuevas notificaciones
-- comiencen en estado PENDIENTE.


INSERT INTO notificaciones
    (titulo, descripcion, fecha_creacion, estado, id_usuario)
VALUES
    (
        'Ordenador no enciende',
        'El ordenador del Aula 101 no se enciende correctamente.',
        '2026-09-15 09:15:00',
        'PENDIENTE',
        2
    ),

    (
        'Proyector con problemas',
        'El proyector del Aula 101 muestra una imagen con poca luminosidad.',
        '2026-09-16 10:30:00',
        'PENDIENTE',
        3
    ),

    (
        'Teclado defectuoso',
        'El teclado del puesto 05 no responde correctamente.',
        '2026-09-17 11:00:00',
        'PENDIENTE',
        4
    ),

    (
        'Cambio de monitor',
        'Se solicita sustituir el monitor del puesto 08.',
        '2026-09-18 12:15:00',
        'PENDIENTE',
        5
    ),

    (
        'Problema de red',
        'El equipo del Aula 102 no tiene conexion a Internet.',
        '2026-09-19 08:45:00',
        'PENDIENTE',
        2
    );


-- ============================================================
-- 5. CAMBIAR ESTADOS DE ALGUNAS NOTIFICACIONES
-- ============================================================
-- Ahora podemos cambiar el estado después de crearlas.


UPDATE notificaciones
SET estado = 'EN_PROCESO'
WHERE id_notificacion = 2;

UPDATE notificaciones
SET estado = 'REALIZADA'
WHERE id_notificacion = 3;


-- ============================================================
-- 6. TRASLADAR EQUIPAMIENTOS
-- ============================================================
-- IMPORTANTE:
-- Estos UPDATE activan automáticamente el trigger
-- trg_equipamiento_traslado.
--
-- El trigger:
--   1. Cierra la ubicacion anterior.
--   2. Crea una nueva fila en el historico.
--
-- Los IDs de ubicacion son:
--
-- 1 = Almacen
-- 2 = Aula 101
-- 3 = Aula 102
-- 4 = Aula 103
-- 5 = Sala de Profesores
-- 6 = Despacho Direccion
-- 7 = Laboratorio
-- 8 = Salon de Actos


-- Portatil Profesor 01 -> Sala de Profesores
UPDATE equipamientos
SET id_ubicacion_actual = 5
WHERE id_equipamiento = 1;


-- Portatil Alumno 01 -> Aula 101
UPDATE equipamientos
SET id_ubicacion_actual = 2
WHERE id_equipamiento = 2;


-- Ordenador Sobremesa 01 -> Aula 101
UPDATE equipamientos
SET id_ubicacion_actual = 2
WHERE id_equipamiento = 3;


-- Ordenador Sobremesa 02 -> Aula 102
UPDATE equipamientos
SET id_ubicacion_actual = 3
WHERE id_equipamiento = 4;


-- Monitor -> Aula 103
UPDATE equipamientos
SET id_ubicacion_actual = 4
WHERE id_equipamiento = 5;


-- Proyector -> Aula 101
UPDATE equipamientos
SET id_ubicacion_actual = 2
WHERE id_equipamiento = 7;


-- Altavoces -> Salon de Actos
UPDATE equipamientos
SET id_ubicacion_actual = 8
WHERE id_equipamiento = 8;


-- Webcam -> Laboratorio
UPDATE equipamientos
SET id_ubicacion_actual = 7
WHERE id_equipamiento = 9;


-- ============================================================
-- 7. SEGUNDO TRASLADO DE ALGUNOS EQUIPOS
-- ============================================================
-- Esto sirve para comprobar que el histórico guarda
-- VARIAS ubicaciones para un mismo equipamiento.


-- El Portatil Profesor 01 pasa de Sala de Profesores
-- a Despacho Direccion.
UPDATE equipamientos
SET id_ubicacion_actual = 6
WHERE id_equipamiento = 1;


-- El Portatil Alumno 01 pasa de Aula 101
-- a Aula 102.
UPDATE equipamientos
SET id_ubicacion_actual = 3
WHERE id_equipamiento = 2;


-- El Proyector pasa de Aula 101
-- a Salon de Actos.
UPDATE equipamientos
SET id_ubicacion_actual = 8
WHERE id_equipamiento = 7;


-- ============================================================
-- 8. CONSULTAS DE COMPROBACION
-- ============================================================


-- ------------------------------------------------------------
-- USUARIOS
-- ------------------------------------------------------------

SELECT *
FROM usuarios;


-- ------------------------------------------------------------
-- UBICACIONES
-- ------------------------------------------------------------

SELECT *
FROM ubicaciones;


-- ------------------------------------------------------------
-- EQUIPAMIENTOS CON SU UBICACION ACTUAL
-- ------------------------------------------------------------

SELECT
    e.id_equipamiento,
    e.nombre,
    e.marca,
    e.modelo,
    e.categoria,
    u.nombre AS ubicacion_actual
FROM equipamientos e
JOIN ubicaciones u
    ON u.id_ubicacion = e.id_ubicacion_actual
ORDER BY e.id_equipamiento;


-- ------------------------------------------------------------
-- HISTORICO COMPLETO
-- ------------------------------------------------------------

SELECT
    h.id_historico,
    e.nombre AS equipamiento,
    u.nombre AS ubicacion,
    h.fecha_inicio,
    h.fecha_fin
FROM historico_ubicaciones h
JOIN equipamientos e
    ON e.id_equipamiento = h.id_equipamiento
JOIN ubicaciones u
    ON u.id_ubicacion = h.id_ubicacion
ORDER BY
    e.id_equipamiento,
    h.fecha_inicio;


-- ------------------------------------------------------------
-- SOLO UBICACIONES ACTUALES DEL HISTORICO
-- ------------------------------------------------------------

SELECT
    e.nombre AS equipamiento,
    u.nombre AS ubicacion_actual,
    h.fecha_inicio
FROM historico_ubicaciones h
JOIN equipamientos e
    ON e.id_equipamiento = h.id_equipamiento
JOIN ubicaciones u
    ON u.id_ubicacion = h.id_ubicacion
WHERE h.fecha_fin IS NULL
ORDER BY e.nombre;


-- ------------------------------------------------------------
-- NOTIFICACIONES
-- ------------------------------------------------------------

SELECT
    n.id_notificacion,
    n.titulo,
    n.estado,
    n.fecha_creacion,
    CONCAT(u.nombre, ' ', u.apellidos) AS usuario
FROM notificaciones n
JOIN usuarios u
    ON u.id_usuario = n.id_usuario
ORDER BY n.fecha_creacion;


-- ------------------------------------------------------------
-- NUMERO DE EQUIPAMIENTOS POR CATEGORIA
-- ------------------------------------------------------------

SELECT
    categoria,
    COUNT(*) AS cantidad
FROM equipamientos
GROUP BY categoria;


-- ------------------------------------------------------------
-- NUMERO DE EQUIPAMIENTOS POR UBICACION
-- ------------------------------------------------------------

SELECT
    u.nombre AS ubicacion,
    COUNT(e.id_equipamiento) AS cantidad
FROM ubicaciones u
LEFT JOIN equipamientos e
    ON e.id_ubicacion_actual = u.id_ubicacion
GROUP BY u.id_ubicacion, u.nombre
ORDER BY u.nombre;


-- ------------------------------------------------------------
-- NOTIFICACIONES POR ESTADO
-- ------------------------------------------------------------

SELECT
    estado,
    COUNT(*) AS cantidad
FROM notificaciones
GROUP BY estado;