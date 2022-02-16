# create databases
CREATE DATABASE IF NOT EXISTS `misp`;

# create misp user and grant rights
CREATE USER IF NOT EXISTS 'misp'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON misp.* TO 'misp'@'%';