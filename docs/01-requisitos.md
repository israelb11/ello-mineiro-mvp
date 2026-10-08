# Requisitos — MVP Ello Mineiro (Fase 1: Cadastro e Login)

> Status: **rascunho para revisão**. Nenhuma implementação foi iniciada.
>
> Regras de negócio válidas para o futuro, mas **fora do código desta fase**, estão em [03-regras-futuras.md](03-regras-futuras.md).

## 1. Escopo

**Dentro (Fase 1):** cadastro público de usuários (sempre com o perfil padrão `Usuario`), login, tela Home pós-login, armazenamento seguro de senhas.

**Fora (fases futuras):** promoção de perfil pelo setor administrativo, matrícula do aluno e registro de funcionário, vínculo com turmas, notas, presença, matérias, calendário acadêmico, consulta de professores. Ver [03-regras-futuras.md](03-regras-futuras.md). Os perfis `Aluno`, `Professor`, `Suporte` e `Administrativo` já existem no banco, mas **não são atribuídos por nenhuma tela ou rota do MVP**.

## 2. Atores

| Ator | Descrição |
|---|---|
| Visitante | Não autenticado; pode se cadastrar e fazer login |
| Usuário | Autenticado com o perfil padrão `Usuario` (único ator logado no MVP) |
| Aluno, Professor, Suporte, Administrativo | Perfis existentes no banco; atribuídos apenas em fases futuras (ver doc 03) |

## 3. Requisitos Funcionais (RF)

| ID | Requisito | Prioridade |
|---|---|---|
| RF01 | O sistema deve permitir cadastrar um usuário com: nome, e-mail, `user_login` (nome de usuário escolhido por ele), senha e dados pessoais opcionais (CPF, RG, nascimento, gênero, telefones). **O formulário não oferece escolha de perfil** | Alta |
| RF02 | O sistema deve permitir cadastrar ao menos um endereço associado ao usuário | Média |
| RF03 | O sistema deve validar unicidade de `user_login`, `email`, `cpf` e `rg` e retornar erro claro em caso de duplicidade | Alta |
| RF04 | O sistema deve validar formato de e-mail, CPF (dígitos verificadores), CEP, UF e telefone | Alta |
| RF05 | O usuário deve poder fazer login com `user_login` **ou** `email` + senha | Alta |
| RF06 | Em login válido, a API deve emitir um token de acesso (JWT) com expiração | Alta |
| RF07 | Em login inválido, a API deve responder com mensagem genérica (sem revelar se o usuário existe) | Alta |
| RF08 | Usuários com `ativo = false` não podem fazer login | Alta |
| RF09 | A Home só pode ser acessada com token válido; sem token, redireciona para login | Alta |
| RF10 | A API deve expor uma rota autenticada que retorna os dados do usuário logado (`GET /me`), sem a senha | Alta |
| RF11 | O perfil (`permissao_nome`) deve ser lido do banco (nunca do corpo da requisição) e respeitado nas rotas protegidas; no MVP, todo usuário tem o perfil `Usuario` | Média |
| RF13 | Todo novo cadastro deve receber automaticamente o perfil `Usuario`; qualquer campo de perfil enviado na requisição deve ser ignorado ou rejeitado | Alta |
| RF12 | O usuário deve poder encerrar a sessão (logout no front: descartar token) | Média |

### Decisão de negócio (resolvida)
O README antigo previa que a tela de cadastro permitisse escolher o perfil, o que deixaria qualquer visitante se cadastrar como `Administrativo`. **Decisão:** o cadastro público **não** pede perfil. Todo usuário nasce com o perfil padrão `Usuario` (acesso básico: calendário e dados públicos, sem dados pessoais de terceiros, em linha com a LGPD). Os demais perfis serão liberados futuramente pelo setor administrativo (ver [03-regras-futuras.md](03-regras-futuras.md)). O primeiro administrador, quando necessário, será criado por seed/script, nunca por tela.

### Identificador de login (resolvido)
O `user_login` é um **nome de usuário escolhido pelo próprio usuário** no cadastro (3 a 30 caracteres, apenas `a-z`, `0-9`, `.`, `_`; único; guardado em minúsculas). Ele **não é** a matrícula nem o registro funcional. Estes são identificadores institucionais, emitidos pela escola no futuro, em tabelas próprias.

## 4. Requisitos Não Funcionais (RNF)

### Segurança
| ID | Requisito |
|---|---|
| RNF01 | Senhas armazenadas apenas como hash com **Argon2id** ou **bcrypt** (salt automático). Nunca em texto puro nem em logs |
| RNF02 | Política de senha: mínimo 8 caracteres (recomendado 10+), validada no backend |
| RNF03 | Toda comunicação via **HTTPS** |
| RNF04 | SQL puro com queries **sempre parametrizadas** (`%s`), concentrado em `app/repositories/` (prevenção de SQL Injection). Ver [02-decisoes-arquitetura.md](02-decisoes-arquitetura.md) |
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

- RN01: `user_login` (nome de usuário) é único e imutável após criado. Não representa matrícula nem registro funcional.
- RN02: Todo usuário tem exatamente 1 perfil. No cadastro, o perfil é sempre `Usuario`.
- RN05: O perfil nunca é definido pelo próprio usuário nem pelo corpo da requisição de cadastro.
- RN03: Exclusão de usuário é **lógica** (`ativo = false`), preservando histórico futuro (notas, presença).
- RN04: Um usuário pode ter vários endereços; apenas um deve estar `ATIVO` por tipo.

## 6. Rotas da API (contrato inicial)

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| POST | `/api/auth/register` | Pública | Cria usuário com o perfil padrão `Usuario` (sem campo de perfil) |
| POST | `/api/auth/login` | Pública | Retorna JWT |
| GET | `/api/me` | Token | Dados do usuário logado (inclui o perfil) |
| GET | `/health` | Pública | Verifica se a API está no ar |
| GET | `/` | Pública | Retorna `index.html` (login), servido pelo próprio backend |
| GET | `/cadastro`, `/home` | Pública (página) | Páginas estáticas; os dados só vêm da API autenticada |

Exemplo de login:
```json
// POST /api/auth/login
{ "identificador": "maria.silva ou maria@email.com", "senha": "********" }
// 200
{ "access_token": "<jwt>", "token_type": "bearer", "expires_in": 3600 }
```

## 7. Revisão do `seed.sql` (pontos para discutir)

| Ponto | Observação |
|---|---|
| `senha VARCHAR(255)` | Adequado para hash bcrypt (60) / Argon2 (~100). Renomear para `senha_hash` deixa a intenção clara |
| Perfil padrão | Inserir `Usuario` em `Permissoes` e definir `permissao_nome DEFAULT 'Usuario'` em `Usuarios` |
| Comentário de `user_login` | Hoje diz "Matrícula ou Registro"; passar a "nome de usuário escolhido pelo usuário" |
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
3. Ajustar `seed.sql` (itens da seção 7).
4. Atualizar o `README.md` (remover a escolha de perfil e a duplicidade de introdução).
5. Só então iniciar o backend.
