cd $GITHUB_WORKSPACE
echo $(ls)

# remove any old auto deploy
rm -rf autodeploy
# create an autodeploy folder
mkdir autodeploy
# run the ant
ant
# move the xar from build to autodeploy
mv build/*.xar autodeploy/

# use sed to replace the template git-sync with secrets and other
TEMPLATE_FILE="./build/git-sync_template.xql"
DESTINATION_FILE="./modules/git-sync.xql"

# SECRET_KEY, $ADMIN_PASSWORD

sed \
    -e "s/\${SECRET_KEY}/$SECRET_KEY/" \
    $TEMPLATE_FILE > $DESTINATION_FILE


echo docker build $GITHUB_WORKSPACE \
    --file Dockerfile \
    --tag $DOCKERHUB_USERNAME/$REPO_NAME:latest \
    --build-arg ADMIN_PASSWORD=$ADMIN_PASSWORD

docker build $GITHUB_WORKSPACE \
    --file Dockerfile \
    --tag $DOCKERHUB_USERNAME/$REPO_NAME:latest \
    --build-arg ADMIN_PASSWORD=$ADMIN_PASSWORD

docker push $DOCKERHUB_USERNAME/$REPO_NAME:latest