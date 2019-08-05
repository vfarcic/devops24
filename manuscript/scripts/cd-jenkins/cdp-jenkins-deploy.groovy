import java.text.SimpleDateFormat

currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER
env.REPO = "https://github.com/vfarcic/go-demo-3.git"
env.IMAGE = "vfarcic/go-demo-3"
env.ADDRESS = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}.acme.com"
env.PROD_ADDRESS = "go-demo-3.acme.com"
env.CM_ADDR = "acme.com"
env.TAG = "${currentBuild.displayName}"
env.TAG_BETA = "${env.TAG}-${env.BRANCH_NAME}"
env.CHART_VER = "0.0.1"
env.CHART_NAME = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}"
def label = "jenkins-slave-${UUID.randomUUID().toString()}"

podTemplate(
  label: label,
  namespace: "go-demo-3-build",
  serviceAccount: "build",
  yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: helm
    image: vfarcic/helm:2.9.1
    command: ["cat"]
    tty: true
  - name: kubectl
    image: vfarcic/kubectl
    command: ["cat"]
    tty: true
  - name: golang
    image: golang:1.12
    command: ["cat"]
    tty: true
"""
) {
  node(label) {
    node("docker") {
      stage("build") {
        git "${env.REPO}"
        sh """sudo docker image build \
          -t ${env.IMAGE}:${env.TAG_BETA} ."""
        withCredentials([usernamePassword(
          credentialsId: "docker",
          usernameVariable: "USER",
          passwordVariable: "PASS"
        )]) {
          sh """sudo docker login \
            -u $USER -p $PASS"""
        }
        sh """sudo docker image push \
          ${env.IMAGE}:${env.TAG_BETA}"""
      }
    }
    stage("func-test") {
      try {
        container("helm") {
          git "${env.REPO}"
          sh """helm upgrade \
            ${env.CHART_NAME} \
            helm/go-demo-3 -i \
            --tiller-namespace go-demo-3-build \
            --set image.tag=${env.TAG_BETA} \
            --set ingress.host=${env.ADDRESS} \
            --set replicaCount=2 \
            --set dbReplicaCount=1"""
        }
        container("kubectl") {
          sh """kubectl -n go-demo-3-build \
            rollout status deployment \
            ${env.CHART_NAME}"""
        }
        container("golang") { // Uses env ADDRESS
          sh "go get -d -v -t"
          sh """go test ./... -v \
            --run FunctionalTest"""
        }
      } catch(e) {
          error "Failed functional tests"
      } finally {
        container("helm") {
          sh """helm delete \
            ${env.CHART_NAME} \
            --tiller-namespace go-demo-3-build \
            --purge"""
        }
      }
    }
    stage("release") {
      node("docker") {
        sh """sudo docker pull \
          ${env.IMAGE}:${env.TAG_BETA}"""
        sh """sudo docker image tag \
          ${env.IMAGE}:${env.TAG_BETA} \
          ${env.IMAGE}:${env.TAG}"""
        sh """sudo docker image tag \
          ${env.IMAGE}:${env.TAG_BETA} \
          ${env.IMAGE}:latest"""
        withCredentials([usernamePassword(
          credentialsId: "docker",
          usernameVariable: "USER",
          passwordVariable: "PASS"
        )]) {
          sh """sudo docker login \
            -u $USER -p $PASS"""
        }
        sh """sudo docker image push \
          ${env.IMAGE}:${env.TAG}"""
        sh """sudo docker image push \
          ${env.IMAGE}:latest"""
      }
      container("helm") {
        sh "helm package helm/go-demo-3"
        withCredentials([usernamePassword(
          credentialsId: "chartmuseum",
          usernameVariable: "USER",
          passwordVariable: "PASS"
        )]) {
          sh """curl -u $USER:$PASS \
            --data-binary "@go-demo-3-${CHART_VER}.tgz" \
            http://${env.CM_ADDR}/api/charts"""
        }
      }
    }
    stage("deploy") {
      try {
        container("helm") {
          sh """helm upgrade \
            go-demo-3 \
            helm/go-demo-3 -i \
            --tiller-namespace go-demo-3-build \
            --namespace go-demo-3 \
            --set image.tag=${env.TAG} \
            --set ingress.host=${env.PROD_ADDRESS}"""
        }
        container("kubectl") {
          sh """kubectl -n go-demo-3 \
            rollout status deployment \
            go-demo-3"""
        }
        container("golang") {
          sh "go get -d -v -t"
          sh """DURATION=1 ADDRESS=${env.PROD_ADDRESS} \
            go test ./... -v \
            --run ProductionTest"""
        }
      } catch(e) {
        container("helm") {
          sh """helm rollback \
            go-demo-3 0 \
            --tiller-namespace go-demo-3-build"""
          error "Failed production tests"
        }
      }
    }
  }
}