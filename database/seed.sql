-- =====================================================================
-- Ello Mineiro - MVP (Fase 1: Cadastro e Login)
-- Esquema do banco (MySQL 8.0.16+ / TiDB). Fonte da verdade do esquema:
-- mudanças são feitas aqui e comunicadas ao grupo (doc 02, seção 7).
-- Charset utf8mb4 em todas as tabelas para suportar acentos.
-- =====================================================================

-- 1. Tabela de Permissões (Perfis fixos do sistema)
CREATE TABLE Permissoes (
    nome_permissao VARCHAR(20) PRIMARY KEY, -- 'Usuario', 'Aluno', 'Professor', 'Suporte', 'Administrativo'
    descricao VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Carga inicial obrigatória de perfis
-- 'Usuario' é o perfil padrão de todo cadastro público (RN02).
-- Os demais só serão atribuídos no futuro pelo setor administrativo (doc 03).
INSERT INTO Permissoes (nome_permissao, descricao) VALUES
('Usuario', 'Acesso básico: calendário e conteúdo público'),
('Aluno', 'Acesso a consulta de notas e frequência'),
('Professor', 'Acesso a lançamento de notas e faltas'),
('Suporte', 'Acesso a configurações do sistema'),
('Administrativo', 'Acesso à gestão escolar geral');

-- 2. Tabela Unificada de Usuários (Login + Dados Pessoais - Perfeito para MVP)
CREATE TABLE Usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_login VARCHAR(30) NOT NULL UNIQUE,  -- Nome de usuário escolhido pelo usuário (3-30, a-z 0-9 . _, minúsculas, imutável). NÃO é matrícula
    email VARCHAR(100) NOT NULL UNIQUE,
    senha_hash VARCHAR(255) NOT NULL,        -- Apenas o hash (Argon2id ou bcrypt), nunca a senha em texto puro
    permissao_nome VARCHAR(20) NOT NULL DEFAULT 'Usuario', -- Definido pelo backend, nunca pelo corpo da requisição (RN05)
    nome VARCHAR(100) NOT NULL,
    genero VARCHAR(20),
    cpf CHAR(11) UNIQUE,                     -- Opcional no cadastro público (LGPD); só dígitos
    rg VARCHAR(30) UNIQUE,                   -- Opcional no cadastro público (LGPD)
    data_nasc DATE,
    telefone VARCHAR(15),
    telefone_sec VARCHAR(15),
    ativo BOOL NOT NULL DEFAULT TRUE,        -- Exclusão lógica (RN03)
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (permissao_nome) REFERENCES Permissoes(nome_permissao) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Tabela de Endereço (Relacionamento 1 para N)
CREATE TABLE Endereco (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    tipo VARCHAR(20),      -- Ex: 'Residencial', 'Comercial'
    cep CHAR(8),           -- Só dígitos
    rua VARCHAR(100),
    numero VARCHAR(20),
    bairro VARCHAR(100),
    complemento VARCHAR(255),
    cidade VARCHAR(50),
    uf CHAR(2),
    situacao VARCHAR(10) NOT NULL DEFAULT 'ATIVO',
    CONSTRAINT chk_endereco_situacao CHECK (situacao IN ('ATIVO', 'INATIVO')),
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
