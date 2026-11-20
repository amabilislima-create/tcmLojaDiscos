

USE master;
IF DB_ID('loja_discos') IS NOT NULL
BEGIN
    ALTER DATABASE loja_discos SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE loja_discos;
END
CREATE DATABASE loja_discos;
USE loja_discos;

CREATE TABLE dbo.usuario (
    id          INT IDENTITY(1,1) NOT NULL,
    nome        NVARCHAR(100) NOT NULL,
    email       NVARCHAR(120) NOT NULL,
    endereco    NVARCHAR(255) NULL,
    senha_hash  NVARCHAR(255) NOT NULL,
    perfil      VARCHAR(10)   NOT NULL CONSTRAINT df_usuario_perfil DEFAULT 'cliente',
    CONSTRAINT pk_usuario        PRIMARY KEY (id),
    CONSTRAINT uq_usuario_email  UNIQUE (email),
    CONSTRAINT ck_usuario_perfil CHECK (perfil IN ('cliente','admin'))
);
CREATE TABLE dbo.genero (
    id    INT IDENTITY(1,1) NOT NULL,
    nome  NVARCHAR(60) NOT NULL,
    ativo BIT NOT NULL CONSTRAINT df_genero_ativo DEFAULT 1,
    CONSTRAINT pk_genero PRIMARY KEY (id),
    CONSTRAINT uq_genero_nome UNIQUE (nome)
);
CREATE TABLE dbo.subgenero (
    id        INT IDENTITY(1,1) NOT NULL,
    id_genero INT NOT NULL,
    nome      NVARCHAR(60) NOT NULL,
    ativo     BIT NOT NULL CONSTRAINT df_subgenero_ativo DEFAULT 1,
    CONSTRAINT pk_subgenero PRIMARY KEY (id),
    CONSTRAINT fk_subgenero_genero FOREIGN KEY (id_genero) REFERENCES dbo.genero(id),
    CONSTRAINT uq_subgenero_nome UNIQUE (id_genero, nome)
);
CREATE TABLE dbo.artista (
    id           INT IDENTITY(1,1) NOT NULL,
    id_subgenero INT NOT NULL,
    nome         NVARCHAR(100) NOT NULL,
    ativo        BIT NOT NULL CONSTRAINT df_artista_ativo DEFAULT 1,
    CONSTRAINT pk_artista PRIMARY KEY (id),
    CONSTRAINT fk_artista_subgenero FOREIGN KEY (id_subgenero) REFERENCES dbo.subgenero(id)
);
CREATE TABLE dbo.disco (
    id         INT IDENTITY(1,1) NOT NULL,
    titulo     NVARCHAR(150) NOT NULL,
    id_artista INT NOT NULL,
    ano        SMALLINT NULL,
    formato    VARCHAR(10) NOT NULL,
    preco      DECIMAL(10,2) NOT NULL,
    capa       NVARCHAR(255) NULL,
    ativo      BIT NOT NULL CONSTRAINT df_disco_ativo DEFAULT 1,
    CONSTRAINT pk_disco PRIMARY KEY (id),
    CONSTRAINT fk_disco_artista FOREIGN KEY (id_artista) REFERENCES dbo.artista(id),
    CONSTRAINT ck_disco_formato CHECK (formato IN ('vinil','cd')),
    CONSTRAINT ck_disco_preco   CHECK (preco >= 0)
);
CREATE TABLE dbo.carrinho_item (
    id         INT IDENTITY(1,1) NOT NULL,
    id_usuario INT NOT NULL,
    id_disco   INT NOT NULL,
    quantidade INT NOT NULL,
    CONSTRAINT pk_carrinho_item PRIMARY KEY (id),
    CONSTRAINT uq_carrinho_item UNIQUE (id_usuario, id_disco),
    CONSTRAINT fk_carrinho_usuario FOREIGN KEY (id_usuario) REFERENCES dbo.usuario(id),
    CONSTRAINT fk_carrinho_disco   FOREIGN KEY (id_disco)   REFERENCES dbo.disco(id),
    CONSTRAINT ck_carrinho_qtd CHECK (quantidade > 0)
);

