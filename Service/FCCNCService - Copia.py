import os
import sys
import time
import logging
import datetime as dt

import win32serviceutil
import win32service
import win32event
import servicemanager

import requests

# =====================
# CONFIGURAÇÕES BÁSICAS
# =====================

API_BASE = "http://localhost:1125/pedidopago/v1"

INTERVALO_SEGUNDOS = 5 * 60  # 5 minutos
HORA_INICIO = dt.time(8, 0)  # 08:00
HORA_FIM = dt.time(20, 0)    # 20:00


def configurar_logging():
    """Configura o logging na pasta onde o script está."""
    try:
        base_dir = os.path.dirname(os.path.abspath(__file__))
    except:
        # fallback raro para ambiente estranho
        base_dir = os.getcwd()

    log_path = os.path.join(base_dir, "pedidopago_service.log")

    logging.basicConfig(
        filename=log_path,
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )

    logging.info("Logging inicializado. Arquivo: %s", log_path)


def obter_access_token():
    """Consome a API de access token."""
    url = f"{API_BASE}/accesstoken/obter"
    logging.info(f"Chamando: GET {url}")

    resp = requests.get(url, timeout=30)
    resp.raise_for_status()

    try:
        dados = resp.json()
    except Exception:
        dados = resp.text

    logging.info(f"AccessToken OK. Resposta: {dados}")
    return dados


def gravar_transacoes():
    """Consome a API de gravação de transações (apenas horário comercial)."""
    url = f"{API_BASE}/transacoes/gravar"
    logging.info(f"Chamando: POST {url}")

    resp = requests.post(url, timeout=60)
    resp.raise_for_status()

    try:
        dados = resp.json()
    except Exception:
        dados = resp.text

    logging.info(f"Gravar transações OK. Resposta: {dados}")
    return dados


def eh_horario_comercial(agora: dt.datetime) -> bool:
    """Retorna True se estiver entre 08:00 e 20:00."""
    hora_atual = agora.time()
    return HORA_INICIO <= hora_atual < HORA_FIM


class PedidoPagoService(win32serviceutil.ServiceFramework):
    _svc_name_ = "PedidoPagoService"
    _svc_display_name_ = "PedidoPago Integração Financeira"
    _svc_description_ = (
        "Serviço que obtém AccessToken e grava transacoes do PedidoPago "
        "a cada 5 minutos, gravando somente em horário comercial (08h às 20h)."
    )

    def __init__(self, args):
        win32serviceutil.ServiceFramework.__init__(self, args)
        # Evento que será sinalizado quando o serviço for parado
        self.hWaitStop = win32event.CreateEvent(None, 0, 0, None)
        self.running = True

    def SvcStop(self):
        """Chamado quando o serviço recebe comando de parar."""
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
        logging.info("PedidoPagoService recebendo comando de parada...")
        self.running = False
        win32event.SetEvent(self.hWaitStop)

    def SvcDoRun(self):
        """Entrada principal do serviço."""
        configurar_logging()
        logging.info("PedidoPagoService iniciado via SCM.")

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
        # Em vez de time.sleep(...), vamos usar WaitForSingleObject com timeout.
        # Assim ele acorda a cada INTERVALO_SEGUNDOS OU quando receber stop.

        while self.running:
            inicio_ciclo = dt.datetime.now()
            logging.info("Iniciando ciclo de execução.")

            try:
                # 1) Sempre obter AccessToken
                obter_access_token()

                # 2) Se for horário comercial, gravar transações
                if eh_horario_comercial(inicio_ciclo):
                    logging.info("Dentro do horário comercial. Gravando transações...")
                    gravar_transacoes()
                else:
                    logging.info("Fora do horário comercial. Não irá gravar transações.")

            except requests.HTTPError as e:
                logging.error(f"Erro HTTP ao consumir API: {e}", exc_info=True)
            except Exception as e:
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
    # Se rodar direto, trata como serviço (instalar/start/stop via linha de comando)
    win32serviceutil.HandleCommandLine(PedidoPagoService)
