// Example Jenkinsfile — deploy app infrastructure via ECS/Fargate agent
pipeline {
    agent {
        ecs {
            inheritFrom 'jenkins-agent'
        }
    }

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'stage', 'prod'], description: 'Target environment')
        choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform action')
    }

    environment {
        AWS_REGION      = 'eu-central-1'
        PROJECT_NAME    = 'jenkins-ecs'
        TF_DIR          = 'terraform/03-app-infra'
        DEPLOY_ROLE_ARN = "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${PROJECT_NAME}-deploy-${params.ENVIRONMENT}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Assume Deploy Role') {
            steps {
                script {
                    def creds = sh(
                        script: """
                            aws sts assume-role \
                                --role-arn ${DEPLOY_ROLE_ARN} \
                                --role-session-name jenkins-${params.ENVIRONMENT}-${BUILD_NUMBER} \
                                --output json
                        """,
                        returnStdout: true
                    ).trim()
                    def json = readJSON text: creds
                    env.AWS_ACCESS_KEY_ID     = json.Credentials.AccessKeyId
                    env.AWS_SECRET_ACCESS_KEY = json.Credentials.SecretAccessKey
                    env.AWS_SESSION_TOKEN     = json.Credentials.SessionToken
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir(TF_DIR) {
                    sh "terraform init -backend-config=envs/${params.ENVIRONMENT}.backend.hcl -reconfigure"
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir(TF_DIR) {
                    sh "terraform plan -var='aws_region=${AWS_REGION}' -out=tfplan"
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir(TF_DIR) {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                input message: "Destroy ${params.ENVIRONMENT}? This is irreversible."
                dir(TF_DIR) {
                    sh "terraform destroy -auto-approve -var='aws_region=${AWS_REGION}'"
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
