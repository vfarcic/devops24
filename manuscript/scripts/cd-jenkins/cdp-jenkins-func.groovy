import java.text.SimpleDateFormat

currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER
env.REPO = "https://github.com/vfarcic/go-demo-3.git"
env.IMAGE = "vfarcic/go-demo-3"
env.ADDRESS = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}.acme.com"
env.TAG_BETA = "${currentBuild.displayName}-${env.BRANCH_NAME}"
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
  }
}