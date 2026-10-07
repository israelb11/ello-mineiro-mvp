# MVP Escola Ello Mineiro

Repositório destinado ao desenvolvimento do MVP (Produto Mínimo Viável) do sistema de gestão escolar da Escola Particular Ello Mineiro.

O objetivo principal desta aplicação é centralizar a autenticação de usuários, permitindo que alunos consultem notas e frequências, enquanto professores realizam os lançamentos acadêmicos e a equipe administrativa/suporte gerencie a plataforma.

Funcionalidades do Escopo Atual (Fase 1):

Modelagem e arquitetura do banco de dados relacional (MySQL).

Módulo de Autenticação e Controle de Acesso baseado em papéis (RBAC: Aluno, Professor, Suporte, Administrativo).

Gestão de usuários, credenciais seguras e endereços.

# Escola Particular Ello Mineiro — MVP

Aplicação Full Stack para o sistema de gestão da **Escola Particular Ello Mineiro**. Este MVP (Produto Mínimo Viável) tem como foco principal a implementação segura do fluxo de **Autenticação, Cadastro e Controle de Acesso** para os utilizadores da plataforma.

---

## Escopo do MVP

O projeto contempla a estrutura inicial da aplicação cobrindo a interface, o serviço de backend e o banco de dados relacional.

### Frontend (Estático)
Interface desenvolvida de forma estática, responsável pelo consumo de rotas API (`GET` e `POST`) para comunicação com o servidor.
* **Tela de Login:** Autenticação via `user_login` (Matrícula/Registro) ou `email` e senha.
* **Tela de Cadastro:** Formulário para registo de novos utilizadores e seleção de perfil/permissão.
* **Tela Home:** Dashboard inicial para onde o utilizador é redirecionado após um login bem-sucedido.

### Backend & API
API REST responsável pela lógica de negócio e processamento de dados.
* **Rota de Cadastro (`POST`):** Recebe os dados do utilizador, valida as informações e insere na base de dados.
* **Rota de Login (`POST`):** Valida credenciais e emite o token de acesso.
* **Boas Práticas de Segurança:** 
  * Armazenamento seguro de senhas através de algoritmos de *hashing* criptográfico (ex.: BCrypt / Argon2). Nenhuma senha é guardada em texto limpo.
  * Proteção contra acessos não autorizados nas rotas internas.

### Banco de Dados (MySQL)
Estrutura relacional otimizada e normalizada para suportar o ecossistema da aplicação:
* **`Permissoes`:** Tabela de perfis fixos do sistema (`Aluno`, `Professor`, `Suporte`, `Administrativo`).
* **`Usuarios`:** Centralização das credenciais de acesso, identificadores únicos (`user_login`) e dados pessoais.
* **`Endereco`:** Mapeamento de endereços associados aos utilizadores (relacionamento 1:N).

---

## Tecnologias Utilizadas

* **Frontend:** HTML5, CSS3, JavaScript (Fetch API / Axios)
* **Backend:** Python (Flask / FastAPI)
* **Banco de Dados:** MySQL
* **Segurança:** Werkzeug / Passlib / BCrypt (Hashing de senhas) e PyJWT (JSON Web Token)
