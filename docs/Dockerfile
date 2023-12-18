# Utiliza la imagen base de Jenkins
FROM jenkins/jenkins

# Cambia el usuario a root para tener permisos de administrador
USER root

# Actualiza los paquetes disponibles y luego instala lsb-release, una utilidad para obtener información sobre la distribución de Linux
RUN apt-get update && apt-get install -y lsb-release

# Descarga y guarda la llave GPG de Docker para asegurar que los paquetes descargados son auténticos
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc https://download.docker.com/linux/debian/gpg

# Añade el repositorio de Docker al sistema para poder instalar paquetes de Docker desde allí
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.asc] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

# Actualiza de nuevo los paquetes disponibles y luego instala la CLI de Docker (docker-ce-cli)
RUN apt-get update && apt-get install -y docker-ce-cli

# Regresa al usuario jenkins para las operaciones siguientes
USER jenkins

# Instala plugins específicos en Jenkins utilizando el CLI de plugins de Jenkins
RUN jenkins-plugin-cli --plugins "blueocean-pipeline-api-impl:latest"
RUN jenkins-plugin-cli --plugins "docker-workflow:latest"
RUN jenkins-plugin-cli --plugins "json-path-api:latest"