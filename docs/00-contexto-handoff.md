# Contexto do Projeto e Ponto de Retomada

> Documento de **passagem de contexto**. Serve para iniciar uma nova conversa (humana ou com assistente de IA) em outra máquina sem perder o histórico de decisões. Leia também [01-requisitos.md](01-requisitos.md), [02-decisoes-arquitetura.md](02-decisoes-arquitetura.md) e [03-regras-futuras.md](03-regras-futuras.md).

## 1. Projeto

- **O quê:** MVP do sistema de gestão da escola particular **Ello Mineiro**, trabalho em grupo da disciplina de **Banco de Dados** (curso técnico). Projeto de aprendizagem.
- **Escopo da Fase 1:** apenas **cadastro e login** de usuários, com senhas em hash e rotas de API para o front. Notas, presença, turmas e calendário são fases futuras.
- **Estado atual:** **documentação fechada** (inclui `database/seed.sql` revisado) e esqueleto de pastas vazio. Nenhum código de aplicação foi escrito. Combinado com o usuário: **documentar tudo antes de implementar.**
- **Idioma:** português (documentação, nomes de campos e commits).

## 2. Decisões já tomadas

| Tema | Decisão |
|---|---|
| Banco | **MySQL** (mantém a modelagem do `seed.sql`). Hospedagem gratuita: **TiDB Cloud Serverless** (alternativas: Aiven; plano B: Neon/PostgreSQL) |
| Backend | **Python + FastAPI**, hospedado no **Render** (plano gratuito, com cold start) |
| Front-end | HTML/CSS/JS estáticos **servidos pelo próprio backend** (`GET /` retorna `index.html`; API em `/api/*`). **Deploy único, mesma origem, sem CORS** |
| Acesso ao banco | **SQL puro** (PyMySQL), **sem ORM**, para o grupo ver os `SELECT/INSERT/UPDATE`. Todo SQL em `app/repositories/`, sempre parametrizado (`%s`) |
| Senhas | Hash **Argon2id** ou **bcrypt**, feito só no backend |
| Token | **JWT** (PyJWT, HS256, expiração curta) |
| Armazenamento do JWT | **Cookie `HttpOnly; Secure; SameSite=Lax; Path=/`** (nome `access_token`). Login responde com `Set-Cookie` (sem token no corpo); `POST /api/auth/logout` apaga o cookie. CSRF mitigado por `SameSite`, `POST` só com JSON e checagem de `Origin` |
| Perfil no cadastro | O formulário **não pede perfil**. Todo usuário nasce com o perfil padrão **`Usuario`**. Perfis `Aluno/Professor/Suporte/Administrativo` existem no banco, mas só serão atribuídos no futuro pelo setor administrativo (ver doc 03) |
| `user_login` | **Nome de usuário escolhido pelo usuário** (3–30 caracteres, `a-z 0-9 . _`, único, imutável). **Não** é a matrícula. Matrícula (padrão X) e registro funcional (padrão Y) serão identificadores separados, futuros |
| Login | Aceita `user_login` **ou** e-mail + senha |

Tabelas do banco atual (`database/seed.sql`): `Permissoes`, `Usuarios`, `Endereco`.

## 3. Ponto resolvido: armazenamento do JWT

**Decisão (2026-10-08): cookie `HttpOnly; Secure; SameSite=Lax; Path=/`.** A opção `sessionStorage` foi descartada.

| Critério | Cookie HttpOnly (escolhido) | sessionStorage + header `Authorization: Bearer` |
|---|---|---|
| Roubo do token por XSS | **Resistente** (JS não lê o cookie) | Vulnerável |
| CSRF | Exposto, mitigável (`SameSite=Lax`, apenas `POST` JSON, checar `Origin`) | Não afetado |
| Simplicidade para o grupo entender | Média | **Alta** |
| Código do front | **Mais simples** (navegador envia sozinho) | Precisa anexar header em todo `fetch` |
| Encaixe com mesma origem | **Excelente** | Bom |
| Mobile / outro domínio no futuro | Pior | **Melhor** |
| Logout | Rota `POST /api/auth/logout` que apaga o cookie | `sessionStorage.clear()` (token segue válido até expirar) |

**Onde foi aplicada:**
- `01-requisitos.md`: RF06, RF09, RF12, RNF05, nova RNF18 (CSRF), rota `POST /api/auth/logout` e exemplos de login/logout com `Set-Cookie`.
- `02-decisoes-arquitetura.md`: seção 5 (atributos do cookie, fluxo, CSRF, limitações) e item 3 das "Perguntas em aberto".
- `03-regras-futuras.md`: seção 7 (revogação e token CSRF dedicado como evoluções).

## 4. Outras pendências

1. ~~Ajustar o `seed.sql`~~ → **feito** e movido para `database/seed.sql`: perfil `Usuario` + `DEFAULT 'Usuario'`; `senha_hash`; comentário de `user_login`; `CHECK` em `Endereco.situacao`; `utf8mb4`. **Em aberto (opcionais):** `atualizado_em`, `ultimo_login`, telefone só com dígitos.
2. ~~Atualizar o `README.md`~~ → **feito:** introdução única, sem escolha de perfil, stack alinhada (FastAPI, deploy único, SQL puro, cookie HttpOnly).
3. **Manter MySQL ou migrar para PostgreSQL** se o host gratuito falhar (item 4 do doc 02).
4. **Próximo passo:** iniciar o backend, na ordem `/health` → servir `index.html` → `register` → `login` → `me` → `logout`.

## 5. Estrutura de pastas criada (arquivos vazios)

```
app/ (main.py, db.py, repositories/, routers/)
database/ (seed.sql)
frontend/ (index.html, cadastro.html, home.html, static/css, static/js)
docs/
requirements.txt  .env.example  .gitignore  README.md
```

## 6. Prompt sugerido para iniciar o novo chat

> Leia `docs/00-contexto-handoff.md`, `docs/01-requisitos.md`, `docs/02-decisoes-arquitetura.md`, `docs/03-regras-futuras.md`, `database/seed.sql` e `README.md`. A documentação do MVP Ello Mineiro (cadastro e login) está fechada, incluindo a decisão do JWT em cookie HttpOnly. Vamos iniciar o backend FastAPI na ordem da seção 4, item 4, seguindo as regras de SQL puro do doc 02.
