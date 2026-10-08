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
| RF06 | Em login válido, a API deve emitir um token de acesso (JWT) com expiração, entregue **somente** em cookie `HttpOnly` via `Set-Cookie` (o token **não** aparece no corpo da resposta) | Alta |
| RF07 | Em login inválido, a API deve responder com mensagem genérica (sem revelar se o usuário existe) | Alta |
| RF08 | Usuários com `ativo = false` não podem fazer login | Alta |
| RF09 | Os dados da Home só podem ser obtidos com cookie de sessão válido; se `GET /api/me` responder `401`, o front redireciona para o login (`/`) | Alta |
| RF10 | A API deve expor uma rota autenticada que retorna os dados do usuário logado (`GET /me`), sem a senha | Alta |
| RF11 | O perfil (`permissao_nome`) deve ser lido do banco (nunca do corpo da requisição) e respeitado nas rotas protegidas; no MVP, todo usuário tem o perfil `Usuario` | Média |
| RF13 | Todo novo cadastro deve receber automaticamente o perfil `Usuario`; qualquer campo de perfil enviado na requisição deve ser ignorado ou rejeitado | Alta |
| RF12 | O usuário deve poder encerrar a sessão por `POST /api/auth/logout`, que apaga o cookie do token (`Max-Age=0`) | Média |

### Decisão de negócio (resolvida)
O README antigo previa que a tela de cadastro permitisse escolher o perfil, o que deixaria qualquer visitante se cadastrar como `Administrativo`. **Decisão:** o cadastro público **não** pede perfil. Todo usuário nasce com o perfil padrão `Usuario` (acesso básico: calendário e dados públicos, sem dados pessoais de terceiros, em linha com a LGPD). Os demais perfis serão liberados futuramente pelo setor administrativo (ver [03-regras-futuras.md](03-regras-futuras.md)). O primeiro administrador, quando necessário, será criado por seed/script, nunca por tela.

### Identificador de login (resolvido)
O `user_login` é um **nome de usuário escolhido pelo próprio usuário** no cadastro (3 a 30 caracteres, apenas `a-z`, `0-9`, `.`, `_`; único; guardado em minúsculas). Ele **não é** a matrícula nem o registro funcional. Estes são identificadores institucionais, emitidos pela escola no futuro, em tabelas próprias.

