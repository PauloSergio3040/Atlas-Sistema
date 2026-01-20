-- Atlas
create schema if not exists atlas;

use atlas;

-- Tabelas de base
create table atlas.categorias (
	idCategoria int primary key auto_increment,
	nomeCategoria varchar(50) not null,
	descricao varchar(255),
	constraint uq_categoria_nome unique (nomeCategoria)
);

create table atlas.fornecedores (
	idFornecedor int primary key auto_increment,
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
	cep varchar(8) not null,
	constraint uq_fornecedor_cnpj unique (cnpj)
);

create table atlas.produtos (
	idProduto int primary key auto_increment,
	nomeProduto varchar(60) not null,
	descricao varchar(255),
	preco decimal(10,2),
	quantidadeEstoque decimal(10,2) not null default 0,
	idCategoria int not null,
	idFornecedor int not null,
	constraint fk_produtos_categorias
		foreign key (idCategoria) references atlas.categorias(idCategoria),
	constraint fk_produtos_fornecedores
		foreign key (idFornecedor) references atlas.fornecedores(idFornecedor)
);

create table atlas.tipoMovimentacao (
	idTipoMovimentacao int primary key auto_increment,
	descMovimentacao varchar(60) not null,
	operacaoEstoque int not null, -- 1 entrada | -1 saída | 0 neutra
	sttsMovimentacao int not null,
	constraint uq_tipomov_desc unique (descMovimentacao)
);

create table atlas.transacoes (
	idTransacao int primary key auto_increment,
	dtTransacao datetime not null,
	qtdTransacao decimal(10,2) not null,
	descTransacao varchar(50),
	respTransacao varchar(50) not null,
	idProduto int not null,
	idTipoMovimentacao int not null,
	constraint fk_transacoes_produtos
		foreign key (idProduto) references atlas.produtos(idProduto),
	constraint fk_transacoes_tipomov
		foreign key (idTipoMovimentacao) references atlas.tipoMovimentacao(idTipoMovimentacao)
);

-- Controla quais períodos estão abertos ou fechados
create table atlas.periodoEstoque (
	idPeriodo int primary key auto_increment,
	ano int not null,
	mes int not null,
	fechado tinyint not null default 0,
	dataFechamento datetime,
	constraint uq_periodo unique (ano, mes)
);

-- Registra ações sensíveis no sistema
create table atlas.auditoria (
	idAuditoria int primary key auto_increment,
	tabelaAfetada varchar(40),
	acao varchar(10),
	idRegistro int,
	usuario varchar(50),
	dataAcao datetime default now()
);

-- Indices
create index idx_produtos_categoria  on atlas.produtos (idCategoria);
create index idx_produtos_fornecedor on atlas.produtos (idFornecedor);
create index idx_transacoes_produto  on atlas.transacoes (idProduto);
create index idx_transacoes_tipomov  on atlas.transacoes (idTipoMovimentacao);
create index idx_transacoes_data     on atlas.transacoes (dtTransacao);

-- Dados base
insert into atlas.categorias (nomeCategoria, descricao) values
('carro','veículo automotor de passeio'),
('moto','veículo automotor de 2 rodas');

insert into atlas.fornecedores
(nomeFornecedor, cnpj, telefone, email, logradouro, numeroImovel, complemento, bairro, municipio, estado, cep)
values
('importadora s.a.','68976091000249','1133728888','bmwbrasil@gmail.com',
 'rua colômbia','320','','jardim paulista','são paulo','sp','01402000');

insert into atlas.produtos
(nomeProduto, descricao, preco, idCategoria, idFornecedor)
values
('bmw 325 e36','sedã esportivo anos 90, RWD, seis em linha',70000.00,1,1);

insert into atlas.tipoMovimentacao
(descMovimentacao, operacaoEstoque, sttsMovimentacao)
values
('entrada', 1,1),
('saída', -1,1),
('entrada não faturada',1,1),
('saída não faturada',-1,1),
('troca',0,1),
('ajuste de inventário',0,1),
('devolução de cliente',1,1),
('devolução ao fornecedor',-1,1),
('inventário inicial',1,1);

-- Regra de negocio, prod não nasce com estoque
update atlas.produtos set quantidadeEstoque = 0 where idProduto = 1;

