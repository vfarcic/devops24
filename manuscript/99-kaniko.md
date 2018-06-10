```bash
cd ../go-demo-3

docker run -it --rm \
    -v $(pwd):/workspace \
    --entrypoint=/busybox/sh \
    gcr.io/kaniko-project/executor:debug

mkdir /workspace

cd /workspace/

wget https://raw.githubusercontent.com/vfarcic/go-demo-3/master/Dockerfile

/kaniko/executor \
    -d vfarcic/go-demo-3 \
    -c /workspace \
    -f /workspace/Dockerfile
```