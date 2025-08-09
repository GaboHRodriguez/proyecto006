<?php
// api.php (Versión FINAL con JSON en todo el intercambio, creación de usuarios ABIERTA)

// 1. Habilitar la visualización de TODOS los errores para depuración
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// 2. Configuración de CORS y cabeceras
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8"); // La respuesta es JSON
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// 3. Manejo de peticiones OPTIONS (preflight)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// 4. Credenciales de la Base de Datos
$dbHost = 'localhost';
$dbUser = 'Gabriel';
$dbPass = 'Loberia690';
$dbName = 'AdministracionEdificios';
$dbPort = 3306;

// 5. Conexión a la Base de Datos
$conn = null;
try {
    $conn = new mysqli($dbHost, $dbUser, $dbPass, $dbName, $dbPort);
    if ($conn->connect_error) {
        error_log("DB Connection Error: " . $conn->connect_error);
        http_response_code(500);
        echo json_encode(["message" => "Error de conexión a la base de datos: " . $conn->connect_error]); // Respuesta JSON
        exit();
    }
    $conn->set_charset("utf8mb4"); // Aseguramos UTF-8 para la conexión
} catch (mysqli_sql_exception $e) {
    http_response_code(500);
    echo json_encode(["message" => "Error de conexión a la base de datos: " . $e->getMessage()]); // Respuesta JSON
    exit();
}

// 6. Funciones de ayuda (para obtener IDs de FK y roles)
function getConsorcioId($conn, $nombre) {
    $stmt = $conn->prepare("SELECT Codigo FROM Consorcios WHERE Nombre = ?");
    $stmt->bind_param("s", $nombre);
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result->fetch_assoc();
    $stmt->close();
    return $row ? $row['Codigo'] : null;
}

function getGremioId($conn, $nombreFantasia) {
    $stmt = $conn->prepare("SELECT Id FROM Gremios WHERE Nombre_Fantasia = ?");
    $stmt->bind_param("s", $nombreFantasia);
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result->fetch_assoc();
    $stmt->close();
    return $row ? $row['Id'] : null;
}

function getEstadoId($conn, $estado) {
    $stmt = $conn->prepare("SELECT id FROM Estado WHERE Estado = ?");
    $stmt->bind_param("s", $estado);
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result->fetch_assoc();
    $stmt->close();
    return $row ? $row['id'] : null;
}

// NUEVA FUNCIÓN: Obtener ID de Rol por Nombre
function getRoleId($conn, $roleName) {
    $stmt = $conn->prepare("SELECT id FROM roles WHERE name = ?");
    $stmt->bind_param("s", $roleName);
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result->fetch_assoc();
    $stmt->close();
    return $row ? $row['id'] : null;
}

// NUEVA FUNCIÓN: Obtener Nombre de Rol por ID
function getRoleName($conn, $roleId) {
    $stmt = $conn->prepare("SELECT name FROM roles WHERE id = ?");
    $stmt->bind_param("i", $roleId);
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result->fetch_assoc();
    $stmt->close();
    return $row ? $row['name'] : null;
}

// NUEVA FUNCIÓN: Verificar si el usuario es Super Usuario (para permisos)
function isSuperUser($conn, $userId) {
    $stmt = $conn->prepare("SELECT r.name FROM users u JOIN roles r ON u.role_id = r.id WHERE u.id = ?");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result->fetch_assoc();
    $stmt->close();
    return ($row && $row['name'] === 'Super Usuario');
}

// 7. Lógica de Ruteo Principal
$method = $_SERVER['REQUEST_METHOD'];
$request_data = []; // Usaremos esta variable para los datos de la solicitud

// Leer de php://input y json_decode para POST/PUT
if ($method === 'POST' || $method === 'PUT') {
    $input = file_get_contents("php://input");
    error_log("RAW_INPUT for " . $method . " (JSON): " . $input); // Log de la entrada RAW
    $request_data = json_decode($input, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        error_log("JSON_DECODE_ERROR for " . $method . ": " . json_last_error_msg()); // Log si el JSON es inválido
        http_response_code(400);
        echo json_encode(["message" => "Error al decodificar JSON: " . json_last_error_msg()]); // Respuesta JSON
        exit();
    }
    $endpoint = $request_data['endpoint'] ?? null;
    error_log("Parsed Data (after json_decode) for " . $method . ": " . json_encode($request_data)); // Log de los datos parseados
} else { // Para GET, DELETE
    $endpoint = $_GET['endpoint'] ?? null;
    error_log("Received " . $method . " request. Endpoint: " . ($endpoint ?? 'N/A') . ". Query Params: " . json_encode($_GET)); // Log de GET
}