-- Triggers
delimiter $$

-- Bloqueio de estoque negativo
-- Executa ANTES da transação ser gravada
create trigger trg_bloqueia_estoque_negativo
before insert on atlas.transacoes
for each row
begin
	declare estoque_atual decimal(10,2);
	declare impacto int;

	select quantidadeEstoque
	into estoque_atual
	from atlas.produtos
	where idProduto = NEW.idProduto;

	select operacaoEstoque
	into impacto
	from atlas.tipoMovimentacao
	where idTipoMovimentacao = NEW.idTipoMovimentacao;

	-- Se for saída e o resultado ficar negativo → BLOQUEIA
	if (estoque_atual + (NEW.qtdTransacao * impacto)) < 0 then
		signal sqlstate '45000'
		set message_text = 'Operação inválida: estoque insuficiente';
	end if;
end$$

-- Atualização automatica de estoque
-- Executa APÓS a transação ser gravada
create trigger trg_atualiza_estoque
after insert on atlas.transacoes
for each row
begin
	update atlas.produtos
	set quantidadeEstoque =
		quantidadeEstoque +
		(
			NEW.qtdTransacao *
			(
				select operacaoEstoque
				from atlas.tipoMovimentacao
				where idTipoMovimentacao = NEW.idTipoMovimentacao
			)
		)
	where idProduto = NEW.idProduto;
end$$

delimiter ;

-- Atualização de estoque ao alterar uma transação
-- Se alguém corrigir uma transação já lançada, o estoque precisa refletir a diferença, não somar tudo de novo.
delimiter $$

-- Atualiza o estoque quando uma transação é alterada
create trigger trg_atualiza_estoque_after_update
after update on atlas.transacoes
for each row
begin
	declare impacto_old int;
	declare impacto_new int;

	-- Operação antiga
	select operacaoEstoque
	into impacto_old
	from atlas.tipoMovimentacao
	where idTipoMovimentacao = OLD.idTipoMovimentacao;

	-- Operação nova
	select operacaoEstoque
	into impacto_new
	from atlas.tipoMovimentacao
	where idTipoMovimentacao = NEW.idTipoMovimentacao;

	-- Remove o efeito antigo e aplica o novo
	update atlas.produtos
	set quantidadeEstoque =
		quantidadeEstoque
		- (OLD.qtdTransacao * impacto_old)
		+ (NEW.qtdTransacao * impacto_new)
	where idProduto = NEW.idProduto;
end$$

delimiter ;

-- Bloqueio de exclusão de transações críticas
-- Não permitir apagar transações, apenas corrigir.
delimiter $$

-- Impede exclusão de transações
create trigger trg_bloqueia_delete_transacao
before delete on atlas.transacoes
for each row
begin
	signal sqlstate '45000'
	set message_text = 'Transações não podem ser excluídas. Utilize correção ou ajuste.';
end$$

delimiter ;

delimiter $$

-- Impede inserção de transações em período já fechado
create trigger trg_bloqueia_periodo_fechado
before insert on atlas.transacoes
for each row
begin
	declare periodo_fechado int;

	select fechado
	into periodo_fechado
	from atlas.periodoEstoque
	where ano = year(NEW.dtTransacao)
	  and mes = month(NEW.dtTransacao);

	-- Se existir o período e ele estiver fechado → bloqueia
	if periodo_fechado = 1 then
		signal sqlstate '45000'
		set message_text = 'Período de estoque fechado. Alteração não permitida.';
	end if;
end$$

delimiter ;

delimiter $$

-- Registra qualquer nova transação na auditoria
create trigger trg_auditoria_transacoes
after insert on atlas.transacoes
for each row
begin
	insert into atlas.auditoria
	(tabelaAfetada, acao, idRegistro, usuario)
	values
	('transacoes', 'insert', NEW.idTransacao, NEW.respTransacao);
end$$

delimiter ;
-- Ideia é criar historico tipo: “fulano lançou isso, nesse momento”

delimiter $$

-- Relatório consolidado de estoque e giro
create procedure atlas.sp_relatorio_estoque()
begin
	select
		e.idProduto,
		e.nomeProduto,
		e.quantidadeEstoque,
		g.giro_estimado
	from atlas.vw_estoque_atual e
	left join atlas.vw_giro_estoque g
		on e.idProduto = g.idProduto;
