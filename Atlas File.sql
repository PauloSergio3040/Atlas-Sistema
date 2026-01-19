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

-- Contraints e Integridade
alter table atlas.categorias
	add constraint uq_categoria_nome unique (nomeCategoria);

alter table atlas.fornecedores
	add constraint uq_fornecedor_cnpj unique (cnpj);

alter table atlas.tipoMovimentacao
	add constraint uq_tipomov_desc unique (descMovimentacao);

-- Foreign Keys
alter table atlas.produtos
	add constraint fk_produtos_categorias
	foreign key (idCategoria) references atlas.categorias(idCategoria),
	add constraint fk_produtos_fornecedores
	foreign key (idFornecedor) references atlas.fornecedores(idFornecedor);

alter table atlas.transacoes
	add constraint fk_transacoes_produtos
	foreign key (idProduto) references atlas.produtos(idProduto),
	add constraint fk_transacoes_tipomov
	foreign key (idTipoMovimentacao) references atlas.tipoMovimentacao(idTipoMovimentacao);

-- Dados Iniciais

-- Categorias
insert into atlas.categorias (nomeCategoria, descricao)
values
('carro', 'veículo automotor de passeio'),
('moto', 'veículo automotor de 2 rodas');

-- Fornecedores
insert into atlas.fornecedores
(nomeFornecedor, cnpj, telefone, email, logradouro, numeroImovel, complemento, bairro, municipio, estado, cep)
values
('importadora s.a.', '68976091000249', '1133728888', 'bmwbrasil@gmail.com',
 'rua colômbia', '320', '', 'jardim paulista', 'são paulo', 'sp', '01402000');

-- Produtos
insert into atlas.produtos
(nomeProduto, descricao, preco, quantidadeEstoque, idCategoria, idFornecedor)
values
('bmw 325 e36', 'sedã esportivo dos anos 90, tração traseira e motor seis em linha', 70000.00, 5, 1, 1);

-- Tipos de Movimentação
insert into atlas.tipoMovimentacao
(descMovimentacao, operacaoEstoque, sttsMovimentacao)
values
('entrada', 1, 1),
('saída', -1, 1),
('entrada não faturada', 1, 1),
('saída não faturada', -1, 1),
('troca', 0, 1),
('ajuste de inventário', 0, 1),
('devolução de cliente', 1, 1),
('devolução ao fornecedor', -1, 1);

-- CRUD Controlado
update atlas.produtos
set preco = 75000.00
where idProduto = 1;

-- Testes de integridade
insert into atlas.transacoes
(dtTransacao, qtdTransacao, descTransacao, respTransacao, idProduto, idTipoMovimentacao)
values (now(), 1, 'teste inválido', 'sistema', 999, 1);

start transaction;

delete from atlas.produtos
where idProduto = 1;

rollback;

-- Transações Validas
insert into atlas.transacoes
(dtTransacao, qtdTransacao, descTransacao, respTransacao, idProduto, idTipoMovimentacao)
values
(now(), 2, 'compra lote importadora', 'sistema', 1, 1);

insert into atlas.transacoes
(dtTransacao, qtdTransacao, descTransacao, respTransacao, idProduto, idTipoMovimentacao)
values
(now(), 1, 'devolução por arrependimento', 'atendimento', 1, 7);

insert into atlas.transacoes
(dtTransacao, qtdTransacao, descTransacao, respTransacao, idProduto, idTipoMovimentacao)
values
(now(), -1, 'diferença em inventário físico', 'auditoria', 1, 6);

-- Joins
select
	t.dtTransacao,
	p.nomeProduto,
	c.nomeCategoria,
	f.nomeFornecedor,
	tm.descMovimentacao,
	t.qtdTransacao
from atlas.transacoes t
join atlas.produtos p on t.idProduto = p.idProduto
join atlas.categorias c on p.idCategoria = c.idCategoria
join atlas.fornecedores f on p.idFornecedor = f.idFornecedor
join atlas.tipoMovimentacao tm on t.idTipoMovimentacao = tm.idTipoMovimentacao;
