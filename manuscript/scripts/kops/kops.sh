######################
# Create The Cluster #
######################

# Make sure that your kops version is v1.9 or higher.

# Make sure that all the prerequisites described in the "Appendix B" are met.

# Do not run the commands from below if you are a **Windows** user. You'll have to follow the instructions from the Appendix B instead.

source cluster/kops

chmod +x kops/cluster-setup.sh

NODE_COUNT=2 NODE_SIZE=t2.medium \
    ./kops/cluster-setup.sh

#######################
# Destroy the cluster #
#######################

kops delete cluster --name $NAME --yes

aws s3api delete-bucket \
    --bucket $BUCKET_NAME
