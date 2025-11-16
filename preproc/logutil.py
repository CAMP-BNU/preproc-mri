"""Central logger for the package"""
import logging

_LOG_FMT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"


def get_logger(name: str = "preproc", level: str = None) -> logging.Logger:
    logger = logging.getLogger(name)
    if not logger.handlers:
        # basic config may be set on import, but we only configure once
        ch = logging.StreamHandler()
        ch.setFormatter(logging.Formatter(_LOG_FMT))
        logger.addHandler(ch)
    if level is None:
        # respects root logging config
        logger.setLevel(logging.INFO)
    else:
        logger.setLevel(getattr(logging, level.upper(), logging.INFO))
    return logger
