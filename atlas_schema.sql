-- MySQL dump 10.13  Distrib 8.0.44, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: atlas
-- ------------------------------------------------------
-- Server version	8.0.44

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `auditoria`
--

DROP TABLE IF EXISTS `auditoria`;
CREATE TABLE `auditoria` (
  `idAuditoria` int NOT NULL AUTO_INCREMENT,
  `tabelaAfetada` varchar(40) DEFAULT NULL,
  `acao` varchar(10) DEFAULT NULL,
  `idRegistro` int DEFAULT NULL,
  `usuario` varchar(50) DEFAULT NULL,
  `dataAcao` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`idAuditoria`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Table structure for table `categorias`
--

DROP TABLE IF EXISTS `categorias`;
CREATE TABLE `categorias` (
  `idCategoria` int NOT NULL AUTO_INCREMENT,
  `nomeCategoria` varchar(50) NOT NULL,
  `descricao` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`idCategoria`),
  UNIQUE KEY `uq_categoria_nome` (`nomeCategoria`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Table structure for table `fornecedores`
--

DROP TABLE IF EXISTS `fornecedores`;
CREATE TABLE `fornecedores` (
  `idFornecedor` int NOT NULL AUTO_INCREMENT,
  `nomeFornecedor` varchar(45) NOT NULL,
  `cnpj` varchar(14) NOT NULL,
  `telefone` varchar(20) DEFAULT NULL,
  `email` varchar(120) DEFAULT NULL,
  `logradouro` varchar(80) NOT NULL,
  `numeroImovel` varchar(10) NOT NULL,
  `complemento` varchar(20) DEFAULT NULL,
  `bairro` varchar(40) NOT NULL,
  `municipio` varchar(40) NOT NULL,
  `estado` varchar(2) NOT NULL,
  `cep` varchar(8) NOT NULL,
  PRIMARY KEY (`idFornecedor`),
  UNIQUE KEY `uq_fornecedor_cnpj` (`cnpj`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Table structure for table `periodoestoque`
--

DROP TABLE IF EXISTS `periodoestoque`;
CREATE TABLE `periodoestoque` (
  `idPeriodo` int NOT NULL AUTO_INCREMENT,
  `ano` int NOT NULL,
  `mes` int NOT NULL,
  `fechado` tinyint NOT NULL DEFAULT 0,
  `dataFechamento` datetime DEFAULT NULL,
  PRIMARY KEY (`idPeriodo`),
  UNIQUE KEY `uq_periodo` (`ano`,`mes`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Table structure for table `produtos`
--

DROP TABLE IF EXISTS `produtos`;
CREATE TABLE `produtos` (
  `idProduto` int NOT NULL AUTO_INCREMENT,
  `nomeProduto` varchar(60) NOT NULL,
  `descricao` varchar(255) DEFAULT NULL,
  `preco` decimal(10,2) DEFAULT NULL,
  `quantidadeEstoque` decimal(10,2) NOT NULL DEFAULT 0.00,
  `idCategoria` int NOT NULL,
  `idFornecedor` int NOT NULL,
  PRIMARY KEY (`idProduto`),
  KEY `idx_produtos_categoria` (`idCategoria`),
  KEY `idx_produtos_fornecedor` (`idFornecedor`),
  CONSTRAINT `fk_produtos_categorias`
    FOREIGN KEY (`idCategoria`) REFERENCES `categorias` (`idCategoria`),
  CONSTRAINT `fk_produtos_fornecedores`
    FOREIGN KEY (`idFornecedor`) REFERENCES `fornecedores` (`idFornecedor`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Table structure for table `tipomovimentacao`
--

DROP TABLE IF EXISTS `tipomovimentacao`;
CREATE TABLE `tipomovimentacao` (
  `idTipoMovimentacao` int NOT NULL AUTO_INCREMENT,
  `descMovimentacao` varchar(60) NOT NULL,
  `operacaoEstoque` int NOT NULL,
  `sttsMovimentacao` int NOT NULL,
  PRIMARY KEY (`idTipoMovimentacao`),
  UNIQUE KEY `uq_tipomov_desc` (`descMovimentacao`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Table structure for table `transacoes`
--

DROP TABLE IF EXISTS `transacoes`;
CREATE TABLE `transacoes` (
  `idTransacao` int NOT NULL AUTO_INCREMENT,
  `dtTransacao` datetime NOT NULL,
  `qtdTransacao` decimal(10,2) NOT NULL,
  `descTransacao` varchar(50) DEFAULT NULL,
  `respTransacao` varchar(50) NOT NULL,
  `idProduto` int NOT NULL,
  `idTipoMovimentacao` int NOT NULL,
  PRIMARY KEY (`idTransacao`),
  KEY `idx_transacoes_produto` (`idProduto`),
  KEY `idx_transacoes_tipomov` (`idTipoMovimentacao`),
  KEY `idx_transacoes_data` (`dtTransacao`),
  CONSTRAINT `fk_transacoes_produtos`
    FOREIGN KEY (`idProduto`) REFERENCES `produtos` (`idProduto`),
  CONSTRAINT `fk_transacoes_tipomov`
    FOREIGN KEY (`idTipoMovimentacao`) REFERENCES `tipomovimentacao` (`idTipoMovimentacao`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Views (final structure)
--

DROP VIEW IF EXISTS `vw_base_curva_abc`;
CREATE VIEW `vw_base_curva_abc` AS
select
  p.idProduto,
  p.nomeProduto,
  sum((t.qtdTransacao * p.preco) * abs(tm.operacaoEstoque)) as valor_movimentado
from produtos p
join transacoes t on p.idProduto = t.idProduto
join tipomovimentacao tm on t.idTipoMovimentacao = tm.idTipoMovimentacao
where tm.operacaoEstoque <> 0
group by p.idProduto, p.nomeProduto;

DROP VIEW IF EXISTS `vw_cobertura_estoque`;
CREATE VIEW `vw_cobertura_estoque` AS
select
  p.idProduto,
  p.nomeProduto,
  p.quantidadeEstoque,
  avg(t.qtdTransacao) as media_saida,
  case
    when avg(t.qtdTransacao) = 0 then null
    else p.quantidadeEstoque / avg(t.qtdTransacao)
  end as cobertura_estimada
from produtos p
join transacoes t on p.idProduto = t.idProduto
join tipomovimentacao tm on t.idTipoMovimentacao = tm.idTipoMovimentacao
where tm.operacaoEstoque = -1
group by p.idProduto, p.nomeProduto, p.quantidadeEstoque;

-- (demais views seguem a mesma lógica, apenas sem DEFINER)

--
-- Restore settings
--

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-26
