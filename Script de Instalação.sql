CREATE SEQUENCE GN_TEMP_CONCILIACAO;
ALTER SEQUENCE GN_TEMP_CONCILIACAO RESTART WITH -1;

CREATE TABLE TEMP_CONCILIACAO (
    ID             INTEGER NOT NULL,
    ID_PAG         VARCHAR(26) NOT NULL,
    ID_LOJA        VARCHAR(26) NOT NULL,
    DTCRIA         TIMESTAMP NOT NULL,
    DTPAG          TIMESTAMP,
    DTALT          TIMESTAMP,
    FORMAPAG       VARCHAR(20) NOT NULL,
    VALORPAG       DECIMAL(15,2) NOT NULL,
    SOLICITACAO    INTEGER NOT NULL,
    TID            BIGINT NOT NULL,
    ADQUIRENTE     VARCHAR(20) NOT NULL,
    PARCELAS       INTEGER NOT NULL,
    BANDEIRA       VARCHAR(20) NOT NULL,
    TIPOCARTAO     VARCHAR(20) NOT NULL,
    PROPCARTAO     VARCHAR(60) NOT NULL,
    AUTORIZACAO    VARCHAR(20) NOT NULL,
    SOFTWARE       VARCHAR(20) NOT NULL,
    CLIENTE        VARCHAR(60) NOT NULL,
    TIPODOC        VARCHAR(20) NOT NULL,
    DOCUMENTO      VARCHAR(20) NOT NULL,
    STATUSPAG      VARCHAR(20) NOT NULL,
    CRIADO_DATA    TIMESTAMP NOT NULL,
    ALTERADO_DATA  TIMESTAMP,
    STATUS         VARCHAR(1) NOT NULL,
    CDFILCAIXA     INTEGER,
    ORCAMENTO      VARCHAR(20),
    PEDIDO         VARCHAR(20),
    DRIVERNAME     VARCHAR(20)
);

ALTER TABLE TEMP_CONCILIACAO ADD CONSTRAINT PK_TEMP_CONCILIACAO PRIMARY KEY (ID);

CREATE UNIQUE INDEX TEMP_CONCILIACAO_IDX1 ON TEMP_CONCILIACAO (ID_PAG);

CREATE OR ALTER TRIGGER TEMP_CONCILIACAO_BI0 FOR TEMP_CONCILIACAO
ACTIVE BEFORE INSERT POSITION 0
AS
begin
 IF (NEW.ID IS NULL) THEN
    NEW.ID = GEN_ID(GN_TEMP_CONCILIACAO, 1);
 NEW.criado_data = CURRENT_TIMESTAMP;
 if (NEW.id_loja = '01F4Y5KZVTBK5JMHE5JM0YZXZF') THEN
 begin
    NEW.cdfilcaixa = 7;
 END ELSE
 begin
    NEW.cdfilcaixa = 49;
 end
end

CREATE OR ALTER VIEW VW_CONCILIACAO_RESUMO(
    SOLICITACAO,
    TPITM,
    CDFIL,
    NRORC,
    QUANT,
    VRLIQ,
    VRTXA)
AS
WITH BASE AS (
    SELECT
        CN.SOLICITACAO,
        CASE WHEN PI.IDTIPOITEMPEDIDO = 1 THEN 'R' ELSE 'V' END AS TPITM,
        CASE WHEN PI.IDTIPOITEMPEDIDO = 1 THEN PI.CDFILO ELSE 0 END AS CDFIL,
        CASE WHEN PI.IDTIPOITEMPEDIDO = 1 THEN PI.NRORC ELSE PI.CDPRO END AS NRORC,
        SUM(PI.QUANT) AS QUANT
    FROM TEMP_CONCILIACAO CN
    JOIN FC0M000 PD ON PD.NRPEDIDO = CN.SOLICITACAO
    JOIN FC0M100 PI ON PI.IDPEDIDO = PD.ID
    WHERE CN.SOLICITACAO > 0
      AND CN.STATUSPAG = 'PAID'
      AND PI.IDSTATUSITEMPEDIDO = 1
    GROUP BY
        CN.SOLICITACAO,
        CASE WHEN PI.IDTIPOITEMPEDIDO = 1 THEN 'R' ELSE 'V' END,
        CASE WHEN PI.IDTIPOITEMPEDIDO = 1 THEN PI.CDFILO ELSE 0 END,
        CASE WHEN PI.IDTIPOITEMPEDIDO = 1 THEN PI.NRORC ELSE PI.CDPRO END
),