EXEC('
CREATE VIEW dbo.vw_catalogo AS
SELECT d.id, d.titulo, d.ano, d.formato, d.preco, d.capa,
       a.id AS id_artista,   a.nome AS artista,
       s.id AS id_subgenero, s.nome AS subgenero,
       g.id AS id_genero,    g.nome AS genero
FROM dbo.disco d
JOIN dbo.artista   a ON a.id = d.id_artista
JOIN dbo.subgenero s ON s.id = a.id_subgenero
JOIN dbo.genero    g ON g.id = s.id_genero
WHERE d.ativo = 1 AND a.ativo = 1 AND s.ativo = 1 AND g.ativo = 1;
');

EXEC('
CREATE PROCEDURE dbo.usp_cadastrar_cliente
    @nome NVARCHAR(100), @email NVARCHAR(120),
    @endereco NVARCHAR(255), @senha_hash NVARCHAR(255), @id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.usuario WHERE email = @email)
    BEGIN
        RAISERROR(''E-mail ja cadastrado.'', 16, 1);
        RETURN;
    END
    INSERT INTO dbo.usuario (nome, email, endereco, senha_hash, perfil)
    VALUES (@nome, @email, @endereco, @senha_hash, ''cliente'');
    SET @id = SCOPE_IDENTITY();
END;
');

EXEC('
CREATE PROCEDURE dbo.usp_login @email NVARCHAR(120)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT id, nome, endereco, senha_hash, perfil
    FROM dbo.usuario
    WHERE email = @email;
END;
');

EXEC('
CREATE PROCEDURE dbo.usp_adicionar_ao_carrinho
    @id_usuario INT, @id_disco INT, @qtd INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    IF @qtd < 1
    BEGIN
        RAISERROR(''Quantidade invalida.'', 16, 1);
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM dbo.disco WHERE id = @id_disco AND ativo = 1)
    BEGIN
        RAISERROR(''Disco indisponivel.'', 16, 1);
        RETURN;
    END
    UPDATE dbo.carrinho_item SET quantidade = quantidade + @qtd
    WHERE id_usuario = @id_usuario AND id_disco = @id_disco;
    IF @@ROWCOUNT = 0
        INSERT INTO dbo.carrinho_item (id_usuario, id_disco, quantidade)
        VALUES (@id_usuario, @id_disco, @qtd);
END;
');

EXEC('
CREATE PROCEDURE dbo.usp_alterar_quantidade_carrinho
    @id_usuario INT, @id_disco INT, @qtd INT
AS
BEGIN
    SET NOCOUNT ON;
    IF @qtd < 0
    BEGIN
        RAISERROR(''Quantidade invalida.'', 16, 1);
        RETURN;
    END
    IF @qtd = 0
    BEGIN
        DELETE FROM dbo.carrinho_item
        WHERE id_usuario = @id_usuario AND id_disco = @id_disco;
        RETURN;
    END
    UPDATE dbo.carrinho_item SET quantidade = @qtd
    WHERE id_usuario = @id_usuario AND id_disco = @id_disco;
    IF @@ROWCOUNT = 0
        RAISERROR(''Item nao esta no carrinho.'', 16, 1);
END;
');

EXEC('
CREATE PROCEDURE dbo.usp_listar_carrinho @id_usuario INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.id_disco, d.titulo, a.nome AS artista, d.capa, d.preco, c.quantidade,
           d.preco * c.quantidade AS subtotal
    FROM dbo.carrinho_item c
    JOIN dbo.disco   d ON d.id = c.id_disco
    JOIN dbo.artista a ON a.id = d.id_artista
    WHERE c.id_usuario = @id_usuario AND d.ativo = 1
    ORDER BY d.titulo;
END;
');

EXEC('
CREATE PROCEDURE dbo.usp_finalizar_compra
    @id_usuario INT, @total DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.carrinho_item WHERE id_usuario = @id_usuario)
    BEGIN
        RAISERROR(''Carrinho vazio.'', 16, 1);
        RETURN;
    END
    SELECT @total = ISNULL(SUM(c.quantidade * d.preco), 0)
    FROM dbo.carrinho_item c
    JOIN dbo.disco d ON d.id = c.id_disco
    WHERE c.id_usuario = @id_usuario AND d.ativo = 1;
    DELETE FROM dbo.carrinho_item WHERE id_usuario = @id_usuario;
END;
');

EXEC('
CREATE PROCEDURE dbo.usp_disco_inserir
    @titulo NVARCHAR(150), @id_artista INT, @ano SMALLINT, @formato VARCHAR(10),
    @preco DECIMAL(10,2), @capa NVARCHAR(255), @id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.artista WHERE id = @id_artista AND ativo = 1)
    BEGIN
        RAISERROR(''Artista nao encontrado.'', 16, 1);
        RETURN;
    END
    INSERT INTO dbo.disco (titulo, id_artista, ano, formato, preco, capa)
    VALUES (@titulo, @id_artista, @ano, @formato, @preco, @capa);
    SET @id = SCOPE_IDENTITY();
END;
');

EXEC('
CREATE PROCEDURE dbo.usp_disco_atualizar
    @id INT, @titulo NVARCHAR(150), @id_artista INT, @ano SMALLINT,
    @formato VARCHAR(10), @preco DECIMAL(10,2), @capa NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.disco
    SET titulo = @titulo, id_artista = @id_artista, ano = @ano,
        formato = @formato, preco = @preco, capa = @capa
    WHERE id = @id;
    IF @@ROWCOUNT = 0
        RAISERROR(''Disco nao encontrado.'', 16, 1);
END;
');

EXEC('
CREATE PROCEDURE dbo.usp_disco_inativar @id INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.disco SET ativo = 0 WHERE id = @id;
    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR(''Disco nao encontrado.'', 16, 1);
        RETURN;
    END
    DELETE FROM dbo.carrinho_item WHERE id_disco = @id;
END;
');

EXEC('
CREATE PROCEDURE dbo.usp_painel_totais
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        (SELECT COUNT(*) FROM dbo.disco   WHERE ativo = 1)          AS total_discos,
        (SELECT COUNT(*) FROM dbo.artista WHERE ativo = 1)          AS total_artistas,
        (SELECT COUNT(*) FROM dbo.usuario WHERE perfil = ''cliente'') AS total_clientes;
END;
');

USE master;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'loja_cliente')
    CREATE LOGIN loja_cliente WITH PASSWORD = 'Troque#Cliente2026', CHECK_POLICY = ON;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'loja_admin')
    CREATE LOGIN loja_admin WITH PASSWORD = 'Troque#Admin2026', CHECK_POLICY = ON;
USE loja_discos;
CREATE USER loja_cliente FOR LOGIN loja_cliente;
CREATE USER loja_admin   FOR LOGIN loja_admin;

GRANT SELECT ON dbo.vw_catalogo TO loja_cliente;
GRANT SELECT ON dbo.genero      TO loja_cliente;
GRANT SELECT ON dbo.subgenero   TO loja_cliente;
GRANT SELECT ON dbo.artista     TO loja_cliente;
GRANT EXECUTE ON dbo.usp_cadastrar_cliente           TO loja_cliente;
GRANT EXECUTE ON dbo.usp_login                       TO loja_cliente;
GRANT EXECUTE ON dbo.usp_adicionar_ao_carrinho       TO loja_cliente;
GRANT EXECUTE ON dbo.usp_alterar_quantidade_carrinho TO loja_cliente;
GRANT EXECUTE ON dbo.usp_listar_carrinho             TO loja_cliente;
GRANT EXECUTE ON dbo.usp_finalizar_compra            TO loja_cliente;
GRANT SELECT ON SCHEMA::dbo TO loja_admin;
GRANT INSERT, UPDATE ON dbo.genero    TO loja_admin;
GRANT INSERT, UPDATE ON dbo.subgenero TO loja_admin;
GRANT INSERT, UPDATE ON dbo.artista   TO loja_admin;
GRANT INSERT, UPDATE ON dbo.disco     TO loja_admin;
GRANT EXECUTE ON SCHEMA::dbo TO loja_admin;
DENY SELECT (senha_hash) ON dbo.usuario TO loja_admin;

INSERT INTO dbo.genero (nome) VALUES
    (N'R&B'), (N'Soul'), (N'MPB'), (N'Samba'),
    (N'Pop'), (N'Rock'), (N'Jazz'), (N'Clássica');
CREATE TABLE #seed (gen NVARCHAR(60), sub NVARCHAR(60), art NVARCHAR(100));
INSERT INTO #seed (gen, sub, art) VALUES
 (N'Pop', N'Synthpop', N'Depeche Mode'),
 (N'Pop', N'Indie Pop', N'Ana Frango Elétrico'),
 (N'Pop', N'K-Pop', N'Red Velvet'),
 (N'Pop', N'Electropop', N'Charli XCX'),
 (N'Rock', N'Rock Clássico', N'Led Zeppelin'),
 (N'Rock', N'Punk Rock', N'Garotos Podres'),
 (N'Rock', N'Grunge', N'Alice in Chains'),
 (N'Rock', N'Indie Rock', N'Pure Joy'),
 (N'Jazz', N'Bebop', N'Charlie Parker'),
 (N'Jazz', N'Cool Jazz', N'Miles Davis'),
 (N'Jazz', N'Jazz Fusion', N'Herbie Hancock'),
 (N'Jazz', N'Smooth Jazz', N'Kenny G'),
 (N'Clássica', N'Barroco', N'Antonio Vivaldi'),
 (N'Clássica', N'Clássico (Era)', N'Wolfgang Amadeus Mozart'),
 (N'Clássica', N'Romantismo', N'Frédéric Chopin'),
 (N'Clássica', N'Minimalismo', N'Philip Glass'),
 (N'R&B', N'Contemporary R&B', N'Alicia Keys'),
 (N'R&B', N'Neo-Soul', N'Lauryn Hill'),
 (N'R&B', N'Alternative R&B', N'Frank Ocean'),
 (N'R&B', N'R&B Brasil', N'Tim Maia'),
 (N'Soul', N'Motown Soul', N'Stevie Wonder'),
 (N'Soul', N'Southern Soul', N'Otis Redding'),
 (N'Soul', N'Psychedelic Soul', N'The Temptations'),
 (N'MPB', N'Bossa Nova', N'João Gilberto'),
 (N'MPB', N'Tropicalismo', N'Os Mutantes'),
 (N'MPB', N'Vanguarda Paulista', N'Itamar Assumpção'),
 (N'MPB', N'Nova MPB', N'Liniker'),
 (N'Samba', N'Samba de Breque', N'Adoniran Barbosa'),
 (N'Samba', N'Samba-Enredo', N'Dona Ivone Lara'),
 (N'Samba', N'Partido-Alto', N'Martinho da Vila'),
 (N'Samba', N'Samba-Canção', N'Cartola');
INSERT INTO dbo.subgenero (id_genero, nome)
SELECT g.id, s.sub FROM #seed s JOIN dbo.genero g ON g.nome = s.gen;
INSERT INTO dbo.artista (id_subgenero, nome)
SELECT sg.id, s.art
FROM #seed s
JOIN dbo.genero g     ON g.nome = s.gen
JOIN dbo.subgenero sg ON sg.id_genero = g.id AND sg.nome = s.sub;
DROP TABLE #seed;
INSERT INTO dbo.disco (titulo, id_artista, ano, formato, preco)
SELECT a.nome, a.id, NULL, 'vinil', 89.90 + (a.id % 7) * 20
FROM dbo.artista a;

