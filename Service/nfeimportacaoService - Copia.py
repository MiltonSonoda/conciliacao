import pyodbc
import win32serviceutil
import win32service
import win32event
import servicemanager
import time
from datetime import datetime
from datetime import datetime 
import pandas_read_xml as pdx
import os
import glob
import xmltodict
import shutil
import logging

# Configuração do logging

log_file = os.path.join(os.path.dirname(__file__), 'erros.log')

logging.basicConfig(
    filename=log_file,
    level=logging.ERROR,    # Nível de log (ERROR para capturar apenas erros)
    format='%(asctime)s - %(levelname)s - %(message)s'  # Formato da mensagem de log
)

class NfeImportacaoService(win32serviceutil.ServiceFramework):
    _svc_name_ = "NfeImportacaoService"
    _svc_display_name_ = "NFe Importação Serviço"
    _svc_description_ = "Serviço para rodar a rotina de importação de NFe continuamente."

    def __init__(self, args):
        super().__init__(args)
        self.stop_event = win32event.CreateEvent(None, 0, 0, None)
        self.running = True
        self.conn = None  # Inicializa a variável de conexão como None
        #self.pasta = 'C:\\Users\\USUARIO\\Documents\\Coopermag\\BI NFe Arquivos XML\\HUB SIEG'
        self.pasta = 'C:\\Users\\Administrador.WIN-C4842SFD7Q9\\HUB SIEG\\XML\\NF-es'
    
    def SvcStop(self):
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
        win32event.SetEvent(self.stop_event)
        self.running = False
        if self.conn:
            self.conn.close()  # Fecha a conexão ao banco de dados ao parar o serviço

    def SvcDoRun(self):
        servicemanager.LogMsg(
            servicemanager.EVENTLOG_INFORMATION_TYPE,
            servicemanager.PYS_SERVICE_STARTED,
            (self._svc_name_, "")
        )

        self.main() 

    def connect_to_database(self):
        
        host = '177.107.94.21'
        database = 'BRSight'
        user = 'coopermag'
        password = 'cabreUva@266'

        connectionString = f'DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={host};DATABASE={database};UID={user};PWD={password};TrustServerCertificate=yes;LongAsMax=yes'

        conn = pyodbc.connect(connectionString)
        return conn
           
    def disconnect_database(self):
        
        if self.conn is not None:
           self.conn.close()
           self.conn = None

        pass

    def main(self):
        while self.running:
            try:

                self.arquivos = glob.glob(self.pasta+'/**/*.xml', recursive = True)
                # itera sobre os arquivos e processa cada um deles
                if len(self.arquivos) > 0:
                    self.conn = self.connect_to_database()
                    if self.conn is None:
                       servicemanager.LogErrorMsg("Erro: Conexão ao banco de dados falhou.")
                       raise Exception("Erro: Conexão ao banco de dados falhou.")

                #servicemanager.LogErrorMsg("Banco conectado com sucesso.'")                              

                try:
                    for arquivo in self.arquivos:
                        if os.path.isfile(arquivo):
                            self.processarArquivo(arquivo)
                finally:
                    self.disconnect_database()
                time.sleep(10)  # Intervalo entre execuções para evitar alta carga
            except Exception as e:
                servicemanager.LogErrorMsg(str(e))
                time.sleep(5)  # Espera um pouco antes de tentar novamente

    def processarArquivo(self, arquivo):
        if os.path.isfile(arquivo):
            arquivo_processado = arquivo.replace('HUB SIEG', 'HUB SIEG - PROCESSADOS')
            with open(arquivo, 'r', encoding='utf8') as f:
                conteudo = f.read()
                f.close()
                conteudo = conteudo.replace('<?xml version="1.0" encoding="UTF-8"?>', '')
                conteudo = conteudo.replace('<?xml version="1.0" encoding="utf-8"?>', '')

                # CFOP de Transportadora
                if conteudo.find('<CFOP>5353</CFOP>') >= 0:
                    os.remove(arquivo)
                    return

                # nfeProc não encontrado
                if conteudo.find('<nfeProc') < 0:
                    os.remove(arquivo)
                    return

                # para pegar a chave da nfe
                xmlDict = xmltodict.parse(conteudo)  # Parse XML
                chave = xmlDict['nfeProc']['protNFe']['infProt']['chNFe']
                if chave == '':
                    os.remove(arquivo)
                    return

                if chave == '53241000002927474117550241710200013292128611':
                    os.remove(arquivo)
                    return

                df = pdx.read_xml(conteudo)
                json_data = df.to_json()
                
                json_data = json_data.replace('{"nfeProc":{"0":{', '{"nfeProc":{"doc":{')
                json_data = json_data.replace('"det":{"@nItem"', '"det":[{"@nItem"')
                json_data = json_data.replace('},"total":{', '}],"total":{')
                json_data = json_data.replace('"@Id":', '"Id":')
                json_data = json_data.replace('"@versao":', '"versao":')
                # cria um cursor para executar comandos SQL

                if self.conn is None:
                    self.conn = self.connect_to_database

                cur = self.conn.cursor()

                sql = """SELECT ID FROM "DOCUMENTO_FISCAL" WHERE "LICENCA" = ? AND 
                        "EMPRESA" = ? AND "TIPO_DOCUMENTO" = ? AND "TIPO_MOVIMENTO" = ? AND 
                        "CHAVE" = ?"""
                valores = (435, 1, 1, 1, chave)

                cur.execute(sql, valores)
                rows = cur.fetchall()
                # Já existe, despreza
                if rows:
                    # Verifica se tem Movimento, se não exisitir deleta Documento_Fiscal 
                    # para reinseir pois depende da Trigger a alimentação do movimento
                    # Situação ocorre se Exception na execução da Trigger. 
                    id_doc = rows[0][0]
                    sql = """SELECT 1 FROM "LISTA_MOVIMENTO" WHERE "ID_DOCUMENTO_FISCAL" = ?"""
                    valores = (id_doc,)
                    cur.execute(sql, valores)
                    rowsDoc = cur.fetchall()
                    if not rowsDoc:
                        sql = """DELETE FROM "MOVIMENTO" WHERE "LICENCA" = ? AND 
                                "EMPRESA" = ? AND "TIPO_DOCUMENTO" = ? AND "TIPO_MOVIMENTO" = ? AND 
                                "CHAVE" = ?"""
                        valores = (435, 1, 1, 1, chave)
                        cur.execute(sql, valores)
                        #
                        sql = """DELETE FROM DOCUMENTO_FISCAL WHERE "ID" = ?""" 
                        valores = (id_doc,)
                        cur.execute(sql, valores)
                        self.conn.commit()   
                        return 
                        
                    #sql = """INSERT INTO "LOG_IMPORTACAO" ("LICENCA", 
                    #        "CONTEUDO", "MENSAGEM", "CRIADO_DATA")
                    #VALUES (?, ?, ?, ?)"""
                    #valores = (435, 'teste já existe', chave, datetime.now())
                    #if self.conn is None:
                    #    self.connect_to_database()
                    #cur = self.conn.cursor()
                    #
                    #try:
                    #    cur.execute(sql, valores)
                    #    # confirma a transação
                    #    self.conn.commit()
                    #    # fecha o cursor e a conexão com a base de dados
                    #    cur.close()
                    #except Exception as error:
                    #    self.conn.rollback()
                    #    # Grava erros críticos no log e continua a execução do serviço
                    #    logging.error(f"Erro crítico: {error}", exc_info=True)
                    
                    os.remove(arquivo)
                    return

                # define a consulta SQL para inserir dados na tabela
                sql = """INSERT INTO "DOCUMENTO_FISCAL" ("LICENCA", "EMPRESA", "TIPO_DOCUMENTO", 
                        "TIPO_MOVIMENTO", "CHAVE", "XML", "JBXML", "CRIADO_DATA", "STATUS")
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"""

                try:
                    while True: 

                        # define os valores a serem inseridos na tabela
                        valores = (435, 1, 1, 1, chave, conteudo, json_data, datetime.now(), 'A')
                        # executa a consulta SQL com os valores

                        if self.conn is None:
                           self.conn = self.connect_to_database
                        cur = self.conn.cursor()
                        try:
                            cur.execute(sql, valores)
                            # confirma a transação
                            self.conn.commit()
                            # fecha o cursor e a conexão com a base de dados
                            cur.close()
                            # copia para procesados
                            os.makedirs(os.path.dirname(arquivo_processado), exist_ok=True)                            
                            shutil.copy(arquivo, arquivo_processado)
                            break
                        except Exception as error:
                            self.conn.rollback()
                            #if 'The duplicate key value' in str(error): 
                            #    break
                            if 'XML parsing: line 1, character 38, unable to switch the encodingDB-Lib' in str(error) or 'Análise XML: linha 1, caractere 38, não é possível alternar a codificação (9402) (SQLParamData)' in str(error):
                                conteudo = conteudo.replace('encoding="utf-8"?>', 'encoding="utf-16"?>')
                                conteudo = conteudo.replace('encoding="UTF-8"?>', 'encodpython nfeimportacao.py installing="utf-16"?>')
                                continue

                            raise Exception(error)

                except Exception as error:
                    # 01/03/2025 - Passa a gravar na tabela Log_Importacao
                    
                    sql = """INSERT INTO "LOG_IMPORTACAO" ("LICENCA", 
                            "CONTEUDO", "MENSAGEM", "CRIADO_DATA")
                    VALUES (?, ?, ?, ?)"""

                    valores = (435, conteudo, str(error), datetime.now())
                    if self.conn is None:
                        self.connect_to_database()
                    cur = self.conn.cursor()
                    
                    try:
                        cur.execute(sql, valores)
                        # confirma a transação
                        self.conn.commit()
                        # fecha o cursor e a conexão com a base de dados
                        cur.close()
                    except Exception as error:
                        self.conn.rollback()
                        # Grava erros críticos no log e continua a execução do serviço
                        logging.error(f"Erro crítico: {error}", exc_info=True)

            os.remove(arquivo)


if __name__ == '__main__':
    win32serviceutil.HandleCommandLine(NfeImportacaoService)
