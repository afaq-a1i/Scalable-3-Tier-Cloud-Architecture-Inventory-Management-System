#!/bin/bash
# 1. Install required packages
dnf update -y
dnf install -y httpd php php-mysqli php-json mariadb105 jq

# 2. Start Web Server
systemctl start httpd
systemctl enable httpd

# 3. Variables (Specific to your environment)
ENDPOINT="countries.c368u2kk215h.eu-north-1.rds.amazonaws.com"
SECRET_ARN="arn:aws:secretsmanager:eu-north-1:068406408985:secret:rds!db-f0f65129-a4f3-4d65-b5df-6291fcd139f9-Sjr8ct"

# 4. Get Metadata (Instance IP) and RDS Password
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4)
DB_PASS=$(aws secretsmanager get-secret-value --secret-id $SECRET_ARN --region eu-north-1 --query SecretString --output text | jq -r '.password')

# 5. Download and Import Database Data
wget https://aws-tc-largeobjects.s3.amazonaws.com/ec2-config/country_data.sql -O /tmp/country_data.sql
mysql -h $ENDPOINT -u admin -p"$DB_PASS" countries < /tmp/country_data.sql

# 6. Create the PHP Application
cat <<EOF > /var/www/html/index.php
<?php
\$conn = new mysqli("$ENDPOINT", "admin", "$DB_PASS", "countries");

if (\$conn->connect_error) {
    echo "<h1>Database Connection Failed</h1>";
    echo "<p>" . \$conn->connect_error . "</p>";
} else {
    echo "<h1>Connected to RDS from Web Server IP: $INSTANCE_IP</h1>";
    echo "<h2>Inventory Table: Countries</h2>";
    
    \$result = \$conn->query("SELECT Name, Code, Region, Population FROM country ORDER BY Name ASC LIMIT 20");
    
    echo "<table border='1' style='width:80%; text-align:left; border-collapse: collapse;'>";
    echo "<tr style='background-color: #f2f2f2;'><th>Country Name</th><th>Code</th><th>Region</th><th>Population</th></tr>";
    while(\$row = \$result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . \$row['Name'] . "</td>";
        echo "<td>" . \$row['Code'] . "</td>";
        echo "<td>" . \$row['Region'] . "</td>";
        echo "<td>" . number_format(\$row['Population']) . "</td>";
        echo "</tr>";
    }
    echo "</table>";
}
?>
EOF

# 7. Finalize Permissions
chown -R ec2-user:apache /var/www/html
chmod -R 775 /var/www/html