from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Configura tu URL de conexión a MySQL (reemplaza 'usuario', 'contraseña' y 'localhost' si es necesario)
SQLALCHEMY_DATABASE_URL = "mysql+pymysql://root:kmayte05@localhost:3306/blog_db"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Dependencia para obtener la sesión de base de datos en los endpoints
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()