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

## 4. Pontos em aberto (retomar daqui)

Antes de iniciar o código do backend, há dois pontos em aberto para avaliar ou confirmar:

### 4.1. Colunas opcionais em `database/seed.sql`
- **`atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`** na tabela `Usuarios`: rastreia quando o cadastro foi alterado.
- **`ultimo_login DATETIME NULL`** na tabela `Usuarios`: atualizado no login com sucesso para fins de auditoria/suporte.
- **Padronização de telefone**: manter `VARCHAR(15)` ou restringir a `VARCHAR(11)` (apenas dígitos numéricos `DDD + número`).
> *Observação:* O `seed.sql` atual já é totalmente funcional e suficiente para o MVP. Se o grupo preferir simplicidade, pode-se manter como está.

### 4.2. Estratégia de hospedagem do Banco (MySQL vs PostgreSQL)
- **Principal:** MySQL no **TiDB Cloud Serverless** (compatível com MySQL, mantém 100% da sintaxe do `seed.sql`).
- **Plano B:** **Neon (PostgreSQL)** se houver indisponibilidade ou dificuldade no TiDB Cloud. *Impacto se mudar:* adaptar `AUTO_INCREMENT` para `GENERATED ALWAYS AS IDENTITY` e trocar driver `PyMySQL` por `psycopg` ou `asyncpg`.

---

## 5. Próximo passo após fechar os pontos acima

Iniciar a implementação do backend em Python + FastAPI, na seguinte ordem incremental:
1. Configuração de ambiente e dependências (`requirements.txt`, `.env.example`).
2. Conexão com o banco (`app/db.py`) e rota `GET /health`.
3. Montagem dos arquivos estáticos (`StaticFiles`) servindo `frontend/index.html` em `GET /`.
4. Repositórios SQL (`app/repositories/usuarios.py`, `enderecos.py`).
5. Rotas de autenticação (`POST /api/auth/register`, `POST /api/auth/login`, `POST /api/auth/logout`).
6. Rota protegida `GET /api/me` lendo token do cookie `HttpOnly`.
7. Telas do front-end (`index.html`, `cadastro.html`, `home.html`) consumindo as rotas.

## 6. Estrutura de pastas do projeto

```
ello-mineiro-mvp/
├── docs/                # 00-contexto-handoff, 01-requisitos, 02-decisoes, 03-regras
├── database/            # seed.sql (esquema do MySQL)
├── app/                 # Backend FastAPI
│   ├── main.py          # App FastAPI, montagem de estáticos e roteadores
│   ├── db.py            # Conexão SQL puro
│   ├── repositories/    # Todo o SQL fica aqui (SQL parametrizado com %s)
│   └── routers/         # Endpoints da API (/api/auth, /api/me)
├── frontend/            # Servido pelo próprio FastAPI
│   ├── index.html       # Login (rota "/")
│   ├── cadastro.html    # Cadastro (rota "/cadastro")
│   ├── home.html        # Home / Dashboard (rota "/home")
│   └── static/          # CSS e JS
├── requirements.txt
├── .env.example
├── .gitignore
└── README.md
```

## 7. Prompts sugeridos para iniciar o novo chat

### Opção A: Se quiser resolver os pontos pendentes antes de codificar
> "Leia `docs/00-contexto-handoff.md`, `docs/01-requisitos.md`, `docs/02-decisoes-arquitetura.md`, `docs/03-regras-futuras.md`, `database/seed.sql` e `README.md`. Vamos repassar e decidir os pontos em aberto da seção 4 do arquivo de handoff (colunas opcionais do seed e confirmação do host de banco de dados) antes de iniciar a escrita de código."

### Opção B: Se quiser ir direto para a implementação do backend
> "Leia `docs/00-contexto-handoff.md`, `docs/01-requisitos.md`, `docs/02-decisoes-arquitetura.md`, `docs/03-regras-futuras.md`, `database/seed.sql` e `README.md`. A documentação do MVP Ello Mineiro está fechada (JWT em cookie HttpOnly, SQL puro). Vamos iniciar o desenvolvimento do backend FastAPI seguindo a ordem da seção 5 do handoff."
