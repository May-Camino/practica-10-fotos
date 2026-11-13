from datetime import datetime
from typing import List, Optional
from database import Base, get_db
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Session, relationship

# aqui encendemos nuestra app de fastapi y le ponemos un titulo bonito
app = FastAPI(title="Blog API Integrador")

# esto es como abrirle la puerta de la entrada a cualquier dispositivo (flutter, web, movil)
# sin esto, flutter se enoja y no deja pasar la informacion por seguridad
origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================
# 2. MODELOS DE SQLALCHEMY (como creamos las tablas en la base de datos)
# ============================================================


class Usuario(Base):
  __tablename__ = "usuario"

  id_usr = Column(Integer, primary_key=True, index=True, autoincrement=True)
  nom_usr = Column(String(100), nullable=False)
  mail = Column(String(150), nullable=False, unique=True)
  pass_ = Column("pass", String(255), nullable=False)
  dir_usr = Column(String(255), nullable=True)
  tip_usu = Column(Integer, default=1, nullable=False)

  comentarios = relationship("Comentario", back_populates="autor")


class Blog(Base):
  __tablename__ = "blog"

  id_blog = Column(Integer, primary_key=True, index=True, autoincrement=True)
  titulo = Column(String(200), nullable=False)
  desc = Column(String(500), nullable=True)
  img = Column(String(255), nullable=True)
  tags = Column(String(255), nullable=True)

  comentarios = relationship("Comentario", back_populates="post")


class Comentario(Base):
  __tablename__ = "comentarios"

  id_com = Column(Integer, primary_key=True, index=True, autoincrement=True)
  comentario = Column(String(500), nullable=False)
  fecha = Column(DateTime, default=datetime.utcnow, nullable=False)
  estatus = Column(Integer, default=1, nullable=False)
  usr_id = Column(Integer, ForeignKey("usuario.id_usr"), nullable=False)
  blog_id = Column(Integer, ForeignKey("blog.id_blog"), nullable=False)

  autor = relationship("Usuario", back_populates="comentarios")
  post = relationship("Blog", back_populates="comentarios")


# ============================================================
# 3. ESQUEMAS DE PYDANTIC (las reglas para validar los datos que viajan como json)
# ============================================================


class ComentarioCreate(BaseModel):
  comentario: str
  usr_id: int
  blog_id: int


class ComentarioResponse(BaseModel):
  id_com: int
  comentario: str
  fecha: datetime
  usr_id: int
  nom_usr: str

  class Config:
    from_attributes = True


class BlogBase(BaseModel):
  id_blog: int
  titulo: str
  desc: Optional[str] = None
  img: Optional[str] = None
  tags: Optional[str] = None

  class Config:
    from_attributes = True


class BlogDetailResponse(BlogBase):
  comentarios: List[ComentarioResponse] = []


class RegistroUsuario(BaseModel):
  nom_usr: str
  mail: str
  password: str
  dir_usr: Optional[str] = None


class Login(BaseModel):
  mail: str
  password: str


class UsuarioResponse(BaseModel):
  id_usr: int
  nom_usr: str
  mail: str

  class Config:
    from_attributes = True


class BlogCreate(BaseModel):
  titulo: str
  desc: str
  img: Optional[str] = None
  tags: Optional[str] = None


# ============================================================
# 4. ENDPOINTS DE LA API (las rutas a las que flutter toca la puerta para pedir o enviar cosas)
# ============================================================


# aqui flutter pide la lista completa de todos los blogs publicados
@app.get("/posts", response_model=List[BlogBase])
def get_posts(db: Session = Depends(get_db)):
  # es como ir al archivero y traerse todas las filas de la tabla blog
  posts = db.query(Blog).all()
  return posts


# aqui flutter pide el detalle de un solo blog junto con sus comentarios y el autor de cada uno
@app.get("/posts/{blog_id}", response_model=BlogDetailResponse)
def get_post_detail(blog_id: int, db: Session = Depends(get_db)):
  # buscamos el blog por su id unico
  post = db.query(Blog).filter(Blog.id_blog == blog_id).first()

  if not post:
    raise HTTPException(status_code=404, detail="Post no encontrado")

  comentarios_dto = []

  # recorremos los comentarios uno por uno para armar la informacion que vera el usuario
  for com in post.comentarios:
    if com.estatus == 1:
      comentarios_dto.append(
          ComentarioResponse(
              id_com=com.id_com,
              comentario=com.comentario,
              fecha=com.fecha,
              usr_id=com.usr_id,
              nom_usr=com.autor.nom_usr if com.autor else "Usuario Anónimo",
          )
      )

  return BlogDetailResponse(
      id_blog=post.id_blog,
      titulo=post.titulo,
      desc=post.desc,
      img=post.img,
      tags=post.tags,
      comentarios=comentarios_dto,
  )


