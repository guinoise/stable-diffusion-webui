import os
import logging


def setup_logging(loglevel):
    if loglevel is None:
        loglevel = os.environ.get("SD_WEBUI_LOG_LEVEL")

    #Hardcode default to INFO
    if loglevel is None:
        loglevel = "INFO"

    if loglevel:
        log_level = getattr(logging, loglevel.upper(), None) or logging.INFO
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s [%(levelname)-9s][%(name)-20s] %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S',
        )
    #Remove logs for httpx, too much infos
    logging.getLogger("httpx").setLevel(logging.WARNING)


