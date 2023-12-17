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