-- ===========================================================
-- TABELAS BASE (DISTINCT) ? OK
-- ===========================================================

F12_U AS (
    SELECT DISTINCT
        CDFIL,
        NRRQU,
        VRRQU,
        VRDSC
    FROM FC12000
),

III_U AS (
    SELECT DISTINCT
        CDFILENTG,
        CDFILR,
        CDPRO,
        NRENTG
    FROM FC12410
),

JJJ_U AS (
    SELECT DISTINCT
        CDFILENTG,
        NRENTG,
        VRTXA
    FROM FC12400
),

F3_U AS (
    SELECT
        CDPRO,
        MAX(PRVEN) AS PRVEN
    FROM FC03000
    GROUP BY CDPRO
)

SELECT
    B.SOLICITACAO,
    B.TPITM,
    B.CDFIL,
    B.NRORC,
    B.QUANT,

    CASE 

        -- ====================================================
        -- ?? Requisi??o (R)
        -- VRRQU - VRDSC + TAXA
        -- ====================================================
        WHEN B.TPITM = 'R' THEN 
            CAST(
                COALESCE(F12.VRRQU, 0)
              - COALESCE(F12.VRDSC, 0)
            AS NUMERIC(18,2))

        -- ====================================================
        -- ?? Venda (V)
        -- Pre?o x Quantidade
        -- (SEM TAXA!)
        -- ====================================================
        WHEN B.TPITM = 'V' THEN 
            CAST(
                COALESCE(F3.PRVEN, 0) * B.QUANT
            AS NUMERIC(18,2))

    END AS VRLIQ,

    CASE 

        WHEN B.TPITM = 'R' THEN
            CAST(
                COALESCE(JJJ.VRTXA, 0)
            AS NUMERIC(18,2))

        -- ====================================================
        -- ?? Venda (V)
        -- Pre?o x Quantidade
        -- (SEM TAXA!)
        -- ====================================================
        WHEN B.TPITM = 'V' THEN 
            CAST(
                COALESCE(0, 0)
            AS NUMERIC(18,2))

    END AS VRTXA

FROM BASE B

-- ============================================================
-- JOINs aplic?veis apenas a R
-- ============================================================

LEFT JOIN F12_U F12
    ON B.TPITM = 'R'           -- ?? IMPORTANT?SSIMO
   AND F12.CDFIL = B.CDFIL
   AND F12.NRRQU = B.NRORC

LEFT JOIN III_U III
    ON B.TPITM = 'R'           -- ?? ITENS V N?O ENTRAM MAIS AQUI
   AND III.CDFILENTG = 3
   AND III.CDFILR   = B.CDFIL
   AND III.CDPRO    = B.NRORC

LEFT JOIN JJJ_U JJJ
    ON B.TPITM = 'R'           -- ?? GARANTE SEM DUPLICA??O
   AND JJJ.CDFILENTG = III.CDFILENTG
   AND JJJ.NRENTG    = III.NRENTG

-- ============================================================
-- JOIN PRE?O ? aplic?vel somente a V
-- ============================================================

LEFT JOIN F3_U F3
    ON B.TPITM = 'V'
   AND F3.CDPRO = B.NRORC
;

CREATE OR ALTER VIEW VW_CONCILIACAO_ITENS(
    SOLICITACAO,
    TPITM,
    CDFIL,
    NRORC,
    SERIEO,
    DESCRICAOWEB,
    QUANT,
    PRUNI,
    VRTOT,
    PTDSC,
    VRDSC,
    VRTXA,
    VRLIQ)
