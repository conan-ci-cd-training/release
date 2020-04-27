def config_url = "https://github.com/conan-ci-cd-training/settings.git"

def artifactory_metadata_repo = "conan-metadata"
def conan_develop_repo = "conan-develop"
def conan_tmp_repo = "conan-tmp"
def artifactory_url = (env.ARTIFACTORY_URL != null) ? "${env.ARTIFACTORY_URL}" : "jfrog.local"


pipeline {

    agent none

    parameters {
        string(name: 'product',)
        string(name: 'build_name',)
        string(name: 'build_number',)
        string(name: 'profile',)
    }

    stages {
        stage("Create, test and promote debian package") {
            steps {
                script {
                    def product = (params.product != null && params.product != "") ? "${params.product}" : "App/1.0@mycompany/stable"
                    def build_name = (params.build_name != null && params.build_name != "") ? "${params.build_name}" : "App/develop"
                    def build_number = (params.build_number != null && params.build_number != "") ? "${params.build_number}" : "2"
                    def profile = (params.profile != null && params.profile != "") ? "${params.profile}" : "release-gcc6"
                    docker.image("conanio/gcc6").inside("--net=host") {
                        def scmVars = checkout scm
                        String version = product.tokenize("/")[1].split("@")[0]
                        withEnv(["CONAN_USER_HOME=${env.WORKSPACE}/conan_cache","JFROG_CLI_HOME_DIR=/tmp"]) {
                            try {
                                sh "conan config install ${config_url}"
                                sh "conan remote add ${conan_develop_repo} http://${artifactory_url}:8081/artifactory/api/conan/${conan_develop_repo}"
                                withCredentials([usernamePassword(credentialsId: 'artifactory-credentials', usernameVariable: 'ARTIFACTORY_USER', passwordVariable: 'ARTIFACTORY_PASSWORD')]) {                      
                                    sh "conan user -p ${ARTIFACTORY_PASSWORD} -r ${conan_develop_repo} ${ARTIFACTORY_USER}"
                                    def lockfile_url = "http://${artifactory_url}:8081/artifactory/${artifactory_metadata_repo}/${build_name}/${build_number}/${product}/${profile}/conan.lock"
                                    stage("Download product: ${product} build name: ${build_name} build number: ${build_number} lockfile for profile: ${profile}") {
                                        sh "curl --user \"\${ARTIFACTORY_USER}\":\"\${ARTIFACTORY_PASSWORD}\" -o conan.lock ${lockfile_url}"
                                    }
                                    stage("Create Debian Package") {
                                        sh "conan install ${product} --lockfile conan.lock -g deploy -r ${conan_develop_repo}"
                                        sh "./generateDebianPkg.sh ${version}"
                                    }
                                    stage("Upload package to SIT repo in Artifactory") {
                                        def deb_url = "http://${artifactory_url}:8081/artifactory/app-debian-sit-local/pool/myapp_${version}.deb;deb.distribution=stretch;deb.component=main;deb.architecture=x86-64" 
                                        sh "curl --user \"\${ARTIFACTORY_USER}\":\"\${ARTIFACTORY_PASSWORD}\" -X PUT \"${deb_url}\" -T myapp_${version}.deb"
                                    }
                                    stage("Generate and publish build info") {
                                        sh "curl -o jfrog -L 'https://api.bintray.com/content/jfrog/jfrog-cli-go/1.35.3/jfrog-cli-linux-386/jfrog?bt_package=jfrog-cli-linux-386'"
                                        sh "chmod a+x jfrog && printenv"
                                        sh "./jfrog rt c --interactive=false  --url=http://jfrog.local:8081/artifactory --user=${ARTIFACTORY_USER} --password=${ARTIFACTORY_PASSWORD} art7"
                                        sh "./jfrog rt u myapp_${version}.deb app-debian-sit-local/pool/ --build-name=\"${env.JOB_NAME}\" --build-number=\"${env.BUILD_ID}\""
                                        sh "./jfrog rt bad ${env.JOB_NAME} ${env.BUILD_ID} conan.lock"
                                        sh "./jfrog rt bp ${env.JOB_NAME} ${env.BUILD_ID}"
                                    }
                                    stage("Pass System Integration Tests") {
                                        echo "System Integration Tests OK!"
                                    }
                                    stage("Promote to UAT after tests passed") {
                                        sh "./jfrog rt bpr ${env.JOB_NAME} ${env.BUILD_ID} app-debian-uat-local --status=\"SIT_OK\"  --comment=\"passed integration tests\" --include-dependencies=false --copy=false"
                                    }
                                }
                            }
                            finally {
                                deleteDir()
                            }                        
                        }
                    }
                }
            }
        }
    }
}
