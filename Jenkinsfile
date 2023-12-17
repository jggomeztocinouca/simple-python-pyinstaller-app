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
