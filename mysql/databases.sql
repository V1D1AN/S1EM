# create databases
CREATE DATABASE IF NOT EXISTS `misp`;
CREATE DATABASE IF NOT EXISTS `codimd`;

CREATE USER IF NOT EXISTS 'misp'@'%' IDENTIFIED BY 'misppass';
GRANT ALL PRIVILEGES ON misp.* TO 'misp'@'%';
CREATE USER IF NOT EXISTS 'codiuser'@'%' IDENTIFIED BY 'codipass';
GRANT ALL PRIVILEGES ON codimd.* TO 'codiuser'@'%';