end$$

delimiter ;

-- Uso:
call atlas.sp_relatorio_estoque();
-- Isso já está pronto para uma API REST.

delimiter $$

-- Histórico de movimentações por produto e período
create procedure atlas.sp_historico_produto_periodo (
	in p_idProduto int,
	in p_dataInicio date,
	in p_dataFim date
)
begin
	select
		t.idTransacao,
		t.dtTransacao,
		t.qtdTransacao,
		tm.descMovimentacao,
		t.respTransacao
	from atlas.transacoes t
	join atlas.tipoMovimentacao tm
		on t.idTipoMovimentacao = tm.idTipoMovimentacao
	where t.idProduto = p_idProduto
	  and date(t.dtTransacao) between p_dataInicio and p_dataFim
	order by t.dtTransacao;
end$$

delimiter ;

-- Uso:
call atlas.sp_historico_produto_periodo(1, '2024-01-01', '2024-12-31');
-- Isso já conversa direto com frontend ou BI.

delimiter $$

-- Retorna a curva ABC pronta para consumo
create procedure atlas.sp_relatorio_curva_abc ()
begin
	select
		idProduto,
		nomeProduto,
		valor_movimentado,
		classe_abc
	from atlas.vw_curva_abc
	order by classe_abc, valor_movimentado desc;
end$$

delimiter ;

delimiter $$

-- Gera transações simuladas para teste de volume
create procedure atlas.sp_simula_movimentacoes (
	in p_idProduto int,
	in p_qtd int
)
begin
	declare i int default 0;

	while i < p_qtd do
		insert into atlas.transacoes
		(dtTransacao, qtdTransacao, descTransacao, respTransacao, idProduto, idTipoMovimentacao)
		values
		(
			now(),
			1,
			'simulação de carga',
			'sistema',
			p_idProduto,
			2 -- saída
		);

		set i = i + 1;
	end while;
end$$

delimiter ;

-- Uso:
call atlas.sp_simula_movimentacoes(1, 100);
	select count(*) from atlas.transacoes;
    select * from atlas.vw_estoque_atual;

-- Views oficiais (camada de leitura)
-- Elas evitam joins repetitivos e padronizam o acesso aos dados.

-- Estoque atual consolidado
create view atlas.vw_estoque_atual as
select
	p.idProduto,
	p.nomeProduto,
	c.nomeCategoria,
	f.nomeFornecedor,
	p.quantidadeEstoque
from atlas.produtos p
join atlas.categorias c  on p.idCategoria = c.idCategoria
join atlas.fornecedores f on p.idFornecedor = f.idFornecedor;

-- Histórico legível de movimentações
create view atlas.vw_historico_estoque as
select
	t.idTransacao,
	t.dtTransacao,
	p.nomeProduto,
	tm.descMovimentacao,
	t.qtdTransacao,
	t.respTransacao
from atlas.transacoes t
join atlas.produtos p on t.idProduto = p.idProduto
join atlas.tipoMovimentacao tm on t.idTipoMovimentacao = tm.idTipoMovimentacao;

-- Giro de estoque por produto
-- Mede quantas vezes o estoque foi renovado no período
create view atlas.vw_giro_estoque as
select
	p.idProduto,
	p.nomeProduto,
	sum(t.qtdTransacao * abs(tm.operacaoEstoque)) as volume_movimentado,
	p.quantidadeEstoque as estoque_atual,
	case
		when p.quantidadeEstoque = 0 then null
		else sum(t.qtdTransacao * abs(tm.operacaoEstoque)) / p.quantidadeEstoque
	end as giro_estimado
from atlas.produtos p
join atlas.transacoes t on p.idProduto = t.idProduto
join atlas.tipoMovimentacao tm on t.idTipoMovimentacao = tm.idTipoMovimentacao
where tm.operacaoEstoque = -1 -- só saídas
group by p.idProduto, p.nomeProduto, p.quantidadeEstoque;
-- isso responde “esse produto gira rápido ou fica parado?”

