import logging
import os

try:
    from tqdm import tqdm


    class TqdmLoggingHandler(logging.Handler):
        def __init__(self, fallback_handler: logging.Handler):
            super().__init__()
            self.fallback_handler = fallback_handler

        def emit(self, record):
            try:
                # If there are active tqdm progress bars,
                # attempt to not interfere with them.
                if tqdm._instances:
                    tqdm.write(self.format(record))
                else:
                    self.fallback_handler.emit(record)
            except Exception:
                self.fallback_handler.emit(record)

except ImportError:
    TqdmLoggingHandler = None


def setup_logging(loglevel):
    if loglevel is None:
        loglevel = os.environ.get("SD_WEBUI_LOG_LEVEL")

    #Hardcode default to INFO
    if loglevel is None:
        loglevel = "INFO"
<<<<<<< HEAD
    loghandlers = []

    if TQDM_IMPORTED:
        loghandlers.append(TqdmLoggingHandler())
=======
>>>>>>> a93ae0aa144a5113c5214ac6b46982edaf31d43c

    if loglevel:
        log_level = getattr(logging, loglevel.upper(), None) or logging.INFO
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s [%(levelname)-9s][%(name)-20s] %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S',
        )
    #Remove logs for httpx, too much infos
    logging.getLogger("httpx").setLevel(logging.WARNING)

<<<<<<< HEAD
=======
    if logging.root.handlers:
        # Already configured, do not interfere
        return

    formatter = logging.Formatter(
        '%(asctime)s %(levelname)s [%(name)s] %(message)s',
        '%Y-%m-%d %H:%M:%S',
    )

    if os.environ.get("SD_WEBUI_RICH_LOG"):
        from rich.logging import RichHandler
        handler = RichHandler()
    else:
        handler = logging.StreamHandler()
        handler.setFormatter(formatter)

    if TqdmLoggingHandler:
        handler = TqdmLoggingHandler(handler)

    handler.setFormatter(formatter)

    log_level = getattr(logging, loglevel.upper(), None) or logging.INFO
    logging.root.setLevel(log_level)
    logging.root.addHandler(handler)
>>>>>>> a93ae0aa144a5113c5214ac6b46982edaf31d43c
