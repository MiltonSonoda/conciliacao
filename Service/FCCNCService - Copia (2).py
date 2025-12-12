import os
import sys
import time
import logging
import datetime as dt

import requests
from requests.exceptions import ReadTimeout, ConnectionError

import win32serviceutil
import win32service
import win32event
import servicemanager


# =====================
# CONFIGURAÇÕES BÁSICAS
# =====================

API_BASE = "http://localhost:1125/pedidopago/v1"

INTERVALO_SEGUNDOS = 5 * 60  # 5 minutos
HORA_INICIO = dt.time(8, 0)  # 08:00
HORA_FIM = dt.time(20, 0)    # 20:00


def configurar_logging():
    """
    Configura o logging na pasta do script.
    Em serviço, o working dir não é o do script, então usamos __file__.
    """
    try:
        base_dir = os.path.dirname(os.path.abspath(__file__))
    except Exception:
        # fallback raro (mas deixa algo funcional)
        base_dir = os.getcwd()

    log_path = os.path.join(base_dir, "FCCNCService.log")

    logging.basicConfig(
        filename=log_path,
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )

    logging.info("Logging inicializado. Arquivo: %s", log_path)


def eh_horario_comercial(agora: dt.datetime) -> bool:
    """Retorna True se estiver entre 08:00 e 20:00."""
    hora_atual = agora.time()
    return HORA_INICIO <= hora_atual < HORA_FIM


def obter_access_token():
    """
    Consome a API de access token.
    Retorna o JSON/texto em caso de sucesso, ou None em caso de falha.
    """
    url = f"{API_BASE}/accesstoken/obter"
    logging.info(f"Chamando: GET {url}")

    try:
        # timeout=(conexão, leitura) em segundos
        resp = requests.get(url, timeout=(5, 30))
        resp.raise_for_status()
    except ReadTimeout:
        logging.warning("Timeout ao obter access token (nenhuma resposta em até 30s).")
        return None
    except ConnectionError as e:
        logging.error(f"Falha de conexão ao obter access token: {e}")
        return None
    except Exception as e:
        logging.error(f"Erro geral ao obter access token: {e}", exc_info=True)
        return None

    try:
        dados = resp.json()
    except Exception:
        dados = resp.text

    logging.info(f"AccessToken OK. Resposta: {dados}")
    return dados


def gravar_transacoes():
    """
    Consome a API de gravação de transações.
    Retorna o JSON/texto em caso de sucesso, ou None em caso de falha.
    """
    url = f"{API_BASE}/transacoes/gravar"
    logging.info(f"Chamando: POST {url}")

    try:
        resp = requests.post(url, timeout=(5, 60))
        resp.raise_for_status()
    except ReadTimeout:
        logging.warning("Timeout ao gravar transações (nenhuma resposta em até 60s).")
        return None
    except ConnectionError as e:
        logging.error(f"Falha de conexão ao gravar transações: {e}")
        return None
    except Exception as e:
        logging.error(f"Erro geral ao gravar transações: {e}", exc_info=True)
        return None

    try:
        dados = resp.json()
    except Exception:
        dados = resp.text

    logging.info(f"Gravar transações OK. Resposta: {dados}")
    return dados


class FCCNCService(win32serviceutil.ServiceFramework):
    _svc_name_ = "FCCNCService"
    _svc_display_name_ = "FCCNC Integração PedidoPago"
    _svc_description_ = (
        "Serviço que obtém AccessToken e grava transações do PedidoPago "
        "a cada 5 minutos, gravando somente em horário comercial (08h às 20h)."
    )

    def __init__(self, args):
        win32serviceutil.ServiceFramework.__init__(self, args)
        # Evento sinalizado quando o serviço for parado
        self.hWaitStop = win32event.CreateEvent(None, 0, 0, None)
        self.running = True

    def SvcStop(self):
        """Chamado quando o serviço recebe comando de parar."""
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
        logging.info("FCCNCService recebendo comando de parada...")
        self.running = False
        win32event.SetEvent(self.hWaitStop)

    def SvcDoRun(self):
        """Entrada principal do serviço."""
        configurar_logging()
        logging.info("FCCNCService iniciado via SCM.")

        # Registra no Event Viewer
        servicemanager.LogMsg(
            servicemanager.EVENTLOG_INFORMATION_TYPE,
            servicemanager.PYS_SERVICE_STARTED,
            (self._svc_name_, "")
        )

        self.main_loop()

    def main_loop(self):
        """Loop principal, respeitando sinal de parada."""
        logging.info("Loop principal iniciado.")

        while self.running:
            inicio_ciclo = dt.datetime.now()
            logging.info("Iniciando ciclo de execução.")

            try:
                # 1) Sempre tentar obter AccessToken
                token_result = obter_access_token()

                if token_result is None:
                    logging.warning(
                        "Não foi possível obter access token neste ciclo. "
                        "Transações não serão gravadas."
                    )
                else:
                    # 2) Se for horário comercial, gravar transações
                    if eh_horario_comercial(inicio_ciclo):
                        logging.info("Dentro do horário comercial. Gravando transações...")
                        gravar_transacoes()
                    else:
                        logging.info("Fora do horário comercial. Não irá gravar transações.")

            except Exception as e:
                # Caso escape algo não tratado nas funções
                logging.error(f"Erro inesperado no ciclo: {e}", exc_info=True)

            logging.info(
                f"Ciclo finalizado. Aguardando {INTERVALO_SEGUNDOS} segundos ou comando de parada..."
            )

            # Espera até INTERVALO_SEGUNDOS ou até receber sinal para parar
            rc = win32event.WaitForSingleObject(
                self.hWaitStop,
                int(INTERVALO_SEGUNDOS * 1000)
            )

            if rc == win32event.WAIT_OBJECT_0:
                # Recebeu sinal de parada
                logging.info("Sinal de parada recebido. Encerrando loop principal.")
                break


if __name__ == '__main__':
    win32serviceutil.HandleCommandLine(FCCNCService)