-- Produtos sem saída nos últimos 90 dias
create view atlas.vw_produtos_parados as
select
	p.idProduto,
	p.nomeProduto,
	max(t.dtTransacao) as ultima_movimentacao
from atlas.produtos p
left join atlas.transacoes t
	on p.idProduto = t.idProduto
	and t.idTipoMovimentacao in (
		select idTipoMovimentacao
		from atlas.tipoMovimentacao
		where operacaoEstoque = -1
	)
group by p.idProduto, p.nomeProduto
having
	ultima_movimentacao is null
	or ultima_movimentacao < now() - interval 90 day;
-- produto parado não é erro, é alerta de negócio.

-- Cobertura estimada de estoque em dias
create view atlas.vw_cobertura_estoque as
select
	p.idProduto,
	p.nomeProduto,
	p.quantidadeEstoque,
	avg(t.qtdTransacao) as media_saida,
	case
		when avg(t.qtdTransacao) = 0 then null
		else p.quantidadeEstoque / avg(t.qtdTransacao)
	end as cobertura_estimada
from atlas.produtos p
join atlas.transacoes t on p.idProduto = t.idProduto
join atlas.tipoMovimentacao tm on t.idTipoMovimentacao = tm.idTipoMovimentacao
where tm.operacaoEstoque = -1
group by p.idProduto, p.nomeProduto, p.quantidadeEstoque;

-- Base da curva ABC
-- Calcula o valor movimentado por produto
create view atlas.vw_base_curva_abc as
select
	p.idProduto,
	p.nomeProduto,
	sum(t.qtdTransacao * p.preco * abs(tm.operacaoEstoque)) as valor_movimentado
from atlas.produtos p
join atlas.transacoes t on p.idProduto = t.idProduto
join atlas.tipoMovimentacao tm on t.idTipoMovimentacao = tm.idTipoMovimentacao
where tm.operacaoEstoque <> 0
group by p.idProduto, p.nomeProduto;
-- não importa se foi entrada ou saída, aqui importa quanto dinheiro passou.

-- Classificação ABC baseada no valor acumulado
create view atlas.vw_curva_abc as
select
	idProduto,
	nomeProduto,
	valor_movimentado,
	sum(valor_movimentado) over () as total_geral,
	sum(valor_movimentado) over (
		order by valor_movimentado desc
	) / sum(valor_movimentado) over () as percentual_acumulado,
	case
		when sum(valor_movimentado) over (
			order by valor_movimentado desc
		) / sum(valor_movimentado) over () <= 0.8 then 'A'
		when sum(valor_movimentado) over (
			order by valor_movimentado desc
		) / sum(valor_movimentado) over () <= 0.95 then 'B'
		else 'C'
	end as classe_abc
from atlas.vw_base_curva_abc;
/*
	- até 80% do valor -> A
	- até 95% -> B
	- resto -> C
*/

-- Inventario incial
insert into atlas.transacoes
(dtTransacao, qtdTransacao, descTransacao, respTransacao, idProduto, idTipoMovimentacao)
values
(now(),5,'inventário inicial do sistema','sistema',1,
 (select idTipoMovimentacao
  from atlas.tipoMovimentacao
  where descMovimentacao = 'inventário inicial'));

-- Validação

-- Estoque atual
select idProduto, nomeProduto, quantidadeEstoque
from atlas.produtos
where idProduto = 1;

-- Estoque teórico (derivado do histórico)
select
	p.idProduto,
	p.nomeProduto,
	p.quantidadeEstoque as estoque_atual,
	sum(t.qtdTransacao * tm.operacaoEstoque) as estoque_teorico
from atlas.produtos p
join atlas.transacoes t  on p.idProduto = t.idProduto
join atlas.tipoMovimentacao tm on t.idTipoMovimentacao = tm.idTipoMovimentacao
where p.idProduto = 1
group by p.idProduto, p.nomeProduto, p.quantidadeEstoque;

-- Integridade basica

-- Deve falhar
-- Motivo: nomeCategoria é único
insert into atlas.categorias (nomeCategoria, descricao)
values ('carro', 'categoria duplicada');
-- R: Error Code: 1062. Duplicate entry 'carro' for key 'categorias.uq_categoria_nome'

