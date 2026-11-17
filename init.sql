CREATE DATABASE IF NOT EXISTS biotrace
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;
USE biotrace;

CREATE USER 'webdataviz'@'%' IDENTIFIED BY 'web123';
GRANT SELECT, INSERT, DELETE, UPDATE ON biotrace.* TO 'webdataviz'@'%';


-- ACESSO -----------------------------------------------------

CREATE TABLE cargo (
    id_cargo INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(45) NOT NULL
);

-- ORGANIZAÇÕES -------------------------------------------------

CREATE TABLE empresa (
    id_empresa INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    razao_social VARCHAR(100) NOT NULL,
    cnpj CHAR(14) NOT NULL UNIQUE,
    telefone_comercial VARCHAR(11),
    cep CHAR(8),
    numero VARCHAR(10),
    ativo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE hospital (
    id_hospital INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome_hospital VARCHAR(100) NOT NULL,
    cnpj CHAR(14) NOT NULL,
    cep CHAR(8),
    numero VARCHAR(10),
    fk_empresa INT NOT NULL,
    CONSTRAINT fk_hospital_empresa FOREIGN KEY (fk_empresa) REFERENCES empresa (id_empresa),
    CONSTRAINT uk_hospital_empresa_cnpj UNIQUE (fk_empresa, cnpj)
);

-- USUÁRIOS -------------------------------------------------------

CREATE TABLE usuario (
    id_usuario INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome_usuario VARCHAR(45) NOT NULL,
    dt_nasc_usuario DATE,
    telefone_usuario VARCHAR(11),
    cpf_usuario CHAR(11) NOT NULL UNIQUE,
    email_usuario VARCHAR(100) NOT NULL UNIQUE,
    senha_usuario VARCHAR(255) NOT NULL,
    fk_empresa INT NOT NULL,
    fk_cargo INT NOT NULL,
    CONSTRAINT fk_usuario_cargo FOREIGN KEY (fk_cargo) REFERENCES cargo (id_cargo),
    CONSTRAINT fk_usuario_empresa FOREIGN KEY (fk_empresa) REFERENCES empresa (id_empresa)
);

-- EQUIPAMENTOS -----------------------------------------------------

CREATE TABLE modelo_equipamento (
    id_modelo_equipamento INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome_modelo VARCHAR(60) NOT NULL,
    fk_empresa INT NOT NULL,
    CONSTRAINT fk_modelo_empresa FOREIGN KEY (fk_empresa) REFERENCES empresa (id_empresa),
    CONSTRAINT uk_modelo_empresa_nome UNIQUE (fk_empresa, nome_modelo)
);

CREATE TABLE lote_equipamento (
    id_lote_equipamento INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    numero_lote VARCHAR(60) NOT NULL,
    fk_empresa INT NOT NULL,
    fk_modelo_equipamento INT NOT NULL,
    CONSTRAINT uk_lote_empresa_numero UNIQUE (fk_empresa, numero_lote),
    CONSTRAINT fk_lote_empresa FOREIGN KEY (fk_empresa) REFERENCES empresa (id_empresa),
    CONSTRAINT fk_lote_modelo FOREIGN KEY (fk_modelo_equipamento) REFERENCES modelo_equipamento (id_modelo_equipamento)
);

CREATE TABLE equipamento (
    id_equipamento INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    numero_serie VARCHAR(60) NOT NULL UNIQUE,
    fk_hospital INT NULL DEFAULT NULL,
    fk_lote INT NOT NULL,
    CONSTRAINT fk_equipamento_hospital FOREIGN KEY (fk_hospital) REFERENCES hospital (id_hospital),
    CONSTRAINT fk_equipamento_lote FOREIGN KEY (fk_lote) REFERENCES lote_equipamento (id_lote_equipamento)
);

-- COMPONENTES E MÉTRICAS -------------------------------------------

CREATE TABLE tipo_componente (
    id_tipo_componente INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome_componente VARCHAR(45) NOT NULL
);

CREATE TABLE componente (
    id_componente INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    fk_equipamento INT NOT NULL,
    fk_tipo_componente INT NOT NULL,
    CONSTRAINT fk_componente_equipamento FOREIGN KEY (fk_equipamento) REFERENCES equipamento (id_equipamento),
    CONSTRAINT fk_componente_tipo FOREIGN KEY (fk_tipo_componente) REFERENCES tipo_componente (id_tipo_componente)
);

CREATE TABLE tipo_metrica (
    id_tipo_metrica INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tipo_metrica VARCHAR(45) NOT NULL,
    unidade VARCHAR(10)
);

CREATE TABLE metrica (
    id_metrica INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    fk_tipo_metrica INT NOT NULL,
    fk_componente INT NOT NULL,
    CONSTRAINT fk_metrica_tipo FOREIGN KEY (fk_tipo_metrica) REFERENCES tipo_metrica (id_tipo_metrica),
    CONSTRAINT fk_metrica_componente FOREIGN KEY (fk_componente) REFERENCES componente (id_componente)
);

CREATE TABLE parametro_metrica (
    id_parametro_metrica INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    limite_uso DECIMAL(5,2),
    limite_ociosidade DECIMAL(5,2),
    habilitado BOOLEAN NOT NULL DEFAULT TRUE,
    fk_metrica INT NOT NULL,
    CONSTRAINT fk_parametro_metrica FOREIGN KEY (fk_metrica) REFERENCES metrica (id_metrica)
);

CREATE TABLE alerta (
    id_alerta BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    fk_metrica INT NOT NULL,

    tipo_alerta ENUM('USO', 'OCIOSIDADE') NOT NULL,

    confirmado_em DATETIME(6) NOT NULL,
    ultima_violacao_em DATETIME(6) NOT NULL,
    encerrado_em DATETIME(6),

    motivo_encerramento ENUM(
        'NORMALIZACAO',
        'MUDANCA_CONDICAO'
    ),

    limite_aplicado DECIMAL(5,2) NOT NULL,
    valor_confirmacao DOUBLE NOT NULL,

    CONSTRAINT fk_alerta_metrica
        FOREIGN KEY (fk_metrica)
        REFERENCES metrica (id_metrica),

    CONSTRAINT uk_alerta_confirmacao
        UNIQUE (fk_metrica, tipo_alerta, confirmado_em)
);

CREATE TABLE protocolo_ensaio (
    id_protocolo INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    versao INT NOT NULL DEFAULT 1,
    procedimento TEXT NOT NULL,
    duracao_minutos INT NOT NULL,
    intervalo_coleta_segundos INT NOT NULL DEFAULT 180,
    cobertura_minima_percentual DECIMAL(5,2) NOT NULL,
    tolerancia_envio_minutos INT NOT NULL,
    limite_temperatura DECIMAL(5,2) NOT NULL,
    limite_cpu DECIMAL(5,2) NOT NULL,
    limite_ram DECIMAL(5,2) NOT NULL,
    minimo_disco_livre DECIMAL(5,2) NOT NULL,
    checklist_layout TEXT NOT NULL,
    checklist_compatibilidade TEXT NOT NULL,
    checklist_funcionamento TEXT NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fk_modelo_equipamento INT NOT NULL,
    fk_responsavel INT NOT NULL,
    FOREIGN KEY (fk_modelo_equipamento) REFERENCES modelo_equipamento (id_modelo_equipamento),
    FOREIGN KEY (fk_responsavel) REFERENCES usuario (id_usuario)
);

CREATE TABLE ensaio (
    id_ensaio INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    ambiente VARCHAR(20) NOT NULL,
    situacao VARCHAR(40) NOT NULL DEFAULT 'planejado',
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    inicio DATETIME,
    termino_previsto DATETIME,
    encerrado_em DATETIME,
    observacoes TEXT,
    reinicios_programados TEXT,
    fk_protocolo INT NOT NULL,
    fk_responsavel INT NOT NULL,
    FOREIGN KEY (fk_protocolo) REFERENCES protocolo_ensaio (id_protocolo),
    FOREIGN KEY (fk_responsavel) REFERENCES usuario (id_usuario)
);

CREATE TABLE ensaio_equipamento (
    fk_ensaio INT NOT NULL,
    fk_equipamento INT NOT NULL,
    fk_lote INT NOT NULL,
    PRIMARY KEY (fk_ensaio, fk_equipamento),
    FOREIGN KEY (fk_ensaio) REFERENCES ensaio (id_ensaio),
    FOREIGN KEY (fk_equipamento) REFERENCES equipamento (id_equipamento),
    FOREIGN KEY (fk_lote) REFERENCES lote_equipamento (id_lote_equipamento)
);

CREATE TABLE relatorio_ensaio (
    id_relatorio INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    situacao VARCHAR(40) NOT NULL DEFAULT 'aguardando_dados',
    resultado_temperatura VARCHAR(20) NOT NULL DEFAULT 'pendente',
    resultado_recursos VARCHAR(20) NOT NULL DEFAULT 'pendente',
    resultado_estabilidade VARCHAR(20) NOT NULL DEFAULT 'pendente',
    resultado_layout VARCHAR(20) NOT NULL DEFAULT 'pendente',
    resultado_compatibilidade VARCHAR(20) NOT NULL DEFAULT 'pendente',
    resultado_funcionamento VARCHAR(20) NOT NULL DEFAULT 'pendente',
    resultado_final VARCHAR(20) NOT NULL DEFAULT 'pendente',
    cobertura_percentual DECIMAL(5,2),
    duracao_atendida BOOLEAN,
    pico_temperatura DECIMAL(5,2),
    maior_uso_cpu DECIMAL(5,2),
    maior_uso_ram DECIMAL(5,2),
    menor_disco_livre DECIMAL(5,2),
    observacoes_automaticas TEXT,
    observacoes_layout TEXT,
    observacoes_compatibilidade TEXT,
    observacoes_funcionamento TEXT,
    observacoes_revisao TEXT,
    referencia_gold VARCHAR(1024),
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    automatico_concluido_em DATETIME,
    revisado_em DATETIME,
    fk_ensaio INT NOT NULL UNIQUE,
    fk_revisado_por INT,
    FOREIGN KEY (fk_ensaio) REFERENCES ensaio (id_ensaio),
    FOREIGN KEY (fk_revisado_por) REFERENCES usuario (id_usuario)
);

CREATE TABLE acao_correcao (
    id_correcao INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    criterio VARCHAR(40) NOT NULL,
    descricao TEXT NOT NULL,
    situacao VARCHAR(40) NOT NULL DEFAULT 'aberta',
    prazo_final DATE NOT NULL,
    orcamento_estimado DECIMAL(12,2),
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    encerrado_em DATETIME,
    fk_relatorio INT NOT NULL,
    fk_responsavel INT NOT NULL,
    fk_ensaio_reteste INT,
    FOREIGN KEY (fk_relatorio) REFERENCES relatorio_ensaio (id_relatorio),
    FOREIGN KEY (fk_responsavel) REFERENCES usuario (id_usuario),
    FOREIGN KEY (fk_ensaio_reteste) REFERENCES ensaio (id_ensaio)
);


INSERT INTO empresa (razao_social, cnpj, telefone_comercial, cep, numero) VALUES
('BioTrace Tecnologia Ltda','12345678000101', '1133334444', '01310100', '1000');


INSERT INTO cargo (nome) VALUES
('BioTrace'),
('Administrador'),
('Gestor'),
('Analista');

INSERT INTO usuario (nome_usuario, dt_nasc_usuario, telefone_usuario, cpf_usuario, email_usuario, senha_usuario, fk_empresa, fk_cargo) VALUES
-- BioTrace (empresa 1, cargo 1)
('Ana Clara',        '1995-03-12', '11987654321', '12345678901', 'ana.clara@biotrace.com',         SHA2('ana123', 256),      1, 1),
('Bruno Rafael',     '1996-07-25', '11987654322', '23456789012', 'bruno.rafael@biotrace.com',      SHA2('bruno123', 256),    1, 1),
('Eduardo Lupianez', '1994-11-08', '11987654323', '34567890123', 'eduardo.lupianez@biotrace.com',  SHA2('eduardo123', 256),  1, 1),
('Pedro Ludovic',    '1997-02-19', '11987654324', '45678901234', 'pedro.ludovic@biotrace.com',     SHA2('pedro123', 256),    1, 1),
('Jonatas Teles',    '1993-09-14', '11987654325', '56789012345', 'jonatas.teles@biotrace.com',     SHA2('jonatas123', 256),  1, 1),
('Miguel Soares',    '1998-05-30', '11987654326', '67890123456', 'miguel.soares@biotrace.com',     SHA2('miguel123', 256),   1, 1);

INSERT INTO tipo_componente (nome_componente) VALUES
('CPU'),
('Memória RAM'),
('Disco'),
('Rede'),
('Sistema Operacional');

INSERT INTO tipo_metrica (tipo_metrica, unidade) VALUES
('cpu_percent', '%'),
('cpu_por_nucleo', '%'),
('temperatura_cpu', '°C'),
('memoria_percent', '%'),
('memoria_disponivel_gb', 'GB'),
('disco_percent', '%'),
('disco_livre_gb', 'GB'),
('rede_bytes_enviados', 'bytes'),
('rede_bytes_recebidos', 'bytes'),
('rede_erros_entrada', 'erros'),
('rede_erros_saida', 'erros'),
('uptime_horas', 'horas'),
('processos_ativos', 'processos');

-- EMPRESA DE DEMONSTRAÇÃO E ADMINISTRADOR -------------------------

INSERT INTO empresa (razao_social, cnpj, telefone_comercial, cep, numero)
VALUES ('Hospitalar Exemplo Ltda', '11222333000181', '1133339999', '01310930', '150');

INSERT INTO usuario (
    nome_usuario,
    dt_nasc_usuario,
    telefone_usuario,
    cpf_usuario,
    email_usuario,
    senha_usuario,
    fk_empresa,
    fk_cargo
)
SELECT
    'Administrador Demo',
    '1990-01-15',
    '11999990000',
    '98765432100',
    'admin@hospitalar-exemplo.com',
    SHA2('admin123', 256),
    e.id_empresa,
    c.id_cargo
FROM empresa e
CROSS JOIN cargo c
WHERE e.cnpj = '11222333000181'
  AND c.nome = 'Administrador';

INSERT INTO modelo_equipamento (nome_modelo, fk_empresa)
SELECT 'Monitor Hospitalar Demo', e.id_empresa
FROM empresa e
WHERE e.cnpj = '11222333000181';

INSERT INTO lote_equipamento (numero_lote, fk_empresa, fk_modelo_equipamento)
SELECT 'LT-DEMO-001', e.id_empresa, m.id_modelo_equipamento
FROM empresa e
JOIN modelo_equipamento m
    ON m.fk_empresa = e.id_empresa
WHERE e.cnpj = '11222333000181'
  AND m.nome_modelo = 'Monitor Hospitalar Demo';

INSERT INTO equipamento (numero_serie, fk_hospital, fk_lote)
SELECT 'BT-DEMO-0001', NULL, l.id_lote_equipamento
FROM lote_equipamento l
JOIN empresa e ON e.id_empresa = l.fk_empresa
WHERE e.cnpj = '11222333000181'
  AND l.numero_lote = 'LT-DEMO-001';

-- COMPONENTES DO EQUIPAMENTO DE DEMONSTRAÇÃO -----------------------

INSERT INTO componente (fk_equipamento, fk_tipo_componente)
SELECT e.id_equipamento, tc.id_tipo_componente
FROM equipamento e
JOIN lote_equipamento l ON l.id_lote_equipamento = e.fk_lote
JOIN empresa emp ON emp.id_empresa = l.fk_empresa
CROSS JOIN tipo_componente tc
WHERE e.numero_serie = 'BT-DEMO-0001'
  AND emp.cnpj = '11222333000181'
  AND tc.nome_componente IN (
      'CPU', 'Memória RAM', 'Disco', 'Rede', 'Sistema Operacional'
  );

-- MÉTRICAS DO EQUIPAMENTO DE DEMONSTRAÇÃO ---------------------------

INSERT INTO metrica (fk_tipo_metrica, fk_componente)
SELECT tm.id_tipo_metrica, c.id_componente
FROM componente c
JOIN tipo_componente tc ON tc.id_tipo_componente = c.fk_tipo_componente
JOIN equipamento e ON e.id_equipamento = c.fk_equipamento
JOIN lote_equipamento l ON l.id_lote_equipamento = e.fk_lote
JOIN empresa emp ON emp.id_empresa = l.fk_empresa
CROSS JOIN tipo_metrica tm
WHERE e.numero_serie = 'BT-DEMO-0001'
  AND emp.cnpj = '11222333000181'
  AND (
      (tc.nome_componente = 'CPU'
          AND tm.tipo_metrica IN ('cpu_percent', 'cpu_por_nucleo', 'temperatura_cpu'))
      OR (tc.nome_componente = 'Memória RAM'
          AND tm.tipo_metrica IN ('memoria_percent', 'memoria_disponivel_gb'))
      OR (tc.nome_componente = 'Disco'
          AND tm.tipo_metrica IN ('disco_percent', 'disco_livre_gb'))
      OR (tc.nome_componente = 'Rede'
          AND tm.tipo_metrica IN (
              'rede_bytes_enviados', 'rede_bytes_recebidos',
              'rede_erros_entrada', 'rede_erros_saida'
          ))
      OR (tc.nome_componente = 'Sistema Operacional'
          AND tm.tipo_metrica IN ('uptime_horas', 'processos_ativos'))
  );

-- PARÂMETROS PADRÃO DAS MÉTRICAS DO EQUIPAMENTO --------------------

INSERT INTO parametro_metrica (
    limite_uso,
    limite_ociosidade,
    habilitado,
    fk_metrica
)
SELECT
    CASE tm.tipo_metrica
        WHEN 'cpu_percent' THEN 90.00
        WHEN 'memoria_percent' THEN 90.00
        WHEN 'disco_percent' THEN 90.00
        ELSE NULL
    END,
    CASE tm.tipo_metrica
        WHEN 'cpu_percent' THEN 5.00
        WHEN 'memoria_percent' THEN 10.00
        WHEN 'disco_percent' THEN 10.00
        ELSE NULL
    END,
    TRUE,
    m.id_metrica
FROM metrica m
JOIN tipo_metrica tm ON tm.id_tipo_metrica = m.fk_tipo_metrica
JOIN componente c ON c.id_componente = m.fk_componente
JOIN equipamento e ON e.id_equipamento = c.fk_equipamento
JOIN lote_equipamento l ON l.id_lote_equipamento = e.fk_lote
JOIN empresa emp ON emp.id_empresa = l.fk_empresa
WHERE e.numero_serie = 'BT-DEMO-0001'
  AND emp.cnpj = '11222333000181';
