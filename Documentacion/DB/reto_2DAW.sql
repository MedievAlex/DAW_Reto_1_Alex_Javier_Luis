-- ============================================================
-- RETO 2DAW - Gestión del equipamiento y mantenimiento
-- Versión con HISTÓRICO DE UBICACIONES
-- Motor: MySQL 8.x / MariaDB
-- ============================================================

DROP DATABASE IF EXISTS reto_2daw;
CREATE DATABASE reto_2daw
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE reto_2daw;

-- 1. USUARIOS ------------------------------------------------
CREATE TABLE usuarios (
    id_usuario INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    apellidos VARCHAR(120) NOT NULL,
    nombre_usuario VARCHAR(60) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    rol ENUM('ADMIN', 'USER') NOT NULL
) ENGINE=InnoDB;

-- 2. UBICACIONES ----------------------------------------------
CREATE TABLE ubicaciones (
    id_ubicacion INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

INSERT INTO ubicaciones (nombre, descripcion)
VALUES ('Almacén', 'Ubicación inicial de todos los equipamientos');

-- 3. EQUIPAMIENTOS --------------------------------------------
CREATE TABLE equipamientos (
    id_equipamiento INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    descripcion VARCHAR(255) NOT NULL,
    marca VARCHAR(100) NOT NULL,
    modelo VARCHAR(100) NOT NULL,
    categoria ENUM(
        'PORTATIL',
        'SOBREMESA',
        'PERIFERICO',
        'AUDIOVISUAL',
        'OTROS'
    ) NOT NULL,
    id_ubicacion_actual INT UNSIGNED NOT NULL,
    CONSTRAINT fk_equipamientos_ubicacion_actual
        FOREIGN KEY (id_ubicacion_actual)
        REFERENCES ubicaciones(id_ubicacion)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 4. HISTORICO_UBICACIONES ------------------------------------
-- Esta tabla resuelve la relación N:M entre EQUIPAMIENTOS y UBICACIONES.
CREATE TABLE historico_ubicaciones (
    id_historico BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_equipamiento INT UNSIGNED NOT NULL,
    id_ubicacion INT UNSIGNED NOT NULL,
    fecha_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_fin DATETIME NULL,
    CONSTRAINT fk_historico_equipamiento
        FOREIGN KEY (id_equipamiento)
        REFERENCES equipamientos(id_equipamiento)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_historico_ubicacion
        FOREIGN KEY (id_ubicacion)
        REFERENCES ubicaciones(id_ubicacion)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_historico_fechas
        CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
) ENGINE=InnoDB;

CREATE INDEX idx_historico_equipamiento
    ON historico_ubicaciones(id_equipamiento);
CREATE INDEX idx_historico_ubicacion
    ON historico_ubicaciones(id_ubicacion);
CREATE INDEX idx_historico_abierto
    ON historico_ubicaciones(id_equipamiento, fecha_fin);

-- 5. NOTIFICACIONES -------------------------------------------
CREATE TABLE notificaciones (
    id_notificacion INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(150) NOT NULL,
    descripcion TEXT NOT NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('PENDIENTE', 'EN_PROCESO', 'REALIZADA')
        NOT NULL DEFAULT 'PENDIENTE',
    id_usuario INT UNSIGNED NOT NULL,
    CONSTRAINT fk_notificaciones_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE INDEX idx_notificaciones_usuario ON notificaciones(id_usuario);
CREATE INDEX idx_notificaciones_estado ON notificaciones(estado);
CREATE INDEX idx_equipamientos_categoria ON equipamientos(categoria);
CREATE INDEX idx_equipamientos_ubicacion_actual ON equipamientos(id_ubicacion_actual);

-- TRIGGERS ----------------------------------------------------
DELIMITER $$

-- Todo equipamiento nuevo empieza obligatoriamente en Almacén.
CREATE TRIGGER trg_equipamiento_ubicacion_inicial
BEFORE INSERT ON equipamientos
FOR EACH ROW
BEGIN
    DECLARE v_id_almacen INT UNSIGNED;

    SELECT id_ubicacion
      INTO v_id_almacen
      FROM ubicaciones
     WHERE nombre = 'Almacén'
     LIMIT 1;

    IF v_id_almacen IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No existe la ubicación obligatoria Almacén';
    END IF;

    SET NEW.id_ubicacion_actual = v_id_almacen;
END$$

-- Al crear un equipamiento, se abre automáticamente su primera fila de histórico.
CREATE TRIGGER trg_equipamiento_crear_historico
AFTER INSERT ON equipamientos
FOR EACH ROW
BEGIN
    INSERT INTO historico_ubicaciones
        (id_equipamiento, id_ubicacion, fecha_inicio, fecha_fin)
    VALUES
        (NEW.id_equipamiento, NEW.id_ubicacion_actual, CURRENT_TIMESTAMP, NULL);
END$$

-- Cuando cambia la ubicación actual, se cierra la anterior y se abre la nueva.
CREATE TRIGGER trg_equipamiento_traslado
BEFORE UPDATE ON equipamientos
FOR EACH ROW
BEGIN
    IF NEW.id_ubicacion_actual <> OLD.id_ubicacion_actual THEN
        UPDATE historico_ubicaciones
           SET fecha_fin = CURRENT_TIMESTAMP
         WHERE id_equipamiento = OLD.id_equipamiento
           AND fecha_fin IS NULL;

        INSERT INTO historico_ubicaciones
            (id_equipamiento, id_ubicacion, fecha_inicio, fecha_fin)
        VALUES
            (OLD.id_equipamiento, NEW.id_ubicacion_actual, CURRENT_TIMESTAMP, NULL);
    END IF;
END$$

-- Solo puede existir una fila abierta por equipamiento.
CREATE TRIGGER trg_historico_unico_abierto_insert
BEFORE INSERT ON historico_ubicaciones
FOR EACH ROW
BEGIN
    IF NEW.fecha_fin IS NULL
       AND EXISTS (
            SELECT 1
              FROM historico_ubicaciones
             WHERE id_equipamiento = NEW.id_equipamiento
               AND fecha_fin IS NULL
       ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El equipamiento ya tiene una ubicación actual abierta';
    END IF;
END$$

-- No se puede borrar la ubicación Almacén.
CREATE TRIGGER trg_no_borrar_almacen
BEFORE DELETE ON ubicaciones
FOR EACH ROW
BEGIN
    IF OLD.nombre = 'Almacén' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La ubicación Almacén es obligatoria y no puede eliminarse';
    END IF;
END$$

-- Solo USER puede ser creador de una notificación; siempre comienza PENDIENTE.
CREATE TRIGGER trg_notificacion_solo_user
BEFORE INSERT ON notificaciones
FOR EACH ROW
BEGIN
    DECLARE v_rol VARCHAR(10);

    SELECT rol
      INTO v_rol
      FROM usuarios
     WHERE id_usuario = NEW.id_usuario
     LIMIT 1;

    IF v_rol IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El usuario indicado no existe';
    END IF;

    IF v_rol <> 'USER' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Solo los usuarios USER pueden crear notificaciones';
    END IF;

    SET NEW.estado = 'PENDIENTE';
END$$

-- Una notificación REALIZADA no se puede eliminar.
CREATE TRIGGER trg_notificacion_no_borrar_realizada
BEFORE DELETE ON notificaciones
FOR EACH ROW
BEGIN
    IF OLD.estado = 'REALIZADA' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Una notificación REALIZADA no puede eliminarse';
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- EJEMPLOS DE CONSULTA
-- ============================================================

-- Inventario con ubicación actual:
-- SELECT e.id_equipamiento, e.nombre, e.marca, e.modelo,
--        e.categoria, u.nombre AS ubicacion_actual
-- FROM equipamientos e
-- JOIN ubicaciones u ON u.id_ubicacion = e.id_ubicacion_actual;

-- Histórico de un equipamiento:
-- SELECT h.id_historico, u.nombre AS ubicacion,
--        h.fecha_inicio, h.fecha_fin
-- FROM historico_ubicaciones h
-- JOIN ubicaciones u ON u.id_ubicacion = h.id_ubicacion
-- WHERE h.id_equipamiento = 1
-- ORDER BY h.fecha_inicio;

-- Ubicación actual a partir del histórico:
-- SELECT u.nombre, h.fecha_inicio
-- FROM historico_ubicaciones h
-- JOIN ubicaciones u ON u.id_ubicacion = h.id_ubicacion
-- WHERE h.id_equipamiento = 1
--   AND h.fecha_fin IS NULL;

-- Un usuario puede tener varias notificaciones incluso en la misma fecha.
-- Eso sigue siendo una relación 1:N.