### Armazenamento do JWT (resolvido)
O JWT fica em **cookie `HttpOnly; Secure; SameSite=Lax; Path=/`**, definido pelo backend no login. O JavaScript do front **não lê nem guarda** o token: o navegador o envia sozinho em toda chamada a `/api/*` (mesma origem). Motivos: resistência a roubo do token por XSS e encaixe natural com a arquitetura de mesma origem. Detalhes em [02-decisoes-arquitetura.md](02-decisoes-arquitetura.md#5-estratégia-de-autenticação).

## 4. Requisitos Não Funcionais (RNF)

### Segurança
| ID | Requisito |
|---|---|
| RNF01 | Senhas armazenadas apenas como hash com **Argon2id** ou **bcrypt** (salt automático). Nunca em texto puro nem em logs |
| RNF02 | Política de senha: mínimo 8 caracteres (recomendado 10+), validada no backend |
| RNF03 | Toda comunicação via **HTTPS** |
| RNF04 | SQL puro com queries **sempre parametrizadas** (`%s`), concentrado em `app/repositories/` (prevenção de SQL Injection). Ver [02-decisoes-arquitetura.md](02-decisoes-arquitetura.md) |
| RNF05 | Front e API na mesma origem (sem CORS habilitado). Cookie do token com `HttpOnly; Secure; SameSite=Lax; Path=/` e `Max-Age` igual à expiração do JWT |
| RNF06 | Segredos (chave JWT, string de conexão) em variáveis de ambiente, nunca no Git |
| RNF07 | Limitação de tentativas de login (rate limiting) contra força bruta |
| RNF08 | JWT com expiração curta (ex.: 30–60 min) e algoritmo fixo (HS256) |
| RNF09 | Dados pessoais (CPF, RG) tratados conforme **LGPD**: coletar só o necessário, nunca expor em respostas desnecessárias |
| RNF10 | Mensagens de erro não vazam detalhes internos (stack trace, SQL) |
| RNF18 | Proteção contra **CSRF** nas rotas que alteram estado: `SameSite=Lax`, somente `POST` com corpo JSON (`Content-Type: application/json`) e checagem do header `Origin` contra o host da aplicação. Nenhuma rota `GET` altera dados |

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
| POST | `/api/auth/login` | Pública | Valida credenciais e grava o JWT em cookie `HttpOnly` (`Set-Cookie`) |
| POST | `/api/auth/logout` | Cookie | Apaga o cookie do token (`Max-Age=0`) e responde `204` |
| GET | `/api/me` | Cookie | Dados do usuário logado (inclui o perfil) |
| GET | `/health` | Pública | Verifica se a API está no ar |
| GET | `/` | Pública | Retorna `index.html` (login), servido pelo próprio backend |
| GET | `/cadastro`, `/home` | Pública (página) | Páginas estáticas; os dados só vêm da API autenticada |

Exemplo de login:
```http
POST /api/auth/login
Content-Type: application/json

{ "identificador": "maria.silva ou maria@email.com", "senha": "********" }
```
```http
HTTP/1.1 200 OK
Set-Cookie: access_token=<jwt>; HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=3600
Content-Type: application/json

{ "mensagem": "Login realizado com sucesso", "expires_in": 3600 }
```

Exemplo de logout:
```http
POST /api/auth/logout
```
```http
HTTP/1.1 204 No Content
Set-Cookie: access_token=; HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=0
```

> O token **nunca** vai no corpo da resposta. Em login inválido: `401` com mensagem genérica (RF07). Em rota protegida sem cookie ou com token expirado: `401`.

## 7. Revisão do `database/seed.sql`

| Ponto | Situação |
|---|---|
| `senha VARCHAR(255)` | **Feito:** renomeada para `senha_hash` (255 comporta bcrypt ~60 e Argon2id ~100) |
| Perfil padrão | **Feito:** `Usuario` inserido em `Permissoes` e `permissao_nome DEFAULT 'Usuario'` |
| Comentário de `user_login` | **Feito:** "nome de usuário escolhido pelo usuário" |
| `Permissoes` com PK textual | Mantida (ok para MVP; `ON UPDATE CASCADE` já mitiga) |
| `cpf`, `rg` UNIQUE e nullable | Mantidos opcionais (LGPD, doc 03 §6). MySQL permite vários NULL |
| `telefone VARCHAR(15)` | Mantido. **Em aberto:** padronizar só dígitos |
| `atualizado_em` / `ultimo_login` | **Em aberto** (opcional) |
| `Endereco.situacao` | **Feito:** `NOT NULL DEFAULT 'ATIVO'` + `CHECK (situacao IN ('ATIVO','INATIVO'))`. O backend também valida (o `CHECK` só é aplicado no MySQL 8.0.16+; no TiDB depende de `tidb_enable_check_constraint`) |
| Índices | `user_login` e `email` já têm índice via UNIQUE |
| Charset | **Feito:** tabelas com `utf8mb4` / `utf8mb4_unicode_ci` |
| Local do arquivo | **Feito:** movido da raiz para `database/seed.sql` |
| README | **Feito:** introduções unificadas e stack alinhada |

## 8. Próximos passos
1. Revisar e aprovar este documento.
2. ~~Fechar decisões em [02-decisoes-arquitetura.md](02-decisoes-arquitetura.md)~~ (resta só o plano B do banco).
3. ~~Ajustar `seed.sql`~~ (itens opcionais em aberto na seção 7).
4. ~~Atualizar o `README.md`~~.
5. Iniciar o backend.
