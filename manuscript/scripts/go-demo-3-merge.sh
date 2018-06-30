cd ../go-demo-3

git add .

git commit -m \
    "Packaging Kubernetes Applications chapter"

git push

git remote add upstream \
    https://github.com/vfarcic/go-demo-3.git

git fetch upstream

git checkout master

git merge upstream/master

cd ../k8s-specs