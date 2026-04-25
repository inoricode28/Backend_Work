// usuarioModel.js

import mysql from "mysql2/promise";
import config from "./../config";

const createUsuarioTableAndData = async () => {
    try {
        const dbConnection = await mysql.createConnection({
            host: config.host,
            database: config.database,
            user: config.user,
            password: config.password
        });

        const [rows, fields] = await dbConnection.execute(`SHOW TABLES LIKE 'Usuario'`);

        if (rows.length === 0) {
            await dbConnection.execute(`
            CREATE TABLE Usuario (
                id         INT             AUTO_INCREMENT  PRIMARY KEY,
                nombre     VARCHAR(100)    NOT NULL,
                apellido   VARCHAR(100)    NOT NULL,
                correo     VARCHAR(100)    NOT NULL,
                celular    VARCHAR(50)     NOT NULL,
                user       VARCHAR(50)     NOT NULL,
                pass       VARCHAR(100)    NOT NULL
            );
            `);
            console.log(`Tabla 'Usuario' creada exitosamente.`);
            
            await dbConnection.execute(`
            INSERT INTO Usuario (nombre, apellido, correo, celular, user, pass) VALUES
            ('Oscar', 'Guerrero', 'Oguerrero64@gmail.com', '997137674', 'oguerrero', '$R@cs0'),
            ('Miguel', 'Chavez', 'miguel@gmail.com', '935681036', 'miguel', '1234'),
            ('Luis', 'Zúñiga', 'luiszuvillanueva001@gmail.com', '3189462', 'lzuniga', '12345'),
            ('Hilda', 'Villanueva', 'gavb_9@hotmail.com', '00790771', 'gvillanueva', '54321');
            `);
            console.log(`Datos insertados en la tabla 'Usuario'.`);
        } else {
            console.log(`La tabla 'Usuario' ya existe.`);
        }

        await dbConnection.end();
    } catch (error) {
        console.error('Error al crear o verificar la tabla Usuario:', error.message);
        throw error;
    }
};

export default createUsuarioTableAndData;
