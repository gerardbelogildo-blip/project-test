-- ------------------------------------------------------------
-- 1. Criação da base de dados
-- ------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS danieta_sabores
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE danieta_sabores;

-- ------------------------------------------------------------
-- 2. Tabela: clientes
-- ------------------------------------------------------------
CREATE TABLE clientes (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome_completo VARCHAR(100) NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    newsletter TINYINT(1) DEFAULT 0,  -- 0 = não, 1 = sim
    INDEX idx_email (email),
    INDEX idx_telefone (telefone)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 3. Tabela: ocasioes_especiais (tipos de evento)
-- ------------------------------------------------------------
CREATE TABLE ocasioes_especiais (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE,
    descricao VARCHAR(100)
) ENGINE=InnoDB;

INSERT INTO ocasioes_especiais (nome, descricao) VALUES
('Nenhuma', 'Sem ocasião especial'),
('Aniversário', 'Celebração de aniversário'),
('Data de Nascimento', 'Data de nascimento'),
('Noivado', 'Celebração de noivado'),
('Jantar de Negócios', 'Jantar corporativo'),
('Outra', 'Outras ocasiões');

-- ------------------------------------------------------------
-- 4. Tabela: mesas (tipos de mesa disponíveis)
-- ------------------------------------------------------------
CREATE TABLE mesas (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tipo VARCHAR(30) NOT NULL UNIQUE,   -- standard, window, private, terrace
    descricao VARCHAR(80),
    capacidade_maxima TINYINT UNSIGNED DEFAULT 4,
    icone VARCHAR(50)                  -- classe Font Awesome
) ENGINE=InnoDB;

INSERT INTO mesas (tipo, descricao, capacidade_maxima, icone) VALUES
('standard', 'Mesa padrão', 4, 'fa-chair'),
('window', 'Mesa junto à janela', 4, 'fa-window-maximize'),
('private', 'Sala privada', 8, 'fa-door-closed'),
('terrace', 'Mesa no terraço', 6, 'fa-umbrella-beach');

-- ------------------------------------------------------------
-- 5. Tabela: horarios_disponiveis (slots padrão)
-- ------------------------------------------------------------
CREATE TABLE horarios_disponiveis (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    horario TIME NOT NULL UNIQUE,
    descricao VARCHAR(20)
) ENGINE=InnoDB;

INSERT INTO horarios_disponiveis (horario, descricao) VALUES
('12:00:00', '12:00'),
('14:00:00', '14:00'),
('16:00:00', '16:00'),
('18:00:00', '18:00'),
('20:00:00', '20:00'),
('22:00:00', '22:00');

-- ------------------------------------------------------------
-- 6. Tabela: reservas (principal)
-- ------------------------------------------------------------
CREATE TABLE reservas (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT UNSIGNED NOT NULL,
    data_reserva DATE NOT NULL,
    horario_id TINYINT UNSIGNED NOT NULL,   -- FK para horarios_disponiveis
    numero_pessoas VARCHAR(10) NOT NULL,    -- pode guardar '7-10', '10+', etc.
    mesa_id TINYINT UNSIGNED,              -- tipo de mesa preferido (pode ser nulo)
    ocasiao_id TINYINT UNSIGNED DEFAULT 1, -- FK ocasioes_especiais (1 = Nenhuma)
    pedidos_especiais TEXT,
    status ENUM('pendente', 'confirmada', 'cancelada', 'concluida') DEFAULT 'pendente',
    codigo_reserva VARCHAR(20) UNIQUE,     -- código amigável para o cliente
    data_solicitacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_confirmacao DATETIME NULL,
    data_cancelamento DATETIME NULL,
    termos_aceitos TINYINT(1) DEFAULT 1,   -- sempre true no momento da reserva
    ip_origem VARCHAR(45),                -- para rastreio
    INDEX idx_data (data_reserva),
    INDEX idx_status (status),
    INDEX idx_codigo (codigo_reserva),
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE RESTRICT,
    FOREIGN KEY (horario_id) REFERENCES horarios_disponiveis(id),
    FOREIGN KEY (mesa_id) REFERENCES mesas(id),
    FOREIGN KEY (ocasiao_id) REFERENCES ocasioes_especiais(id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 7. Tabela: logs_reservas (auditoria)
-- ------------------------------------------------------------
CREATE TABLE logs_reservas (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reserva_id INT UNSIGNED NOT NULL,
    acao VARCHAR(50) NOT NULL,          -- 'criada', 'confirmada', 'cancelada', 'alterada'
    data_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
    observacoes TEXT,
    FOREIGN KEY (reserva_id) REFERENCES reservas(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 8. Tabela: politicas (para exibição no front‑end)
-- ------------------------------------------------------------
CREATE TABLE politicas (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    descricao TEXT NOT NULL,
    icone VARCHAR(50),
    ordem TINYINT UNSIGNED DEFAULT 0,
    ativa TINYINT(1) DEFAULT 1
) ENGINE=InnoDB;

INSERT INTO politicas (titulo, descricao, icone, ordem) VALUES
('Política de Cancelamento', 'Cancelamentos devem ser feitos com pelo menos 12 horas de antecedência. Para grupos de mais de 8 pessoas, 24 horas.', 'fa-clock', 1),
('Política de Atrasos', 'Reservas serão mantidas por 15 minutos após o horário marcado. Após este período, a mesa poderá ser disponibilizada.', 'fa-user-clock', 2),
('Grupos Grandes', 'Para grupos de mais de 10 pessoas, reserva com 48 horas de antecedência. Depósito pode ser solicitado.', 'fa-users', 3),
('Crianças', 'Crianças são bem‑vindas. Cadeiras altas disponíveis. Menu infantil até 10 anos.', 'fa-child', 4);