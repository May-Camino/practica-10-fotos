
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, EmailStr
from typing import List
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import sessionmaker, declarative_base

# Conexion a MySQL
DATABASE_URL = "mysql+mysqlconnector://root:kmayte05@localhost/db_escuela"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

# Inicializar FastAPI
app = FastAPI(title="API Escolar")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Modelo de Alumno
class Alumno(Base):
    __tablename__ = "alumnos"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100))
    edad = Column(Integer)
    carrera = Column(String(100))


# Modelo de Maestro
class Maestro(Base):
    __tablename__ = "maestros"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100))
    especialidad = Column(String(100))
    experiencia = Column(Integer)
    correo = Column(String(100))


# Modelo de Usuario
class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    usuario = Column(String(50), unique=True, index=True)
    contrasena = Column(String(100))


# Crear tablas si no existen
Base.metadata.create_all(bind=engine)


# Esquema de Alumno
class AlumnoSchema(BaseModel):
    nombre: str = Field(..., min_length=2)
    edad: int = Field(..., ge=16, le=99)
    carrera: str


class AlumnoOut(AlumnoSchema):
    id: int

    class Config:
        orm_mode = True


# Esquema de Maestro
class MaestroSchema(BaseModel):
    nombre: str = Field(..., min_length=2)
    especialidad: str = Field(..., min_length=3)
    experiencia: int = Field(..., ge=0, le=50)
    correo: EmailStr


class MaestroOut(MaestroSchema):
    id: int

    class Config:
        orm_mode = True


# Esquema de Login
class LoginSchema(BaseModel):
    usuario: str
    contrasena: str


# LOGIN
@app.post("/login")
def login(datos: LoginSchema):
    db = SessionLocal()

    usuario_encontrado = db.query(Usuario).filter(
        Usuario.usuario == datos.usuario,
        Usuario.contrasena == datos.contrasena
    ).first()

    if usuario_encontrado is None:
        raise HTTPException(
            status_code=401,
            detail="Usuario o contrasena incorrectos"
        )

    return {
        "mensaje": "Login correcto",
        "usuario": usuario_encontrado.usuario
    }


# CRUD de Alumnos

@app.post("/alumnos/", response_model=AlumnoOut)
def crear_alumno(datos: AlumnoSchema):
    db = SessionLocal()

    nuevo = Alumno(**datos.dict())
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    return nuevo


@app.get("/alumnos/", response_model=List[AlumnoOut])
def listar_alumnos():
    db = SessionLocal()

    resultado = db.query(Alumno).all()

    return resultado


@app.get("/alumnos/{id}", response_model=AlumnoOut)
def obtener_alumno(id: int):
    db = SessionLocal()

    alumno = db.query(Alumno).filter(
        Alumno.id == id
    ).first()

    if alumno is None:
        raise HTTPException(
            status_code=404,
            detail="Alumno no encontrado"
        )

    return alumno


@app.put("/alumnos/{id}", response_model=AlumnoOut)
def actualizar_alumno(id: int, datos: AlumnoSchema):
    db = SessionLocal()

    alumno = db.query(Alumno).filter(
        Alumno.id == id
    ).first()

    if alumno is None:
        raise HTTPException(
            status_code=404,
            detail="Alumno no encontrado"
        )

    for key, value in datos.dict().items():
        setattr(alumno, key, value)

    db.commit()
    db.refresh(alumno)

    return alumno


@app.delete("/alumnos/{id}")
def eliminar_alumno(id: int):
    db = SessionLocal()

    alumno = db.query(Alumno).filter(
        Alumno.id == id
    ).first()

    if alumno is None:
        raise HTTPException(
            status_code=404,
            detail="Alumno no encontrado"
        )

    db.delete(alumno)
    db.commit()

    return {"mensaje": "Alumno eliminado"}


# CRUD de Maestros

@app.post("/maestros/", response_model=MaestroOut)
def crear_maestro(datos: MaestroSchema):
    db = SessionLocal()

    nuevo = Maestro(**datos.dict())
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    return nuevo


@app.get("/maestros/", response_model=List[MaestroOut])
def listar_maestros():
    db = SessionLocal()

    resultado = db.query(Maestro).all()

    return resultado


@app.get("/maestros/{id}", response_model=MaestroOut)
def obtener_maestro(id: int):
    db = SessionLocal()

    maestro = db.query(Maestro).filter(
        Maestro.id == id
    ).first()

    if maestro is None:
        raise HTTPException(
            status_code=404,
            detail="Maestro no encontrado"
        )

    return maestro


@app.put("/maestros/{id}", response_model=MaestroOut)
def actualizar_maestro(id: int, datos: MaestroSchema):
    db = SessionLocal()

    maestro = db.query(Maestro).filter(
        Maestro.id == id
    ).first()

    if maestro is None:
        raise HTTPException(
            status_code=404,
            detail="Maestro no encontrado"
        )

    for key, value in datos.dict().items():
        setattr(maestro, key, value)

    db.commit()
    db.refresh(maestro)

    return maestro


@app.delete("/maestros/{id}")
def eliminar_maestro(id: int):
    db = SessionLocal()

    maestro = db.query(Maestro).filter(
        Maestro.id == id
    ).first()

    if maestro is None:
        raise HTTPException(
            status_code=404,
            detail="Maestro no encontrado"
        )

    db.delete(maestro)
    db.commit()

    return {"mensaje": "Maestro eliminado"}
