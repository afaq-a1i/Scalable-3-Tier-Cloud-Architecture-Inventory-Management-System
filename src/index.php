<?php
// Establish connection to RDS Backend
$conn = new mysqli($host, $user, $pass, "countries");

if ($conn->connect_error) {
    die("<h3>Database Connection Error: 500</h3>");
}

echo "<h1>Production Node IP: " . $_SERVER['SERVER_ADDR'] . "</h1>";

// Query to retrieve inventory data
$result = $conn->query("SELECT Name, Code, Population FROM country ORDER BY Population DESC");

if ($result) {
    echo "<table border='1' cellpadding='10'>";
    echo "<tr><th>Country</th><th>Code</th><th>Population</th></tr>";
    while($row = $result->fetch_assoc()) {
        echo "<tr>
                <td>{$row['Name']}</td>
                <td>{$row['Code']}</td>
                <td>" . number_format($row['Population']) . "</td>
              </tr>";
    }
    echo "</table>";
}
?>
