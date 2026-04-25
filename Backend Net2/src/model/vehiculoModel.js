// vehiculoModel.js

import mysql from "mysql2/promise";
import config from "./../config";

const createVehiculoTableAndData = async () => {
    try {
        const dbConnection = await mysql.createConnection({
            host: config.host,
            database: config.database,
            user: config.user,
            password: config.password
        });

        const [rows, fields] = await dbConnection.execute(`SHOW TABLES LIKE 'Vehiculo'`);

        if (rows.length === 0) {
            await dbConnection.execute(`
            CREATE TABLE Vehiculo (
                id          INT             AUTO_INCREMENT  PRIMARY KEY,
                Placa       VARCHAR(100)    NOT NULL,
                Marca       VARCHAR(100)    NOT NULL,
                Modelo      VARCHAR(100)    NOT NULL,
                Kilometraje VARCHAR(100)    NOT NULL
            );
            `);
            console.log(`Tabla 'Vehiculo' creada exitosamente.`);

            await dbConnection.execute(`
            INSERT INTO Vehiculo (Placa, Marca, Modelo, Kilometraje) VALUES
            ('ABC123', 'Toyota', 'Corolla', '50000'),
            ('DEF456', 'Ford', 'Focus', '30000'),
            ('GHI789', 'Honda', 'Civic', '40000'),
            ('JKL012', 'Chevrolet', 'Malibu', '60000');
            `);
            console.log(`Datos insertados en la tabla 'Vehiculo'.`);
        } else {
            console.log(`La tabla 'Vehiculo' ya existe.`);
        }

        await dbConnection.end();
    } catch (error) {
        console.error('Error al crear o verificar la tabla Vehiculo:', error.message);
        throw error;
    }
};

export default createVehiculoTableAndData;