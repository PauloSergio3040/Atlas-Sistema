📦 Atlas — Sistema de Controle de Estoque

Planejar. Construir. Validar. Operar.
Nada entra no estoque sem regra. Nada sai sem rastreio.

📌 Visão Geral

O Atlas é um projeto de banco de dados relacional desenvolvido em MySQL, focado em controle de estoque com integridade, rastreabilidade e coerência de negócio.

O objetivo do projeto não é apenas “funcionar”, mas resistir:

- a dados inválidos

- ao crescimento do sistema

- a erros da aplicação

- a decisões ruins no frontend ou backend

No Atlas, o banco impõe regras.
A aplicação apenas as respeita.

🎯 Objetivos do Projeto

- Modelar um sistema de estoque realista e auditável

- Garantir integridade referencial com chaves estrangeiras

- Aplicar unicidade baseada em regras de negócio

- Separar claramente:

- estrutura do banco

- dados iniciais

- testes de integridade

- consultas relacionais

- Preparar o banco para automações futuras (triggers e procedures)

- Praticar SQL como engenharia, não como tentativa-e-erro.

🧱 Estrutura Atual do Banco

Tabelas principais

- categorias
Classificação lógica dos produtos

- fornecedores
Origem dos itens (CNPJ único, dados completos)

- produtos
Entidade central do estoque

- tipoMovimentacao
Define regras semânticas de entrada, saída e ajustes

- transacoes
Histórico auditável de todas as movimentações

🔒 Decisões de Modelagem

Estoque e transações usam decimal(10,2)
→ suporte a quantidades fracionadas

Chaves estrangeiras garantem rastreabilidade total

unique aplicado somente onde duplicação quebra significado

Histórico nunca é sobrescrito

Nenhuma regra crítica fica implícita na aplicação

🧪 Estado Atual do Projeto

✅ Concluído

- Estrutura completa do banco

- Tipos de dados consolidados

- Chaves primárias e estrangeiras

- Regras de unicidade

- Dados iniciais para testes

- CRUD básico

- Testes com transaction, commit e rollback

- Testes de falha por integridade referencial

- Consultas com JOIN simples e múltiplos

- Organização dos scripts por responsabilidade

🔄 Em andamento

Consolidação de consultas relacionais

Validação semântica do estoque vs transações

📋 Próximos Passos (Banco de Dados)

ETAPA 6 — Regras Avançadas de Integridade e Performance

- Índices baseados em consultas reais

- Testes adicionais de inserções inválidas

- Validação global de consistência

ETAPA 7 — Triggers e Procedures

- Planejamento das regras automáticas

- Trigger de atualização de estoque

- Procedures para relatórios

- Documentação das regras de negócio

ETAPA 8 — Consultas Avançadas e KPIs

- Agregações

- CASE

- Subconsultas

- Window Functions

- KPIs de estoque (giro, cobertura, curva ABC)

ETAPA 9 — Segurança e Administração

- Usuários e permissões

- Estratégia de backup

- Restauração

- Monitoramento

ETAPA 10 — Finalização

- Dicionário de dados

- Views

- Validação com dados próximos do real

🚀 Visão de Futuro — Aplicação Completa

O Atlas será evoluído para uma aplicação web completa, desacoplada e escalável.

Backend:

- Node.js + TypeScript

- Arquitetura em camadas

- API REST

- Autenticação e autorização

- Docker

- Deploy via AWS ECS

Frontend:

- React + TypeScript

- Interface focada em leitura clara de dados

- Dashboards de estoque

- Relatórios gerenciais

- Infraestrutura

- Containers Docker

- AWS ECS

- Separação clara entre banco, backend e frontend

🧠 Filosofia do Projeto

Integridade > conveniência
Semântica antes de sintaxe
Banco como guardião das regras
Código explica decisões
Nada mágico, tudo rastreável
