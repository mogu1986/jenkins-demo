/*
*  Description: java pipeline as code
*  Date: 2019-04-23 16:14
*  Author: wei.gao
*/
pipeline {

    agent {
        label 'master'
    }

    options {
        // 保留1个工程
        buildDiscarder(logRotator(numToKeepStr: '1'))
        // 不允许同时执行多次
        disableConcurrentBuilds()
        // 整个pipeline超时时间
        timeout(time: 20, unit: 'MINUTES')
    }

    environment {
        // harbor 相关配置
        HARBOR = "harbor.top.mw"
        HARBOR_URL = "http://${HARBOR}"
        HARBOR_CRED = credentials('harbor')

        // 容器相关配置
        IMAGE_NAME = "${HARBOR}/library/${JOB_NAME}:${BUILD_ID}"
        K8S_CONFIG = credentials('k8s-config')
    }

    parameters {
        choice(name: 'BUILD_BRANCH', choices: 'dev\ntest', description: '请选择部署的环境')
        string(name: 'JAR_PATH', defaultValue: 'target/demo.war', description: 'jar包路径，相对于workspace')
    }

    stages {

        stage('调试信息') {
            steps {
                echo "部署的环境: ${params.BUILD_BRANCH}"
                sh "printenv"
            }
        }

        stage('拉取代码') {
            steps { git branch: params.BUILD_BRANCH, credentialsId: 'gitlab', url: GIT_URL }
        }

        stage('编译') {
            steps {
                configFileProvider(
                    [configFile(fileId: "dev-maven-global-settings", variable: 'MAVEN_SETTINGS')]) {
                    script {
                        sh 'ls -ll'
                        docker.image('maven:3-jdk-8-alpine').inside('-v /root/.m2:/root/.m2 -v /root/.sonar:/root/.sonar') {
                            sh 'mvn -s $MAVEN_SETTINGS clean deploy -B -Dfile.encoding=UTF-8 -Dmaven.test.skip=true -U'
                        }
                    }
                }
            }
        }

     stage("deploy app"){
       steps{
         script{
           docker.image('williamyeh/ansible:centos7').inside() {
             checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false,
                       extensions: [], submoduleCfg: [],
                       userRemoteConfigs: [[credentialsId: 'gitlab', url: 'http://gitlab.top.mw/devops/jenkins-ansible-playbooks.git']]])
             sh "pwd"
             sh "ls target/"
             sh """
                ansible-playbook --syntax-check playbook.yaml -i hosts.ini
             """
           }
         }
       }
     }

    /*
        stage('ansible自动化部署') {
            steps {
                ansiColor('xterm') {
                    ansiblePlaybook(
                        playbook: 'playbook.yml',
                        inventory: 'hosts.ini',
                        credentialsId: 'ansible',
                        extras: "-e hosts=${params.BUILD_BRANCH} -e workspace=${env.WORKSPACE}",
                        colorized: true)
                }
            }
        }
    */

        stage("邮件通知") {
            steps {
                configFileProvider(
                    [configFile(fileId: "html-global-settings", variable: 'body')]) {
                        emailext(
                            to: 'gaowei@fengjinggroup.com',
                            subject: "Running Pipeline: ${currentBuild.fullDisplayName}",
                            body: readFile("${body}")
                        )
                }
            }
        }
    }

/*
    post {
        always {cleanWs()}
    }
*/

}