from contextlib import contextmanager
from psycopg_pool import ConnectionPool
from .settings import settings

pool = ConnectionPool(conninfo=settings.database_url, min_size=1, max_size=8, open=False)

@contextmanager
def db_cursor():
    if pool.closed:
        pool.open()
    with pool.connection() as conn:
        with conn.cursor() as cur:
            yield cur
        conn.commit()