# aqui guardamos un nuevo comentario que alguien escribio desde flutter
@app.post(
    "/comentarios",
    response_model=ComentarioResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_comentario(data: ComentarioCreate, db: Session = Depends(get_db)):

  # primero revisamos si el usuario que quiere comentar de verdad existe en la base
  usr = db.query(Usuario).filter(Usuario.id_usr == data.usr_id).first()

  if not usr:
    raise HTTPException(status_code=404, detail="Usuario no encontrado")

  # luego revisamos si el blog al que le comenta sigue existiendo
  blog = db.query(Blog).filter(Blog.id_blog == data.blog_id).first()

  if not blog:
    raise HTTPException(status_code=404, detail="Post no encontrado")

  # si todo esta bien, creamos la cajita del comentario lista para guardarse
  nuevo_comentario = Comentario(
      comentario=data.comentario, usr_id=data.usr_id, blog_id=data.blog_id
  )

  # guardamos y confirmamos los cambios en la base de datos (como darle guardar en excel)
  db.add(nuevo_comentario)
  db.commit()
  db.refresh(nuevo_comentario)

  return ComentarioResponse(
      id_com=nuevo_comentario.id_com,
      comentario=nuevo_comentario.comentario,
      fecha=nuevo_comentario.fecha,
      usr_id=nuevo_comentario.usr_id,
      nom_usr=usr.nom_usr,
  )


# aqui borramos un comentario, pero validamos que la persona que lo borra sea duenia del comentario
@app.delete("/comentarios/{comentario_id}")
def delete_comentario(
    comentario_id: int, usr_id: int, db: Session = Depends(get_db)
):
  comentario = (
      db.query(Comentario).filter(Comentario.id_com == comentario_id).first()
  )

  if not comentario:
    raise HTTPException(status_code=404, detail="Comentario no encontrado")

  # si el usuario que borra no coincide con el que escribio el comentario, lo bloqueamos
  if comentario.usr_id != usr_id:
    raise HTTPException(
        status_code=403, detail="No tienes permiso para eliminar este comentario"
    )

  db.delete(comentario)
  db.commit()

  return {"message": "Comentario eliminado exitosamente"}


# aqui registramos a un nuevo usuario revisando que su correo no este repetido
@app.post("/RegistroUsuario", response_model=UsuarioResponse)
def registrar_usuario(usuario: RegistroUsuario, db: Session = Depends(get_db)):

  existe = db.query(Usuario).filter(Usuario.mail == usuario.mail).first()

  if existe:
    raise HTTPException(status_code=400, detail="El correo ya está registrado")

  nuevo_usuario = Usuario(
      nom_usr=usuario.nom_usr,
      mail=usuario.mail,
      pass_=usuario.password,
      dir_usr=usuario.dir_usr,
  )

  db.add(nuevo_usuario)
  db.commit()
  db.refresh(nuevo_usuario)

  return nuevo_usuario


# aqui validamos el correo ycontrasena cuando alguien quiere iniciar sesion
@app.post("/Login")
def login(datos: Login, db: Session = Depends(get_db)):

  usuario = db.query(Usuario).filter(Usuario.mail == datos.mail).first()

  if not usuario:
    raise HTTPException(status_code=404, detail="Usuario no encontrado")

  if usuario.pass_ != datos.password:
    raise HTTPException(status_code=401, detail="Contraseña incorrecta")

  return {
      "mensaje": "Login exitoso",
      "id_usr": usuario.id_usr,
      "nom_usr": usuario.nom_usr,
      "mail": usuario.mail,
  }


# aqui creamos una nueva publicacion de blog para que aparezca en la lista principal
@app.post("/posts")
def crear_post(post: BlogCreate, db: Session = Depends(get_db)):
  nuevo_post = Blog(
      titulo=post.titulo, desc=post.desc, img=post.img, tags=post.tags
  )

  db.add(nuevo_post)
  db.commit()
  db.refresh(nuevo_post)

  return nuevo_post