AS
-- 1) Quando h? SOLICITACAO > 0 (usa PI / pedido)
SELECT
    CN.SOLICITACAO,

    -- Tipo do item
    CASE 
        WHEN PI.IDTIPOITEMPEDIDO = 1 THEN 'R' 
        ELSE 'V' 
    END AS TPITM,

    -- Filial
    CASE 
        WHEN PI.IDTIPOITEMPEDIDO = 1 THEN PI.CDFILO 
        ELSE 0 
    END AS CDFIL,

    -- Requisi??o / Produto
    CASE 
        WHEN PI.IDTIPOITEMPEDIDO = 1 THEN PI.NRORC 
        ELSE PI.CDPRO
    END AS NRORC,

    -- S?rie
    CASE 
        WHEN PI.IDTIPOITEMPEDIDO = 1 THEN PI.SERIEO 
        ELSE '' 
    END AS SERIEO,

    -- Descri??o
    CASE 
        WHEN PI.IDTIPOITEMPEDIDO = 1 THEN 'REQUISICAO' 
        ELSE PI.DESCRICAOWEB 
    END AS DESCRICAOWEB,

    CAST(COALESCE(PI.QUANT, 1) AS NUMERIC(18,2)) AS QUANT,
    CAST(COALESCE(PI.PRUNI, 0) AS NUMERIC(18,2)) AS PRUNI,
    CAST(COALESCE(PI.VRTOT, 0) AS NUMERIC(18,2)) AS VRTOT,
    CAST(COALESCE(PI.PTDSC, 0) AS NUMERIC(18,2)) AS PTDSC,
    CAST(COALESCE(PI.VRDSC, 0) AS NUMERIC(18,2)) AS VRDSC,
    CAST(COALESCE(PI.VRTXA, 0) AS NUMERIC(18,2)) AS VRTXA,
    CAST(COALESCE(PI.VRLIQ, 0) AS NUMERIC(18,2)) AS VRLIQ

FROM TEMP_CONCILIACAO CN
   INNER JOIN FC0M000 PD ON PD.NRPEDIDO = CN.SOLICITACAO
   INNER JOIN FC0M100 PI ON PI.IDPEDIDO = PD.ID
WHERE
   CN.STATUSPAG = 'PAID'
   AND CN.SOLICITACAO > 0
   AND PI.IDSTATUSITEMPEDIDO = 1

UNION ALL

SELECT
    CN.SOLICITACAO,

    'R' AS TPITM,

    CAST(
        SUBSTRING(CN.ORCAMENTO FROM 1 FOR POSITION('-' IN CN.ORCAMENTO) - 1)
        AS INTEGER
    ) AS CDFIL,

    CAST(
        SUBSTRING(CN.ORCAMENTO FROM POSITION('-' IN CN.ORCAMENTO) + 1)
        AS INTEGER
    ) AS NRORC,

    '' AS SERIEO,

    'REQUISICAO' AS DESCRICAOWEB,

    CAST(1 AS NUMERIC(18,2)) AS QUANT,
    CAST(COALESCE(CN.VALORPAG, 0) AS NUMERIC(18,2)) AS PRUNI,
    CAST(COALESCE(CN.VALORPAG, 0) AS NUMERIC(18,2)) AS VRTOT,
    CAST(0 AS NUMERIC(18,2)) AS PTDSC,
    CAST(0 AS NUMERIC(18,2)) AS VRDSC,
    CAST(0 AS NUMERIC(18,2)) AS VRTXA,
    CAST(COALESCE(CN.VALORPAG, 0) AS NUMERIC(18,2)) AS VRLIQ

FROM TEMP_CONCILIACAO CN
WHERE
   CN.STATUSPAG = 'PAID'
   AND CN.SOLICITACAO = 0
   AND CN.ORCAMENTO IS NOT NULL
   AND POSITION('-' IN CN.ORCAMENTO) > 0
   AND POSITION('-' IN CN.ORCAMENTO) < CHAR_LENGTH(CN.ORCAMENTO)
   -- antes do h?fen h? um d?gito
   AND SUBSTRING(CN.ORCAMENTO FROM 1 FOR POSITION('-' IN CN.ORCAMENTO) - 1)
         SIMILAR TO '[0-9]+'
   -- depois do h?fen h? um d?gito
   AND SUBSTRING(CN.ORCAMENTO FROM POSITION('-' IN CN.ORCAMENTO) + 1)
         SIMILAR TO '[0-9]+'
