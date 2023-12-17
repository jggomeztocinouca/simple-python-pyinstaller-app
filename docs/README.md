# Entregable 3: Docker, Terraform y Jenkins

## Autores: Francisco Mercado, Jesús Gómez

## Descripción General

Este proyecto demuestra el proceso de construcción y despliegue de un sistema utilizando Docker, Terraform y Jenkins. Se utiliza un `Dockerfile` para crear una imagen personalizada de Jenkins, un `Terrafile` para definir y gestionar la infraestructura requerida, y un `Jenkinsfile` para automatizar el proceso de construcción, prueba y entrega del software.

## Configuración

### Paso 1: Construcción de la Imagen de Jenkins

En el directorio donde se encuentre el `Dockerfile`, proceda de la siguiente manera:

```
docker build -t jenkins_server .
```

### Paso 2: Configuración con Terraform

En el directorio donde se encuentre el `Terrafile`, proceda de la siguiente manera:

1. **Inicializar Terraform**:
   ```
   terraform init
   ```
2. **Aplicar la configuración de Terraform**:
   ```
   terraform apply
   ```

### Paso 3: Configuración de Jenkins

Configurar un job en Jenkins para utilizar el `Jenkinsfile`.

1. Crear un nuevo job en Jenkins.
2. Configurar el job.
   1. Nombre el job
   2. Seleccione la opción "Pipeline"
   3. En la sección "Pipeline", seleccione "Pipeline script from SCM" en la opción "Definition".
   4. Seleccione "Git" en la opción "SCM".
   5. Ingrese la URL del repositorio (en nuestro caso: https://github.com/jggomeztocinouca/simple-python-pyinstaller-app)

### Paso 4: Ejecución del Pipeline

Ejecutar el job en Jenkins. El pipeline automatizará los siguientes pasos:

1. **Construcción (Build)**: Compilación de código Python.
2. **Pruebas (Test)**: Ejecución de pruebas unitarias.
3. **Entrega (Deliver)**: Empaquetado y entrega del ejecutable.

## Archivos Incluidos

### Dockerfile

```Dockerfile
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
# Instala la versión 1.27.9 del plugin Blue Ocean y la versión 572.v950f58993843 del plugin Docker workflow
RUN jenkins-plugin-cli --plugins "blueocean:1.27.9 docker-workflow:572.v950f58993843"
```

### Terraform

```tf
// Configuración básica de Terraform
terraform {
    required_providers {
        docker = {
            source = "kreuzwerker/docker" // Proveedor Docker para Terraform
            version = "~> 3.0.1" // Versión del proveedor Docker a utilizar
        }
    }
}

// Configura el proveedor Docker
provider "docker" {
    host = "npipe:////.//pipe//docker_engine" // Establece el host para el motor de Docker, específico para sistemas Windows
}

// Imagen Docker para Docker-in-Docker (DinD)
resource "docker_image" "docker_in_docker" {
    name = "docker:dind" // Imagen Docker a descargar
    keep_locally = true // Indica que la imagen se mantendrá localmente incluso después de destruir el recurso
}

// Crea una imagen Docker para Jenkins
resource "docker_image" "jenkins_server" {
    name = "jenkins/jenkins" // Imagen Docker a descargar
    keep_locally = true // Indica que la imagen se mantendrá localmente incluso después de destruir el recurso
}

// Crea un volumen Docker para certificados
resource "docker_volume" "jenkins_docker_certificados" {
  name = "jenkins_docker_certificados" // Nombre del volumen
}

// Crea un volumen Docker para datos de Jenkins
resource "docker_volume" "jenkins_data" {
  name = "jenkins_data" // Nombre del volumen
}

// Crea una red Docker para la comunicación entre contenedores
resource "docker_network" "jenkins_network"{
    name = "jenkins_network" // Nombre de la red
}

// Contenedor Docker para Docker-in-Docker (DinD)
resource "docker_container" "jenkins_docker_in_docker" {
    image = docker_image.docker_in_docker.name // Utiliza la imagen Docker definida previamente como recurso
    name = "jenkins_docker_in_docker" // Nombre del contenedor a crear

    rm = true // Elimina el contenedor cuando se detiene
    privileged = true // Ejecuta el contenedor en modo privilegiado
    env = [ "DOCKER_TLS_CERTDIR=/certs" ] // Variable de entorno para la especificación de ubicación de certificados
    volumes {
        volume_name = docker_volume.jenkins_docker_certificados.name // Monta el volumen de certificados
        container_path = "/certs/client" // Ruta en el contenedor donde se montará el volumen
    }
    volumes {
        volume_name = docker_volume.jenkins_data.name // Monta el volumen de datos
        container_path = "/var/jenkins_home" // Ruta en el contenedor donde se montará el volumen
    }
    networks_advanced {
        name = docker_network.jenkins_network.id // Conecta el contenedor a la red Docker creada
        aliases = [ "docker" ] // Alias para el contenedor en la red
    }
    ports {
        internal = 2376 // Puerto interno del contenedor
        external = 2376 // Puerto mapeado en el host
    }
}

// Contenedor Docker para Jenkins
resource "docker_container" "jenkins_server" {
    image = "jenkins_server" // Utiliza la imagen Docker definida previamente como recurso
    name = "jenkins_server" // Nombre del contenedor a crear

    // Establece variables de entorno para la configuración de Jenkins y Docker
    env = [ "DOCKER_HOST=tcp://docker:2376", "DOCKER_CERT_PATH=/certs/client", "DOCKER_TLS_VERIFY=1", "JAVA_OPTS=-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true"]
    volumes {
        volume_name = docker_volume.jenkins_docker_certificados.name // Monta el volumen de certificados
        container_path = "/certs/client"
        read_only = true // Establece el volumen como solo lectura
    }
    volumes {
        volume_name = docker_volume.jenkins_data.name // Monta el volumen de datos
        container_path = "/var/jenkins_home"
    }
    networks_advanced {
        name = docker_network.jenkins_network.id // Conecta el contenedor a la red Docker creada
    }
    ports {
        internal = 8080 // Puerto interno del contenedor para la interfaz web de Jenkins
        external = 8080 // Puerto mapeado en el host para la interfaz web
    }
    ports {
        internal = 50000 // Puerto interno para conexiones de agentes Jenkins
        external = 50000 // Puerto mapeado en el host para conexiones de agentes
    }
}
```

### Jenkinsfile

```groovy
pipeline {
    agent none // Especifica que no hay un agente predeterminado para todas las etapas

    options {
        skipStagesAfterUnstable() // Omite las etapas restantes si el build falla
    }

    stages {
        stage('Build') { // Inicia la etapa "Build"
            agent {
                docker { // Utiliza un agente Docker
                    image 'python:3.12.1-alpine3.19'
                // Especifica la imagen de Docker a usar (Python 3.12.1 en Alpine 3.19)
                }
            }
            steps {
                sh 'python -m py_compile sources/add2vals.py sources/calc.py'
                // Compila los archivos Python especificados

                stash(name: 'compiled-results', includes: 'sources/*.py*')
            // Guarda los resultados compilados para usarlos en etapas posteriores
            }
        }

        stage('Test') { // Inicia la etapa "Test"
            agent {
                docker { // Utiliza un agente Docker
                    image 'qnib/pytest'
                // Especifica la imagen de Docker a usar para pruebas (pytest)
                }
            }
            steps {
                sh 'py.test --junit-xml test-reports/results.xml sources/test_calc.py'
            // Ejecuta las pruebas unitarias y genera un informe en formato JUnit
            }
            post {
                always {
                    junit 'test-reports/results.xml'
                // Muestra los resultados de las pruebas en Jenkins
                }
            }
        }

        stage('Deliver') { // Inicia la etapa "Deliver"
            agent any // Utiliza cualquier agente disponible
            environment {
                VOLUME = '$(pwd)/sources:/src' // Define una variable de entorno para el volumen de Docker
                IMAGE = 'cdrx/pyinstaller-linux:python2' // Define la imagen de Docker para PyInstaller
            }
            steps {
                dir(path: env.BUILD_ID) { // Crea un directorio con el ID del build
                    unstash(name: 'compiled-results')
                    // Recupera los archivos compilados previamente

                    sh "docker run --rm -v ${VOLUME} ${IMAGE} 'pyinstaller -F add2vals.py'"
                // Usa PyInstaller para crear un ejecutable
                }
            }
            post {
                success {
                    archiveArtifacts "${env.BUILD_ID}/sources/dist/add2vals"
                    // Archiva el artefacto generado en caso de éxito

                    sh "docker run --rm -v ${VOLUME} ${IMAGE} 'rm -rf build dist'"
                // Limpia los directorios de construcción y distribución
                }
            }
        }
    }
}

```

## Referencias

- [Jenkins: Build a Python app with PyInstaller](https://www.jenkins.io/doc/tutorials/build-a-python-app-with-pyinstaller/)
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
