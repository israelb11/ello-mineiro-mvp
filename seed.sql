-- 1. Tabela de Permissões (Perfis fixos do sistema)
CREATE TABLE Permissoes (
    nome_permissao VARCHAR(20) PRIMARY KEY, -- 'Aluno', 'Professor', 'Suporte', 'Administrativo'
    descricao VARCHAR(255)
);

-- Carga inicial obrigatória de perfis
INSERT INTO Permissoes (nome_permissao, descricao) VALUES
('Aluno', 'Acesso a consulta de notas e frequência'),
('Professor', 'Acesso a lançamento de notas e faltas'),
('Suporte', 'Acesso a configurações do sistema'),
('Administrativo', 'Acesso à gestão escolar geral');

-- 2. Tabela Unificada de Usuários (Login + Dados Pessoais - Perfeito para MVP)
CREATE TABLE Usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_login VARCHAR(30) NOT NULL UNIQUE, -- Matrícula ou Registro
    email VARCHAR(100) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,            -- Guardará o Hash (ex: BCrypt)
    permissao_nome VARCHAR(20) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    genero VARCHAR(20),
    cpf CHAR(11) UNIQUE,
    rg VARCHAR(30) UNIQUE,
    data_nasc DATE,
    telefone VARCHAR(15),
    telefone_sec VARCHAR(15),
    ativo BOOL NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (permissao_nome) REFERENCES Permissoes(nome_permissao) ON UPDATE CASCADE
);

-- 3. Tabela de Endereço (Relacionamento 1 para N)
CREATE TABLE Endereco (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    tipo VARCHAR(20),      -- Ex: 'Residencial', 'Comercial'
    cep CHAR(8),
    rua VARCHAR(100),
    numero VARCHAR(20),
    bairro VARCHAR(100),
    complemento VARCHAR(255),
    cidade VARCHAR(50),
    uf CHAR(2),
    situacao VARCHAR(10) DEFAULT 'ATIVO', -- 'ATIVO' ou 'INATIVO'
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(id) ON DELETE CASCADE
);