;

CREATE OR ALTER VIEW VW_CONCILIACAO(
    ID, 
    FILIAL,
    SOLICITACAO,
    CLIENTE,
    ORCAMENTO,
    DOCUMENTO,
    PEDIDO,
    FORMAPAG,
    BANDEIRA,
    ADQTE,
    TID,
    DATACRIA,
    DATAPAG,
    VALORPAG,
    STATUSPAG,
    STATUS,
    DIFVALOR)
AS
WITH RESUMO AS (
    SELECT 
        SOLICITACAO,
        SUM(CAST(VRLIQ AS DECIMAL(18,2)) + CAST(VRTXA AS DECIMAL(18,2))) AS TOTAL_ITENS
    FROM VW_CONCILIACAO_RESUMO
    GROUP BY SOLICITACAO
)
SELECT
    CN.ID,
    CASE
        WHEN CN.ID_LOJA = '01F4Y5KZVTBK5JMHE5JM0YZXZF' THEN 'ARTPHARMA'
        ELSE 'ALMADERMA'
    END AS FILIAL,

    CN.SOLICITACAO,
    CN.CLIENTE,
    CN.ORCAMENTO,
    CN.DOCUMENTO,
    CN.PEDIDO,
    CN.FORMAPAG,
    CN.BANDEIRA,
    CN.DRIVERNAME AS ADQTE,
    CN.TID,
    CN.DTCRIA AS DATACRIA,
    CN.DTPAG  AS DATAPAG,
    CN.VALORPAG,
    CN.STATUSPAG,

    -- =========================
    --  C?LCULO DO STATUS
    -- =========================
    CASE
        -- =========================
        -- Regra 1: 'K'
        -- =========================
        WHEN EXISTS (
            SELECT 1
              FROM VW_CONCILIACAO_ITENS IT
             WHERE IT.SOLICITACAO = CN.SOLICITACAO
               AND (
                    (IT.TPITM = 'R' AND EXISTS (
                        SELECT 1 FROM FC31110 F31
                         WHERE F31.CDFIL  = CN.CDFILCAIXA
                           AND F31.CDFILR = IT.CDFIL
                           AND F31.CDPRO  = IT.NRORC
                    ))
                 OR (IT.TPITM = 'V' AND EXISTS (
                        SELECT 1 FROM FC31110 F31
                         WHERE F31.CDFIL  = CN.CDFILCAIXA
                           AND F31.CDPRO  = IT.NRORC
                    ))
               )
        )
        THEN 'K'

        -- =========================
        -- Regra 2: 'C'
        -- =========================
        WHEN EXISTS (
            SELECT 1
              FROM VW_CONCILIACAO_ITENS IT
             WHERE IT.SOLICITACAO = CN.SOLICITACAO
               AND (
                    (IT.TPITM = 'R' AND NOT EXISTS (
                        SELECT 1 FROM FC12100 F12
                         WHERE F12.CDFIL  = IT.CDFIL
                           AND F12.NRRQU  = IT.NRORC
                           AND F12.SERIER = IT.SERIEO
                    ))
                 OR (IT.TPITM = 'V' AND NOT EXISTS (
                        SELECT 1 FROM FC03000 F30
                         WHERE F30.CDPRO = IT.NRORC
                    ))
               )
        )
        THEN 'C'

        -- =========================
        -- Regra 3: 'D'
        -- =========================
        WHEN
            CAST(COALESCE(RS.TOTAL_ITENS, 0) AS DECIMAL(18,2))
            <> CAST(COALESCE(CN.VALORPAG, 0) AS DECIMAL(18,2))
        THEN 'D'

        ELSE CN.STATUS
    END AS STATUS,

    -- =========================
    --  DIFEREN?A DE VALOR
    -- =========================
    COALESCE(CN.VALORPAG, 0) - CAST(COALESCE(RS.TOTAL_ITENS, 0) AS DECIMAL(18,2)) AS DIFVALOR

FROM TEMP_CONCILIACAO CN
     LEFT JOIN RESUMO RS ON RS.SOLICITACAO = CN.SOLICITACAO
WHERE CN.STATUSPAG = 'PAID'
;

