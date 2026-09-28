-- ============================================================
-- Base de datos: Reto 2DAW - Gestión del equipamiento y mantenimiento
-- Motor recomendado: MySQL 8.x
-- ============================================================
-- NOTA SOBRE CATEGORÍAS:
-- El enunciado obliga a usar un ENUM para la categoría, pero no fija sus valores.
-- Para que el script sea ejecutable se usan: PORTATIL, SOBREMESA,
-- PERIFERICO, AUDIOVISUAL y OTROS. Si las categorías definitivas son otras,
-- modifica únicamente el ENUM de EQUIPAMIENTOS.categoria.
--
-- REGLAS QUE SE CONTROLAN PRINCIPALMENTE EN PHP:
--   * Solo ADMIN gestiona usuarios, equipamientos y ubicaciones.
--   * USER puede consultar equipamientos/ubicaciones y reasignar equipamientos.
--   * USER solo modifica/elimina sus propias notificaciones.
--   * USER no puede modificar el estado de las notificaciones.
--   * ADMIN solo consulta notificaciones y modifica su estado.
-- ============================================================

DROP DATABASE IF EXISTS reto_2daw;
CREATE DATABASE reto_2daw
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE reto_2daw;

-- ============================================================
-- USUARIOS
-- ============================================================
CREATE TABLE usuarios (
    id_usuario INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    apellidos VARCHAR(120) NOT NULL,
    nombre_usuario VARCHAR(60) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rol ENUM('ADMIN', 'USER') NOT NULL,
    CONSTRAINT uq_usuarios_nombre_usuario UNIQUE (nombre_usuario)
) ENGINE = InnoDB;

-- ============================================================
-- UBICACIONES
-- ============================================================
CREATE TABLE ubicaciones (
    id_ubicacion INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255) NOT NULL,
    CONSTRAINT uq_ubicaciones_nombre UNIQUE (nombre)
) ENGINE = InnoDB;

INSERT INTO ubicaciones (nombre, descripcion)
VALUES ('Almacén', 'Ubicación inicial de los equipamientos');

-- ============================================================
-- EQUIPAMIENTOS
-- ============================================================
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
    id_ubicacion INT UNSIGNED NOT NULL,
    CONSTRAINT fk_equipamientos_ubicacion
        FOREIGN KEY (id_ubicacion)
        REFERENCES ubicaciones (id_ubicacion)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE = InnoDB;

DELIMITER $$

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

    SET NEW.id_ubicacion = v_id_almacen;
END$$

DELIMITER ;

-- ============================================================
-- NOTIFICACIONES
-- ============================================================
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
        REFERENCES usuarios (id_usuario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE = InnoDB;

DELIMITER $$

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
            SET MESSAGE_TEXT = 'Solo los usuarios con rol USER pueden crear notificaciones';
    END IF;

    SET NEW.estado = 'PENDIENTE';
END$$

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
-- ÍNDICES ÚTILES
-- ============================================================
CREATE INDEX idx_equipamientos_categoria ON equipamientos (categoria);
CREATE INDEX idx_equipamientos_ubicacion ON equipamientos (id_ubicacion);
CREATE INDEX idx_notificaciones_usuario ON notificaciones (id_usuario);
CREATE INDEX idx_notificaciones_estado ON notificaciones (estado);

-- ============================================================
-- CONSULTAS DE COMPROBACIÓN OPCIONALES
-- ============================================================
-- Inventario con ubicación:
-- SELECT e.id_equipamiento, e.nombre, e.marca, e.modelo,
--        e.categoria, u.nombre AS ubicacion
-- FROM equipamientos e
-- JOIN ubicaciones u ON u.id_ubicacion = e.id_ubicacion
-- ORDER BY e.nombre;

-- Filtrado por categoría:
-- SELECT * FROM equipamientos WHERE categoria = 'PORTATIL';

-- Notificaciones con usuario creador:
-- SELECT n.id_notificacion, n.titulo, n.descripcion,
--        n.fecha_creacion, n.estado, us.nombre_usuario
-- FROM notificaciones n
-- JOIN usuarios us ON us.id_usuario = n.id_usuario
-- ORDER BY n.fecha_creacion DESC;
