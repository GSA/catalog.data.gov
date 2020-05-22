import logging
import sys


def get_logger(name):
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)

    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(logging.INFO)
    formatter = logging.Formatter('%(name)s - %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)

    handler_err = logging.FileHandler(f'error.log')
    handler_err.setLevel(logging.ERROR)
    formatter = logging.Formatter('%(name)s - %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler_err)

    return logger