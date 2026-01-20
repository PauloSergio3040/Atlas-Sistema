# Projeto Atlas — Controle de Estoque

O **Projeto Atlas** é um sistema de banco de dados relacional para controle de estoque, movimentações e auditoria, desenvolvido em MySQL com foco em **integridade, rastreabilidade e regras de negócio no nível do banco**.

O projeto evolui de um modelo CRUD tradicional para uma arquitetura orientada a histórico, onde o estoque é sempre consequência das movimentações registradas.

---

## 🎯 Objetivos do Projeto

* Garantir **consistência de estoque** independentemente do cliente que consome o banco
* Centralizar **regras de negócio no banco de dados**
* Permitir **auditoria completa** de movimentações
* Fornecer **camada de leitura padronizada** para APIs e BI
* Servir como projeto didático e portfólio em SQL avançado

---

## 🧱 Arquitetura Geral

O projeto é dividido logicamente em quatro camadas:

1. **Modelo Transacional**
   Tabelas responsáveis por dados mestres e movimentações (produtos, transações, tipos de movimentação).

2. **Regras de Negócio (Triggers)**
   Garantem integridade, bloqueios e atualização automática de estoque.

3. **Camada Analítica (Views)**
   Consolida dados para leitura, relatórios e dashboards.

4. **Interface de Consumo (Procedures)**
   Fornece operações prontas para APIs REST ou ferramentas de BI.

---

## 📦 Estrutura de Tabelas

### Tabelas Principais

* **categorias** — Classificação dos produtos
* **fornecedores** — Origem dos produtos
* **produtos** — Cadastro e estoque físico atual
* **tipoMovimentacao** — Define impacto no estoque (entrada, saída, neutra)
* **transacoes** — Histórico imutável de movimentações

### Tabelas de Controle

* **periodoEstoque** — Controle de meses abertos/fechados
* **auditoria** — Registro de ações sensíveis no sistema

---

## 🔐 Regras de Negócio Implementadas

* Produto **não nasce com estoque**
* Estoque inicial é registrado via movimentação específica
* Estoque é atualizado automaticamente após cada transação
* Estoque negativo é bloqueado antes da gravação
* Transações **não podem ser excluídas**, apenas corrigidas
* Correções ajustam o estoque pela diferença (não duplicam impacto)
* Transações em períodos fechados são bloqueadas
* Toda transação é auditada automaticamente

Essas regras tornam o banco resiliente a erros de aplicação ou uso indevido.

---

## ⚙️ Triggers

Triggers são usadas para:

* Bloquear estoque negativo (`BEFORE INSERT`)
* Atualizar estoque automaticamente (`AFTER INSERT`)
* Ajustar estoque em correções (`AFTER UPDATE`)
* Impedir exclusão de transações (`BEFORE DELETE`)
* Bloquear lançamentos em período fechado
* Registrar auditoria de operações

---

## 👁️ Views (Camada de Leitura)

As views padronizam consultas e evitam joins repetitivos:

* **vw_estoque_atual** — Estoque consolidado por produto
* **vw_historico_estoque** — Histórico legível de movimentações
* **vw_giro_estoque** — Giro estimado por produto
* **vw_produtos_parados** — Produtos sem saída recente
* **vw_cobertura_estoque** — Cobertura estimada em dias
* **vw_base_curva_abc** — Base financeira da curva ABC
* **vw_curva_abc** — Classificação ABC automática

---

## 📊 Relatórios e Procedures

Procedures prontas para consumo externo:

* **sp_relatorio_estoque** — Visão consolidada de estoque e giro
* **sp_historico_produto_periodo** — Histórico por produto e período
* **sp_relatorio_curva_abc** — Curva ABC pronta para BI
* **sp_simula_movimentacoes** — Geração de carga de teste

Essas procedures permitem uso direto em APIs REST ou dashboards.

---

## 🧪 Testes e Validações

O script inclui testes para:

* Unicidade de categorias e fornecedores
* Integridade referencial (FKs)
* Bloqueio de estoque negativo
* Atualização automática de estoque
* Correção de transações
* Bloqueio de exclusão

Cada falha esperada é documentada com o erro retornado pelo MySQL.

---

## 🚀 Tecnologias Utilizadas

### Banco de Dados

* MySQL 8+
* SQL ANSI
* Triggers, Views e Stored Procedures
* Window Functions

### Backend

* Node.js
* TypeScript
* API REST
* Acesso ao banco via Views e Stored Procedures

### Frontend

* React
* TypeScript
* Consumo de API REST

### Infraestrutura

* Docker
* AWS ECS (Fargate)
* AWS RDS (MySQL)
* AWS Free Tier

---

## 📌 Observações de Design

* O **histórico é a fonte da verdade**
* O estoque físico é sempre reconciliável com o estoque teórico
* Views representam a camada oficial de leitura
* O banco foi projetado para reduzir lógica na aplicação

---

## 📈 Próximos Passos

* Implementar backend em Node.js + TypeScript
* Criar frontend em React + TypeScript
* Containerizar backend e frontend com Docker
* Deploy em AWS ECS (Fargate)
* Utilizar RDS MySQL como banco gerenciado
* Expor API REST para consumo do frontend e BI
* Monitoramento básico via CloudWatch

---

## 🏗️ Arquitetura de Deploy

O projeto será implantado em ambiente cloud utilizando contêineres Docker.

Arquitetura prevista:

* **Frontend**: React + TypeScript, servido via container (Nginx)
* **Backend**: Node.js + TypeScript, exposto via API REST
* **Banco de Dados**: MySQL em AWS RDS
* **Orquestração**: AWS ECS (Fargate)

A aplicação é stateless, permitindo escalabilidade horizontal e reinicialização segura dos containers.

---

## 👤 Autor

Projeto desenvolvido sem uso de IA para códigos diretos, apenas revisão e filtragem de documentaçòes. foi abordado o estudo avançado de modelagem, arquitetura de bancos de dados e integração full stack, com foco em boas práticas de engenharia de software, backend e dados.
