# Escola Particular Ello Mineiro — MVP

Repositório do MVP (Produto Mínimo Viável) do sistema de gestão escolar da **Escola Particular Ello Mineiro**, desenvolvido como trabalho em grupo da disciplina de **Banco de Dados**.

A visão do sistema é centralizar a autenticação dos usuários para que, nas próximas fases, alunos consultem notas e frequência, professores façam os lançamentos acadêmicos e as equipes administrativa e de suporte gerenciem a plataforma. **Esta primeira fase cobre apenas cadastro e login**, com foco em segurança.

> **Status:** fase de documentação concluída; implementação ainda não iniciada. Veja a pasta [`docs/`](docs/).

---

## Escopo da Fase 1

| Dentro | Fora (fases futuras) |
|---|---|
| Cadastro público de usuários | Promoção de perfil pelo setor administrativo |
| Login com `user_login` ou e-mail + senha | Matrícula do aluno e registro funcional |
| Tela Home pós-login | Turmas, notas, presença, matérias, calendário |
| Armazenamento seguro de senhas | — |

Todo usuário cadastrado recebe o perfil padrão **`Usuario`**. Os perfis `Aluno`, `Professor`, `Suporte` e `Administrativo` já existem no banco, mas só serão atribuídos no futuro pelo setor administrativo ([regras futuras](docs/03-regras-futuras.md)).

### Front-end (estático)
HTML, CSS e JavaScript servidos pelo próprio backend, consumindo a API em `/api/*` com URLs relativas.
* **Login (`/`):** autenticação com `user_login` (nome de usuário) **ou** e-mail e senha.
* **Cadastro (`/cadastro`):** formulário de novos usuários. **Não há escolha de perfil.**
* **Home (`/home`):** página exibida após o login; os dados vêm de `GET /api/me`.

### Backend e API
| Método | Rota | Descrição |
|---|---|---|
| POST | `/api/auth/register` | Cria o usuário com o perfil `Usuario` |
| POST | `/api/auth/login` | Valida credenciais e grava o JWT em cookie `HttpOnly` |
| POST | `/api/auth/logout` | Apaga o cookie de sessão |
| GET | `/api/me` | Dados do usuário logado (sem a senha) |
| GET | `/health` | Verifica se a aplicação está no ar |

Contrato completo em [docs/01-requisitos.md](docs/01-requisitos.md).

### Segurança
* Senhas guardadas apenas como hash **Argon2id** ou **bcrypt**; nunca em texto puro.
* JWT (HS256, expiração curta) em cookie **`HttpOnly; Secure; SameSite=Lax`**: o JavaScript não acessa o token.
* Proteção contra CSRF (`SameSite`, `POST` só com JSON, checagem de `Origin`).
* SQL sempre parametrizado (prevenção de SQL Injection).
* Segredos em variáveis de ambiente; front e API na mesma origem (sem CORS).
* Dados pessoais (CPF, RG) tratados conforme a LGPD.

### Banco de dados (MySQL)
Esquema em [`database/seed.sql`](database/seed.sql):
* **`Permissoes`:** perfis fixos (`Usuario`, `Aluno`, `Professor`, `Suporte`, `Administrativo`).
* **`Usuarios`:** credenciais (`user_login`, e-mail, `senha_hash`), perfil e dados pessoais.
* **`Endereco`:** endereços do usuário (relacionamento 1:N).

---

## Tecnologias

| Camada | Escolha |
|---|---|
| Front-end | HTML5, CSS3, JavaScript (Fetch API) |
| Backend | Python + **FastAPI** (Swagger automático em `/docs`) |
| Acesso ao banco | **SQL puro** com PyMySQL (sem ORM), concentrado em `app/repositories/` |
| Banco | **MySQL** (TiDB Cloud Serverless) |
| Segurança | `argon2-cffi` ou `bcrypt` (hash) e PyJWT (token) |
| Hospedagem | **Render**: deploy único, front e API na mesma URL |

---

## Estrutura do repositório

```
app/          código FastAPI (main.py, db.py, repositories/, routers/)
database/     seed.sql (esquema do banco)
frontend/     index.html, cadastro.html, home.html, static/
docs/         requisitos, decisões de arquitetura e regras futuras
```

## Documentação

1. [Contexto e ponto de retomada](docs/00-contexto-handoff.md)
2. [Requisitos](docs/01-requisitos.md)
3. [Decisões de arquitetura](docs/02-decisoes-arquitetura.md)
4. [Regras de negócio futuras](docs/03-regras-futuras.md)