$id = $_GET['id'] ?? null; // ID para DELETE y PUT (desde URL query param)
// $current_user_id = $_GET['current_user_id'] ?? null; // Este ya no es necesario para GET de usuarios si todos pueden verlos

switch ($method) {
    case 'GET':
        if ($endpoint === 'jobs') {
            $base_sql = "SELECT A.ID, A.Titulo, A.Descripcion, A.DiaFin, A.MesFin, A.AnioFin, A.Prioridad AS priority, C.Nombre AS building, D.ID AS departmentId, D.Unidad AS departmentUnit, D.Orden AS departmentOrder, G.Nombre_Fantasia AS technician, E.Estado AS status FROM Avance A JOIN Consorcios C ON A.Consorcio_FK = C.Codigo LEFT JOIN Departamentos D ON A.Departamento_FK = D.ID JOIN Gremios G ON A.Gremio_FK = G.Id JOIN Estado E ON A.Estado_FK = E.id";
            
            $role = $_GET['role'] ?? 'Super Usuario';
            $user_id_filter = $_GET['user_id'] ?? null;

            $params = [];
            $types = '';

            if ($role === 'Administracion' && $user_id_filter) {
                $base_sql .= " WHERE A.Consorcio_FK = ?";
                $params[] = $user_id_filter;
                $types .= 'i';
            } elseif ($role === 'Gremios' && $user_id_filter) {
                $base_sql .= " WHERE A.Gremio_FK = ?";
                $params[] = $user_id_filter;
                $types .= 'i';
            }

            $base_sql .= " ORDER BY A.AnioFin DESC, A.MesFin DESC, A.DiaFin DESC";
            
            $stmt = $conn->prepare($base_sql);

            if (!empty($params)) {
                $stmt->bind_param($types, ...$params);
            }

            $stmt->execute();
            $result = $stmt->get_result();
            
            $output_jobs = [];

            // Define el array de mapeo de prioridad aquí, en la sección GET jobs
            $priorityMap = [
                '0' => 'Baja',
                '1' => 'Media',
                '2' => 'Alta',
                'Baja' => 'Baja',
                'Media' => 'Media',
                'Alta' => 'Alta'
            ];
            
            if ($result && $result->num_rows > 0) {
                while($row = $result->fetch_assoc()) {
                    $priorityText = $priorityMap[$row['priority']] ?? $row['priority'] ?? 'Desconocida';

                    $output_jobs[] = [
                        'ID' => (int)$row['ID'],
                        'Titulo' => $row['Titulo'],
                        'Descripcion' => $row['Descripcion'],
                        'DiaFin' => (int)$row['DiaFin'],
                        'MesFin' => (int)$row['MesFin'],
                        'AnioFin' => (int)$row['AnioFin'],
                        'priority' => $priorityText,
                        'building' => $row['building'],
                        'departmentId' => $row['departmentId'] ? (int)$row['departmentId'] : null,
                        'departmentUnit' => $row['departmentUnit'],
                        'departmentOrder' => $row['departmentOrder'] ? (int)$row['departmentOrder'] : null,
                        'technician' => $row['technician'],
                        'status' => $row['status']
                    ];
                }
            }
            echo json_encode($output_jobs);

        } elseif ($endpoint === 'departments') {
            $sql = "SELECT D.ID, D.Codigo, D.Unidad, D.Orden, D.Nombre, D.Email, D.Telefono, D.Whatsapp, C.Nombre AS consorcioNombre, D.Consorcio_FK AS consorcioId FROM Departamentos D JOIN Consorcios C ON D.Consorcio_FK = C.Codigo ORDER BY C.Nombre, D.Codigo";
            $result = $conn->query($sql);
            $output_depts = [];
            if ($result) {
                while($row = $result->fetch_assoc()) {
                    $output_depts[] = [
                        'ID' => (int)$row['ID'],
                        'consorcioId' => (int)$row['consorcioId'],
                        'Codigo' => (int)$row['Codigo'],
                        'Unidad' => $row['Unidad'],
                        'Orden' => (int)$row['Orden'],
                        'Nombre' => $row['Nombre'],
                        'Email' => $row['Email'],
                        'Telefono' => $row['Telefono'],
                        'Whatsapp' => $row['Whatsapp'],
                        'consorcioNombre' => $row['consorcioNombre']
                    ];
                }
            }
            echo json_encode($output_depts);

        } elseif ($endpoint === 'consorcios') {
            $sql = "SELECT Nombre FROM Consorcios ORDER BY Nombre";
            $result = $conn->query($sql);
            $output_consorcios = [];
            if ($result) {
                while($row = $result->fetch_assoc()) {
                    $output_consorcios[] = $row['Nombre'];
                }
            }
            echo json_encode($output_consorcios);

        } elseif ($endpoint === 'gremios') {
            $sql = "SELECT Nombre_Fantasia FROM Gremios ORDER BY Nombre_Fantasia";
            $result = $conn->query($sql);
            $output_gremios = [];
            if ($result) {
                while($row = $result->fetch_assoc()) {
                    $output_gremios[] = $row['Nombre_Fantasia'];
                }
            }
            echo json_encode($output_gremios);

        } elseif ($endpoint === 'users') {
            // Lógica MODIFICADA: GET users ya no requiere current_user_id para ver la lista de usuarios.
            // if (!$current_user_id || !isSuperUser($conn, $current_user_id)) {
            //     http_response_code(403);
            //     echo json_encode(["message" => "Error: Acceso denegado. Solo Super Usuarios pueden ver la lista de usuarios."]);
            //     exit();
            // }

            $sql = "SELECT u.id, u.username, r.name as role_name, u.consorcio_id, u.gremio_id, u.is_active FROM users u JOIN roles r ON u.role_id = r.id ORDER BY u.username";
            $result = $conn->query($sql);
            $output_users = [];
            if ($result) {
                while($row = $result->fetch_assoc()) {
                    $output_users[] = [
                        'id' => (int)$row['id'],
                        'username' => $row['username'],
                        'role' => $row['role_name'],
                        'consorcio_id' => $row['consorcio_id'] ? (int)$row['consorcio_id'] : null,
                        'gremio_id' => $row['gremio_id'] ? (int)$row['gremio_id'] : null,
                        'is_active' => (bool)$row['is_active']
                    ];
                }
            }
            echo json_encode($output_users);

        } else {
            http_response_code(404);
            echo json_encode(["message" => "Error: Endpoint GET no encontrado."]);
        }
        break;

    case 'POST':
        if ($endpoint === 'login') {
            $username = $request_data['username'] ?? '';
            $password = $request_data['password'] ?? '';

            if (empty($username) || empty($password)) {
                http_response_code(400);
                echo json_encode(["message" => "Usuario y contraseña son requeridos."]);
                exit();
            }

            $stmt = $conn->prepare("SELECT u.id, u.username, u.password_hash, r.name as role_name, u.gremio_id, u.consorcio_id FROM users u JOIN roles r ON u.role_id = r.id WHERE u.username = ? AND u.is_active = 1");
            $stmt->bind_param("s", $username);
            $stmt->execute();
            $result = $stmt->get_result();
            $user = $result->fetch_assoc();
            $stmt->close();

            if ($user && password_verify($password, $user['password_hash'])) {
                http_response_code(200);
                echo json_encode([
                    "message" => "Login exitoso.",
                    "userData" => [
                        "id" => (int)$user['id'],
                        "username" => $user['username'],
                        "role" => $user['role_name'],
                        "gremio_id" => $user['gremio_id'] ? (int)$user['gremio_id'] : null,
                        "consorcio_id" => $user['consorcio_id'] ? (int)$user['consorcio_id'] : null
                    ]
                ]);
            } else {
                http_response_code(401);
                echo json_encode(["message" => "Usuario o contraseña incorrectos."]);
            }
        } else if ($endpoint === 'jobs') {
            $titulo = $request_data['title'] ?? null;
            $descripcion = $request_data['description'] ?? null;
            $dueDateStr = $request_data['dueDate'] ?? null;
            $buildingName = $request_data['building'] ?? null;
            $technicianName = $request_data['technician'] ?? null;
            $statusName = $request_data['status'] ?? null;
            $priority = $request_data['priority'] ?? null;
            $departmentId = $request_data['departmentId'] ?? null; // Recibido como INT o NULL

            if (empty($titulo) || empty($descripcion) || empty($dueDateStr) || empty($buildingName) || empty($technicianName) || empty($statusName) || empty($priority)) {
                error_log("Add Job Error: Missing required fields. Data: " . json_encode($request_data));
                http_response_code(400);
                echo json_encode(["message" => "Faltan campos obligatorios para crear el trabajo."]);
                exit();
            }

            try {
                $dueDate = new DateTime($dueDateStr);
                $diaFin = (int)$dueDate->format('d');
                $mesFin = (int)$dueDate->format('m');
                $anioFin = (int)$dueDate->format('Y');
            } catch (Exception $e) {
                error_log("Add Job Error: Invalid due date format. Date: " . $dueDateStr . ". Error: " . $e->getMessage());
                http_response_code(400);
                echo json_encode(["message" => "Formato de fecha límite inválido."]);
                exit();
            }

            $consorcioFk = getConsorcioId($conn, $buildingName);
            $gremioFk = getGremioId($conn, $technicianName);
            $estadoFk = getEstadoId($conn, $statusName);

            if ($consorcioFk === null || $gremioFk === null || $estadoFk === null) {
                error_log("Add Job Error: FKs not found. Consorcio: {$buildingName} (ID: {$consorcioFk}), Gremio: {$technicianName} (ID: {$gremioFk}), Estado: {$statusName} (ID: {$estadoFk})");
                http_response_code(400);
                echo json_encode(["message" => "Consorcio, Técnico o Estado no encontrados. Verifique los nombres."]);
                exit();
            }

            $sql = "INSERT INTO Avance (Titulo, Descripcion, DiaFin, MesFin, AnioFin, Prioridad, Consorcio_FK, Departamento_FK, Gremio_FK, Estado_FK) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            $stmt = $conn->prepare($sql);
            if ($stmt === false) {
                error_log("Add Job Prepare Error: " . $conn->error);
                http_response_code(500);
                echo json_encode(["message" => "Error interno del servidor al preparar la inserción."]);
                exit();
            }
            
            $stmt->bind_param("ssiiiisiii", $titulo, $descripcion, $diaFin, $mesFin, $anioFin, $priority, $consorcioFk, $departmentId, $gremioFk, $estadoFk);

            if ($stmt->execute()) {
                http_response_code(201);
                echo json_encode(["message" => "Trabajo creado exitosamente.", "id" => $conn->insert_id]);
            } else {
                error_log("Add Job Execute Error: " . $stmt->error);
                http_response_code(500);
                echo json_encode(["message" => "Error al crear el trabajo: " . $stmt->error]);
            }
            $stmt->close();

        } elseif ($endpoint === 'users') { // POST users (Crear usuario) - ABIERTO A CUALQUIER USUARIO
            // Lógica MODIFICADA: Ya NO se requiere current_user_id para la autorización.
            // Se asume que CUALQUIER usuario puede crear un nuevo registro.
            // La variable $current_user_id_from_body (si Flutter la envía) ahora es irrelevante aquí.
            // $current_user_id_from_body = $request_data['current_user_id'] ?? null; // Esto se puede eliminar o ignorar.

            $username = $request_data['username'] ?? null;
            $password = $request_data['password'] ?? null;
            $roleName = $request_data['role'] ?? null;
            $consorcioId = $request_data['consorcioId'] ?? null;
            $gremioId = $request_data['gremioId'] ?? null;
            $isActive = $request_data['is_active'] ?? 1; // Default activo, PHP recibe 1/0

            if (empty($username) || empty($password) || empty($roleName)) {
                http_response_code(400);
                echo json_encode(["message" => "Usuario, contraseña y rol son obligatorios para crear un usuario."]);
                exit();
            }

            $roleId = getRoleId($conn, $roleName);
            if ($roleId === null) {
                http_response_code(400);
                echo json_encode(["message" => "Error: Rol especificado no válido."]);
                exit();
            }

            $stmt = $conn->prepare("SELECT id FROM users WHERE username = ?");
            $stmt->bind_param("s", $username);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows > 0) {
                http_response_code(409); // Conflict
                echo json_encode(["message" => "Error: El nombre de usuario ya existe."]);
                exit();
            }
            $stmt->close();

            $passwordHash = password_hash($password, PASSWORD_BCRYPT);

            $sql = "INSERT INTO users (username, password_hash, role_id, consorcio_id, gremio_id, is_active) VALUES (?, ?, ?, ?, ?, ?)";
            $stmt = $conn->prepare($sql);
            if ($stmt === false) {
                error_log("Create User Prepare Error: " . $conn->error);
                http_response_code(500);
                echo json_encode(["message" => "Error interno del servidor al preparar la inserción de usuario."]);
                exit();
            }

            $stmt->bind_param("ssiiii", $username, $passwordHash, $roleId, $consorcioId, $gremioId, $isActive);

            if ($stmt->execute()) {
                http_response_code(201);
                echo json_encode(["message" => "Usuario creado exitosamente.", "id" => $conn->insert_id]);
            } else {
                error_log("Create User Execute Error: " . $stmt->error);
                http_response_code(500);
                echo json_encode(["message" => "Error al crear el usuario: " . $stmt->error]);
            }
            $stmt->close();

        } else {
            http_response_code(404);
            echo json_encode(["message" => "Endpoint POST no encontrado."]);
        }
        break;

    case 'PUT':
        $current_user_id_from_body = $request_data['current_user_id'] ?? null; // ID del usuario que hace la petición

        if ($endpoint === 'jobs' && $id) {
            $titulo = $request_data['title'] ?? null;
            $descripcion = $request_data['description'] ?? null;
            $dueDateStr = $request_data['dueDate'] ?? null;
            $buildingName = $request_data['building'] ?? null;
            $technicianName = $request_data['technician'] ?? null;
            $statusName = $request_data['status'] ?? null;
            $priority = $request_data['priority'] ?? null; // Recibido como texto 'Baja', 'Media', 'Alta'
            $departmentId = $request_data['departmentId'] ?? null; // Recibido como INT o NULL

            if (empty($titulo) || empty($descripcion) || empty($dueDateStr) || empty($buildingName) || empty($technicianName) || empty($statusName) || empty($priority)) {
                error_log("Update Job Error: Missing required fields. Data: " . json_encode($request_data));
                http_response_code(400);
                echo json_encode(["message" => "Faltan campos obligatorios para actualizar el trabajo."]);
                exit();
            }

            try {
                $dueDate = new DateTime($dueDateStr);
                $diaFin = (int)$dueDate->format('d');
                $mesFin = (int)$dueDate->format('m');
                $anioFin = (int)$dueDate->format('Y');
            } catch (Exception $e) {
                error_log("Update Job Error: Invalid due date format. Date: " . $dueDateStr . ". Error: " . $e->getMessage());
                http_response_code(400);
                echo json_encode(["message" => "Formato de fecha límite inválido."]);
                exit();
            }

            $consorcioFk = getConsorcioId($conn, $buildingName);
            $gremioFk = getGremioId($conn, $technicianName);
            $estadoFk = getEstadoId($conn, $statusName);

            if ($consorcioFk === null || $gremioFk === null || $estadoFk === null) {
                 error_log("Update Job Error: FKs not found. Consorcio: {$buildingName} (ID: {$consorcioFk}), Gremio: {$technicianName} (ID: {$gremioFk}), Estado: {$statusName} (ID: {$estadoFk})");
                http_response_code(400);
                echo json_encode(["message" => "Consorcio, Técnico o Estado no encontrados. Verifique los nombres."]);
                exit();
            }

            $sql = "UPDATE Avance SET Titulo = ?, Descripcion = ?, DiaFin = ?, MesFin = ?, AnioFin = ?, Prioridad = ?, Consorcio_FK = ?, Departamento_FK = ?, Gremio_FK = ?, Estado_FK = ? WHERE ID = ?";
            $stmt = $conn->prepare($sql);
            if ($stmt === false) {
                error_log("Update Job Prepare Error: " . $conn->error);
                http_response_code(500);
                echo json_encode(["message" => "Error interno del servidor al preparar la actualización."]);
                exit();
            }

            $stmt->bind_param("ssiiiisiiii", $titulo, $descripcion, $diaFin, $mesFin, $anioFin, $priority, $consorcioFk, $departmentId, $gremioFk, $estadoFk, $id);

            if ($stmt->execute()) {
                if ($stmt->affected_rows > 0) {
                    http_response_code(200);
                    echo json_encode(["message" => "Trabajo actualizado exitosamente."]);
                } else {
                    error_log("Update Job: No rows affected. Job ID: " . $id);
                    http_response_code(404);
                    echo json_encode(["message" => "Trabajo no encontrado o sin cambios."]);
                }
            } else {
                error_log("Update Job Execute Error: " . $stmt->error);
                http_response_code(500);
                echo json_encode(["message" => "Error al actualizar el trabajo: " . $stmt->error]);
            }
            $stmt->close();

        } elseif ($endpoint === 'users' && $id) { // PUT users (Actualizar usuario)
            if (!$current_user_id_from_body) {
                http_response_code(403);
                echo json_encode(["message" => "Error: ID de usuario actual no proporcionado para la validación."]);
                exit();
            }

            $is_super_user = isSuperUser($conn, $current_user_id_from_body);
            $can_edit_other = $is_super_user;
            $can_edit_self = ($current_user_id_from_body == $id);

            if (!$can_edit_other && !$can_edit_self) {
                http_response_code(403);
                echo json_encode(["message" => "Error: Acceso denegado. No tienes permisos para modificar este usuario."]);
                exit();
            }

            $username = $request_data['username'] ?? null;
            $password = $request_data['password'] ?? null;
            $roleName = $request_data['role'] ?? null;
            $consorcioId = $request_data['consorcioId'] ?? null;
            $gremioId = $request_data['gremioId'] ?? null;
            $isActive = $request_data['is_active'] ?? null;

            if (empty($username)) {
                http_response_code(400);
                echo json_encode(["message" => "Error: El nombre de usuario no puede estar vacío."]);
                exit();
            }

            $stmt = $conn->prepare("SELECT role_id, consorcio_id, gremio_id, is_active FROM users WHERE id = ?");
            $stmt->bind_param("i", $id);
            $stmt->execute();
            $result = $stmt->get_result();
            $current_user_data_in_db = $result->fetch_assoc();
            $stmt->close();

            if (!$current_user_data_in_db) {
                http_response_code(404);
                echo json_encode(["message" => "Error: Usuario a modificar no encontrado."]);
                exit();
            }

            $update_fields = [];
            $params = [];
            $types = '';

            $update_fields[] = "username = ?";
            $params[] = $username;
            $types .= 's';

            if (!empty($password)) {
                $passwordHash = password_hash($password, PASSWORD_BCRYPT);
                $update_fields[] = "password_hash = ?";
                $params[] = $passwordHash;
                $types .= 's';
            }

            if ($is_super_user) {
                if (!empty($roleName)) {
                    $newRoleId = getRoleId($conn, $roleName);
                    if ($newRoleId === null) {
                        http_response_code(400);
                        echo json_encode(["message" => "Error: Rol especificado no válido."]);
                        exit();
                    }
                    $update_fields[] = "role_id = ?";
                    $params[] = $newRoleId;
                    $types .= 'i';
                } else {
                    $update_fields[] = "role_id = ?";
                    $params[] = $current_user_data_in_db['role_id'];
                    $types .= 'i';
                }

                $update_fields[] = "consorcio_id = ?";
                $params[] = $consorcioId;
                $types .= ($consorcioId === null ? 'i' : 'i'); // Siempre 'i' para INT o NULL

                $update_fields[] = "gremio_id = ?";
                $params[] = $gremioId;
                $types .= ($gremioId === null ? 'i' : 'i'); // Siempre 'i' para INT o NULL

                if ($isActive !== null) {
                    $update_fields[] = "is_active = ?";
                    $params[] = $isActive;
                    $types .= 'i';
                } else {
                    $update_fields[] = "is_active = ?";
                    $params[] = $current_user_data_in_db['is_active'];
                    $types .= 'i';
                }

            } else {
                $update_fields[] = "role_id = ?";
                $params[] = $current_user_data_in_db['role_id'];
                $types .= 'i';

                $update_fields[] = "consorcio_id = ?";
                $params[] = $current_user_data_in_db['consorcio_id'];
                $types .= ($current_user_data_in_db['consorcio_id'] === null ? 'i' : 'i');

                $update_fields[] = "gremio_id = ?";
                $params[] = $current_user_data_in_db['gremio_id'];
                $types .= ($current_user_data_in_db['gremio_id'] === null ? 'i' : 'i');

                $update_fields[] = "is_active = ?";
                $params[] = $current_user_data_in_db['is_active'];
                $types .= 'i';
            }

            $sql = "UPDATE users SET " . implode(', ', $update_fields) . " WHERE id = ?";
            $params[] = $id;
            $types .= 'i';

            $stmt = $conn->prepare($sql);
            if ($stmt === false) {
                error_log("Update User Prepare Error: " . $conn->error);
                http_response_code(500);
                echo json_encode(["message" => "Error interno del servidor al preparar la actualización de usuario."]);
                exit();
            }

            if (!call_user_func_array([$stmt, 'bind_param'], array_merge([$types], refValues($params)))) {
                error_log("Update User Bind Param Error: " . $stmt->error);
                http_response_code(500);
                echo json_encode(["message" => "Error interno del servidor al vincular parámetros."]);
                exit();
            }
            
            if ($stmt->execute()) {
                if ($stmt->affected_rows > 0) {
                    http_response_code(200);
                    echo json_encode(["message" => "Usuario actualizado exitosamente."]);
                } else {
                    error_log("Update User: No rows affected. User ID: " . $id);
                    http_response_code(404);
                    echo json_encode(["message" => "Usuario no encontrado o sin cambios."]);
                }
            } else {
                error_log("Update User Execute Error: " . $stmt->error);
                http_response_code(500);
                echo json_encode(["message" => "Error al actualizar el usuario: " . $stmt->error]);
            }
            $stmt->close();
        } else {
            http_response_code(404);
            echo json_encode(["message" => "Endpoint PUT no encontrado o ID faltante."]);
        }
        break;

    case 'DELETE':
        $current_user_id_from_get = $_GET['current_user_id'] ?? null;

        if ($endpoint === 'jobs' && $id) {
            $sql = "DELETE FROM Avance WHERE ID = ?";
            $stmt = $conn->prepare($sql);
            if ($stmt === false) {
                error_log("Delete Job Prepare Error: " . $conn->error);
                http_response_code(500);
                echo json_encode(["message" => "Error interno del servidor al preparar la eliminación."]);
                exit();
            }
            $stmt->bind_param("i", $id);

            if ($stmt->execute()) {
                if ($stmt->affected_rows > 0) {
                    http_response_code(200);
                    echo json_encode(["message" => "Trabajo eliminado exitosamente."]);
                } else {
                    error_log("Delete Job: No rows affected. Job ID: " . $id);
                    http_response_code(404);
                    echo json_encode(["message" => "Trabajo no encontrado."]);
                }
            } else {
                error_log("Delete Job Execute Error: " . $stmt->error);
                http_response_code(500);
                echo json_encode(["message" => "Error al eliminar el trabajo: " . $stmt->error]);
            }
            $stmt->close();

        } elseif ($endpoint === 'users' && $id) { // DELETE users (Eliminar usuario - SOLO SUPER USUARIO)
            if (!$current_user_id_from_get || !isSuperUser($conn, $current_user_id_from_get)) {
                http_response_code(403);
                echo json_encode(["message" => "Error: Acceso denegado. Solo Super Usuarios pueden eliminar usuarios."]);
                exit();
            }

            if ($id == $current_user_id_from_get) {
                http_response_code(400);
                echo json_encode(["message" => "Error: No puedes eliminar tu propia cuenta."]);
                exit();
            }

            $sql = "DELETE FROM users WHERE id = ?";
            $stmt = $conn->prepare($sql);
            if ($stmt === false) {
                error_log("Delete User Prepare Error: " . $conn->error);
                http_response_code(500);
                echo json_encode(["message" => "Error interno del servidor al preparar la eliminación de usuario."]);
                exit();
            }
            $stmt->bind_param("i", $id);

            if ($stmt->execute()) {
                if ($stmt->affected_rows > 0) {
                    http_response_code(200);
                    echo json_encode(["message" => "Usuario eliminado exitosamente."]);
                } else {
                    error_log("Delete User: No rows affected. User ID: " . $id);
                    http_response_code(404);
                    echo json_encode(["message" => "Usuario no encontrado."]);
                }
            } else {
                error_log("Delete User Execute Error: " . $stmt->error);
                http_response_code(500);
                echo json_encode(["message" => "Error al eliminar el usuario: " . $stmt->error]);
            }
            $stmt->close();
        } else {
            http_response_code(404);
            echo json_encode(["message" => "Endpoint DELETE no encontrado o ID faltante."]);
        }
        break;

    default:
        http_response_code(405);
        echo json_encode(["message" => "Método no permitido."]);
        break;
}

$conn->close();

function refValues($arr){
    if (strnatcmp(phpversion(),'5.3') >= 0) // PHP 5.3+
    {
        $refs = array();
        foreach($arr as $key => $value)
            $refs[$key] = &$arr[$key];
        return $refs;
    }
    return $arr;
}

?>
