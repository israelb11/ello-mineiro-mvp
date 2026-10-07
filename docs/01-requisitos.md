# Requisitos — MVP Ello Mineiro (Fase 1: Cadastro e Login)

> Status: **rascunho para revisão**. Nenhuma implementação foi iniciada.

## 1. Escopo

**Dentro (Fase 1):** cadastro de usuários, login, controle de acesso por perfil (RBAC), tela Home pós-login, armazenamento seguro de senhas.

**Fora (fases futuras):** notas, presença, matérias, calendário acadêmico, consulta de professores. (O banco desta fase não os modela.)

## 2. Atores

| Ator | Descrição |
|---|---|
| Visitante | Não autenticado; pode se cadastrar e fazer login |
| Aluno | Perfil `Aluno` |
| Professor | Perfil `Professor` |
| Suporte | Perfil `Suporte` |
| Administrativo | Perfil `Administrativo` |

## 3. Requisitos Funcionais (RF)

| ID | Requisito | Prioridade |
|---|---|---|
| RF01 | O sistema deve permitir cadastrar um usuário com: nome, e-mail, `user_login`, senha, perfil e dados pessoais opcionais (CPF, RG, nascimento, gênero, telefones) | Alta |
| RF02 | O sistema deve permitir cadastrar ao menos um endereço associado ao usuário | Média |
| RF03 | O sistema deve validar unicidade de `user_login`, `email`, `cpf` e `rg` e retornar erro claro em caso de duplicidade | Alta |
| RF04 | O sistema deve validar formato de e-mail, CPF (dígitos verificadores), CEP, UF e telefone | Alta |
| RF05 | O usuário deve poder fazer login com `user_login` **ou** `email` + senha | Alta |
| RF06 | Em login válido, a API deve emitir um token de acesso (JWT) com expiração | Alta |
| RF07 | Em login inválido, a API deve responder com mensagem genérica (sem revelar se o usuário existe) | Alta |
| RF08 | Usuários com `ativo = false` não podem fazer login | Alta |
| RF09 | A Home só pode ser acessada com token válido; sem token, redireciona para login | Alta |
| RF10 | A API deve expor uma rota autenticada que retorna os dados do usuário logado (`GET /me`), sem a senha | Alta |
| RF11 | O perfil (`permissao_nome`) deve ser respeitado nas rotas protegidas (RBAC) | Média |
| RF12 | O usuário deve poder encerrar a sessão (logout no front: descartar token) | Média |

### Decisão de negócio pendente (importante)
Hoje o README diz que a **tela de cadastro permite escolher o perfil**. Isso permitiria que qualquer visitante se cadastrasse como `Administrativo`. Opções:

- **A (recomendada):** cadastro público cria sempre `Aluno`; perfis `Professor/Suporte/Administrativo` só podem ser criados por um `Administrativo` autenticado (ou via seed para o 1º admin).
- **B:** manter escolha livre, apenas para fins de demonstração acadêmica (documentar o risco).

## 4. Requisitos Não Funcionais (RNF)

### Segurança
| ID | Requisito |
|---|---|
| RNF01 | Senhas armazenadas apenas como hash com **Argon2id** ou **bcrypt** (salt automático). Nunca em texto puro nem em logs |
| RNF02 | Política de senha: mínimo 8 caracteres (recomendado 10+), validada no backend |
| RNF03 | Toda comunicação via **HTTPS** |
| RNF04 | Queries parametrizadas / ORM (prevenção de SQL Injection) |
| RNF05 | Front e API na mesma origem (sem CORS habilitado); se o token for cookie, usar `HttpOnly; Secure; SameSite=Lax` |
| RNF06 | Segredos (chave JWT, string de conexão) em variáveis de ambiente, nunca no Git |
| RNF07 | Limitação de tentativas de login (rate limiting) contra força bruta |
| RNF08 | JWT com expiração curta (ex.: 30–60 min) e algoritmo fixo (HS256) |
| RNF09 | Dados pessoais (CPF, RG) tratados conforme **LGPD**: coletar só o necessário, nunca expor em respostas desnecessárias |
| RNF10 | Mensagens de erro não vazam detalhes internos (stack trace, SQL) |

### Qualidade
| ID | Requisito |
|---|---|
| RNF11 | API REST em JSON, com códigos HTTP corretos (201, 400, 401, 403, 409, 422) |
| RNF12 | Documentação automática da API (OpenAPI/Swagger — nativa do FastAPI) |
| RNF13 | Custo de hospedagem **zero** |
| RNF14 | Banco normalizado (mínimo 3FN) com scripts versionados no repositório |
| RNF15 | Código e documentação em português (nomes de campos já seguem isso) |
| RNF16 | Tempo de resposta aceitável (< 1s em operação normal; cold start do plano grátis é tolerado) |
| RNF17 | Responsividade básica do front (mobile e desktop) |

## 5. Regras de Negócio

- RN01: `user_login` (matrícula/registro) é único e imutável após criado.
- RN02: Todo usuário tem exatamente 1 perfil.
- RN03: Exclusão de usuário é **lógica** (`ativo = false`), preservando histórico futuro (notas, presença).
- RN04: Um usuário pode ter vários endereços; apenas um deve estar `ATIVO` por tipo.

## 6. Rotas da API (contrato inicial)

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| POST | `/api/auth/register` | Pública (ver decisão acima) | Cria usuário |
| POST | `/api/auth/login` | Pública | Retorna JWT |
| GET | `/api/me` | Token | Dados do usuário logado |
| GET | `/api/permissoes` | Pública | Lista perfis (para o formulário) |
| GET | `/health` | Pública | Verifica se a API está no ar |
| GET | `/` | Pública | Retorna `index.html` (login), servido pelo próprio backend |
| GET | `/cadastro`, `/home` | Pública (página) | Páginas estáticas; os dados só vêm da API autenticada |

Exemplo de login:
```json
// POST /api/auth/login
{ "identificador": "2026001 ou aluno@email.com", "senha": "********" }
// 200
{ "access_token": "<jwt>", "token_type": "bearer", "expires_in": 3600 }
```

## 7. Revisão do `seed.sql` (pontos para discutir)

| Ponto | Observação |
|---|---|
| `senha VARCHAR(255)` | Adequado para hash bcrypt (60) / Argon2 (~100). Renomear para `senha_hash` deixa a intenção clara |
| `Permissoes` com PK textual | Funciona, mas PK inteira é mais comum; `ON UPDATE CASCADE` já mitiga. Ok para MVP |
| `cpf`, `rg` UNIQUE e nullable | OK em MySQL (permite vários NULL). Considere obrigar CPF |
| `telefone VARCHAR(15)` | Suficiente para `(31)99999-9999` se guardar só dígitos; padronizar |
| `criado_em` | Adicionar `atualizado_em` e `ultimo_login` (opcional) |
| `Endereco.situacao` | Trocar por `CHECK (situacao IN ('ATIVO','INATIVO'))` |
| Índices | `user_login` e `email` já têm índice via UNIQUE |
| Sem `CREATE DATABASE`/charset | Definir `utf8mb4` para acentos |
| README | Há duas introduções duplicadas (linhas 1–13 e 15+); unificar |

## 8. Próximos passos
1. Revisar e aprovar este documento.
2. Fechar decisões em [02-decisoes-arquitetura.md](02-decisoes-arquitetura.md).
3. Ajustar `seed.sql`.
4. Só então iniciar o backend.