-- fornecedor com CNPJ duplicado
-- Deve falhar
-- Motivo: cnpj é único
insert into atlas.fornecedores
(nomeFornecedor, cnpj, logradouro, numeroImovel, bairro, municipio, estado, cep)
values
('fornecedor fake','68976091000249','rua x','10','centro','sp','sp','00000000');
-- R: Error Code: 1062. Duplicate entry '68976091000249' for key 'fornecedores.uq_fornecedor_cnpj'

-- Produto categoria inexistente
-- Deve falhar
-- Motivo: foreign key para categorias
insert into atlas.produtos
(nomeProduto, idCategoria, idFornecedor)
values
('produto inválido', 999, 1);
-- R: Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails

-- Transação de produto inexistente
-- Deve falhar
-- Motivo: foreign key para produtos
insert into atlas.transacoes
(dtTransacao, qtdTransacao, respTransacao, idProduto, idTipoMovimentacao)
values
(now(),1,'sistema',999,1);
-- R: Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails

-- Deve falhar
-- Motivo: foreign key para tipoMovimentacao
insert into atlas.transacoes
(dtTransacao, qtdTransacao, respTransacao, idProduto, idTipoMovimentacao)
values
(now(),1,'sistema',1,999);
-- R: Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails

-- Deve mostrar 5 (inventário inicial)
select idProduto, quantidadeEstoque
from atlas.produtos
where idProduto = 1;
-- R: 1	| 5.00

-- Deve funcionar, estoque: 5 → 3
insert into atlas.transacoes
(dtTransacao, qtdTransacao, descTransacao, respTransacao, idProduto, idTipoMovimentacao)
values
(now(),2,'venda normal','vendas',1,2);

-- Conferencia
select idProduto, quantidadeEstoque
from atlas.produtos
where idProduto = 1;
-- R: 1	| 3.00

-- Deve falhar
-- Motivo: trigger trg_bloqueia_estoque_negativo
insert into atlas.transacoes
(dtTransacao, qtdTransacao, descTransacao, respTransacao, idProduto, idTipoMovimentacao)
values
(now(),10,'tentativa inválida','vendas',1,2);
-- R: Operação inválida: estoque insuficiente

-- Deve funcionar, estoque não muda
insert into atlas.transacoes
(dtTransacao, qtdTransacao, descTransacao, respTransacao, idProduto, idTipoMovimentacao)
values
(now(),50,'troca de mercadoria','atendimento',1,5);

-- Conferencia
select idProduto, quantidadeEstoque
from atlas.produtos
where idProduto = 1;
-- R: 1 | 3.00

-- Entrada normal

-- Deve funcionar, estoque aumenta
insert into atlas.transacoes
(dtTransacao, qtdTransacao, descTransacao, respTransacao, idProduto, idTipoMovimentacao)
values
(now(),4,'compra fornecedor','compras',1,1);

-- Conferencia
select idProduto, quantidadeEstoque
from atlas.produtos
where idProduto = 1;

-- Estoque físico gravado
select idProduto, nomeProduto, quantidadeEstoque
from atlas.produtos
where idProduto = 1;
-- 1 | bmw 325 e36 | 7.00

-- Estoque teórico calculado pelo histórico
select
	p.idProduto,
	p.nomeProduto,
	p.quantidadeEstoque as estoque_atual,
	sum(t.qtdTransacao * tm.operacaoEstoque) as estoque_teorico
from atlas.produtos p
join atlas.transacoes t on p.idProduto = t.idProduto
join atlas.tipoMovimentacao tm on t.idTipoMovimentacao = tm.idTipoMovimentacao
where p.idProduto = 1
group by p.idProduto, p.nomeProduto, p.quantidadeEstoque;
/*Esses dois valores devem bater.
Se não baterem, o histórico revela exatamente onde está o problema.*/

-- R: 1 | bmw 325 e36 | 7.00 | 7.00

-- Corrigindo uma transação existente
update atlas.transacoes
set qtdTransacao = 3
where idTransacao = 1;

select idProduto, quantidadeEstoque
from atlas.produtos
where idProduto = 1;

-- Teste de DELETE
-- Deve falhar
delete from atlas.transacoes
where idTransacao = 1;

-- R: Error Code: 1644. Transações não podem ser excluídas. Utilize correção ou ajuste.
