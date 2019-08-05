import java.text.SimpleDateFormat

currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER
env.PROJECT = "go-demo-3"
env.REPO = "https://github.com/vfarcic/go-demo-3.git"
env.IMAGE = "vfarcic/go-demo-3"
env.DOMAIN = "acme.com"
env.ADDRESS = "go-demo-3.acme.com"
env.CM_ADDR = "acme.com"
env.CHART_VER = "0.0.1"
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
  - name: oc
    image: vfarcic/openshift-client
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
        k8sBuildImageBeta(env.IMAGE)
      }
    }
    stage("func-test") {
      try {
        container("helm") {
          git "${env.REPO}"
          k8sUpgradeBeta(env.PROJECT, env.DOMAIN)
        }
        container("oc") {
          ocCreateEdgeRouteBuild(env.PROJECT, env.DOMAIN)
        }
        container("kubectl") {
          k8sRolloutBeta(env.PROJECT)
        }
        container("golang") {
          k8sFuncTestGolang(env.PROJECT, env.DOMAIN)
        }
      } catch(e) {
          error "Failed functional tests"
      } finally {
        container("helm") {
          k8sDeleteBeta(env.PROJECT)
        }
      }
    }
    stage("release") {
      node("docker") {
        k8sPushImage(env.IMAGE)
      }
      container("helm") {
        k8sPushHelm(env.PROJECT, env.CHART_VER, env.CM_ADDR)
      }
    }
    stage("deploy") {
      try {
        container("helm") {
          k8sUpgrade(env.PROJECT, env.ADDRESS)
        }
        container("oc") {
          ocCreateEdgeRoute(env.PROJECT, env.ADDRESS)
        }
        container("kubectl") {
          k8sRollout(env.PROJECT)
        }
        container("golang") {
          k8sProdTestGolang(env.ADDRESS)
        }
      } catch(e) {
        container("helm") {
          k8sRollback(env.PROJECT)
        }
      }
    }
  }
}