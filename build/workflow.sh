# run the ant
ant

# use sed to replace the template git-sync with secrets and other
TEMPLATE_FILE="./build/git-sync_template.xql"
DESTINATION_FILE="./modules/git-sync.xql"

# SECRET_KEY, $ADMIN_PASSWORD

sed \
    -e "s/\${SECRET_KEY}/$SECRET_KEY/" \
    $TEMPLATE_FILE > $DESTINATION_FILE
