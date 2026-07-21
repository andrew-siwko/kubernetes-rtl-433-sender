pipeline {
    agent { label 'docker-builder' }

    environment {
        REGISTRY = 'kregistry.siwko.org:5000'
        IMAGE = "${REGISTRY}/rtl-433-sender"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        // Built for arm64 only (via buildx cross-build) since this image only ever
        // runs on the arm64 orangepizero3 node with the SDR dongle attached; --push
        // is required in place of a separate load/push step because a non-native
        // arch image can't be loaded into the local docker daemon.
        stage('Build & Push') {
            steps {
                sh "docker buildx build --platform linux/arm64 --provenance=false --sbom=false -f Dockerfile -t ${IMAGE}:${IMAGE_TAG} -t ${IMAGE}:latest --push ."
            }
        }
        stage('Deploy') {
            steps {
                echo "=== apply node taint ==="
                sh "kubectl apply -f k8s/node-taints.yaml"
                sh "kubectl apply -f k8s/rtl-433-sender-deployment.yaml"
                sh "kubectl rollout restart deployment/rtl-433-sender"
            }
        }
    }
}
