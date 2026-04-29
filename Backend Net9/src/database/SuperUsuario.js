const mysql = require('mysql2/promise'); // Usamos la versión basada en promesas de mysql2
const readlineSync = require('readline-sync');
import config from "./../config";

// Conexión a la base de datos MySQL
async function conectarDB() {
  try {
    const connection = await mysql.createConnection({
      host: config.host, // Cambia si es necesario
      user: config.user,     // Usuario root o un usuario con privilegios
      password: config.password,      // Cambia por tu contraseña
      multipleStatements: true
    });
    
    console.log('Conexión exitosa a la base de datos.');
    return connection;
  } catch (err) {
    console.error('Error al conectarse a la base de datos:', err.message);
    process.exit(1);  // Salir del programa si no hay conexión
  }
}

// Función para crear usuario
async function crearUsuario(connection) {
  const newUser = readlineSync.question('Ingrese el nombre de usuario para crear: ');
  const newPassword = readlineSync.question('Ingrese el password para el nuevo usuario: ');

  try {
    // Crear usuario
    await connection.execute(`CREATE USER '${newUser}'@'%' IDENTIFIED BY '${newPassword}'`);
    console.log(`Usuario ${newUser} creado con éxito.`);
    
    // Asignar privilegios
    await connection.execute(`GRANT ALL PRIVILEGES ON *.* TO '${newUser}'@'%'`);
    console.log(`Privilegios asignados correctamente al usuario ${newUser}.`);
    
    // Aplicar cambios con FLUSH PRIVILEGES
    await connection.execute('FLUSH PRIVILEGES');
    console.log('Privilegios aplicados correctamente.');
  } catch (err) {
    console.error('Error al crear el usuario o asignar privilegios:', err.message);
  }
}

// Función para ver usuarios
async function verUsuarios(connection) {
  try {
    const [rows] = await connection.execute(`SELECT user, host, super_priv FROM mysql.user`);
    
    console.log('Lista de usuarios en el sistema:');
    rows.forEach(row => {
      console.log(`Usuario: ${row.user}, Host: ${row.host}, Superusuario: ${row.super_priv}`);
    });
  } catch (err) {
    console.error('Error al obtener los usuarios:', err.message);
  }
}

// Función para eliminar usuario
async function eliminarUsuario(connection) {
  const deleteUser = readlineSync.question('Ingrese el nombre del usuario que desea eliminar: ');

  try {
    await connection.execute(`DROP USER '${deleteUser}'@'%'`);
    console.log(`Usuario ${deleteUser} eliminado con éxito.`);
    
    // Aplicar cambios con FLUSH PRIVILEGES
    await connection.execute('FLUSH PRIVILEGES');
    console.log('Privilegios actualizados correctamente después de la eliminación.');
  } catch (err) {
    console.error('Error al eliminar el usuario:', err.message);
  }
}

// Menú interactivo
async function mostrarMenu(connection) {
  console.log("\n--- Menú ---");
  console.log("1. Crear Usuario");
  console.log("2. Ver Usuarios");
  console.log("3. Eliminar Usuario");
  console.log("0. Salir");

  const opcion = readlineSync.question('Seleccione una opcion: ');

  switch (opcion) {
    case '1':
      await crearUsuario(connection);
      break;
    case '2':
      await verUsuarios(connection);
      break;
    case '3':
      await eliminarUsuario(connection);
      break;
    case '0':
      console.log('Saliendo...');
      await connection.end();
      return;
    default:
      console.log('Opción inválida, por favor intente nuevamente.');
  }

  // Mostrar el menú de nuevo
  mostrarMenu(connection);
}

// Ejecutar la aplicación
(async () => {
  const connection = await conectarDB();  // Conectar a la base de datos
  mostrarMenu(connection);                 // Mostrar el menú si la conexión es exitosa
})();
