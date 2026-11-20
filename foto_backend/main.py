import os
import shutil
from datetime import datetime
from typing import List, Optional
from fastapi import FastAPI, Depends, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, TIMESTAMP, text
from sqlalchemy.orm import sessionmaker, Session, declarative_base

# 1. Configuración de la Base de Datos MySQL
DATABASE_URL = "mysql+pymysql://root:kmayte05@localhost/galeria_foto"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# 2. Modelo SQLAlchemy (Tabla P10_foto)
class FotoDB(Base):
    __tablename__ = "P10_foto"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    descripcion = Column(String(255), nullable=False)
    ruta_foto = Column(String(255), nullable=False)
    fecha = Column(TIMESTAMP, server_default=text("CURRENT_TIMESTAMP"))

# 3. Esquemas Pydantic para validación y respuesta
class FotoSchema(BaseModel):
    id: int
    descripcion: str
    ruta_foto: str
    fecha: Optional[datetime]

    class Config:
        from_attributes = True

class FotoResponse(BaseModel):
    msg: str
    foto: FotoSchema

# 4. Inicialización de la App FastAPI
app = FastAPI(title="API Gestión de Imágenes Práctica 10")

# Configurar CORS para permitir peticiones desde Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Crear carpeta 'uploads' si no existe y montarla como archivos estáticos
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# Dependencia para obtener la sesión de BD
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 5. Endpoints
@app.post("/fotos", response_model=FotoResponse)
async def subir_foto(
    descripcion: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    # Guardar el archivo físicamente en la carpeta uploads/
    ruta_archivo = f"{UPLOAD_DIR}/{file.filename}"
    try:
        with open(ruta_archivo, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al guardar imagen: {str(e)}")

    # Guardar el registro en MySQL
    nueva_foto = FotoDB(
        descripcion=descripcion,
        ruta_foto=ruta_archivo
    )

    db.add(nueva_foto)
    db.commit()
    db.refresh(nueva_foto)

    return {
        "msg": "Foto subida correctamente",
        "foto": nueva_foto
    }

@app.get("/fotos", response_model=List[FotoSchema])
def listar_fotos(db: Session = Depends(get_db)):
    fotos = db.query(FotoDB).all()
    return fotos
