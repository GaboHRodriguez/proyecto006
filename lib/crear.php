<?php
// create_temp_user.php
// Script temporal para crear un nuevo usuario en la base de datos

// 1. Habilitar la visualización de TODOS los errores para depuración
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// 2. Credenciales de la Base de Datos (ajusta si es necesario)
$dbHost = 'localhost';
$dbUser = 'Gabriel';
$dbPass = 'Loberia690';
$dbName = 'AdministracionEdificios';
$dbPort = 3306;

// 3. Conexión a la Base de Datos
$conn = new mysqli($dbHost, $dbUser, $dbPass, $dbName, $dbPort);

// Verificar conexión
if ($conn->connect_error) {
    die("Error de conexión a la base de datos: " . $conn->connect_error);
}

// 4. Datos del nuevo usuario
$username = 'Macarena';
$password_plain = '1917'; // Contraseña en texto plano
$password_hash = password_hash($password_plain, PASSWORD_DEFAULT); // Hash de la contraseña

// Asumiendo que 'Super Usuario' tiene role_id = 1. AJUSTA ESTO SEGÚN TU DB.
$role_id = 2; // ID del rol (ej. Super Usuario)
$is_active = 1; // Usuario activo
$gremio_id = null; // Puede ser null si el rol no es 'Gremios'
$consorcio_id = null; // Puede ser null si el rol no es 'Administracion'

// 5. Verificar si el usuario ya existe para evitar duplicados
$stmt_check = $conn->prepare("SELECT id FROM users WHERE username = ?");
$stmt_check->bind_param("s", $username);
$stmt_check->execute();
$stmt_check->store_result();

if ($stmt_check->num_rows > 0) {
    echo "El usuario '$username' ya existe en la base de datos. No se creó un nuevo registro.<br>";
} else {
    // 6. Preparar la consulta de inserción
    // Asegúrate de que los nombres de las columnas coincidan con los de tu tabla 'users'
    $sql = "INSERT INTO users (username, password_hash, role_id, is_active, gremio_id, consorcio_id) VALUES (?, ?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);

    // Verificar si la preparación de la consulta fue exitosa
    if ($stmt === false) {
        echo "Error al preparar la consulta: " . $conn->error;
    } else {
        // 7. Vincular parámetros y ejecutar la consulta
        // 's' para string, 'i' para int. 'i' para null en columnas INT NULLable suele funcionar.
        $stmt->bind_param("ssiiis", $username, $password_hash, $role_id, $is_active, $gremio_id, $consorcio_id);

        if ($stmt->execute()) {
            echo "Usuario '$username' creado exitosamente con ID: " . $conn->insert_id . "<br>";
            echo "Contraseña ('$password_plain') hasheada: " . $password_hash . "<br>";
            echo "¡Ahora puedes intentar iniciar sesión con 'username: 1' y 'password: 1' en tu app Flutter!<br>";
        } else {
            echo "Error al crear el usuario: " . $stmt->error . "<br>";
        }
        $stmt->close();
    }
}

$stmt_check->close();
$conn->close();
?>