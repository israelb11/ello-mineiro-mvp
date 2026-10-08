# Contexto do Projeto e Ponto de Retomada

> Documento de **passagem de contexto**. Serve para iniciar uma nova conversa (humana ou com assistente de IA) em outra máquina sem perder o histórico de decisões. Leia também [01-requisitos.md](01-requisitos.md), [02-decisoes-arquitetura.md](02-decisoes-arquitetura.md) e [03-regras-futuras.md](03-regras-futuras.md).

## 1. Projeto

- **O quê:** MVP do sistema de gestão da escola particular **Ello Mineiro**, trabalho em grupo da disciplina de **Banco de Dados** (curso técnico). Projeto de aprendizagem.
- **Escopo da Fase 1:** apenas **cadastro e login** de usuários, com senhas em hash e rotas de API para o front. Notas, presença, turmas e calendário são fases futuras.
- **Estado atual:** **somente documentação e esqueleto de pastas vazios.** Nenhum código de aplicação foi escrito. Combinado com o usuário: **documentar tudo antes de implementar.**
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
| Perfil no cadastro | O formulário **não pede perfil**. Todo usuário nasce com o perfil padrão **`Usuario`**. Perfis `Aluno/Professor/Suporte/Administrativo` existem no banco, mas só serão atribuídos no futuro pelo setor administrativo (ver doc 03) |
| `user_login` | **Nome de usuário escolhido pelo usuário** (3–30 caracteres, `a-z 0-9 . _`, único, imutável). **Não** é a matrícula. Matrícula (padrão X) e registro funcional (padrão Y) serão identificadores separados, futuros |
| Login | Aceita `user_login` **ou** e-mail + senha |

Tabelas do banco atual (`seed.sql`, na raiz): `Permissoes`, `Usuarios`, `Endereco`.

## 3. Ponto pendente (retomar daqui)

**Onde armazenar o JWT no front-end: cookie HttpOnly ou `sessionStorage`?**

| Critério | Cookie HttpOnly | sessionStorage + header `Authorization: Bearer` |
|---|---|---|
| Roubo do token por XSS | **Resistente** (JS não lê o cookie) | Vulnerável |
| CSRF | Exposto, mitigável (`SameSite=Lax`, apenas `POST` JSON, checar `Origin`) | Não afetado |
| Simplicidade para o grupo entender | Média | **Alta** |
| Código do front | **Mais simples** (navegador envia sozinho) | Precisa anexar header em todo `fetch` |
| Encaixe com mesma origem | **Excelente** | Bom |
| Mobile / outro domínio no futuro | Pior | **Melhor** |
| Logout | Rota `POST /api/auth/logout` que apaga o cookie | `sessionStorage.clear()` (token segue válido até expirar) |

**Recomendação da análise:** **cookie HttpOnly** (`HttpOnly; Secure; SameSite=Lax; Path=/`), por causa do foco em segurança e da arquitetura de mesma origem. Alternativa aceitável para MVP acadêmico: `sessionStorage`, documentando o risco de XSS (evitar `innerHTML` com dados do usuário e usar `Content-Security-Policy`).

**Efeito nos documentos ao decidir:**
- **Cookie:** o login responde com `Set-Cookie` (sem token no corpo); criar `POST /api/auth/logout`; ajustar RF06 e RF12 em `01-requisitos.md`.
- **sessionStorage:** o login devolve `access_token` no JSON (como no exemplo atual do doc 01); sem rota de logout no servidor.

Em ambos os casos, registrar a decisão na seção "Perguntas em aberto" do doc 02 (item 3).

## 4. Outras pendências

1. **Ajustar o `seed.sql`** (ainda não alterado): inserir o perfil `Usuario` em `Permissoes`; `permissao_nome DEFAULT 'Usuario'`; renomear `senha` para `senha_hash`; trocar o comentário de `user_login` (hoje diz "Matrícula ou Registro"); `CHECK` em `Endereco.situacao`; `utf8mb4`; sugestão de mover para `database/`.
2. **Atualizar o `README.md`:** remover a escolha de perfil no cadastro, unificar as duas introduções duplicadas e alinhar a stack (FastAPI, deploy único, SQL puro).
3. **Manter MySQL ou migrar para PostgreSQL** se o host gratuito falhar (item 4 do doc 02).
4. Só depois: iniciar o backend, na ordem `/health` → servir `index.html` → `register` → `login` → `me`.

## 5. Estrutura de pastas criada (arquivos vazios)

```
app/ (main.py, db.py, repositories/, routers/)
database/
frontend/ (index.html, cadastro.html, home.html, static/css, static/js)
docs/
requirements.txt  .env.example  .gitignore  seed.sql  README.md
```

## 6. Prompt sugerido para iniciar o novo chat

> Leia `docs/00-contexto-handoff.md`, `docs/01-requisitos.md`, `docs/02-decisoes-arquitetura.md`, `docs/03-regras-futuras.md`, `seed.sql` e `README.md`. Estamos na fase de documentação do MVP Ello Mineiro (cadastro e login). Ainda **não implemente código**. Vamos resolver o ponto pendente da seção 3 do arquivo de contexto (armazenamento do JWT), atualizar os documentos conforme a decisão e depois ajustar o `seed.sql` e o `README.md`.
