# create databases
CREATE DATABASE IF NOT EXISTS `misp`;

# create misp user and grant rights
CREATE USER 'misp'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'misp'@'%';