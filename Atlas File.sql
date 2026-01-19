-- Atlas — Estrutura do Banco
create schema if not exists atlas;

-- Tabelas
create table atlas.categorias (
	idCategoria int not null primary key auto_increment,
	nomeCategoria varchar(50) not null,
	descricao varchar(255)
);

create table atlas.fornecedores (
	idFornecedor int not null primary key auto_increment,
	nomeFornecedor varchar(45) not null,
	cnpj varchar(14) not null,
	telefone varchar(20),
	email varchar(120),
	logradouro varchar(80) not null,
	numeroImovel varchar(10) not null,
	complemento varchar(20),
	bairro varchar(40) not null,
	municipio varchar(40) not null,
	estado varchar(2) not null,
	cep varchar(8) not null
);

create table atlas.produtos (
	idProduto int not null primary key auto_increment,
	nomeProduto varchar(60) not null,
	descricao varchar(255),
	preco decimal(10,2),
	quantidadeEstoque decimal(10,2) not null default 0,
	idCategoria int not null,
	idFornecedor int not null
);

create table atlas.tipoMovimentacao (
	idTipoMovimentacao int not null primary key auto_increment,
	descMovimentacao varchar(60),
	operacaoEstoque int,
	sttsMovimentacao int
);

create table atlas.transacoes (
	idTransacao int not null primary key auto_increment,
	dtTransacao datetime not null,
	qtdTransacao decimal(10,2) not null,
	descTransacao varchar(50),
	respTransacao varchar(50) not null,
	idProduto int not null,
	idTipoMovimentacao int not null
);